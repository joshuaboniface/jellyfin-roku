sub init()
    m.top.itemComponentName = "TVListDetails"
    m.top.content = setData()

    m.top.vertFocusAnimationStyle = "fixedFocusWrap"

    m.top.showRowLabel = [false]

    updateSize()

    m.top.setFocus(true)
end sub

sub updateSize()
    dimensions = m.top.getScene().currentDesignResolution

    border = 96
    m.top.translation = [border, 75 + 115]

    itemWidth = (dimensions["width"] - border * 2)
    itemHeight = 300

    m.top.visible = true

    ' Size of the individual rows
    m.top.itemSize = [dimensions["width"] - border * 2, itemHeight]
    ' Spacing between Rows
    m.top.itemSpacing = [0, 40]

    ' Size of items in the row
    m.top.rowItemSize = [itemWidth, itemHeight]
    ' Spacing between items in the row
    m.top.rowItemSpacing = [20, 0]
end sub

sub setupRows()
    updateSize()
    objects = m.top.objects
    m.top.numRows = objects.items.count()
    m.top.content = setData()
end sub

function setData()
    data = CreateObject("roSGNode", "ContentNode")
    if m.top.objects = invalid
        ' Return an empty node just to return something; we'll update once we have data
        return data
    end if

    for each item in m.top.objects.items
        row = data.CreateChild("ContentNode")
        row.appendChild(item)
    end for

    return data
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    return false
end function
