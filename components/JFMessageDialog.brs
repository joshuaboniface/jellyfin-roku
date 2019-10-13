sub init()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if key = "OK"
    m.top.close = true
    return true
  end if

  return false
end function
