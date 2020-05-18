sub init()
  m.top.optionsAvailable = false

  main = m.top.findNode("main_group")
  main.translation = [50, 175]

  overview = m.top.findNode("overview")
  overview.width = 1920 - 100 - 400

  m.top.findNode("buttons").setFocus(true)
end sub

sub itemContentChanged()
  ' Updates video metadata
  item = m.top.itemContent
  itemData = item.json
  m.top.id = itemData.id

  m.top.findNode("moviePoster").uri = m.top.itemContent.posterURL

  ' Handle all "As Is" fields
  m.top.overhangTitle = itemData.name
  setFieldText("releaseYear", itemData.productionYear)
  setFieldText("officialRating", itemData.officialRating)
  setFieldText("communityRating", itemData.communityRating)
  setFieldText("overview", itemData.overview)

  if itemData.CriticRating <> invalid then
    setFieldText("criticRatingLabel" , itemData.criticRating)
    if itemData.CriticRating > 60 then
      tomato = "pkg:/images/fresh.png"
    else
      tomato = "pkg:/images/rotten.png"
    end if
    m.top.findNode("criticRatingIcon").uri = tomato
  else
    m.top.findNode("infoGroup").removeChild(m.top.findNode("criticRatingGroup"))
  end if

  if type(itemData.RunTimeTicks) = "LongInteger"
    setFieldText("runtime", stri(getRuntime()) + " mins")
    setFieldText("ends-at", tr("Ends at %1").Replace("%1", getEndTime()))
  end if

  if itemData.genres.count() > 0
    setFieldText("genres", tr("Genres") + ": " + itemData.genres.join(", "))
  end if
  director = invalid
  for each person in itemData.people
    if person.type = "Director"
      director = person.name
      exit for
    end if
  end for
  if director <> invalid
    setFieldText("director", tr("Director") + ": " + director)
  end if
  setFieldText("video_codec", tr("Video") + ": " + itemData.mediaStreams[0].displayTitle)
  setFieldText("audio_codec", tr("Audio") + ": " + itemData.mediaStreams[1].displayTitle)
  ' TODO - cmon now. these are buttons, not words
  if itemData.taglines.count() > 0
    setFieldText("tagline", itemData.taglines[0])
  end if
  setFavoriteColor()
  setWatchedColor()
end sub

sub setFieldText(field, value)
  node = m.top.findNode(field)
  if node = invalid or value = invalid then return

  ' Handle non strings... Which _shouldn't_ happen, but hey
  if type(value) = "roInt" or type(value) = "Integer" then
    value = str(value)
  else if type(value) = "roFloat" or type(value) = "Float" then
    value = str(value)
  else if type(value) <> "roString" and type(value) <> "String" then
    value = ""
  end if

  node.text = value
end sub

function getRuntime() as integer
  itemData = m.top.itemContent.json

  ' A tick is .1ms, so 1/10,000,000 for ticks to seconds,
  ' then 1/60 for seconds to minutess... 1/600,000,000
  return round(itemData.RunTimeTicks / 600000000.0)
end function

function getEndTime() as string
  itemData = m.top.itemContent.json

  date = CreateObject("roDateTime")
  duration_s = int(itemData.RunTimeTicks / 10000000.0)
  date.fromSeconds(date.asSeconds() + duration_s)
  date.toLocalTime()

  return formatTime(date)
end function

sub setFavoriteColor()
  fave = m.top.itemContent.favorite
  fave_button = m.top.findNode("favorite-button")
  if fave <> invalid and fave
    fave_button.textColor = "#00ff00ff"
    fave_button.focusedTextColor = "#269926ff"
  else
    fave_button.textColor = "0xddddddff"
    fave_button.focusedTextColor = "#262626ff"
  end if
end sub

sub setWatchedColor()
  watched = m.top.itemContent.watched
  watched_button = m.top.findNode("watched-button")
  if watched
    watched_button.textColor = "#ff0000ff"
    watched_button.focusedTextColor = "#992626ff"
  else
    watched_button.textColor = "0xddddddff"
    watched_button.focusedTextColor = "#262626ff"
  end if
end sub

function round(f as float) as integer
  ' BrightScript only has a "floor" round
  ' This compares floor to floor + 1 to find which is closer
  m = int(f)
  n = m + 1
  x = abs(f - m)
  y = abs(f - n)
  if y > x
    return m
  else
    return n
  end if
end function
