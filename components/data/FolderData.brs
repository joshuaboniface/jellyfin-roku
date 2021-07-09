sub setFields()
    json = m.top.json

    m.top.id = json.id
    m.top.Title = json.name
    m.top.Type = "Folder"

    m.top.iconUrl = "pkg:/images/media_type_icons/folder_white.png"
    ' This is a temporary measure to avoid displaying landscape photos
    ' in GridItem components that only support portrait. It will be fixed
    ' after the ItemGrid is reworked.
    if m.top.json.Type <> "CollectionFolder"
        setPoster()
    end if
end sub

sub setPoster()
    if m.top.image <> invalid
        m.top.posterURL = m.top.image.url
    else if m.top.json.ImageTags.Primary <> invalid
        imgParams = { "maxHeight": 440, "maxWidth": 295, "Tag": m.top.json.ImageTags.Primary }
        m.top.posterURL = ImageURL(m.top.json.id, "Primary", imgParams)
    end if
end sub
