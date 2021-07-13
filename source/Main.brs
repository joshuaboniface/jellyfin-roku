sub Main (args as Dynamic) as Void

  ' If the Rooibos files are included in deployment, run tests
  'bs:disable-next-line
  if type(Rooibos__Init) = "Function" then Rooibos__Init()

  ' The main function that runs when the application is launched.
  m.screen = CreateObject("roSGScreen")

  ' Set global constants
  setConstants()

  m.port = CreateObject("roMessagePort")
  m.screen.setMessagePort(m.port)
  m.scene = m.screen.CreateScene("JFScene")
  m.screen.show()

  ' Set any initial Global Variables
  m.global = m.screen.getGlobalNode()
  m.global.addFields( {app_loaded: false} )

  m.overhang = CreateObject("roSGNode", "JFOverhang")
  m.scene.insertChild(m.overhang, 0)

  app_start:
  m.overhang.title = ""
  ' First thing to do is validate the ability to use the API

  if not LoginFlow() then return
  wipe_groups()

  ' load home page
  m.overhang.title = tr("Home")
  m.overhang.currentUser = m.user.Name
  m.overhang.showOptions = true
  group = CreateHomeGroup()
  group.userConfig = m.user.configuration
  group.callFunc("loadLibraries")
  m.scene.appendChild(group)

  m.scene.observeField("backPressed", m.port)
  m.scene.observeField("optionsPressed", m.port)
  m.scene.observeField("mutePressed", m.port)

  ' Handle input messages
  input = CreateObject("roInput")
  input.SetMessagePort(m.port)

  m.device = CreateObject("roDeviceInfo")
  m.device.setMessagePort(m.port)
  m.device.EnableScreensaverExitedEvent(true)

  ' Check if we were sent content to play with the startup command (Deep Link)
  if (args.mediaType <> invalid) and (args.contentId <> invalid)
    video = CreateVideoPlayerGroup(args.contentId)

    if video <> invalid
      if group.lastFocus = invalid then group.lastFocus = group.focusedChild
      group.setFocus(false)
      group.visible = false
      group = video
      m.scene.appendChild(group)
      group.setFocus(true)
      group.control = "play"
      ReportPlayback(group, "start")
      m.overhang.visible = false
    else
      dialog = createObject("roSGNode", "Dialog")
      dialog.id = "OKDialog"
      dialog.title = tr("Not found")
      dialog.message = tr("The requested content does not exist on the server")
      dialog.buttons = [tr("OK")]
      m.scene.dialog = dialog
      m.scene.dialog.observeField("buttonSelected", m.port)
    end if
  end if

  ' This is the core logic loop. Mostly for transitioning between scenes
  ' This now only references m. fields so could be placed anywhere, in theory
  ' "group" is always "whats on the screen"
  ' m.scene's children is the "previous view" stack
  while true
    msg = wait(0, m.port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
      print "CLOSING SCREEN"
      return

    else if isNodeEvent(msg, "backPressed")
      n = m.scene.getChildCount() - 1
      if msg.getRoSGNode().focusedChild <> invalid and msg.getRoSGNode().focusedChild.isSubtype("JFVideo")
        stopPlayback()
        RemoveCurrentGroup()
      else
        if n = 1 then return
        RemoveCurrentGroup()
      end if
      group = m.scene.getChild(n-1)
    else if isNodeEvent(msg, "optionsPressed")
      group.lastFocus = group.focusedChild
      panel = group.findNode("options")
      panel.visible = true
      panel.findNode("panelList").setFocus(true)
    else if isNodeEvent(msg, "closeSidePanel")
      if group.lastFocus <> invalid
        group.lastFocus.setFocus(true)
      else
        group.setFocus(true)
      end if
    else if isNodeEvent(msg, "quickPlayNode")
      reportingNode = msg.getRoSGNode()
      itemNode = reportingNode.quickPlayNode
      if itemNode = invalid or itemNode.id = "" then return
      if itemNode.type = "Episode" or itemNode.type = "Movie" or itemNode.type = "Video"
        video = CreateVideoPlayerGroup(itemNode.id)
        if video <> invalid
          group.lastFocus = group.focusedChild
          group.setFocus(false)
          group.visible = false
          group = video
          m.scene.appendChild(group)
          group.setFocus(true)
          group.control = "play"
          ReportPlayback(group, "start")
          m.overhang.visible = false
        end if
      end if
    else if isNodeEvent(msg, "selectedItem")
      ' If you select a library from ANYWHERE, follow this flow
      selectedItem = msg.getData()
      if selectedItem.type = "CollectionFolder" OR selectedItem.type = "UserView" OR selectedItem.type = "Folder" OR selectedItem.type = "Channel" OR selectedItem.type = "Boxset"
        group.lastFocus = group.focusedChild
        group.setFocus(false)
        group.visible = false
        m.overhang.title = selectedItem.title
        group = CreateItemGrid(selectedItem)
        group.overhangTitle = selectedItem.title
        m.scene.appendChild(group)
      else if selectedItem.type = "Episode"
        ' play episode
        ' todo: create an episode page to link here
        video_id = selectedItem.id
        video = CreateVideoPlayerGroup(video_id)
        if video <> invalid
          group.lastFocus = group.focusedChild
          group.setFocus(false)
          group.visible = false
          group = video
          m.scene.appendChild(group)
          group.setFocus(true)
          group.control = "play"
          ReportPlayback(group, "start")
          m.overhang.visible = false
        end if
      else if selectedItem.type = "Series"
        group.lastFocus = group.focusedChild
        group.setFocus(false)
        group.visible = false

        m.overhang.title = selectedItem.title
        m.overhang.showOptions = false
        m.scene.unobserveField("optionsPressed")
        group = CreateSeriesDetailsGroup(selectedItem.json)
        group.overhangTitle = selectedItem.title
        m.scene.appendChild(group)
      else if selectedItem.type = "Movie"
        ' open movie detail page
        group.lastFocus = group.focusedChild
        group.setFocus(false)
        group.visible = false

        m.overhang.title = selectedItem.title
        m.overhang.showOptions = false
        m.scene.unobserveField("optionsPressed")
        group = CreateMovieDetailsGroup(selectedItem)
        group.overhangTitle = selectedItem.title
        m.scene.appendChild(group)

      else if selectedItem.type = "TvChannel" or selectedItem.type = "Video"
        ' play channel feed
        video_id = selectedItem.id

        ' Show Channel Loading spinner
        dialog = createObject("roSGNode", "ProgressDialog")
        dialog.title = tr("Loading Channel Data")
        m.scene.dialog = dialog

        video = CreateVideoPlayerGroup(video_id)
        dialog.close = true

        if video <> invalid
          if group.lastFocus = invalid then group.lastFocus = group.focusedChild
          group.setFocus(false)
          group.visible = false
          group = video
          m.scene.appendChild(group)
          group.setFocus(true)
          group.control = "play"
          ReportPlayback(group, "start")
          m.overhang.visible = false
        else
          dialog = createObject("roSGNode", "Dialog")
          dialog.id = "OKDialog"
          dialog.title = tr("Error loading Channel Data")
          dialog.message = tr("Unable to load Channel Data from the server")
          dialog.buttons = [tr("OK")]
          m.scene.dialog = dialog
          m.scene.dialog.observeField("buttonSelected", m.port)
        end if
      else
        ' TODO - switch on more node types
        message_dialog("This type is not yet supported: " + selectedItem.type + ".")
      end if
    else if isNodeEvent(msg, "movieSelected")
      ' If you select a movie from ANYWHERE, follow this flow
      node = getMsgPicker(msg, "picker")

      group.lastFocus = group.focusedChild
      group.setFocus(false)
      group.visible = false

      m.overhang.title = node.title
      m.overhang.showOptions = false
      m.scene.unobserveField("optionsPressed")
      group = CreateMovieDetailsGroup(node)
      group.overhangTitle = node.title
      m.scene.appendChild(group)
    else if isNodeEvent(msg, "seriesSelected")
      ' If you select a TV Series from ANYWHERE, follow this flow
      node = getMsgPicker(msg, "picker")

      group.lastFocus = group.focusedChild
      group.setFocus(false)
      group.visible = false

      m.overhang.title = node.title
      m.overhang.showOptions = false
      m.scene.unobserveField("optionsPressed")
      group = CreateSeriesDetailsGroup(node)
      group.overhangTitle = node.title
      m.scene.appendChild(group)
    else if isNodeEvent(msg, "seasonSelected")
      ' If you select a TV Season from ANYWHERE, follow this flow
      ptr = msg.getData()
      ' ptr is for [row, col] of selected item... but we only have 1 row
      series = msg.getRoSGNode()
      node = series.seasonData.items[ptr[1]]

      group.lastFocus = group.focusedChild.focusedChild
      group.setFocus(false)
      group.visible = false

      m.overhang.title = series.overhangTitle + " - " + node.title
      m.overhang.showOptions = false
      m.scene.unobserveField("optionsPressed")
      group = CreateSeasonDetailsGroup(series.itemContent, node)
      m.scene.appendChild(group)
    else if isNodeEvent(msg, "episodeSelected")
      ' If you select a TV Episode from ANYWHERE, follow this flow
      node = getMsgPicker(msg, "picker")
      video_id = node.id
      video = CreateVideoPlayerGroup(video_id)
      if video <> invalid
        group.lastFocus = group.focusedChild
        group.setFocus(false)
        group.visible = false
        group = video
        m.scene.appendChild(group)
        group.setFocus(true)
        group.control = "play"
        ReportPlayback(group, "start")
        m.overhang.visible = false
      end if
    else if isNodeEvent(msg, "search_value")
      query = msg.getRoSGNode().search_value
      group.findNode("SearchBox").visible = false
      options = group.findNode("SearchSelect")
      options.visible = true
      options.setFocus(true)

      dialog = createObject("roSGNode", "ProgressDialog")
      dialog.title = tr("Loading Search Data")
      m.scene.dialog = dialog
      results = SearchMedia(query)
      dialog.close = true
      options.itemData = results
      options.query = query
    else if isNodeEvent(msg, "itemSelected")
      ' Search item selected
      node = getMsgPicker(msg)
      group.lastFocus = group.focusedChild
      group.setFocus(false)
      group.visible = false

      ' TODO - swap this based on target.mediatype
      ' types: [ Series (Show), Episode, Movie, Audio, Person, Studio, MusicArtist ]
      if node.type = "Series"
        group = CreateSeriesDetailsGroup(node)
      else
        group = CreateMovieDetailsGroup(node)
      end if
      m.scene.appendChild(group)
      m.overhang.title = group.overhangTitle

    else if isNodeEvent(msg, "buttonSelected")
      ' If a button is selected, we have some determining to do
      btn = getButton(msg)
      if btn <> invalid and btn.id = "play-button"
        ' Check is a specific Audio Stream was selected
        audio_stream_idx = 1
        if group.selectedAudioStreamIndex <> invalid
          audio_stream_idx = group.selectedAudioStreamIndex
        end if

        ' TODO - Do a better job of picking the last focus
        ' This is currently page layout Group, button Group, then button
        video_id = group.id
        video = CreateVideoPlayerGroup(video_id, audio_stream_idx)
        if video <> invalid
          group.lastFocus = group.focusedChild.focusedChild.focusedChild
          group.setFocus(false)
          group.visible = false
          group = video
          m.scene.appendChild(group)
          group.setFocus(true)
          group.control = "play"
          ReportPlayback(group, "start")
          m.overhang.visible = false
        end if
      else if btn <> invalid and btn.id = "watched-button"
        movie = group.itemContent
        if movie.watched
          UnmarkItemWatched(movie.id)
        else
          MarkItemWatched(movie.id)
        end if
        movie.watched = not movie.watched
      else if btn <> invalid and btn.id = "favorite-button"
        movie = group.itemContent
        if movie.favorite
          UnmarkItemFavorite(movie.id)
        else
          MarkItemFavorite(movie.id)
        end if
        movie.favorite = not movie.favorite
      else
        ' If there are no other button matches, check if this is a simple "OK" Dialog & Close if so
        dialog = msg.getRoSGNode()
        if dialog.id = "OKDialog"
          dialog.unobserveField("buttonSelected")
          dialog.close = true
        end if
      end if
    else if isNodeEvent(msg, "optionSelected")
      button = msg.getRoSGNode()
      if button.id = "goto_search"
        ' Exit out of the side panel
        panel.visible = false
        if group.lastFocus <> invalid
          group.lastFocus.setFocus(true)
        else
          group.setFocus(true)
        end if
        group.lastFocus = group.focusedChild
        group.setFocus(false)
        group.visible = false
        m.overhang.showOptions = false
        m.scene.unobserveField("optionsPressed")
        group = CreateSearchPage()
        m.scene.appendChild(group)
        m.overhang.title = group.overhangTitle
        group.findNode("SearchBox").findNode("search-input").setFocus(true)
        group.findNode("SearchBox").findNode("search-input").active = true
      else if button.id = "change_server"
        unset_setting("server")
        unset_setting("port")
        SignOut()
        wipe_groups()
        goto app_start
      else if button.id = "sign_out"
        SignOut()
        wipe_groups()
        goto app_start
      end if
    else if isNodeEvent(msg, "selectSubtitlePressed")
      node = m.scene.focusedChild
      if node.isSubType("JFVideo")
        trackSelected = selectSubtitleTrack(node.Subtitles, node.SelectedSubtitle)
        if trackSelected <> invalid and trackSelected <> -2
          changeSubtitleDuringPlayback(trackSelected)
        end if
      end if
    else if isNodeEvent(msg, "fire")
      ReportPlayback(group, "update")
    else if isNodeEvent(msg, "state")
      node = msg.getRoSGNode()
      if node.state = "finished"
        stopPlayback()
        if node.showID = invalid
          RemoveCurrentGroup()
        else
          nextEpisode =autoPlayNextEpisode(node.id, node.showID)
          if nextEpisode <> invalid then group = nextEpisode
        end if
      else if node.state = "playing" or node.state = "paused"
        ReportPlayback(group, "update")
      end if
    else if type(msg) = "roDeviceInfoEvent"
      event = msg.GetInfo()
      if event.exitedScreensaver = true
        m.overhang.callFunc("resetTime")
        if group.subtype() = "Home"
          currentTime = CreateObject("roDateTime").AsSeconds()
          group.timeLastRefresh = currentTime
          group.callFunc("refresh")
        end if
        ' todo: add other screens to be refreshed - movie detail, tv series, episode list etc.
      else
        print "Unhandled roDeviceInfoEvent:"
        print msg.GetInfo()
      end if
    else if type(msg) = "roInputEvent"
      if msg.IsInput()
          info = msg.GetInfo()
          if info.DoesExist("mediatype") and info.DoesExist("contentid")
            video = CreateVideoPlayerGroup(info.contentId)
            if video <> invalid
              if group.lastFocus = invalid then group.lastFocus = group.focusedChild
              group.setFocus(false)
              group.visible = false
              group = video
              m.scene.appendChild(group)
              group.setFocus(true)
              group.control = "play"
              ReportPlayback(group, "start")
              m.overhang.visible = false
            else
              dialog = createObject("roSGNode", "Dialog")
              dialog.id = "OKDialog"
              dialog.title = tr("Not found")
              dialog.message = tr("The requested content does not exist on the server")
              dialog.buttons = [tr("OK")]
              m.scene.dialog = dialog
              m.scene.dialog.observeField("buttonSelected", m.port)
            end if
          end if
      end if
    else
      print "Unhandled " type(msg)
      print msg
    end if
  end while

end sub

function LoginFlow(startOver = false as boolean)
  if m.scene <> invalid
    m.scene.unobserveField("backPressed")
  end if
  'Collect Jellyfin server and user information
  start_login:

  if get_setting("server") = invalid then startOver = true

  invalidServer = true
  if not startOver
        ' Show Connecting to Server spinner
        dialog = createObject("roSGNode", "ProgressDialog")
        dialog.title = tr("Connecting to Server")
        m.scene.dialog = dialog
        invalidServer = ServerInfo().Error
        dialog.close = true
  end if

  if startOver or invalidServer
    print "Get server details"
    SendPerformanceBeacon("AppDialogInitiate")  ' Roku Performance monitoring - Dialog Starting
    serverSelection = CreateServerGroup()
    SendPerformanceBeacon("AppDialogComplete") ' Roku Performance monitoring - Dialog Closed
    if serverSelection = "backPressed"
      print "backPressed"
      wipe_groups()
      return false
    end if
  end if

  if get_setting("active_user") = invalid
    SendPerformanceBeacon("AppDialogInitiate")  ' Roku Performance monitoring - Dialog Starting
    publicUsers = GetPublicUsers()
    if publicUsers.count()
      publicUsersNodes = []
      for each item in publicUsers
        user = CreateObject("roSGNode", "PublicUserData")
        user.id = item.Id
        user.name = item.Name
        if item.PrimaryImageTag <> invalid
          user.ImageURL = UserImageURL(user.id, { "tag": item.PrimaryImageTag })
        end if
        publicUsersNodes.push(user)
      end for
      userSelected = CreateUserSelectGroup(publicUsersNodes)
      m.scene.focusedChild.visible = false
      if userSelected = "backPressed"
        SendPerformanceBeacon("AppDialogComplete") ' Roku Performance monitoring - Dialog Closed
        return LoginFlow(true)
      else
        'Try to login without password. If the token is valid, we're done
        get_token(userSelected, "")
        if get_setting("active_user") <> invalid
          m.user = AboutMe()
          LoadUserPreferences()
          SendPerformanceBeacon("AppDialogComplete") ' Roku Performance monitoring - Dialog Closed
          return true
        end if
      end if
    else
      userSelected = ""
    end if
    passwordEntry = CreateSigninGroup(userSelected)
    SendPerformanceBeacon("AppDialogComplete") ' Roku Performance monitoring - Dialog Closed
    if passwordEntry = "backPressed"
      m.scene.focusedChild.visible = false
      return LoginFlow(true)
    end if
  end if

  m.user = AboutMe()
  if m.user = invalid or m.user.id <> get_setting("active_user")
    print "Login failed, restart flow"
    unset_setting("active_user")
    goto start_login
  end if

  LoadUserPreferences()
  wipe_groups()

  'Send Device Profile information to server
  body = getDeviceCapabilities()
  req = APIRequest("/Sessions/Capabilities/Full")
  req.SetRequest("POST")
  postJson(req, FormatJson(body))
  return true
end function

sub RunScreenSaver()
  print "Starting screensaver..."
  screen = createObject("roSGScreen")
  m.port = createObject("roMessagePort")
  screen.setMessagePort(m.port)

  screen.createScene("Screensaver")
  screen.Show()

  while true
    msg = wait(8000, m.port)
    if msg <> invalid
      msgType = type(msg)
      if msgType = "roSGScreenEvent"
        if msg.isScreenClosed() then return
      end if
    end if
  end while

end sub

sub wipe_groups()
  ' The 1 remaining child should be the overhang
  while m.scene.getChildCount() > 1
    m.scene.removeChildIndex(1)
  end while
end sub

sub RemoveCurrentGroup()
  ' Pop a group off the stack and expose what's below
  n = m.scene.getChildCount() - 1
  group = m.scene.focusedChild
  m.scene.removeChildIndex(n)
  prevOptionsAvailable = group.optionsAvailable
  group = m.scene.getChild(n - 1)
  m.overhang.title = group.overhangTitle
  m.overhang.showOptions = group.optionsAvailable
  if group.optionsAvailable <> prevOptionsAvailable
    if group.optionsAvailable = false
      m.scene.unobserveField("optionsPressed")
    else
      m.scene.observeField("optionsPressed", m.port)
    end if
  end if
  m.overhang.visible = true
  if group.lastFocus <> invalid
    group.lastFocus.setFocus(true)
  else
    group.setFocus(true)
  end if
  if group.subtype() = "Home"
    currentTime = CreateObject("roDateTime").AsSeconds()
    if group.timeLastRefresh = invalid  or (currentTime - group.timeLastRefresh) > 20
      group.timeLastRefresh = currentTime
      group.callFunc("refresh")
    end if
  end if
  group.visible = true
end sub

' Roku Performance monitoring
sub SendPerformanceBeacon(signalName as string)
  if m.global.app_loaded = false
    m.scene.signalBeacon(signalName)
  end if
end sub
