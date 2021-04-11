function VideoPlayer(id, audio_stream_idx = 1) 
  ' Get video controls and UI
  video = CreateObject("roSGNode", "JFVideo")
  video.id = id
  video = VideoContent(video, audio_stream_idx)
  if video = invalid 
    return invalid
  end if
  jellyfin_blue = "#00a4dcFF"

  video.retrievingBar.filledBarBlendColor = jellyfin_blue
  video.bufferingBar.filledBarBlendColor = jellyfin_blue
  video.trickPlayBar.filledBarBlendColor = jellyfin_blue
  return video
end function

function VideoContent(video, audio_stream_idx = 1) as object
  ' Get video stream
  video.content = createObject("RoSGNode", "ContentNode")
  params = {}

  meta = ItemMetaData(video.id)
  video.content.title = meta.title
  video.showID = meta.showID
  
  ' If there is a last playback positon, ask user if they want to resume
  position = meta.json.UserData.PlaybackPositionTicks
  if position > 0 then
    dialogResult = startPlayBackOver(position)
    'Dialog returns -1 when back pressed, 0 for resume, and 1 for start over
    if dialogResult = -1 then
      'User pressed back, return invalid and don't load video
      return invalid
    else if dialogResult = 1 then
      'Start Over selected, change position to 0
      position = 0
    else if dialogResult = 2 then
      'Mark this item as watched, refresh the page, and return invalid so we don't load the video
      MarkItemWatched(video.id)
      video.content.watched = not video.content.watched
      group = m.scene.focusedChild
      group.timeLastRefresh = CreateObject("roDateTime").AsSeconds()
      group.callFunc("refresh")
      return invalid
    end if
  end if
  video.content.PlayStart = int(position/10000000)

  playbackInfo = ItemPostPlaybackInfo(video.id, position)

  if playbackInfo = invalid then
    return invalid
  end if

  video.PlaySessionId = playbackInfo.PlaySessionId

  if meta.live then
    video.content.live = true
    video.content.StreamFormat = "hls"

    'Original MediaSource seems to be a placeholder and real stream data is available
    'after POSTing to PlaybackInfo
    json = meta.json
    json.AddReplace("MediaSources", playbackInfo.MediaSources)
    json.AddReplace("MediaStreams", playbackInfo.MediaSources[0].MediaStreams)
    meta.json = json
  end if

  container = getContainerType(meta)
  video.container = container

  transcodeParams = getTranscodeParameters(meta, audio_stream_idx)
  transcodeParams.append({"PlaySessionId": video.PlaySessionId})

  if meta.live then
    _livestream_params = {
      "MediaSourceId": playbackInfo.MediaSources[0].Id,
      "LiveStreamId": playbackInfo.MediaSources[0].LiveStreamId,
      "MinSegments": 2  'This is a guess about initial buffer size, segments are 3s each
    }
    params.append(_livestream_params)
    transcodeParams.append(_livestream_params)
  end if

  subtitles =  sortSubtitles(meta.id,meta.json.MediaStreams)
  video.Subtitles = subtitles["all"]
  video.content.SubtitleTracks = subtitles["text"]

  'TODO: allow user selection of subtitle track before playback initiated, for now set to first track
  if video.Subtitles.count() then
    video.SelectedSubtitle = 0
  else
    video.SelectedSubtitle = -1
  end if

  if video.SelectedSubtitle <> -1 and displaySubtitlesByUserConfig(video.Subtitles[video.SelectedSubtitle], meta.json.MediaStreams[audio_stream_idx]) then
    if video.Subtitles[0].IsTextSubtitleStream then
      video.subtitleTrack = video.availableSubtitleTracks[video.Subtitles[0].TextIndex].TrackName
      video.suppressCaptions = false
    else
      video.suppressCaptions = true
      'Watch to see if system overlay opened/closed to change transcoding if caption mode changed
      m.device.EnableAppFocusEvent(True)
      video.captionMode = video.globalCaptionMode
      if video.globalCaptionMode = "On" or (video.globalCaptionMode = "When mute" and m.mute = true) then
        'Only transcode if subtitles are turned on
        transcodeParams.append({"SubtitleStreamIndex" : video.Subtitles[0].index })
      end if
    end if
  else
    video.suppressCaptions = true
    video.SelectedSubtitle = -1
  end if

  video.directPlaySupported = directPlaySupported(meta)
  video.decodeAudioSupported = decodeAudioSupported(meta, audio_stream_idx)
  video.transcodeParams = transcodeParams

  if video.directPlaySupported and video.decodeAudioSupported and transcodeParams.SubtitleStreamIndex = invalid then
    params.append({
      "Static": "true",
      "Container": container,
      "PlaySessionId": video.PlaySessionId,
      "AudioStreamIndex": audio_stream_idx
    })
    video.content.url = buildURL(Substitute("Videos/{0}/stream", video.id), params)
    video.content.streamformat = container
    video.content.switchingStrategy = ""
    video.isTranscode = False
    video.audioTrack = audio_stream_idx + 1 ' Tell Roku what Audio Track to play (convert from 0 based index for roku)
  else
    video.content.url = buildURL(Substitute("Videos/{0}/master.m3u8", video.id), transcodeParams)
    video.isTranscoded = true
  end if
  video.content = authorize_request(video.content)

  ' todo - audioFormat is read only
  video.content.audioFormat = getAudioFormat(meta)
  video.content.setCertificatesFile("common:/certs/ca-bundle.crt")
  return video
