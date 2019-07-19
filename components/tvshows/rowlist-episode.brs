sub init()
    m.top.itemComponentName = "ListPoster"

    m.top.rowFocusAnimationStyle = "floatingFocus"

    updateSize()

    m.top.setFocus(true)
end sub

sub updateSize()
    m.top.numRows = 1
    m.top.rowSize = 3

    dimensions = m.top.getScene().currentDesignResolution

    border = 75
    m.top.translation = [border, border + 115]

    textHeight = 80
    itemWidth = (dimensions["width"] - border*2) / m.top.rowSize
    itemHeight = itemWidth * dimensions["height"]/ dimensions["width"] + textHeight

    m.top.visible = true

    m.top.itemSize = [dimensions["width"] - border*2, itemHeight]
    m.top.itemSpacing = [ 0, 10 ]

    m.top.rowItemSize = [ itemWidth, itemHeight ]
    m.top.rowItemSpacing = [ 0, 0 ]


    episodeData = m.top.TVEpisodeData

    if episodeData = invalid then return

    rowsize = m.top.rowSize

    n = episodeData.items.count()

    ' Test for no remainder
    if int(n/rowsize) = n/rowsize then
        m.top.numRows = n/rowsize
    else
        m.top.numRows = n/rowsize + 1
    end if
end sub

function getData()
    if m.top.TVEpisodeData = invalid then
        data = CreateObject("roSGNode", "ContentNode")
        return data
    end if

    updateSize()

    episodeData = m.top.TVEpisodeData
    rowsize = m.top.rowSize
    data = CreateObject("roSGNode", "ContentNode")
    row = data.CreateChild("ContentNode")
    row.title = "Episodes"
    for each item in episodeData.items
        row.appendChild(item)
    end for
    m.top.content = data
    return data
end function
