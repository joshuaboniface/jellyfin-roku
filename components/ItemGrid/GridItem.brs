sub init()
    m.posterMask = m.top.findNode("posterMask")
    m.itemPoster = m.top.findNode("itemPoster")
    m.itemIcon = m.top.findNode("itemIcon")
    m.posterText = m.top.findNode("posterText")
    m.itemText = m.top.findNode("itemText")
    m.backdrop = m.top.findNode("backdrop")

    m.itemPoster.observeField("loadStatus", "onPosterLoadStatusChanged")

    m.itemText.translation = [0, m.itemPoster.height + 7]

    'Parent is MarkupGrid and it's parent is the ItemGrid
    topParent = m.top.GetParent().GetParent()
    'Get the imageDisplayMode for these grid items
    if topParent.imageDisplayMode <> invalid
        m.itemPoster.loadDisplayMode = topParent.imageDisplayMode
    end if

end sub

sub itemContentChanged()

    ' Set Random background colors from pallet
    posterBackgrounds = m.global.constants.poster_bg_pallet
    m.backdrop.blendColor = posterBackgrounds[rnd(posterBackgrounds.count()) - 1]

    itemData = m.top.itemContent

    if itemData = invalid then return

    if itemData.type = "Movie"
        m.itemPoster.uri = itemData.PosterUrl
        m.itemText.text = itemData.Title
    else if itemData.type = "Series"
        m.itemPoster.uri = itemData.PosterUrl
        m.itemText.text = itemData.Title
    else if itemData.type = "Boxset"
        m.itemPoster.uri = itemData.PosterUrl
        m.itemText.text = itemData.Title
    else if itemData.type = "TvChannel"
        m.itemPoster.uri = itemData.PosterUrl
        m.itemText.text = itemData.Title
    else if itemData.type = "Folder"
        m.itemPoster.uri = itemData.PosterUrl
        m.itemIcon.uri = itemData.iconUrl
        m.itemText.text = itemData.Title
    else if itemData.type = "Video"
        m.itemPoster.uri = itemData.PosterUrl
        m.itemText.text = itemData.Title
    else
        print "Unhandled Item Type: " + itemData.type
    end if

    'If Poster not loaded, ensure "blue box" is shown until loaded
    if m.itemPoster.loadStatus <> "ready"
        m.backdrop.visible = true
        m.posterText.visible = true
    end if

    m.posterText.text = m.itemText.text

end sub

'
'Use FocusPercent to animate scaling of Poser Image
sub focusChanging()
    scaleFactor = 0.85 + (m.top.focusPercent * 0.15)
    m.posterMask.scale = [scaleFactor, scaleFactor]
end sub

'
'Display or hide title Visibility on focus change
sub focusChanged()

    if m.top.itemHasFocus = true
        m.itemText.visible = true
        m.itemText.repeatCount = -1
    else
        m.itemText.visible = false
        m.itemText.repeatCount = 0
    end if

end sub

'Hide backdrop and text when poster loaded
sub onPosterLoadStatusChanged()
    if m.itemPoster.loadStatus = "ready"
        m.backdrop.visible = false
        m.posterText.visible = false
    end if
end sub
