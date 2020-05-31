function VideoPlayer(id)
  ' Get video controls and UI
  video = CreateObject("roSGNode", "JFVideo")
  video.id = id
  video = VideoContent(video)
  if video = invalid 
    return invalid
  end if
  jellyfin_blue = "#00a4dcFF"

  video.retrievingBar.filledBarBlendColor = jellyfin_blue
  video.bufferingBar.filledBarBlendColor = jellyfin_blue
  video.trickPlayBar.filledBarBlendColor = jellyfin_blue
  return video
end function

function VideoContent(video) as object
  ' Get video stream
  video.content = createObject("RoSGNode", "ContentNode")
  params = {}

  meta = ItemMetaData(video.id)
  video.content.title = meta.Name
  
  ' If there is a last playback positon, ask user if they want to resume
  position = meta.json.UserData.PlaybackPositionTicks
  if position > 0 then
    dialogResult = startPlaybackOver(position)
    'Dialog returns -1 when back pressed, 0 for resume, and 1 for start over
    if dialogResult = -1 then
      'User pressed back, return invalid and don't load video
      return invalid
    else if dialogResult = 1 then
      'Start Over selected, change position to 0
      position = 0
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

    'Original MediaSource seems to be a placeholder and real stream data is avaiable
    'after POSTing to PlaybackInfo
    json = meta.json
    json.AddReplace("MediaSources", playbackInfo.MediaSources)
    json.AddReplace("MediaStreams", playbackInfo.MediaSources[0].MediaStreams)
    meta.json = json
  end if

  container = getContainerType(meta)
  video.container = container

  transcodeParams = getTranscodeParameters(meta)
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

  if video.SelectedSubtitle <> -1 and displaySubtitlesByUserConfig(video.Subtitles[video.SelectedSubtitle], meta.json.MediaStreams[1]) then
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
  video.decodeAudioSupported = decodeAudioSupported(meta)
  video.transcodeParams = transcodeParams

  if video.directPlaySupported and video.decodeAudioSupported and transcodeParams.SubtitleStreamIndex = invalid then
    params.append({
      "Static": "true",
      "Container": container
      "PlaySessionId": video.PlaySessionId
    })
    video.content.url = buildURL(Substitute("Videos/{0}/stream", video.id), params)
    video.content.streamformat = container
    video.content.switchingStrategy = ""
    video.isTranscode = False
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

function getTranscodeParameters(meta as object)
  if decodeAudioSupported(meta) then
    audioCodec = meta.json.MediaStreams[1].codec
    audioChannels = meta.json.MediaStreams[1].channels
  else
    audioCodec = "aac"
    audioChannels = 2

    ' If 5.1 Audio Output is connected then allow transcoding to 5.1
    di = CreateObject("roDeviceInfo")
    if di.GetAudioOutputChannel() = "5.1 surround" and di.CanDecodeAudio({ Codec: "aac", ChCnt: 6 }).result then
      audioChannels = 6
    end if
  end if
  return {
    "VideoCodec": "h264",
    "AudioCodec": audioCodec,
    "MaxAudioChannels": audioChannels,
    "MediaSourceId": meta.id,
    "SegmentContainer": "ts",
    "MinSegments": 1,
    "BreakOnNonKeyFrames": "True",
    "h264-profile": "high,main,baseline,constrainedbaseline",
    "RequireAvc": "false",
  }
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
      url = url + Substitute("Stream.js?api_key={0}&format=srt", get_setting("active_user"))
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
  return option_dialog([ "Resume playing at " + ticksToHuman(time) + ".", "Start over from the beginning." ])
end function

function directPlaySupported(meta as object) as boolean
  devinfo = CreateObject("roDeviceInfo")
  if meta.json.MediaSources[0] <> invalid or meta.json.MediaSources[0].SupportsDirectPlay = false then
    return false
  end if
  return devinfo.CanDecodeVideo({ Codec: meta.json.MediaStreams[0].codec }).result
end function

function decodeAudioSupported(meta as object) as boolean
  devinfo = CreateObject("roDeviceInfo")
  return devinfo.CanDecodeAudio({ Codec: meta.json.MediaStreams[1].codec, ChCnt: meta.json.MediaStreams[1].channels }).result
end function

function getContainerType(meta as object) as string
  ' Determine the file type of the video file source
  print type(meta)
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
  if audioInfo.count() = 0 then return ""
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
  params = {
    "PlaySessionId": video.PlaySessionId,
    "PositionTicks": str(int(video.position)) + "0000000",
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
  video.control = "stop"
  m.device.EnableAppFocusEvent(False)
  video.findNode("playbackTimer").control = "stop"
  video.visible = "false"
  if video.status = "finished" then MarkItemWatched(video.id)
  ReportPlayback(video, "stop")
  RemoveCurrentGroup()
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
