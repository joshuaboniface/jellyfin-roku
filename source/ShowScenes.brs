sub ShowServerSelect()
  ' Get and Save Jellyfin Server Information
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSGScreen")
  screen.setMessagePort(port)
  scene = screen.CreateScene("ConfigScene")
  screen.show()

  themeScene(scene)
  scene.findNode("prompt").text = "Connect to Server"

  config = scene.findNode("configOptions")
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

  button = scene.findNode("submit")
  button.observeField("buttonSelected", port)

  server_hostname = config.content.getChild(0)
  server_port = config.content.getChild(1)

  while(true)
    msg = wait(0, port)
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
          scene.findNode("alert").text = "Server not found, is it online?"
          SignOut()
        else
          return
        endif
      end if
    end if
  end while
end sub

sub ShowSignInSelect()
  ' Get and Save Jellyfin user login credentials
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSGScreen")
  screen.setMessagePort(port)
  scene = screen.CreateScene("ConfigScene")
  screen.show()

  themeScene(scene)
  scene.findNode("prompt").text = "Sign In"

  config = scene.findNode("configOptions")
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

  button = scene.findNode("submit")
  button.observeField("buttonSelected", port)

  config = scene.findNode("configOptions")

  username = config.content.getChild(0)
  password = config.content.getChild(1)

  while(true)
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
      return
    else if type(msg) = "roSGNodeEvent"
      node = msg.getNode()
      if node = "submit"
        ' Validate credentials
        get_token(username.value, password.value)
        if get_setting("active_user") <> invalid then return
        print "Login attempt failed..."
        scene.findNode("alert").text = "Login attempt failed."
      end if
    end if
  end while
end sub

sub ShowLibrarySelect()
  ' Main screen after logging in. Shows the user's libraries
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSGScreen")
  screen.setMessagePort(port)
  scene = screen.CreateScene("Library")

  screen.show()

  themeScene(scene)

  libs = LibraryList()

  scene.libraries = libs
  scene.observeField("librarySelected", port)

  library = scene.findNode("LibrarySelect")

  search = scene.findNode("search")
  search.observeField("escape", port)
  search.observeField("search_value", port)

  sidepanel = scene.findNode("options")
  new_options = []
  options_buttons = [
    {"title": "Change server", "id": "change_server"},
    {"title": "Sign out", "id": "sign_out"},
    {"title": "Add User", "id": "add_user"}
  ]
  for each opt in options_buttons
    o = CreateObject("roSGNode", "OptionsButton")
    o.title = opt.title
    o.id = opt.id
    new_options.push(o)
    o.observeField("escape", port)
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
  sidepanel.observeField("escape", port)

  while(true)
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
      return
    else if nodeEventQ(msg, "escape") and msg.getNode() = "search"
      library.setFocus(true)
    else if nodeEventQ(msg, "escape") and msg.getNode() = "options"
      if user_node.value <> get_setting("active_user")
        PickUser(user_node.value)
        setGlobal("user_change", true)
        return
      end if
      library.setFocus(true)
    else if nodeEventQ(msg, "escape") and msg.getNode() = "change_server"
      unset_setting("server")
      unset_setting("port")
      SignOut()
      return
    else if nodeEventQ(msg, "escape") and msg.getNode() = "sign_out"
      SignOut()
      return
    else if nodeEventQ(msg, "escape") and msg.getNode() = "add_user"
      ' We don't want to SignOut the current user
      unset_setting("active_user")
      unset_setting("server")
      unset_setting("port")
      return
    else if nodeEventQ(msg, "search_value")
      query = msg.getRoSGNode().search_value
      if query <> invalid or query <> ""
        ShowSearchOptions(query)
      end if
      search.search_value = ""
    else if nodeEventQ(msg, "librarySelected")
      target = getMsgRowTarget(msg, "LibrarySelect")
      if target.type = "movies"
        ShowMovieOptions(target)
      else if target.type = "tvshows"
        ShowTVShowOptions(target)
      else if target.type = "boxsets"
        ShowCollections(target)
      else
        scene.dialog = make_dialog("This library type is not yet implemented: " + target.type)
        scene.dialog.observeField("buttonSelected", port)
      end if
    else if nodeEventQ(msg, "buttonSelected")
      if msg.getNode() = "popup"
        msg.getRoSGNode().close = true
      end if
    else
      print msg
    end if
  end while
end sub

