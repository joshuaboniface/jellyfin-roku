function VideoPlayer(id)
  ' Get video controls and UI
  video = CreateObject("roSGNode", "JFVideo")
  video.content = VideoContent(id)

  jellyfin_blue = "#00a4dcFF"

  video.retrievingBar.filledBarBlendColor = jellyfin_blue
  video.bufferingBar.filledBarBlendColor = jellyfin_blue
  video.trickPlayBar.filledBarBlendColor = jellyfin_blue
  return video
end function

function VideoContent(id) as object
  ' Get video stream
  content = createObject("RoSGNode", "ContentNode")

  meta = ItemMetaData(id)
  content.title = meta.Name

  container = getContainerType(meta)

  content.url = buildURL(Substitute("Videos/{0}/stream", id), {
    Static: "true",
    Container: container
  })

  content = authorize_request(content)

  content.streamformat = container
  content.switchingStrategy = ""

  ' todo - audioFormat is read only
  content.audioFormat = getAudioFormat(meta)

  if server_is_https() then
    content.setCertificatesFile("common:/certs/ca-bundle.crt")
  end if

  return content
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
