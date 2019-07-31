sub init()
    m.top.itemComponentName = "LibItem"
    m.top.content = getData()

    m.top.rowFocusAnimationStyle = "floatingFocus"
    m.top.vertFocusAnimationStyle = "floatingFocus"

    m.top.showRowLabel = [false]

    updateSize()

    m.top.setfocus(true)
end sub

sub updateSize()
    m.top.numrows = 1
    m.top.rowSize = 5

    dimensions = m.top.getScene().currentDesignResolution

    border = 200
    m.top.translation = [border, border + 115]

    itemWidth = (dimensions["width"] - border*2) / m.top.rowSize
    itemHeight = itemWidth / 2

    m.top.visible = true

    ' size of the whole row
    m.top.itemSize = [dimensions["width"] - border*2, itemHeight]
    ' spacing between rows
    m.top.itemSpacing = [ 0, 30 ]

    ' size of the item in the row
    m.top.rowItemSize = [ itemWidth, itemHeight ]
    ' spacing between items in a row
    m.top.rowItemSpacing = [ 0, 0 ]
end sub

function setData()
    libs = m.top.liblist
    rowsize = m.top.rowSize

    n = libs.TotalRecordCount

    ' Test for no remainder
    if int(n/rowsize) = n/rowsize then
        m.top.numRows = n/rowsize
    else
        m.top.numRows = n/rowsize + 1
    end if

    m.top.content = getData()
end function

function getData()
    if m.top.libList = invalid then
        data = CreateObject("roSGNode", "ContentNode")
        return data
    end if

    libs = m.top.libList
    rowsize = m.top.rowSize
    data = CreateObject("roSGNode", "ContentNode")
    for rownum=1 to m.top.numRows
        row = data.CreateChild("ContentNode")
        for i=1 to rowsize
            index = (rownum - 1) * rowsize + i
            if index > libs.TotalRecordCount then
                exit for
            end if
            item = libs.Items[index-1]
            row.appendChild(item)
        end for
    end for
    return data
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "down" and (m.top.itemFocused + 1) = m.top.content.getChildCount()
        search = m.top.getScene().findNode("search")
        search.setFocus(true)
        search.findNode("search-input").setFocus(true)
        search.findNode("search-input").active = true
        return true
    else if key = "options"
        options = m.top.getScene().findNode("options")
        list = options.findNode("panelList")

        options.visible = true
        list.setFocus(true)

        return true
    end if

    return false
end function
