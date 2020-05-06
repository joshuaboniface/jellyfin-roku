sub init()
    m.top.layoutDirection = "vert"
    m.top.horizAlignment = "center"
    m.top.vertAlignment = "top"
    m.top.visible = false

    show_dialog()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "OK"
        ' Make a Keyboard Dialog here
        show_dialog()
        return true
    end if

    return false
end function

function onDialogButton()
    d = m.top.getScene().dialog
    button_text = d.buttons[d.buttonSelected]

    if button_text = tr("Search")
        m.top.search_value = d.text
        dismiss_dialog()
        return true
    else if button_text = tr("Cancel")
        dismiss_dialog()
        return true
    end if

    return false
end function

sub show_dialog()
    dialog = CreateObject("roSGNode", "KeyboardDialog")
    dialog.title = tr("Search")
    dialog.buttons = [tr("Search"), tr("Cancel")]

    m.top.getScene().dialog = dialog

    dialog.observeField("buttonselected", "onDialogButton")
end sub

sub dismiss_dialog()
    m.top.getScene().dialog.close = true
end sub
