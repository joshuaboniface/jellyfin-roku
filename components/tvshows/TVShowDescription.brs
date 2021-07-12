sub init()
    buttons = m.top.findNode("buttons")

    buttons.iconUri = ""

    for each button in buttons.getChildren(-1, 0)
        button.maxWidth = 350
        button.minWidth = 350
    end for
end sub

sub itemContentChanged()
    ' Updates video metadata
    ' TODO - make things use item rather than itemData
    item = m.top.itemContent
    itemData = item.json

    m.top.findNode("tvshowPoster").uri = m.top.itemContent.posterURL

    ' Handle all "As Is" fields
    setFieldText("title", itemData.name)
    setFieldText("releaseYear", itemData.productionYear)
    setFieldText("officialRating", itemData.officialRating)
    setFieldText("communityRating", str(itemData.communityRating))
    setFieldText("overview", itemData.overview)


    if type(itemData.RunTimeTicks) = "LongInteger"
        setFieldText("runtime", stri(getRuntime()) + " mins")
    end if

    setFieldText("history", getHistory())

    if itemData.genres.count() > 0
        setFieldText("genres", itemData.genres.join(", "))
    end if
    for each person in itemData.people
        if person.type = "Director"
            exit for
        end if
    end for
    if itemData.taglines.count() > 0
        setFieldText("tagline", itemData.taglines[0])
    end if
end sub

sub setFieldText(field, value)
    node = m.top.findNode(field)
    if node = invalid or value = invalid then return

    ' Handle non strings... Which _shouldn't_ happen, but hey
    if type(value) = "roInt" or type(value) = "Integer"
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

function getHistory() as string
    itemData = m.top.itemContent.json
    ' Aired Fridays at 9:30 PM on ABC (US)

    airwords = invalid
    studio = invalid
    if itemData.status = "Ended"
        verb = "Aired"
    else
        verb = "Airs"
    end if

    airdays = itemData.airdays
    airtime = itemData.airtime
    if airtime <> invalid and airdays.count() = 1
        airwords = airdays[0] + " at " + airtime
    end if

    if itemData.studios.count() > 0
        studio = itemData.studios[0].name
    end if

    if studio = invalid and airwords = invalid
        return ""
    end if

    words = verb
    if airwords <> invalid
        words = words + " " + airwords
    end if
    if studio <> invalid
        words = words + " on " + studio
    end if

    return words
end function

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

