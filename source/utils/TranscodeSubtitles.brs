function selectSubtitleTrack(tracks, current = -1)
  video = m.scene.focusedChild
  trackSelected = selectSubtitleTrackDialog(video.Subtitles, video.SelectedSubtitle)
  if trackSelected = -1  then
    return invalid
  else
    return trackSelected - 1
  end if
end function

function selectSubtitleTrackDialog(tracks, currentTrack = -1)
  iso6392 = getSubtitleLanguages()
  options = ["None"]
  for each item in tracks
    forced = ""
    default = ""
    if item.IsForced then forced = " [Forced]"
    if item.IsDefault then default = " - Default"
    if item.Track.Language <> invalid then
      language = iso6392.lookup(item.Track.Language)
      if language = invalid then language = item.Track.Language
    else 
      language = "Undefined"
    end if
    options.push(language + forced + default)
  end for
  return option_dialog(options, "Select a subtitle track", currentTrack + 1)
end function

sub changeSubtitleDuringPlayback(newid)
  if newid = invalid then return
  if newid = -1 then
    turnoffSubtitles()
    return
  end if

  video = m.scene.focusedChild
  oldTrack = video.Subtitles[video.SelectedSubtitle]
  newTrack = video.Subtitles[newid]

  video.captionMode = video.globalCaptionMode
  m.device.EnableAppFocusEvent(not newTrack.IsTextSubtitleStream)
  video.SelectedSubtitle = newid

  if newTrack.IsTextSubtitleStream then
    if video.content.PlayStart > video.position
      'User has rewinded to before playback was initiated. The Roku never loaded this portion of the text subtitle
      'Changing the track will cause plaback to jump to initial bookmark position.
      video.suppressCaptions = true
      rebuildURL(false)
    end if
    video.subtitleTrack = video.availableSubtitleTracks[newTrack.TextIndex].TrackName
    video.suppressCaptions = false
  else
    video.suppressCaptions = true
  end if

  'Rebuild URL if subtitle track is video or if changed from video subtitle to text subtitle.
  if not newTrack.IsTextSubtitleStream then
    rebuildURL(true)
  else if oldTrack <> invalid and not oldTrack.IsTextSubtitleStream then
    rebuildURL(false)
    if newTrack.TextIndex > 0 then video.subtitleTrack = video.availableSubtitleTracks[newTrack.TextIndex].TrackName
  end if
end sub

function turnoffSubtitles()
  video = m.scene.focusedChild
  current = video.SelectedSubtitle
  video.SelectedSubtitle = -1
  video.suppressCaptions = true
  m.device.EnableAppFocusEvent(false)
  if current > -1 and not video.Subtitles[current].IsTextSubtitleStream then
    rebuildURL(false)
  end if
end function

function systemOverlayClosed()
  video = m.scene.focusedChild
  if video.globalCaptionMode <> video.captionMode then
    video.captionMode = video.globalCaptionMode
    reviewSubtitleDisplay()
  end if
end function

function reviewSubtitleDisplay()
  'TODO handle changing subtitles tracks during playback
  displayed = areSubtitlesDisplayed()
  needed = areSubtitlesNeeded()
  print "displayed: " displayed " needed: " needed
  if areSubtitlesNeeded() and (not areSubtitlesDisplayed()) then 
    rebuildURL(true)
  else if areSubtitlesDisplayed() and (not areSubtitlesNeeded()) then
    rebuildURL(false)
  end if
end function

function areSubtitlesDisplayed()
  index = m.scene.focusedChild.transcodeParams.lookup("SubtitleStreamIndex")
  if index <> invalid and index <> -1 then
    return true
  else 
    return false
  end if
 end function

function areSubtitlesNeeded() 
  captions = m.scene.focusedChild.globalCaptionMode
  if captions = "On"
    return true
  else if captions = "Off"
    return false
  else if captions = "When mute"
    return m.mute
  else if captions = "Instant replay"
    'Unsupported. Do we want to do this? Is it worth transcoding for rewinded content and then untranscoding?
    return false
  end if
end function

sub rebuildURL(captions as boolean)
  playBackBuffer = -5

  video = m.scene.focusedChild
  video.control = "pause"

  tmpParams = video.transcodeParams
  if captions = false then
    tmpParams.delete("SubtitleStreamIndex")
  else
    if video.Subtitles[video.SelectedSubtitle] <> invalid then
      tmpParams.addreplace("SubtitleStreamIndex", int(video.Subtitles[video.SelectedSubtitle].Index))
    end if
  end if

  if video.isTranscoded then
    deleteTranscode(video.PlaySessionId)
  end if
  video.PlaySessionId = ItemGetPlaybackInfo(video.id, int(video.position) + playBackBuffer).PlaySessionId
  tmpParams.PlaySessionId  = video.PlaySessionId
  video.transcodeParams = tmpParams

  if video.directPlaySupported and video.decodeAudioSupported and not captions then
    'Captions are off and we do not need to transcode video or audo
    base = Substitute("Videos/{0}/stream", video.id)
    params = {
      "Static": "true",
      "Container": video.container
      "PlaySessionId": video.PlaySessionId
    }
    video.isTranscoded = false
    video.content.streamformat = video.container
  else
    'Captions are on or we need to transcode for any other reason
    video.content.streamformat = "hls"
    base = Substitute("Videos/{0}/master.m3u8", video.id)
    video.isTranscoded = true
    params = video.transcodeParams
  end if

  video.content.url = buildURL(base, params)
  video.content.PlayStart = int(video.position + playBackBuffer)
  video.control = "play"
end sub
