sub init()
    m.top.itemComponentName = "ListPoster"
    m.top.content = getData()

    'm.top.rowFocusAnimationStyle = "floatingFocus"
    'm.top.vertFocusAnimationStyle = "floatingFocus"

    m.top.showRowLabel = [true]
    m.top.rowLabelOffset = [0, 20]

    updateSize()

    m.top.setfocus(true)
end sub

sub updateSize()
    ' Infinite scroll, rowsize is just how many show on screen at once
    m.top.rowSize = 5

    dimensions = m.top.getScene().currentDesignResolution

    border = 50
    m.top.translation = [border, border]

    textHeight = 80
    ' Do we decide width by rowSize, or rowSize by width...
    itemWidth = (dimensions["width"] - border*2) / m.top.rowSize
    itemHeight = itemWidth * 1.5 + textHeight

    m.top.visible = true

    ' size of the whole row
    m.top.itemSize = [dimensions["width"] - border*2, itemHeight]
    ' spacing between rows
    m.top.itemSpacing = [ 0, 10 ]

    ' size of the item in the row
    m.top.rowItemSize = [ itemWidth, itemHeight ]
    ' spacing between items in a row
    m.top.rowItemSpacing = [ 0, 0 ]
end sub

function getData()
    if m.top.TVSeasonData = invalid then
        data = CreateObject("roSGNode", "ContentNode")
        return data
    end if

    seasonData = m.top.TVSeasonData
    rowsize = m.top.rowSize
    data = CreateObject("roSGNode", "ContentNode")
    row = data.CreateChild("ContentNode")
    row.title = "Seasons"
    for each item in seasonData.items
        row.appendChild(item)
    end for
    m.top.content = data
    return data
end function
