sub init()
    m.top.itemComponentName = "LibItem"
    m.top.content = getData()

    m.top.rowFocusAnimationStyle = "fixedFocusWrap"
    m.top.vertFocusAnimationStyle = "fixedFocusWrap"

    m.top.showRowLabel = [ true ]
    m.top.rowLabelOffset = [0, 20]
    m.top.showRowCounter = [ true ]

    updateSize()

    m.top.setfocus(true)
end sub

sub updateSize()
    m.top.rowSize = 5

    dimensions = m.top.getScene().currentDesignResolution

    border = 200
    ' 115 is the overhand height
    m.top.translation = [border, border + 115]

    itemWidth = 300
    itemHeight = 100

    m.top.visible = true

    ' size of the whole row
    m.top.itemSize = [1920 - border * 2, itemHeight]
    ' spacing between rows
    m.top.itemSpacing = [ 0, 30 ]

    ' size of the item in the row
    m.top.rowItemSize = [ itemWidth, itemHeight ]
    ' spacing between items in a row
    m.top.rowItemSpacing = [ 0, 0 ]
end sub

function getData()
    if m.top.libList = invalid then
        data = CreateObject("roSGNode", "ContentNode")
        m.top.content = data
        return data
    end if

    libs = m.top.libList
    data = CreateObject("roSGNode", "ContentNode")

    row = data.CreateChild("ContentNode")
    row.title = "Libraries"  ' TODO - make this tweakable?
    for i=1 to libs.TotalRecordCount
        item = libs.Items[i-1]
        row.appendChild(item)
    end for
    m.top.content = data
    return data
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    return false
end function
