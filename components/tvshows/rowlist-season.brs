sub init()
    m.top.itemComponentName = "ListPoster"
    m.top.content = getData()

    m.top.rowFocusAnimationStyle = "floatingFocus"
    'm.top.vertFocusAnimationStyle = "floatingFocus"

    m.top.showRowLabel = [false]
    m.top.showRowCounter = [true]
    m.top.rowLabelOffset = [0, 5]

    updateSize()

    m.top.setfocus(true)
end sub

sub updateSize()
    textHeight = 80
    itemWidth = 200
    itemHeight = 380  ' width * 1.5 + text

    m.top.visible = true

    ' size of the whole row
    m.top.itemSize = [1720, itemHeight]
    ' spacing between rows
    m.top.itemSpacing = [ 0, 0 ]

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
