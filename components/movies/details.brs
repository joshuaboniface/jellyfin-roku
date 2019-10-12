sub init()
  m.top.overhangTitle = "Movie"
  main = m.top.findNode("main_group")
  dimensions = m.top.getScene().currentDesignResolution

  main.translation=[50, 175]

  overview = m.top.findNode("overview")
  overview.width = dimensions.width - 100 - 400

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
  setFieldText("communityRating", str(itemData.communityRating))
  setFieldText("overview", itemData.overview)

  setFieldText("runtime", stri(getRuntime()) + " mins")
  setFieldText("ends-at", "Ends at " + getEndTime())

  if itemData.genres.count() > 0
    setFieldText("genres", itemData.genres.join(", "))
  end if
  director = invalid
  for each person in itemData.people
    if person.type = "Director"
      director = person.name
      exit for
    end if
  end for
  if director <> invalid
    setFieldText("director", "Director: " + director)
  end if
  setFieldText("video_codec", "Video: " + itemData.mediaStreams[0].displayTitle)
  setFieldText("audio_codec", "Audio: " + itemData.mediaStreams[1].displayTitle)
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
  hours = date.getHours()
  meridian = "AM"
  if hours = 0
    hours = 12
    meridian = "AM"
  else if hours = 12
    hours = 12
    meridian = "PM"
  else if hours > 12
    hours = hours - 12
    meridian = "PM"
  end if

  return Substitute("{0}:{1} {2}", stri(hours).trim(), leftPad(stri(date.getMinutes()).trim(), "0", 2), meridian)
end function

sub setFavoriteColor()
  fave = m.top.itemContent.favorite
  fave_button = m.top.findNode("favorite-button")
  if fave
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

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false

  if key = "back"
    m.top.backPressed = true
    return true
  end if

  return false
end function
