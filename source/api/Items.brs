function ItemGetPlaybackInfo(id as string, startTimeTicks = 0 as longinteger)
    params = {
        "UserId": get_setting("active_user"),
        "StartTimeTicks": startTimeTicks,
        "IsPlayback": true,
        "AutoOpenLiveStream": true,
        "MaxStreamingBitrate": "140000000"
    }
    resp = APIRequest(Substitute("Items/{0}/PlaybackInfo", id), params)
    return getJson(resp)
end function

function ItemPostPlaybackInfo(id as string, mediaSourceId = "" as string, audioTrackIndex = -1 as integer, subtitleTrackIndex = -1 as integer, startTimeTicks = 0 as longinteger)
    body = {
        "DeviceProfile": getDeviceProfile()
    }
    params = {
        "UserId": get_setting("active_user"),
        "StartTimeTicks": startTimeTicks,
        "IsPlayback": true,
        "AutoOpenLiveStream": true,
        "MaxStreamingBitrate": "140000000",
        "MaxStaticBitrate": "140000000",
        "SubtitleStreamIndex": subtitleTrackIndex
    }

    if mediaSourceId <> "" then params.MediaSourceId = mediaSourceId

    if audioTrackIndex > -1 then params.AudioStreamIndex = audioTrackIndex

    req = APIRequest(Substitute("Items/{0}/PlaybackInfo", id), params)
    req.SetRequest("POST")
    return postJson(req, FormatJson(body))
end function

' Search across all libraries
function SearchMedia(query as string)
    ' This appears to be done differently on the web now
    ' For each potential type, a separate query is done:
    ' varying item types, and artists, and people
    resp = APIRequest(Substitute("Users/{0}/Items", get_setting("active_user")), {
        "searchTerm": query,
        "IncludePeople": true,
        "IncludeMedia": true,
        "IncludeShows": true,
        "IncludeGenres": false,
        "IncludeStudios": false,
        "IncludeArtists": false,
        "IncludeItemTypes": "TvChannel,Movie,BoxSet,Series,Episode,Video"
        "EnableTotalRecordCount": false,
        "ImageTypeLimit": 1,
        "Recursive": true
    })

    data = getJson(resp)
    results = []
    for each item in data.Items
        tmp = CreateObject("roSGNode", "SearchData")
        tmp.image = PosterImage(item.id)
        tmp.json = item
        results.push(tmp)
    end for
    data.SearchHints = results
    return data
end function

' MetaData about an item
function ItemMetaData(id as string)
    url = Substitute("Users/{0}/Items/{1}", get_setting("active_user"), id)
    resp = APIRequest(url)
    data = getJson(resp)
    if data = invalid then return invalid
    imgParams = {}
    if data.UserData.PlayedPercentage <> invalid
        param = { "PercentPlayed": data.UserData.PlayedPercentage }
        imgParams.Append(param)
    end if
    if data.type = "Movie"
        tmp = CreateObject("roSGNode", "MovieData")
        tmp.image = PosterImage(data.id, imgParams)
        tmp.json = data
        return tmp
    else if data.type = "Series"
        tmp = CreateObject("roSGNode", "SeriesData")
        tmp.image = PosterImage(data.id)
        tmp.json = data
        return tmp
    else if data.type = "Episode"
        ' param = { "AddPlayedIndicator": data.UserData.Played }
        ' imgParams.Append(param)
        tmp = CreateObject("roSGNode", "TVEpisodeData")
        tmp.image = PosterImage(data.id, imgParams)
        tmp.json = data
        return tmp
    else if data.type = "BoxSet"
        tmp = CreateObject("roSGNode", "CollectionData")
        tmp.image = PosterImage(data.id, imgParams)
        tmp.json = data
        return tmp
    else if data.type = "Season"
        tmp = CreateObject("roSGNode", "TVSeasonData")
        tmp.image = PosterImage(data.id)
        tmp.json = data
        return tmp
    else if data.type = "Video"
        tmp = CreateObject("roSGNode", "VideoData")
        tmp.image = PosterImage(data.id)
        tmp.json = data
        return tmp
    else if data.type = "TvChannel"
        tmp = CreateObject("roSGNode", "ChannelData")
        tmp.image = PosterImage(data.id)
        tmp.json = data
        return tmp
    else
        print "Items.brs::ItemMetaData processed unhandled type: " data.type
        ' Return json if we don't know what it is
        return data
    end if
end function

' Seasons for a TV Show
function TVSeasons(id as string)
    url = Substitute("Shows/{0}/Seasons", id)
    resp = APIRequest(url, { "UserId": get_setting("active_user") })

    data = getJson(resp)
    results = []
    for each item in data.Items
        imgParams = { "AddPlayedIndicator": item.UserData.Played }
        if item.UserData.UnplayedItemCount > 0
            param = { "UnplayedCount": item.UserData.UnplayedItemCount }
            imgParams.Append(param)
        end if
        tmp = CreateObject("roSGNode", "TVEpisodeData")
        tmp.image = PosterImage(item.id, imgParams)
        tmp.json = item
        results.push(tmp)
    end for
    data.Items = results
    return data
end function

function TVEpisodes(show_id as string, season_id as string)
    url = Substitute("Shows/{0}/Episodes", show_id)
    resp = APIRequest(url, { "seasonId": season_id, "UserId": get_setting("active_user") })

    data = getJson(resp)
    results = []
    for each item in data.Items
        imgParams = { "AddPlayedIndicator": item.UserData.Played, "maxWidth": 712, "maxheight": 400 }
        if item.UserData.PlayedPercentage <> invalid
            param = { "PercentPlayed": item.UserData.PlayedPercentage }
            imgParams.Append(param)
        end if
        tmp = CreateObject("roSGNode", "TVEpisodeData")
        tmp.image = PosterImage(item.id, imgParams)
        if tmp.image <> invalid
            tmp.image.posterDisplayMode = "scaleToFit"
        end if
        tmp.json = item
        tmp.overview = ItemMetaData(item.id).overview
        results.push(tmp)
    end for
    data.Items = results
    return data
end function
