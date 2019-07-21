sub init()
    m.top.visible = false

    panel = m.top.findNode("panel")
    panel.panelSize = "small"
    panel.leftPosition = 0
    panel.focusable = true
    panel.hasNextPanel = false
    panel.leftOnly = true

    list = m.top.findNode("panelList")

    panel.list = list

    bd = m.top.findNode("backdrop")
    bd.color = "#101010DD"
    bd.translation = [0, 0]
    dimensions = m.top.getScene().currentDesignResolution
    bd.width = 575
    bd.height = dimensions.height
end sub

sub setFields()
    options = m.top.options
    buttons = m.top.buttons
    row = m.top.findNode("fieldList")

    row.clear()
    row.appendChildren(options)
    row.appendChildren(buttons)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "options" or key = "back"
        m.top.visible = false
        m.top.escape = true
        return true
    else if key = "OK"
        list = m.top.findNode("panelList")
        data = list.content.getChild(list.itemFocused)
        data.callFunc("press")
        return true
    end if

    return false
end function
