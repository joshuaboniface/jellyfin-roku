sub Main()

  ' If the Rooibos files are included in deployment, run tests
  if (type(Rooibos__Init) = "Function") then Rooibos__Init()

  ' The main function that runs when the application is launched.
  m.screen = CreateObject("roSGScreen")
  m.port = CreateObject("roMessagePort")
  m.screen.setMessagePort(m.port)
  m.scene = m.screen.CreateScene("Scene")

  m.screen.show()
  m.overhang = CreateObject("roSGNode", "JFOverhang")

  themeScene()

  app_start:
  ' First thing to do is validate the ability to use the API
  LoginFlow()


  ' Confirm the configured server and user work
  group = CreateLibraryScene()
  m.overhang.title = group.overhangTitle
  m.scene.appendChild(group)

  while(true)
    msg = wait(0, m.port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() then
      print "CLOSING SCREEN"
      return
    else if isNodeEvent(msg, "backPressed")
      ' Pop a group off the stack and expose what's below
      n = m.scene.getChildCount() - 1
      if n = 1
        ' Overhang + last scene... this is the end
        return
      end if
      m.scene.removeChildIndex(n)
      group = m.scene.getChild(n - 1)
      m.overhang.title = group.overhangTitle
      m.overhang.visible = true
      if group.lastFocus <> invalid
        group.lastFocus.setFocus(true)
      else
        group.setFocus(true)
      end if
      group.visible = true
    else if isNodeEvent(msg, "librarySelected")
      ' If you select a library from ANYWHERE, follow this flow
      node = getMsgPicker(msg, "LibrarySelect")
      if node.type = "movies"
        group.lastFocus = group.focusedChild
        group.setFocus(false)
        group.visible = false

        group = CreateMovieScene(node)
        m.overhang.title = group.overhangTitle
        m.scene.appendChild(group)
      else
        print node.type
      end if
    else if isNodeEvent(msg, "movieSelected")
      ' If you select a movie from ANYWHERE, follow this flow
      node = getMsgPicker(msg, "picker")

      group.lastFocus = group.focusedChild
      group.setFocus(false)
      group.visible = false

      group = CreateMovieDetails(node)
      m.scene.appendChild(group)
      m.overhang.title = group.overhangTitle
    else if isNodeEvent(msg, "buttonSelected")
      ' If a button is selected, we have some determining to do
      btn = getButton(msg)
      if btn.id = "play-button"
        ' TODO - Do a better job of picking the focusedChild
        group.lastFocus = group.focusedChild
        group.setFocus(false)
        group.visible = false
        video_id = group.id

        group = CreateVideoPlayer(video_id)
        m.scene.appendChild(group)
        group.setFocus(true)
        group.control = "play"
        m.overhang.visible = false
      end if
    else
      print type(msg)
      print msg
    end if
  end while

end sub

sub LoginFlow()
  'Collect Jellyfin server and user information
  start_login:
  if get_setting("server") = invalid or ServerInfo() = invalid then
    print "Get server details"
    ShowServerSelect()
  end if

  if get_setting("active_user") = invalid then
    print "Get user login"
    ShowSigninSelect()
  end if

  m.user = AboutMe()
  if m.user = invalid or m.user.id <> get_setting("active_user")
    print "Login failed, restart flow"
    unset_setting("active_user")
    goto start_login
  end if
end sub

sub RunScreenSaver()
  print "Starting screensaver..."
  screen = createObject("roSGScreen")
  m.port = createObject("roMessagePort")
  screen.setMessagePort(m.port)

  scene = screen.createScene("Screensaver")
  screen.Show()

  while(true)
    msg = wait(8000, m.port)
    if (msg <> invalid)
      msgType = type(msg)
      if msgType = "roSGScreenEvent"
        if msg.isScreenClosed() then return
      end if
    end if
  end while

end sub