sub init()
    m.top.backgroundColor = "#262626" '"#101010"
    m.top.backgroundURI = ""
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "back"
        m.top.backPressed = true
        return true
    else if key = "options"
        m.top.optionsPressed = true
        return true
    end if

    return false
end function
