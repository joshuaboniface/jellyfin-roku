sub init()
  m.top.optionsAvailable = false
end sub

sub itemContentChanged()
  m.top.findNode("UserRow").ItemContent = m.top.itemContent
  redraw()
end sub

sub redraw()
  userCount = m.top.itemContent.Count()
  topBorder = 360
  leftBorder= 130
  itemWidth = 300
  itemSpacing = 40

  if userCount < 5 then
    leftBorder = (1920 - ((userCount * itemWidth) + ((userCount - 1) * itemSpacing))) / 2
  end if
'   break()
  m.top.findNode("UserRow").translation = [leftBorder, topBorder]
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false

  if key = "back" then
    m.top.backPressed = true
  else if key = "up" then
    if m.top.focusedChild.isSubType("LabelList") then
      m.top.findNode("UserRow").setFocus(true)
      return true
    end if
  else if key = "down" then
    if m.top.focusedChild.isSubType("UserRow") then
      m.top.findNode("alternateOptions").setFocus(true)
      return true
    end if
  end if
  return false
end function
