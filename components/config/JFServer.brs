sub init() as void
    m.poster = m.top.findNode("poster")
    m.name = m.top.findNode("name")
    m.baseUrl = m.top.findNode("baseUrl")
    m.labels = m.top.findNode("labels")
    setTextColor(0)
end sub

sub itemContentChanged() as void
    server = m.top.itemContent

    m.poster.uri = server.iconUrl
    m.name.text = server.name
    m.baseUrl.text = server.baseUrl
end sub

sub onFocusPercentChange(event)
    'print "focusPercentChange: " ; event.getData()
    setTextColor(event.getData())
end sub

sub setTextColor(percentFocused)
    white = "0xffffffff"
    black = "0x00000099"
    if percentFocused > .4
        color = black
    else
        color = white
    end if

    children = m.labels.getChildren(-1, 0)
    for each child in children
        child.color = color
    end for
end sub
