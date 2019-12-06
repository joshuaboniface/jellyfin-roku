sub init()
  m.top.overhangTitle = "TV Shows"
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false

  if key = "down"
    m.top.lastFocus = m.top.focusedChild
    m.top.findNode("paginator").setFocus(true)
  end if

  return false
end function