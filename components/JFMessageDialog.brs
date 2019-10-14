sub init()
  m.top.observeField("buttonSelected", handle_button)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if key = "OK"
    m.top.buttonSelected = 0
    handle_button()
    return true
  end if

  return false
end function

function handle_button()
  ' We just toggle the close state, so subsequent touches don't do anything funny
  m.top.close = true
  m.top.close = false
end function
