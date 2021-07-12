sub init()
    m.top.optionsAvailable = false
    m.options = m.top.findNode("options")

    main = m.top.findNode("main_group")
    main.translation = [96, 175]

    overview = m.top.findNode("overview")
    overview.width = 1920 - 96 - 300 - 96 - 30

    m.top.findNode("buttons").setFocus(true)
end sub

sub itemContentChanged()
    ' Updates video metadata
    item = m.top.itemContent
    itemData = item.json
    m.top.id = itemData.id
    m.top.findNode("moviePoster").uri = m.top.itemContent.posterURL

    ' Find first Audio Stream and set that as default
    for i = 0 to itemData.mediaStreams.Count() - 1
        if itemData.mediaStreams[i].Type = "Audio"
            m.top.selectedAudioStreamIndex = i
            exit for
        end if
    end for

    ' Handle all "As Is" fields
    m.top.overhangTitle = itemData.name
    setFieldText("releaseYear", itemData.productionYear)
    setFieldText("officialRating", itemData.officialRating)
    setFieldText("overview", itemData.overview)

    if itemData.communityRating <> invalid
        setFieldText("communityRating", itemData.communityRating)
    else
        ' hide the star icon
        m.top.findNode("communityRatingGroup").visible = false
    end if

    if itemData.CriticRating <> invalid
        setFieldText("criticRatingLabel", itemData.criticRating)
        if itemData.CriticRating > 60
            tomato = "pkg:/images/fresh.png"
        else
            tomato = "pkg:/images/rotten.png"
        end if
        m.top.findNode("criticRatingIcon").uri = tomato
    else
        m.top.findNode("infoGroup").removeChild(m.top.findNode("criticRatingGroup"))
    end if

    if type(itemData.RunTimeTicks) = "LongInteger"
        setFieldText("runtime", stri(getRuntime()) + " mins")
        setFieldText("ends-at", tr("Ends at %1").Replace("%1", getEndTime()))
    end if

    if itemData.genres.count() > 0
        setFieldText("genres", tr("Genres") + ": " + itemData.genres.join(", "))
    end if

    ' show tags if there are no genres to display
    if itemData.genres.count() = 0 and itemData.tags.count() > 0
        setFieldText("genres", tr("Tags") + ": " + itemData.tags.join(", "))
    end if

    directors = []
    for each person in itemData.people
        if person.type = "Director"
            directors.push(person.name)
        end if
    end for
    if directors.count() > 0
        setFieldText("director", tr("Director") + ": " + directors.join(", "))
    end if

    if itemData.mediaStreams[0] <> invalid
        setFieldText("video_codec", tr("Video") + ": " + itemData.mediaStreams[0].displayTitle)
    end if
    if itemData.mediaStreams[m.top.selectedAudioStreamIndex] <> invalid
        setFieldText("audio_codec", tr("Audio") + ": " + itemData.mediaStreams[m.top.selectedAudioStreamIndex].displayTitle)
    end if
    ' TODO - cmon now. these are buttons, not words
    if itemData.taglines.count() > 0
        setFieldText("tagline", itemData.taglines[0])
    end if
    setFavoriteColor()
    setWatchedColor()
    SetUpOptions(itemData.mediaStreams)
end sub


sub SetUpOptions(streams)

    tracks = []

    for i = 0 to streams.Count() - 1
        if streams[i].Type = "Audio"
            tracks.push({ "Title": streams[i].displayTitle, "Description": streams[i].Title, "Selected": m.top.selectedAudioStreamIndex = i, "StreamIndex": i })
        end if
    end for

    options = {}
    options.views = tracks
    m.options.options = options

end sub


sub setFieldText(field, value)
    node = m.top.findNode(field)
    if node = invalid or value = invalid then return

    ' Handle non strings... Which _shouldn't_ happen, but hey
    if type(value) = "roInt" or type(value) = "Integer"
        value = str(value)
    else if type(value) = "roFloat" or type(value) = "Float"
        value = str(value)
    else if type(value) <> "roString" and type(value) <> "String"
        value = ""
    end if

    node.text = value
end sub

function getRuntime() as integer
    itemData = m.top.itemContent.json

    ' A tick is .1ms, so 1/10,000,000 for ticks to seconds,
    ' then 1/60 for seconds to minutess... 1/600,000,000
    return round(itemData.RunTimeTicks / 600000000.0)
end function

function getEndTime() as string
    itemData = m.top.itemContent.json

    date = CreateObject("roDateTime")
    duration_s = int(itemData.RunTimeTicks / 10000000.0)
    date.fromSeconds(date.asSeconds() + duration_s)
    date.toLocalTime()

    return formatTime(date)
end function

sub setFavoriteColor()
    fave = m.top.itemContent.favorite
    fave_button = m.top.findNode("favorite-button")
    if fave <> invalid and fave
        fave_button.textColor = "#00ff00ff"
        fave_button.focusedTextColor = "#269926ff"
    else
        fave_button.textColor = "0xddddddff"
        fave_button.focusedTextColor = "#262626ff"
    end if
end sub

sub setWatchedColor()
    watched = m.top.itemContent.watched
    watched_button = m.top.findNode("watched-button")
    if watched
        watched_button.textColor = "#ff0000ff"
        watched_button.focusedTextColor = "#992626ff"
    else
        watched_button.textColor = "0xddddddff"
        watched_button.focusedTextColor = "#262626ff"
    end if
end sub

function round(f as float) as integer
    ' BrightScript only has a "floor" round
    ' This compares floor to floor + 1 to find which is closer
    m = int(f)
    n = m + 1
    x = abs(f - m)
    y = abs(f - n)
    if y > x
        return m
    else
        return n
    end if
end function

'
'Check if options updated and any reloading required
sub optionsClosed()
    if m.options.audioSteamIndex <> m.top.selectedAudioStreamIndex
        m.top.selectedAudioStreamIndex = m.options.audioSteamIndex
        setFieldText("audio_codec", tr("Audio") + ": " + m.top.itemContent.json.mediaStreams[m.top.selectedAudioStreamIndex].displayTitle)
    end if
    m.top.findNode("buttons").setFocus(true)
end sub


function onKeyEvent(key as string, press as boolean) as boolean

    ' Due to the way the button pressed event works, need to catch the release for the button as the press is being sent
    ' directly to the main loop.  Will get this sorted in the layout update for Movie Details
    if key = "OK" and m.top.findNode("audio-button").isInFocusChain()
        m.options.visible = true
        m.options.setFocus(true)
    end if

    if not press then return false

    if key = "options"
        if m.options.visible = true
            m.options.visible = false
            optionsClosed()
        else
            m.options.visible = true
            m.options.setFocus(true)
        end if
        return true
    else if key = "back"
        if m.options.visible = true
            m.options.visible = false
            optionsClosed()
            return true
        end if
    end if
    return false
end function