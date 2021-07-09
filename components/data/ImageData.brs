sub setFields()
    json = m.top.json
    m.top.imagetype = json.imagetype
    m.top.size = json.size
    m.top.height = json.height
    m.top.width = json.width
end sub