end function


function getTranscodeParameters(meta as object, audio_stream_idx = 1)

  params = {"AudioStreamIndex": audio_stream_idx}
  if decodeAudioSupported(meta, audio_stream_idx) and meta.json.MediaStreams[audio_stream_idx] <> invalid and meta.json.MediaStreams[audio_stream_idx].Type = "Audio" then
    audioCodec = meta.json.MediaStreams[audio_stream_idx].codec
    audioChannels = meta.json.MediaStreams[audio_stream_idx].channels
  else
    params.Append({"AudioCodec": "aac"})

    ' If 5.1 Audio Output is connected then allow transcoding to 5.1
    di = CreateObject("roDeviceInfo")
    if di.GetAudioOutputChannel() = "5.1 surround" and di.CanDecodeAudio({ Codec: "aac", ChCnt: 6 }).result then
      params.Append({"MaxAudioChannels": "6"})
    else
      params.Append({"MaxAudioChannels": "2"})
    end if
  end if

  streamInfo = {}
  
  if meta.json.MediaStreams[0] <> invalid and meta.json.MediaStreams[0].codec <> invalid then
    streamInfo.Codec = meta.json.MediaStreams[0].codec
  end if
	
  if meta.json.MediaStreams[0] <> invalid and meta.json.MediaStreams[0].Profile <> invalid and meta.json.MediaStreams[0].Profile.len() > 0 then
    streamInfo.Profile = LCase(meta.json.MediaStreams[0].Profile)
  end if
  if meta.json.MediaSources[0] <> invalid and meta.json.MediaSources[0].container <> invalid and meta.json.MediaSources[0].container.len() > 0  then
    streamInfo.Container = meta.json.MediaSources[0].container
  end if

  devinfo = CreateObject("roDeviceInfo")
  res = devinfo.CanDecodeVideo(streamInfo)

  if res.result = false then
    params.Append({"VideoCodec": "h264"})
    streamInfo.Profile = "h264"
    streamInfo.Container = "ts"
  end if

  params.Append({"MediaSourceId": meta.id})
  params.Append({"DeviceId": devinfo.getChannelClientID()})

  return params
end function

