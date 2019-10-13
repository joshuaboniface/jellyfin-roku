function isNodeEvent(msg, field as string) as boolean
  return type(msg) = "roSGNodeEvent" and msg.getField() = field
end function

function getMsgPicker(msg, subnode="" as string) as object
  node = msg.getRoSGNode()
  ' Subnode allows for handling alias messages
  if subnode <> ""
    node = node.findNode(subnode)
  end if
  coords = node.rowItemSelected
  target = node.content.getChild(coords[0]).getChild(coords[1])
  return target
end function

function getButton(msg, subnode="buttons" as string) as object
  buttons = msg.getRoSGNode().findNode(subnode)
  active_button = buttons.focusedChild

  return active_button
end function

sub themeScene()
  ' Takes a scene and applies a consisten UI Theme
  m.scene.backgroundColor = "#101010"
  m.scene.backgroundURI = ""

  m.scene.insertChild(m.overhang, 0)
end sub

function leftPad(base as string, fill as string, length as integer) as string
  while len(base) < length
    base = fill + base
  end while
  return base
end function

function message_dialog(message="" as string)
  ' Takes a string and returns an object for dialog popup
  dialog = createObject("roSGNode", "JFMessageDialog")
  dialog.id = "popup"
  dialog.buttons = ["OK"]
  dialog.message = message

  m.scene.dialog = dialog
  m.scene.dialog.observeField("buttonSelected", handle_dialog)
  m.scene.dialog.setFocus(true)
end function

function handle_dialog(msg)
  print("THERE")
  m.scene.dialog.close = true
end function
