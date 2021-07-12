sub init()
    m.top.itemComponentName = "ListPoster"
    m.top.content = getData()

    updateSize()

    m.top.showRowLabel = [true]
    m.top.rowLabelOffset = [0, 20]
    m.top.showRowCounter = [true]

    ' TODO - Define a failed to load image background
    ' m.top.failedBitmapURI

    m.top.setFocus(true)
end sub

sub updateSize()
    ' In search results, rowSize only dictates how many are on screen at once
    m.top.rowSize = 5

    dimensions = m.top.getScene().currentDesignResolution

    border = 75
    m.top.translation = [border, border + 115]

    textHeight = 80
    itemWidth = (dimensions["width"] - border * 2) / m.top.rowSize
    itemHeight = itemWidth * 1.5 + textHeight

    m.top.itemSize = [dimensions["width"] - border * 2, itemHeight]
    m.top.itemSpacing = [0, 50]

    m.top.rowItemSize = [itemWidth, itemHeight]
    m.top.rowItemSpacing = [0, 0]
end sub

function getData()
    if m.top.itemData = invalid
        data = CreateObject("roSGNode", "ContentNode")
        return data
    end if

    itemData = m.top.itemData

    ' todo - Or get the old data? I can't remember...
    data = CreateObject("roSGNode", "ContentNode")
    ' Do this to keep the ordering, AssociateArrays have no order
    type_array = ["Movie", "Series", "TvChannel", "Episode", "AlbumArtist", "Album", "Audio", "Person"]
    content_types = {
        "TvChannel": { "label": "Channels", "count": 0 },
        "Movie": { "label": "Movies", "count": 0 },
        "Series": { "label": "Shows", "count": 0 },
        "Episode": { "label": "Episodes", "count": 0 },
        "AlbumArtist": { "label": "Artists", "count": 0 },
        "Album": { "label": "Albums", "count": 0 },
        "Audio": { "label": "Songs", "count": 0 },
        "Person": { "label": "People", "count": 0 }
    }

    for each item in itemData.searchHints
        if content_types[item.type] <> invalid
            content_types[item.type].count += 1
        end if
    end for

    for each ctype in type_array
        content_type = content_types[ctype]
        if content_type.count > 0
            addRow(data, content_type.label, ctype)
        end if
    end for

    m.top.content = data
    return data
end function

sub addRow(data, title, type_filter)
    itemData = m.top.itemData
    row = data.CreateChild("ContentNode")
    row.title = title
    for each item in itemData.SearchHints
        if item.type = type_filter
            row.appendChild(item)
        end if
    end for
end sub
