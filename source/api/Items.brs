function ItemsList(params={} as object)
  ' Gets items based on a query.
  resp = APIRequest("Items", params)
  data = getJson(resp)
  ' TODO - parse items
  return data
end function

function UserItems(params={} as object)
  ' Gets items based on a query
  resp = APIRequest(Substitute("Items/{0}/Items", get_setting("active_user")), params)
  data = getJson(resp)
  ' TODO - parse items
  return data
end function

function UserItemsResume(params={} as object)
  ' Gets items based on a query
  resp = APIRequest(Substitute("Items/{0}/Items/Resume", get_setting("active_user")), params)
  data = getJson(resp)
  ' TODO - parse items
  return data
end function




' List of available libraries
function LibraryList()
  url = Substitute("Users/{0}/Views/", get_setting("active_user"))
  resp = APIRequest(url)
  data = getJson(resp)
  results = []
  for each item in data.Items
    tmp = CreateObject("roSGNode", "LibraryData")
    tmp.json = item
    results.push(tmp)
  end for
  data.Items = results
  return data
end function

' Search across all libraries
function SearchMedia(query as String)
  ' This appears to be done differently on the web now
  ' For each potential type, a separate query is done:
  ' varying item types, and artists, and people
  resp = APIRequest(Substitute("Users/{0}/Items", get_setting("active_user")), {
    "searchTerm": query,
    "IncludePeople": true,
    "IncludeMedia": true,
    "IncludeGenres": false,
    "IncludeStudios": false,
    "IncludeArtists": false,
    ' "IncludeItemTypes: "Movie",
    "EnableTotalRecordCount":  false,
    "ImageTypeLimit": 1,
    "Recursive": true
  })
  data = getJson(resp)
  results = []
  for each item in data.Items
    tmp = CreateObject("roSGNode", "SearchData")
    tmp.image = PosterImage(item.id)
    tmp.json = item
    results.push(tmp)
  end for
  data.SearchHints = results
  return data
end function

' List items from within a library
function ItemList(library_id=invalid as String, params={})
  if params["limit"] = invalid
    params["limit"] = 30
  end if
  if params["page"] = invalid
    params["page"] = 1
  end if
  params["parentid"] = library_id
  url = Substitute("Users/{0}/Items/", get_setting("active_user"))
  resp = APIRequest(url, params)
  data = getJson(resp)
  results = []
  for each item in data.Items
    if item.type = "Movie"
      tmp = CreateObject("roSGNode", "MovieData")
      tmp.image = PosterImage(item.id)
      tmp.json = item
      results.push(tmp)
    else if item.type = "Series"
      tmp = CreateObject("roSGNode", "SeriesData")
      tmp.image = PosterImage(item.id)
      tmp.json = item
      results.push(tmp)
    else if item.type = "BoxSet"
      tmp = CreateObject("roSGNode", "CollectionData")
      tmp.image = PosterImage(item.id)
      tmp.json = item
      results.push(tmp)
    else
      print item.type
      ' Otherwise we just stick with the JSON
      results.push(item)
    end if
  end for
  data.items = results
  return data
end function

' MetaData about an item
function ItemMetaData(id as String)
  url = Substitute("Users/{0}/Items/{1}", get_setting("active_user"), id)
  resp = APIRequest(url)
  data = getJson(resp)
  if data.type = "Movie"
    tmp = CreateObject("roSGNode", "MovieData")
    tmp.image = PosterImage(data.id)
    tmp.json = data
    return tmp
  else if data.type = "Series"
    tmp = CreateObject("roSGNode", "SeriesData")
    tmp.image = PosterImage(data.id)
    tmp.json = data
    return tmp
  else if data.type = "Episode"
    tmp = CreateObject("roSGNode", "TVEpisodeData")
    tmp.image = PosterImage(data.id)
    tmp.json = data
    return tmp
  else if data.type = "BoxSet"
    tmp = CreateObject("roSGNode", "CollectionData")
    tmp.image = PosterImage(data.id)
    tmp.json = item
    return tmp
  else
    print data.type
    ' Return json if we don't know what it is
    return data
  end if
  return data
end function

' Seasons for a TV Show
function TVSeasons(id as String)
  url = Substitute("Shows/{0}/Seasons", id)
  resp = APIRequest(url, {"UserId": get_setting("active_user")})

  data = getJson(resp)
  results = []
  for each item in data.Items
    tmp = CreateObject("roSGNode", "TVEpisodeData")
    tmp.image = PosterImage(item.id)
    tmp.json = item
    results.push(tmp)
  end for
  data.Items = results
  return data
end function

function TVEpisodes(show_id as String, season_id as String)
  url = Substitute("Shows/{0}/Episodes", show_id)
  resp = APIRequest(url, {"seasonId": season_id, "UserId": get_setting("active_user")})

  data = getJson(resp)
  results = []
  for each item in data.Items
    tmp = CreateObject("roSGNode", "TVEpisodeData")
    tmp.image = PosterImage(item.id)
    tmp.image.posterDisplayMode = "scaleToFit"
    tmp.json = item
    results.push(tmp)
  end for
  data.Items = results
  return data
end function

' The next up episode for a TV show
function TVNext(id as String)
  url = Substitute("Shows/NextUp", id)
  resp = APIRequest(url, {"UserId": get_setting("active_user"), "SeriesId": id})

  data = getJson(resp)
  for each item in data.Items
    item.image = PosterImage(item.id)
  end for
  return data
end function
