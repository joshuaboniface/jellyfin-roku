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

  page_num = 1
  page_size = 20
  sort_order = get_user_setting("movie_sort_order", "Ascending")
  sort_field = get_user_setting("movie_sort_field", "SortName")

  item_list = ItemList(library.id, {"limit": page_size,
    "StartIndex": page_size * (page_num - 1),
    "SortBy": sort_field,
    "SortOrder": sort_order,
    "IncludeItemTypes": "Movie"
  })
  group.objects = item_list

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

sub ShowTVShowOptions(library)
  ' TV Show List Page
  port = m.port
  screen = m.screen
  scene = screen.CreateScene("TVShows")

  overhang = scene.findNode("overhang")
  overhang.title = library.name

  themeScene(scene)

  item_grid = scene.findNode("picker")

  page_num = 1
  page_size = 50

  sort_order = get_user_setting("series_sort_order", "Ascending")
  sort_field = get_user_setting("series_sort_field", "SortName")

  item_list = ItemList(library.id, {"limit": page_size,
    "page": page_num,
    "SortBy": sort_field,
    "SortOrder": sort_order })
  item_grid.objects = item_list

  item_grid.observeField("escapeButton", port)
  item_grid.observeField("itemSelected", port)

  pager = scene.findNode("pager")
  pager.currentPage = page_num
  pager.maxPages = item_list.TotalRecordCount / page_size
  if item_list.TotalRecordCount mod page_size > 0 then pager.maxPages += 1

  pager.observeField("escape", port)
  pager.observeField("pageSelected", port)

  sidepanel = scene.findNode("options")
  panel_options = [
    {"title": "Sort Field",
     "base_title": "Sort Field",
     "key": "series_sort_field",
     "default": "SortName",
     "values": [
       {display: "Date Added", value: "DateCreated"},
       {display: "Release Date", value: "PremiereDate"},
       {display: "Name", value: "SortName"}
     ]},
    {"title": "Sort Order",
     "base_title": "Sort Order",
     "key": "series_sort_order",
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
  sidepanel.observeField("escape", port)

  while true
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
      return
    else if nodeEventQ(msg, "escapeButton")
      node = msg.getRoSGNode()
      if node.escapeButton = "down"
        pager.setFocus(true)
        pager.getChild(0).setFocus(true)
      else if node.escapeButton = "options"
        sidepanel.visible = true
        sidepanel.findNode("panelList").setFocus(true)
      end if
    else if nodeEventQ(msg, "escape") and msg.getNode() = "pager"
      item_grid.setFocus(true)
    else if nodeEventQ(msg, "escape") and msg.getNode() = "options"
      item_grid.setFocus(true)
    else if nodeEventQ(msg, "pageSelected") and pager.pageSelected <> invalid
      pager.pageSelected = invalid
      page_num = int(val(msg.getData().id))
      pager.currentPage = page_num
      item_list = ItemList(library.id, {"limit": page_size,
        "StartIndex": page_size * (page_num - 1),
        "SortBy": sort_field,
        "SortOrder": sort_order })
      item_grid.objects = item_list
      item_grid.setFocus(true)
    else if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
      return
    else if nodeEventQ(msg, "itemSelected")
      target = getMsgRowTarget(msg)
      ShowTVShowDetails(target)
    end if
  end while
end sub

sub ShowTVShowDetails(series)
  ' TV Show Detail Page
  port = m.port
  screen = m.screen
  scene = screen.CreateScene("TVShowItemDetailScene")

  themeScene(scene)

  series = ItemMetaData(series.id)
  scene.itemData = series
  scene.findNode("description").findNode("buttons").setFocus(true)
  scene.seasonData = TVSeasons(series.id)

  scene.findNode("description").findNode("buttons").setFocus(true)

  'buttons = scene.findNode("buttons")
  'buttons.observeField("buttonSelected", port)

  scene.findNode("seasons").observeField("rowItemSelected", port)

  while true
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
      return
    else if nodeEventQ(msg, "buttonSelected")
      ' What button could we even be watching yet
    else if nodeEventQ(msg, "rowItemSelected")
      ' Assume for now it's a season being selected
      season_list = msg.getRoSGNode()
      item = msg.getData()
      season = season_list.content.getChild(item[0]).getChild(item[1])

      ShowTVSeasonEpisodes(series, season)
    else
      print msg
      print type(msg)
    end if
  end while
end sub

sub ShowTVSeasonEpisodes(series, season)
  ' TV Show Season Episdoe List
  port = m.port
  screen = m.screen
  scene = screen.CreateScene("TVEpisodes")

  themeScene(scene)

  scene.showData = ItemMetaData(series.id)
  scene.seasonData = TVSeasons(series.id)
  scene.episodeData = TVEpisodes(series.id, season.id)

  scene.findNode("TVEpisodeSelect").observeField("rowItemSelected", port)

  while true
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
      return
    else if nodeEventQ(msg, "rowItemSelected")
      episode_list = msg.getRoSGNode()
      item = msg.getData()
      episode = episode_list.content.getChild(item[0]).getChild(item[1])

      ShowVideoPlayer(episode.id)
    else
      print msg
      print type(msg)
    end if
  end while
end sub

sub ShowCollections(library)
  ' Load Movie Collection Items
  port = m.port
  screen = m.screen
  scene = screen.CreateScene("Collections")

  overhang = scene.findNode("overhang")
  overhang.title = library.name

  themeScene(scene)

  item_grid = scene.findNode("picker")

  page_num = 1
  page_size = 50

  sort_order = get_user_setting("collection_sort_order", "Ascending")
  sort_field = get_user_setting("collection_sort_field", "SortName")

  item_list = ItemList(library.id, {"limit": page_size,
    "StartIndex": page_size * (page_num - 1),
    "SortBy": sort_field,
    "SortOrder": sort_order })
  item_grid.objects = item_list

  item_grid.observeField("escapeButton", port)
  item_grid.observeField("itemSelected", port)

  pager = scene.findNode("pager")
  pager.currentPage = page_num
  pager.maxPages = item_list.TotalRecordCount / page_size
  if item_list.TotalRecordCount mod page_size > 0 then pager.maxPages += 1

  pager.observeField("escape", port)
  pager.observeField("pageSelected", port)

  sidepanel = scene.findNode("options")
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
  sidepanel.observeField("escape", port)

  while true
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
      return
    else if nodeEventQ(msg, "escapeButton")
      node = msg.getRoSGNode()
      if node.escapeButton = "down"
        pager.setFocus(true)
        pager.getChild(0).setFocus(true)
      else if node.escapeButton = "options"
        sidepanel.visible = true
        sidepanel.findNode("panelList").setFocus(true)
      end if
    else if nodeEventQ(msg, "escape") and msg.getNode() = "pager"
      item_grid.setFocus(true)
    else if nodeEventQ(msg, "escape") and msg.getNode() = "options"
      item_grid.setFocus(true)
    else if nodeEventQ(msg, "pageSelected") and pager.pageSelected <> invalid
      pager.pageSelected = invalid
      page_num = int(val(msg.getData().id))
      pager.currentPage = page_num
      item_list = ItemList(library.id, {"limit": page_size,
        "StartIndex": page_size * (page_num - 1),
        "SortBy": sort_field,
        "SortOrder": sort_order })
      item_grid.itemData = item_list
      item_grid.setFocus(true)
    else if nodeEventQ(msg, "itemSelected")
      target = getMsgRowTarget(msg)
      ShowMovieOptions(target)
    else
      print msg
      print msg.getField()
      print msg.getData()
    end if
  end while
end sub

sub ShowSearchOptions(query)
  ' Search Results Page
  port = m.port
  screen = m.screen
  scene = screen.CreateScene("SearchResults")

  themeScene(scene)

  options = scene.findNode("SearchSelect")

  sort_order = get_user_setting("search_sort_order", "Ascending")
  sort_field = get_user_setting("search_sort_field", "SortName")

  results = SearchMedia(query)
  options.itemData = results
  options.query = query

  options.observeField("itemSelected", port)

  while true
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
      return
    else if nodeEventQ(msg, "itemSelected")
      target = getMsgRowTarget(msg)
      ' TODO - swap this based on target.mediatype
      ' types: [ Episode, Movie, Audio, Person, Studio, MusicArtist ]
      ShowMovieDetails(target)
    else
      print msg
      print msg.getField()
      print msg.getData()
    end if
  end while
end sub

function CreateSidePanel(buttons, options)
  group = CreateObject("roSGNode", "OptionsSlider")
  group.buttons = buttons
  group.options = options

end function

function CreateVideoPlayerGroup(video_id)
  ' Video is Playing
  video = VideoPlayer(video_id)

  video.observeField("backPressed", m.port)
  video.observeField("state", m.port)

  return video
end function
