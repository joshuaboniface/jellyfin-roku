sub itemContentChanged()
  itemData = m.top.itemContent
  if itemData = invalid then return

  m.itemText = m.top.findNode("itemText")
  itemPoster = m.top.findNode("itemPoster")
  itemTextExtra = m.top.findNode("itemTextExtra")

  ' Desired Image Width
  imageWidth = 464
  if m.top.GetParent().content.imageWidth <> invalid
    imageWidth = m.top.GetParent().content.imageWidth
  end if

  itemPoster.width = imageWidth
  m.itemText.maxWidth = imageWidth
  itemTextExtra.width = imageWidth

  ' Whether to use WidePoster or Thumbnail in this row
  usePoster = m.top.GetParent().content.usePoster


  ' Format the Data based on the type of Home Data

  if itemData.type = "CollectionFolder" OR itemData.type = "UserView" then
    m.itemText.text = itemData.name
    itemPoster.uri = itemData.widePosterURL
    return
  end if

  if itemData.type = "UserView" then
    itemPoster.width = "96"
    itemPoster.height = "96"
    itemPoster.translation = "[192, 88]"
    m.itemText.text = itemData.name
    itemPoster.uri = itemData.widePosterURL
    return
  end if


  m.itemText.height = 34
  m.itemText.font.size = 25
  m.itemText.horizAlign = "left"
  m.itemText.vertAlign = "bottom"
  itemTextExtra.visible = true
  itemTextExtra.font.size = 22


  if itemData.type = "Episode" then
    m.itemText.text = itemData.json.SeriesName

    if usePoster = true then
      itemPoster.uri = itemData.widePosterURL
    else
      itemPoster.uri = itemData.thumbnailURL
    end if

    ' Set Series and Episode Number for Extra Text
    extraPrefix = ""
    if itemData.json.ParentIndexNumber <> invalid then
      extraPrefix = "S" + StrI(itemData.json.ParentIndexNumber).trim()
    end if
    if itemData.json.IndexNumber <> invalid then
      extraPrefix = extraPrefix + "E" + StrI(itemData.json.IndexNumber).trim()
    end if
    if extraPrefix.len() > 0 then
      extraPrefix = extraPrefix + " - "
    end if

    itemTextExtra.text = extraPrefix + itemData.name
    return
  end if

  if itemData.type = "Movie" then
    m.itemText.text = itemData.name

    if imageWidth = 180
      itemPoster.uri = itemData.posterURL
    else
      itemPoster.uri = itemData.thumbnailURL
    end if

    ' Set Release Year and Age Rating for Extra Text
    textExtra = ""
    if itemData.json.ProductionYear <> invalid then
      textExtra = StrI(itemData.json.ProductionYear).trim()
    end if
    if itemData.json.OfficialRating <> invalid then
      if textExtra <> "" then
        textExtra = textExtra + " - " + itemData.json.OfficialRating
      else
        textExtra = itemData.json.OfficialRating
      end if
    end if
    itemTextExtra.text = textExtra

    return
  end if

  if itemData.type = "Series" then

    m.itemText.text = itemData.name

    if usePoster = true then
      itemPoster.uri = itemData.widePosterURL
    else
      itemPoster.uri = itemData.thumbnailURL
    end if

    textExtra = ""
    if itemData.json.ProductionYear <> invalid then
      textExtra = StrI(itemData.json.ProductionYear).trim()
    end if

    ' Set Years Run for Extra Text
    if itemData.json.Status = "Continuing" then
      textExtra = textExtra + " - Present"
    else if itemData.json.Status = "Ended" and itemData.json.EndDate <> invalid
      textExtra = textExtra + " - " + LEFT(itemData.json.EndDate, 4)
    end if
    itemTextExtra.text = textExtra

    return
  end if

  if itemData.type = "MusicAlbum" then
    m.itemText.text = itemData.name
    itemTextExtra.text = itemData.json.AlbumArtist
    itemPoster.uri = itemData.posterURL
    return
  end if

  print "Unhandled Item Type: " + itemData.type

end sub

'
' Enable title scrolling based on item Focus
sub focusChanged()

  if m.top.itemHasFocus = true then
    m.itemText.repeatCount = -1
  else
    m.itemText.repeatCount = 0
  end if

end sub