sub ShowMovieOptions(library)
  ' Movie list page
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSGScreen")
  screen.setMessagePort(port)
  scene = screen.CreateScene("Movies")

  screen.show()

  overhang = scene.findNode("overhang")
  overhang.title = library.name

  themeScene(scene)

  item_grid = scene.findNode("picker")

  page_num = 1
  page_size = 50  ' Make this customizable somehow

  sort_order = get_user_setting("movie_sort_order", "Ascending")
  sort_field = get_user_setting("movie_sort_field", "SortName")

  item_list = ItemList(library.id, {"limit": page_size,
    "StartIndex": page_size * (page_num - 1),
    "SortBy": sort_field,
    "SortOrder": sort_order,
    "IncludeItemTypes": "Movie"
  })
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
        "SortOrder": sort_order,
        "IncludeItemTypes": "Movie"
      })
      item_grid.objects = item_list
      item_grid.setFocus(true)
    else if nodeEventQ(msg, "itemSelected")
      target = getMsgRowTarget(msg)
      ShowMovieDetails(target)
    else
      print msg
      print msg.getField()
      print msg.getData()
    end if
  end while
end sub

sub ShowMovieDetails(movie)
  ' Movie detail page
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSGScreen")
  screen.setMessagePort(port)
  scene = screen.CreateScene("MovieItemDetailScene")

  screen.show()

  themeScene(scene)

  movie = ItemMetaData(movie.id)
  scene.itemContent = movie

  buttons = scene.findNode("buttons")
  for each b in buttons.getChildren(-1, 0)
    b.observeField("buttonSelected", port)
  end for

  while true
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
      return
    else if nodeEventQ(msg, "buttonSelected")
      if msg.getNode() = "play-button"
        showVideoPlayer(movie.id)
      else if msg.getNode() = "watched-button"
        if movie.watched
          UnmarkItemWatched(movie.id)
        else
          MarkItemWatched(movie.id)
        end if
        movie.watched = not movie.watched
      else if msg.getNode() = "favorite-button"
        if movie.favorite
          UnmarkItemFavorite(movie.id)
        else
          MarkItemFavorite(movie.id)
        end if
        movie.favorite = not movie.favorite
      end if
    else
      print msg
      print type(msg)
    end if
  end while
end sub

sub ShowTVShowOptions(library)
  ' TV Show List Page
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSGScreen")
  screen.setMessagePort(port)
  scene = screen.CreateScene("TVShows")

  screen.show()

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
    if nodeEventQ(msg, "escape") and msg.getNode() = "pager"
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
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSGScreen")
  screen.setMessagePort(port)
  scene = screen.CreateScene("TVShowItemDetailScene")

  screen.show()

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
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSGScreen")
  screen.setMessagePort(port)
  scene = screen.CreateScene("TVEpisodes")

  screen.show()

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
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSGScreen")
  screen.setMessagePort(port)
  scene = screen.CreateScene("Collections")

  screen.show()

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
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSGScreen")
  screen.setMessagePort(port)
  scene = screen.CreateScene("SearchResults")

  screen.show()

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

sub showVideoPlayer(video_id)
  ' Video is Playing
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSGScreen")
  screen.setMessagePort(port)
  scene = screen.CreateScene("Scene")

  screen.show()

  themeScene(scene)

  video = VideoPlayer(video_id)
  scene.appendChild(video)

  video.setFocus(true)

  video.observeField("state", port)

  while true
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
      PlaystateStop(video_id)
      return

      ' Video is already gone by this point
      ' TODO - add an event listener higher up that watches for closing
      ' so we can handle end of video a bit better
      if video = invalid then return

      progress = int( video.position / video.duration * 100)
      if progress > 95  ' TODO - max resume percentage
        MarkItemWatched(video_id)
      end if
      ticks = video.position * 10000000
      PlaystateStop(video_id, {"PositionTicks": ticks})
      return
    else if nodeEventQ(msg, "state")
      state = msg.getData()
      if state = "stopped" or state = "finished"
        print "Stopping Video!"
        ticks = video.position * 10000000
        PlaystateStop(video_id, {"PositionTicks": ticks})
        screen.close()
      else if state = "paused"
        ticks = video.position * 10000000
        PlaystateUpdate(video_id, {
          "PositionTicks": ticks,
          "IsPaused": true
        })
      else if state = "playing"
        ticks = video.position * 10000000
        PlaystateStart(video_id, {
          "PositionTicks": ticks,
          "IsPaused": false
        })
      end if
    end if
  end while

end sub
