sub init()
    m.title = m.top.findNode("title")
    m.title.translation = [2, 0]

    m.poster = m.top.findNode("poster")
    m.poster.translation = [2, 0]

    m.backdrop = m.top.findNode("backdrop")

    m.backdrop.color = "#404040FF"

    updateSize()
end sub

sub updateSize()
    m.title = m.top.findNode("title")
    m.poster = m.top.findNode("poster")
    m.backdrop = m.top.findNode("backdrop")

    image = invalid
    if m.top.itemContent <> invalid and m.top.itemContent.image <> invalid
      image = m.top.itemContent.image
    end if

    if image = invalid
      m.backdrop.visible = true
    else
      m.backdrop.visible = false
    end if

    ' TODO - abstract this in case the parent doesnt have itemSize
    maxSize = m.top.getParent().itemSize

    ' Always reserve the bottom for the Poster Title
    m.title.wrap = true
    m.title.maxLines = 2
    m.title.width = maxSize[0]
    m.title.height = 80
    m.title.translation = [0, int(maxSize[1]) - m.title.height]

    ratio = 1.5
    if image <> invalid and image.width <> 0 and image.height <> 0
      ratio = image.height / image.width
    end if

    m.poster.width = int(maxSize[0]) - 4
    m.poster.height = m.poster.width * ratio

    posterVertSpace = int(maxSize[1]) - m.title.height - 20

    if m.poster.height > posterVertSpace
      ' Do a thing to shrink the image if it is too tall
    end if

    m.poster.translation = [2, (posterVertSpace - m.poster.height) / 2]

    m.backdrop.translation = [2, (posterVertSpace - m.poster.height) / 2]
    m.backdrop.width = m.poster.width
    m.backdrop.height = m.poster.height

end sub

function itemContentChanged() as void

    m.title = m.top.findNode("title")
    m.poster = m.top.findNode("poster")
    itemData = m.top.itemContent
    m.title.text = itemData.title
    if itemData.json.lookup("Type") = "Episode" and itemData.json.IndexNumber <> invalid
        m.title.text = StrI(itemData.json.IndexNumber) + ". " + m.title.text
    end if
    m.poster.uri = itemData.posterUrl

    updateSize()
end function
