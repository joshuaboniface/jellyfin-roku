sub init()
    m.top.itemComponentName = "ConfigItem"

    m.top.drawFocusFeedback = True
    m.top.vertFocusAnimationStyle = "floatingFocus"

    m.top.observeField("itemSelected", "onItemSelected")

    m.top.itemSize = [750, 75]
    m.top.itemSpacing = [0, 25]

    m.top.setfocus(true)

end sub

sub setData()
    items = m.top.configItems
    data = CreateObject("roSGNode", "ContentNode")
    data.appendChildren(items)

    m.top.content = data
end sub

sub onItemSelected()
    i = m.top.itemSelected
    itemField = m.top.content.getchild(i)

    show_dialog(itemField)
end sub

function onDialogButton()
    d = m.dialog
    button_text = d.buttons[d.buttonSelected]

    if button_text = tr("OK")
        m.configField.value = d.text
        dismiss_dialog()
        return true
    else if button_text = tr("Cancel")
        dismiss_dialog()
        return true
    end if
    return false
end function


sub show_dialog(configField)
    dialog = createObject("roSGNode", "KeyboardDialog")
    m.configField = configField
    dialog.title = "Enter the " + configField.label
    dialog.buttons = [tr("OK"), tr("Cancel")]

    if configField.type = "password"
        dialog.keyboard.textEditBox.secureMode = true
    end if

    if configField.value <> ""
        dialog.text = configField.value
    end if

    m.top.getscene().dialog = dialog
    m.dialog = dialog

    dialog.observeField("buttonSelected", "onDialogButton")
end sub

sub dismiss_dialog()
    m.dialog.close = true
end sub
