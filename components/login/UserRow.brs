sub init()
    m.top.itemComponentName = "UserItem"
    m.top.content = SetData()
    m.top.observeField("itemSelected", "SetUser")
    m.top.showRowLabel = [false]
    updateSize()
    m.top.setFocus(true)
end sub

sub updateSize()
    itemWidth = 300
    itemHeight = 364

    m.top.visible = true

    ' Size of the individual rows
    m.top.itemSize = [1660, itemHeight]
    ' Spacing between Rows
    m.top.itemSpacing = [0, 40]

    ' Size of items in the row
    m.top.rowItemSize = [itemWidth, itemHeight]
    ' Spacing between items in the row
    m.top.rowItemSpacing = [40, 0]
end sub


function setData()
    if m.top.itemContent = invalid
        data = CreateObject("roSGNode", "ContentNode")
        return data
    end if

    userData = m.top.itemContent
    data = CreateObject("roSGNode", "ContentNode")
    row = data.CreateChild("ContentNode")
    for each item in userData
        row.appendChild(item)
    end for
    m.top.content = data
    updateSize()
    return data
end function

sub setUser()
    m.top.userSelected = m.top.itemContent[m.top.rowItemFocused[1]].Name
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    return false
end function
