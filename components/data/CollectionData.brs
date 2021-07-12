sub setFields()
    json = m.top.json

    m.top.id = json.id
    m.top.Title = json.name
    m.top.overview = json.overview
    m.top.Description = json.overview
    m.top.favorite = json.UserData.isFavorite
    m.top.watched = json.UserData.played
    m.top.Type = "Boxset"

    setPoster()
end sub

sub setPoster()
    if m.top.image <> invalid
        m.top.posterURL = m.top.image.url
    else

        if m.top.json.ImageTags.Primary <> invalid
            imgParams = { "maxHeight": 440, "maxWidth": 295, "Tag": m.top.json.ImageTags.Primary }
            m.top.posterURL = ImageURL(m.top.json.id, "Primary", imgParams)
        else if m.top.json.BackdropImageTags <> invalid
            imgParams = { "maxHeight": 440, "Tag": m.top.json.BackdropImageTags[0] }
            m.top.posterURL = ImageURL(m.top.json.id, "Backdrop", imgParams)
        end if

        ' Add Backdrop Image
        if m.top.json.BackdropImageTags <> invalid
            imgParams = { "maxHeight": 720, "maxWidth": 1280, "Tag": m.top.json.BackdropImageTags[0] }
            m.top.backdropURL = ImageURL(m.top.json.id, "Backdrop", imgParams)
        end if

    end if

end sub