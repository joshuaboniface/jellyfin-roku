sub init()

    m.itemText = m.top.findNode("itemText")
    m.itemPoster = m.top.findNode("itemPoster")
    m.itemIcon = m.top.findNode("itemIcon")
    m.itemTextExtra = m.top.findNode("itemTextExtra")
    m.itemPoster.observeField("loadStatus", "onPosterLoadStatusChanged")

    ' Randomize the background colors
    m.backdrop = m.top.findNode("backdrop")
    posterBackgrounds = m.global.constants.poster_bg_pallet
    m.backdrop.color = posterBackgrounds[rnd(posterBackgrounds.count()) - 1]

end sub


sub itemContentChanged()
    itemData = m.top.itemContent
    if itemData = invalid then return
    itemData.Title = itemData.name ' Temporarily required while we move from "HomeItem" to "JFContentItem"


    m.itemPoster.width = itemData.imageWidth
    m.itemText.maxWidth = itemData.imageWidth
    m.itemTextExtra.width = itemData.imageWidth
    m.itemTextExtra.visible = true


    m.backdrop.width = itemData.imageWidth

    if itemData.iconUrl <> invalid
        m.itemIcon.uri = itemData.iconUrl
    end if

    ' Format the Data based on the type of Home Data
    if itemData.type = "CollectionFolder" or itemData.type = "UserView" or itemData.type = "Channel"
        m.itemText.text = itemData.name
        m.itemPoster.uri = itemData.widePosterURL
        return
    end if

    if itemData.type = "UserView"
        m.itemPoster.width = "96"
        m.itemPoster.height = "96"
        m.itemPoster.translation = "[192, 88]"
        m.itemText.text = itemData.name
        m.itemPoster.uri = itemData.widePosterURL
        return
    end if


    m.itemText.height = 34
    m.itemText.font.size = 25
    m.itemText.horizAlign = "left"
    m.itemText.vertAlign = "bottom"
    m.itemTextExtra.visible = true
    m.itemTextExtra.font.size = 22


    if itemData.type = "Episode"
        m.itemText.text = itemData.json.SeriesName

        if itemData.usePoster = true
            m.itemPoster.uri = itemData.widePosterURL
        else
            m.itemPoster.uri = itemData.thumbnailURL
        end if

        ' Set Series and Episode Number for Extra Text
        extraPrefix = ""
        if itemData.json.ParentIndexNumber <> invalid
            extraPrefix = "S" + StrI(itemData.json.ParentIndexNumber).trim()
        end if
        if itemData.json.IndexNumber <> invalid
            extraPrefix = extraPrefix + "E" + StrI(itemData.json.IndexNumber).trim()
        end if
        if extraPrefix.len() > 0
            extraPrefix = extraPrefix + " - "
        end if

        m.itemTextExtra.text = extraPrefix + itemData.name
        return
    end if

    if itemData.type = "Movie"
        m.itemText.text = itemData.name

        ' Use best image, but fallback to secondary if it's empty
        if (itemData.imageWidth = 180 and itemData.posterURL <> "") or itemData.thumbnailURL = ""
            m.itemPoster.uri = itemData.posterURL
        else
            m.itemPoster.uri = itemData.thumbnailURL
        end if

        ' Set Release Year and Age Rating for Extra Text
        textExtra = ""
        if itemData.json.ProductionYear <> invalid
            textExtra = StrI(itemData.json.ProductionYear).trim()
        end if
        if itemData.json.OfficialRating <> invalid
            if textExtra <> ""
                textExtra = textExtra + " - " + itemData.json.OfficialRating
            else
                textExtra = itemData.json.OfficialRating
            end if
        end if
        m.itemTextExtra.text = textExtra

        return
    end if

    if itemData.type = "Video"
        m.itemText.text = itemData.name

        if itemData.imageWidth = 180
            m.itemPoster.uri = itemData.posterURL
        else
            m.itemPoster.uri = itemData.thumbnailURL
        end if
        return
    end if
    if itemData.type = "Series"

        m.itemText.text = itemData.name

        if itemData.usePoster = true
            if itemData.imageWidth = 180
                m.itemPoster.uri = itemData.posterURL
            else
                m.itemPoster.uri = itemData.widePosterURL
            end if
        else
            m.itemPoster.uri = itemData.thumbnailURL
        end if

        textExtra = ""
        if itemData.json.ProductionYear <> invalid
            textExtra = StrI(itemData.json.ProductionYear).trim()
        end if

        ' Set Years Run for Extra Text
        if itemData.json.Status = "Continuing"
            textExtra = textExtra + " - Present"
        else if itemData.json.Status = "Ended" and itemData.json.EndDate <> invalid
            textExtra = textExtra + " - " + LEFT(itemData.json.EndDate, 4)
        end if
        m.itemTextExtra.text = textExtra

        return
    end if

    if itemData.type = "MusicAlbum"
        m.itemText.text = itemData.name
        m.itemTextExtra.text = itemData.json.AlbumArtist
        m.itemPoster.uri = itemData.posterURL
        return
    end if

    print "Unhandled Item Type: " + itemData.type

end sub

'
' Enable title scrolling based on item Focus
sub focusChanged()

    if m.top.itemHasFocus = true
        m.itemText.repeatCount = -1
    else
        m.itemText.repeatCount = 0
    end if

end sub

'Hide backdrop and icon when poster loaded
sub onPosterLoadStatusChanged()
    if m.itemPoster.loadStatus = "ready" and m.itemPoster.uri <> ""
        m.backdrop.visible = false
        m.itemIcon.visible = false
    else
        m.backdrop.visible = true
        m.itemIcon.visible = true
    end if
end sub