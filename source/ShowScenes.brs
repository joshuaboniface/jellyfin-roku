sub CreateServerGroup()
  ' Get and Save Jellyfin Server Information
  group = CreateObject("roSGNode", "ConfigScene")
  m.scene.appendChild(group)

  group.findNode("prompt").text = "Connect to Server"


  config = group.findNode("configOptions")
  server_field = CreateObject("roSGNode", "ConfigData")
  server_field.label = "Server"
  server_field.field = "server"
  server_field.type = "string"
  if get_setting("server") <> invalid
    server_field.value = get_setting("server")
  end if
  port_field = CreateObject("roSGNode", "ConfigData")
  port_field.label = "Port"
  port_field.field = "port"
  port_field.type = "string"
  if get_setting("port") <> invalid
    port_field.value = get_setting("port")
  end if
  items = [ server_field, port_field ]
  config.configItems = items

  button = group.findNode("submit")
  button.observeField("buttonSelected", m.port)

  server_hostname = config.content.getChild(0)
  server_port = config.content.getChild(1)

  while(true)
    msg = wait(0, m.port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
      return
    else if type(msg) = "roSGNodeEvent"
      node = msg.getNode()
      if node = "submit"
        set_setting("server", server_hostname.value)
        set_setting("port", server_port.value)
        if ServerInfo() = invalid then
          ' Maybe don't unset setting, but offer as a prompt
          ' Server not found, is it online? New values / Retry
          print "Server not found, is it online? New values / Retry"
          group.findNode("alert").text = "Server not found, is it online?"
          SignOut()
        else
          group.visible = false
          return
        endif
      end if
    end if
  end while

  ' Just hide it when done, in case we need to come back
  group.visible = false
end sub

sub CreateSigninGroup()
  ' Get and Save Jellyfin user login credentials
  group = CreateObject("roSGNode", "ConfigScene")
  m.scene.appendChild(group)

  group.findNode("prompt").text = "Sign In"

  config = group.findNode("configOptions")
  username_field = CreateObject("roSGNode", "ConfigData")
  username_field.label = "Username"
  username_field.field = "username"
  username_field.type = "string"
  password_field = CreateObject("roSGNode", "ConfigData")
  password_field.label = "Password"
  password_field.field = "password"
  password_field.type = "password"
  items = [ username_field, password_field ]
  config.configItems = items

  button = group.findNode("submit")
  button.observeField("buttonSelected", m.port)

  config = group.findNode("configOptions")

  username = config.content.getChild(0)
  password = config.content.getChild(1)

  while(true)
    msg = wait(0, m.port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
      group.visible = false
      return
    else if type(msg) = "roSGNodeEvent"
      node = msg.getNode()
      if node = "submit"
        ' Validate credentials
        get_token(username.value, password.value)
        if get_setting("active_user") <> invalid then return
        print "Login attempt failed..."
        group.findNode("alert").text = "Login attempt failed."
      end if
    end if
  end while

  ' Just hide it when done, in case we need to come back
  group.visible = false
end sub

function CreateLibraryGroup()
  ' Main screen after logging in. Shows the user's libraries
  group = CreateObject("roSGNode", "Library")

  libs = LibraryList()

  group.libraries = libs
  group.observeField("librarySelected", m.port)

  library = group.findNode("LibrarySelect")

  sidepanel = group.findNode("options")
  sidepanel.observeField("closeSidePanel", m.port)
  new_options = []
  options_buttons = [
    {"title": "Search", "id": "goto_search"},
    {"title": "Change server", "id": "change_server"},
    {"title": "Sign out", "id": "sign_out"},
    {"title": "Add User", "id": "add_user"}
  ]
  for each opt in options_buttons
    o = CreateObject("roSGNode", "OptionsButton")
    o.title = opt.title
    o.id = opt.id
    o.observeField("optionSelected", m.port)
    new_options.push(o)
  end for

  ' And a profile button
  user_node = CreateObject("roSGNode", "OptionsData")
  user_node.id = "active_user"
  user_node.title = "Profile"
  user_node.base_title = "Profile"
  user_options = []
  for each user in AvailableUsers()
    user_options.push({display: user.username + "@" + user.server, value: user.id})
  end for
  user_node.choices = user_options
  user_node.value = get_setting("active_user")
  new_options.push(user_node)

  sidepanel.options = new_options

  return group
end function

function CreateMovieListGroup(library)
  group = CreateObject("roSGNode", "Movies")
  group.id = library.id
  group.library = library

  group.observeField("movieSelected", m.port)

  sidepanel = group.findNode("options")
  movie_options = [
    {"title": "Sort Field",
     "base_title": "Sort Field",
     "key": "movie_sort_field",
     "default": "DateCreated",
     "values": [
       {display: "Date Added", value: "DateCreated"},
       {display: "Release Date", value: "PremiereDate"},
       {display: "Name", value: "SortName"}
     ]},
    {"title": "Sort Order",
     "base_title": "Sort Order",
     "key": "movie_sort_order",
     "default": "Ascending",
     "values": [
       {display: "Descending", value: "Descending"},
       {display: "Ascending", value: "Ascending"}
     ]}
  ]
  new_options = []
  for each opt in movie_options
    o = CreateObject("roSGNode", "OptionsData")
    o.title = opt.title
    o.choices = opt.values
    o.base_title = opt.base_title
    o.config_key = opt.key
    o.value = get_user_setting(opt.key, opt.default)
    new_options.append([o])
  end for

  sidepanel.options = new_options
  sidepanel.observeField("closeSidePanel", m.port)

  p = CreatePaginator()
  group.appendChild(p)

  group.pageNumber = 1
  p.currentPage = group.pageNumber

  MovieLister(group, m.page_size)

  return group
end function

function CreateMovieDetailsGroup(movie)
  group = CreateObject("roSGNode", "MovieDetails")


  movie = ItemMetaData(movie.id)
  group.itemContent = movie

  buttons = group.findNode("buttons")
  for each b in buttons.getChildren(-1, 0)
    b.observeField("buttonSelected", m.port)
  end for

  return group
end function

function CreateSeriesListGroup(library)
  group = CreateObject("roSGNode", "TVShows")
  group.id = library.id
  group.library = library

  group.observeField("seriesSelected", m.port)

  sidepanel = group.findNode("options")

  p = CreatePaginator()
  group.appendChild(p)

  group.pageNumber = 1
  p.currentPage = group.pageNumber
  SeriesLister(group, m.page_size)

  return group
end function

function CreateSeriesDetailsGroup(series)
  group = CreateObject("roSGNode", "TVShowDetails")

  group.itemContent = ItemMetaData(series.id)
  group.seasonData = TVSeasons(series.id)

  group.observeField("seasonSelected", m.port)

  return group
end function

function CreateSeasonDetailsGroup(series, season)
  group = CreateObject("roSGNode", "TVEpisodes")

  group.seasonData = TVSeasons(series.id)
  group.objects = TVEpisodes(series.id, season.id)

  group.observeField("episodeSelected", m.port)

  return group
end function

function CreateCollectionsList(library)
  ' Load Movie Collection Items
  group = CreateObject("roSGNode", "Collections")
  group.id = library.id
  group.library = library

  group.observeField("collectionSelected", m.port)

  sidepanel = group.findNode("options")
  panel_options = [
    {"title": "Sort Field",
     "base_title": "Sort Field",
     "key": "movie_sort_field",
     "default": "SortName",
     "values": [
       {display: "Date Added", value: "DateCreated"},
       {display: "Release Date", value: "PremiereDate"},
       {display: "Name", value: "SortName"}
     ]},
    {"title": "Sort Order",
     "base_title": "Sort Order",
     "key": "movie_sort_order",
     "default": "Ascending",
     "values": [
       {display: "Descending", value: "Descending"},
       {display: "Ascending", value: "Ascending"}
     ]}
  ]
  new_options = []
  for each opt in panel_options
    o = CreateObject("roSGNode", "OptionsData")
    o.title = opt.title
    o.choices = opt.values
    o.base_title = opt.base_title
    o.config_key = opt.key
    o.value = get_user_setting(opt.key, opt.default)
    new_options.append([o])
  end for

  sidepanel.options = new_options
  sidepanel.observeField("closeSidePanel", m.port)

  p = CreatePaginator()
  group.appendChild(p)

  group.pageNumber = 1
  p.currentPage = group.pageNumber

  CollectionLister(group, m.page_size)

  return group
end function

function CreateSearchPage()
  ' Search + Results Page
  group = CreateObject("roSGNode", "SearchResults")

  search = group.findNode("SearchBox")
  search.observeField("search_value", m.port)

  options = group.findNode("SearchSelect")
  options.observeField("itemSelected", m.port)

  return group
end function

function CreateSidePanel(buttons, options)
  group = CreateObject("roSGNode", "OptionsSlider")
  group.buttons = buttons
  group.options = options

end function

function CreatePaginator()
  group = CreateObject("roSGNode", "Pager")
  group.id = "paginator"

  group.observeField("pageSelected", m.port)

  return group
end function

function CreateVideoPlayerGroup(video_id)
  ' Video is Playing
  video = VideoPlayer(video_id)
  timer = video.findNode("playbackTimer")

  video.observeField("backPressed", m.port)
  video.observeField("state", m.port)
  video.observeField("position", m.port)
  timer.control = "start"
  timer.observeField("fire", m.port)

  return video
end function

function MovieLister(group, page_size)
  sort_order = get_user_setting("movie_sort_order", "Ascending")
  sort_field = get_user_setting("movie_sort_field", "SortName")

  item_list = ItemList(group.id, {"limit": page_size,
    "StartIndex": page_size * (group.pageNumber - 1),
    "SortBy": sort_field,
    "SortOrder": sort_order,
    "IncludeItemTypes": "Movie"
  })
  group.objects = item_list


  p = group.findNode("paginator")
  p.maxPages = div_ceiling(group.objects.TotalRecordCount, page_size)
end function

function SeriesLister(group, page_size)
  sort_order = get_user_setting("series_sort_order", "Ascending")
  sort_field = get_user_setting("series_sort_field", "SortName")

  item_list = ItemList(group.id, {"limit": page_size,
    "StartIndex": page_size * (group.pageNumber - 1),
    "SortBy": sort_field,
    "SortOrder": sort_order,
    "IncludeItemTypes": "Series"
  })
  group.objects = item_list

  p = group.findNode("paginator")
  p.maxPages = div_ceiling(group.objects.TotalRecordCount, page_size)
end function

function CollectionLister(group, page_size)
  sort_order = get_user_setting("boxsets_sort_order", "Ascending")
  sort_field = get_user_setting("boxsets_sort_field", "SortName")

  item_list = ItemList(group.id, {"limit": page_size,
    "StartIndex": page_size * (group.pageNumber - 1),
    "SortBy": sort_field,
    "SortOrder": sort_order,
  })
  group.objects = item_list

  p = group.findNode("paginator")
  p.maxPages = div_ceiling(group.objects.TotalRecordCount, page_size)
end function


