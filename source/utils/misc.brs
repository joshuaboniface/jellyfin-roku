function isNodeEvent(msg, field as string) as boolean
  return type(msg) = "roSGNodeEvent" and msg.getField() = field
end function


function getMsgPicker(msg, subnode = "" as string) as object
  node = msg.getRoSGNode()
  ' Subnode allows for handling alias messages
  if subnode <> ""
    node = node.findNode(subnode)
  end if
  coords = node.rowItemSelected
  target = node.content.getChild(coords[0]).getChild(coords[1])
  return target
end function

function getButton(msg, subnode = "buttons" as string) as object
  buttons = msg.getRoSGNode().findNode(subnode)
  if buttons = invalid then return invalid
  active_button = buttons.focusedChild
  return active_button
end function

function leftPad(base as string, fill as string, length as integer) as string
  while len(base) < length
    base = fill + base
  end while
  return base
end function

function ticksToHuman(ticks as longinteger) as string
  totalSeconds = int(ticks / 10000000)
  hours = stri(int(totalSeconds / 3600)).trim()
  minutes = stri(int((totalSeconds - (val(hours) * 3600)) / 60)).trim()
  seconds = stri(totalSeconds - (val(hours) * 3600) - (val(minutes) * 60)).trim()
  if val(hours) > 0 and val(minutes) < 10 then minutes = "0" + minutes
  if val(seconds) < 10 then seconds = "0" + seconds
  r = ""
  if val(hours) > 0 then r = hours + ":"
  r = r + minutes + ":" + seconds
  return r
end function

' Format time as 12 or 24 hour format based on system clock setting
function formatTime(time) as string
  hours = time.getHours()
  minHourDigits = 1
  di = CreateObject("roDeviceInfo")
  if di.GetClockFormat() = "12h"
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
  else
    ' For 24hr Clock, no meridian and pad hours to 2 digits
    minHourDigits = 2
    meridian = ""
  end if

  return Substitute("{0}:{1} {2}", leftPad(stri(hours).trim(), "0", minHourDigits), leftPad(stri(time.getMinutes()).trim(), "0", 2), meridian)

end function

function div_ceiling(a as integer, b as integer) as integer
  if a < b then return 1
  if int(a / b) = a / b
    return a / b
  end if
  return a / b + 1
end function

'Returns the item selected or -1 on backpress or other unhandled closure of dialog.
function get_dialog_result(dialog, port)
  while dialog <> invalid
    msg = wait(0, port)
    if isNodeEvent(msg, "backPressed")
      return -1
    else if isNodeEvent(msg, "itemSelected")
      return dialog.findNode("optionList").itemSelected
    end if
  end while
  'Dialog has closed outside of this loop, return -1 for failure
  return -1
end function

function lastFocusedChild(obj as object) as object
  child = obj
  for i = 0 to obj.getChildCount()
    if obj.focusedChild <> invalid
      child = child.focusedChild
    end if
  end for
  return child
end function

function show_dialog(message as string, options = [], defaultSelection = 0) as integer
  lastFocus = lastFocusedChild(m.scene)
  'We want to handle backPressed instead of the main loop
  m.scene.unobserveField("backPressed")

  dialog = createObject("roSGNode", "JFMessageDialog")
  if options.count() then dialog.options = options
  if message.len() > 0
    reg = CreateObject("roFontRegistry")
    font = reg.GetDefaultFont()
    dialog.fontHeight = font.GetOneLineHeight()
    dialog.fontWidth = font.GetOneLineWidth(message, 999999999)
    dialog.message = message
  end if

  if defaultSelection > 0
    dialog.findNode("optionList").jumpToItem = defaultSelection
  end if

  dialog.visible = true
  m.scene.appendChild(dialog)
  dialog.setFocus(true)

  port = CreateObject("roMessagePort")
  dialog.observeField("backPressed", port)
  dialog.findNode("optionList").observeField("itemSelected", port)

  result = get_dialog_result(dialog, port)

  m.scene.removeChildIndex(m.scene.getChildCount() - 1)
  lastFocus.setFocus(true)
  m.scene.observeField("backPressed", m.port)

  return result
end function

function message_dialog(message = "" as string)
  return show_dialog(message, ["OK"])
end function

function option_dialog(options, message = "", defaultSelection = 0) as integer
  return show_dialog(message, options, defaultSelection)
end function

'
' Take a jellyfin hostname and ensure it's a full url.
' prepend http or https and append default ports, and remove excess slashes
'
function standardize_jellyfin_url(url as string)
  'Append default ports
  maxSlashes = 0
  if left(url, 8) = "https://" or left(url, 7) = "http://"
    maxSlashes = 2
  end if
  'Check to make sure entry has no extra slashes before adding default ports.
  if Instr(0, url, "/") = maxSlashes
    if url.len() > 5 and mid(url, url.len() - 4, 1) <> ":" and mid(url, url.len() - 5, 1) <> ":"
      if left(url, 5) = "https"
        url = url + ":8920"
      else
        url = url + ":8096"
      end if
    end if
  end if
  'Append http:// to server
  if left(url, 4) <> "http"
    url = "http://" + url
  end if
  return url
end function