'Checks available subtitle tracks and puts subtitles in forced, default, and non-default/forced but preferred language at the top
function sortSubtitles(id as string, MediaStreams)
  tracks = { "forced": [], "default": [], "normal": [] }
  'Too many args for using substitute
  dashedid = id.left(8) + "-" + id.mid(8,4) + "-" + id.mid(12,4) + "-" + id.mid(16,4) + "-" + id.right(12)
  prefered_lang = m.user.Configuration.SubtitleLanguagePreference
  for each stream in MediaStreams
    if stream.type = "Subtitle" then
      'Documentation lists that srt, ttml, and dfxp can be sideloaded but only srt was working in my testing,
      'forcing srt for all text subtitles
      url = Substitute("{0}/Videos/{1}/{2}/Subtitles/{3}/0/", get_url(), dashedid, id, stream.index.tostr())
      url = url + Substitute("Stream.srt?api_key={0}", get_setting("active_user"))
      stream = {
        "Track": { "Language" : stream.language, "Description": stream.displaytitle , "TrackName": url },
        "IsTextSubtitleStream": stream.IsTextSubtitleStream,
        "Index": stream.index,
        "TextIndex": -1,
        "IsDefault": stream.IsDefault,
        "IsForced": stream.IsForced
      }
      if stream.isForced then
        trackType = "forced"
      else if stream.IsDefault then
        trackType = "default"
      else
        trackType = "normal"
      end if
      if prefered_lang <> "" and prefered_lang = stream.Track.Language then
        tracks[trackType].unshift(stream)
      else
        tracks[trackType].push(stream)
      end if
    end if
  end for
  tracks["default"].append(tracks["normal"])
  tracks["forced"].append(tracks["default"])
  textTracks = []
  for i = 0 to tracks["forced"].count() - 1
    if tracks["forced"][i].IsTextSubtitleStream then tracks["forced"][i].TextIndex = textTracks.count()
    textTracks.push(tracks["forced"][i].Track)
  end for
  return { "all" : tracks["forced"], "text": textTracks }
end function

'Opens dialog asking user if they want to resume video or start playback over
function startPlayBackOver(time as LongInteger) as integer
  if m.scene.focusedChild.overhangTitle = "Home" then
    return option_dialog([ "Resume playing at " + ticksToHuman(time) + ".", "Start over from the beginning.", "Watched"])
  else
    return option_dialog([ "Resume playing at " + ticksToHuman(time) + ".", "Start over from the beginning."])
  endif
end function

function directPlaySupported(meta as object) as boolean
  devinfo = CreateObject("roDeviceInfo")
  if meta.json.MediaSources[0] <> invalid and meta.json.MediaSources[0].SupportsDirectPlay = false then
    return false
  end if

  if meta.json.MediaStreams[0] = invalid then
    return false
  end if

  streamInfo =  { Codec: meta.json.MediaStreams[0].codec }
  if meta.json.MediaStreams[0].Profile <> invalid and meta.json.MediaStreams[0].Profile.len() > 0 then
    streamInfo.Profile = LCase(meta.json.MediaStreams[0].Profile)
  end if
  if meta.json.MediaSources[0].container <> invalid and meta.json.MediaSources[0].container.len() > 0  then
    'CanDecodeVideo() requires the .container to be format: “mp4”, “hls”, “mkv”, “ism”, “dash”, “ts” if its to direct stream
    if meta.json.MediaSources[0].container = "mov" then 
        streamInfo.Container = "mp4"
    else
    	streamInfo.Container = meta.json.MediaSources[0].container
    end if
  end if
  return devinfo.CanDecodeVideo(streamInfo).result
end function

function decodeAudioSupported(meta as object, audio_stream_idx = 1) as boolean

  'Check for missing audio and allow playing
  if meta.json.MediaStreams[audio_stream_idx] = invalid or meta.json.MediaStreams[audio_stream_idx].Type <> "Audio" then return true
  if meta.json.MediaStreams[audio_stream_idx]["Codec"] = "opus" return false
  devinfo = CreateObject("roDeviceInfo")
  codec = meta.json.MediaStreams[audio_stream_idx].codec
  streamInfo = { Codec: codec, ChCnt: meta.json.MediaStreams[audio_stream_idx].channels }

  'Otherwise check Roku can decode stream and channels
  canDecode = devinfo.CanDecodeAudio(streamInfo)
  return canDecode.result
