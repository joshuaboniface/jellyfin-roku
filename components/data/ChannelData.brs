sub setFields()
    json = m.top.json

    m.top.id = json.id
    m.top.title = json.name
    m.top.live = true
end sub

sub setPoster()
    if m.top.image <> invalid
        m.top.posterURL = m.top.image.url
    else
        m.top.posterURL = ""
    end if
end sub