end function

function getContainerType(meta as object) as string
  ' Determine the file type of the video file source
  if meta.json.mediaSources = invalid then return ""

  container = meta.json.mediaSources[0].container
  if container = invalid
    container = ""
  else if container = "m4v" or container = "mov"
    container = "mp4"
  end if

  return container
end function

function getAudioFormat(meta as object) as string
  ' Determine the codec of the audio file source
  if meta.json.mediaSources = invalid then return ""

  audioInfo = getAudioInfo(meta)
  if audioInfo.count() = 0 or audioInfo[0].codec = invalid then return ""
  return audioInfo[0].codec
end function

function getAudioInfo(meta as object) as object
  ' Return audio metadata for a given stream
  results = []
  for each source in meta.json.mediaSources[0].mediaStreams
    if source["type"] = "Audio"
      results.push(source)
    end if
  end for
  return results
end function

function ReportPlayback(video, state = "update" as string)

  if video = invalid or video.position = invalid then return void

  params = {
    "PlaySessionId": video.PlaySessionId,
    "PositionTicks": int(video.position) * 10000000&,   'Ensure a LongInteger is used
    "IsPaused": (video.state = "paused"),
  }
  if video.content.live then
    params.append({
      "MediaSourceId": video.transcodeParams.MediaSourceId,
      "LiveStreamId": video.transcodeParams.LiveStreamId
    })
  end if
  PlaystateUpdate(video.id, state, params)
end function

function StopPlayback()
  video = m.scene.focusedchild
  if video.state = "finished" then MarkItemWatched(video.id)
  video.control = "stop"
  m.device.EnableAppFocusEvent(False)
  video.findNode("playbackTimer").control = "stop"
  ReportPlayback(video, "stop")
end function

function displaySubtitlesByUserConfig(subtitleTrack, audioTrack)
  subtitleMode = m.user.Configuration.SubtitleMode
  audioLanguagePreference = m.user.Configuration.AudioLanguagePreference
  subtitleLanguagePreference = m.user.Configuration.SubtitleLanguagePreference
  if subtitleMode = "Default"
    return (subtitleTrack.isForced or subtitleTrack.isDefault)
  else if subtitleMode = "Smart"
    return (audioLanguagePreference <> "" and audioTrack.Language <> invalid and subtitleLanguagePreference <> "" and subtitleTrack.Track.Language <> invalid and subtitleLanguagePreference = subtitleTrack.Track.Language and audioLanguagePreference <> audioTrack.Language)
  else if subtitleMode = "OnlyForced"
    return subtitleTrack.IsForced
  else if subtitleMode = "Always"
    return true
  else if subtitleMode = "None"
    return false
  else
    return false
  end if
end function

function autoPlayNextEpisode(videoID as string, showID as string)
  ' use web client setting
  if m.user.Configuration.EnableNextEpisodeAutoPlay then
    ' query API for next episode ID
    url = Substitute("Shows/{0}/Episodes", showID)
    urlParams = { "UserId": get_setting("active_user")}
    urlParams.Append({ "StartItemId": videoID })
    urlParams.Append({ "Limit": 2 })
    resp = APIRequest(url, urlParams)
    data = getJson(resp)
    
    if data <> invalid and data.Items.Count() = 2 then
      ' remove finished video node
      n = m.scene.getChildCount() - 1
      m.scene.removeChildIndex(n)
      ' setup new video node
      nextVideo = CreateVideoPlayerGroup(data.Items[1].Id)
      m.scene.appendChild(nextVideo)
      nextVideo.setFocus(true)
      nextVideo.control = "play"
      ReportPlayback(nextVideo, "start")
      return nextVideo
    else
      ' can't play next episode
      RemoveCurrentGroup()
    end if
  else
    RemoveCurrentGroup()
  end if
  return invalid
end function
