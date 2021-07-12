sub init()

    m.buttons = m.top.findNode("buttons")
    m.buttons.buttons = [tr("Audio")]
    m.buttons.setFocus(true)

    m.selectedItem = 0
    m.selectedAudioIndex = 0

    m.menus = []
    m.menus.push(m.top.findNode("audioMenu"))

    m.viewNames = []

    ' Set button color to global
    m.top.findNode("audioMenu").focusBitmapBlendColor = m.global.constants.colors.button

    ' Animation
    m.fadeAnim = m.top.findNode("fadeAnim")
    m.fadeOutAnimOpacity = m.top.findNode("outOpacity")
    m.fadeInAnimOpacity = m.top.findNode("inOpacity")

    m.buttons.observeField("focusedIndex", "buttonFocusChanged")

end sub

sub optionsSet()

    '  Views Tab
    if m.top.options.views <> invalid
        viewContent = CreateObject("roSGNode", "ContentNode")
        index = 0
        selectedViewIndex = 0

        for each view in m.top.options.views
            entry = viewContent.CreateChild("AudioTrackListData")
            entry.title = view.Title
            entry.description = view.Description
            entry.streamIndex = view.StreamIndex
            m.viewNames.push(view.Name)
            if view.Selected <> invalid and view.Selected = true
                selectedViewIndex = index
                entry.selected = true
                m.top.audioSteamIndex = view.streamIndex
            end if
            index = index + 1
        end for

        m.menus[0].content = viewContent
        m.menus[0].jumpToItem = selectedViewIndex
        m.selectedAudioIndex = selectedViewIndex
    end if

end sub

' Switch menu shown when button focus changes
sub buttonFocusChanged()
    if m.buttons.focusedIndex = m.selectedItem then return
    m.fadeOutAnimOpacity.fieldToInterp = m.menus[m.selectedItem].id + ".opacity"
    m.fadeInAnimOpacity.fieldToInterp = m.menus[m.buttons.focusedIndex].id + ".opacity"
    m.fadeAnim.control = "start"
    m.selectedItem = m.buttons.focusedIndex
end sub


function onKeyEvent(key as string, press as boolean) as boolean

    if key = "down" or (key = "OK" and m.top.findNode("buttons").hasFocus())
        m.top.findNode("buttons").setFocus(false)
        m.menus[m.selectedItem].setFocus(true)
        m.menus[m.selectedItem].drawFocusFeedback = true

        'If user presses down from button menu, focus first item.  If OK, focus checked item
        if key = "down"
            m.menus[m.selectedItem].jumpToItem = 0
        else
            m.menus[m.selectedItem].jumpToItem = m.menus[m.selectedItem].itemSelected
        end if

        return true
    else if key = "OK"
        if m.menus[m.selectedItem].isInFocusChain()

            selMenu = m.menus[m.selectedItem]
            selIndex = selMenu.itemSelected

            if m.selectedAudioIndex = selIndex
            else
                selMenu.content.GetChild(m.selectedAudioIndex).selected = false
                newSelection = selMenu.content.GetChild(selIndex)
                newSelection.selected = true
                m.selectedAudioIndex = selIndex
                m.top.audioSteamIndex = newSelection.streamIndex
            end if
        end if
        return true
    else if key = "back" or key = "up"
        if m.menus[m.selectedItem].isInFocusChain()
            m.buttons.setFocus(true)
            m.menus[m.selectedItem].drawFocusFeedback = false
            return true
        end if
    else if key = "options"
        m.menus[m.selectedItem].drawFocusFeedback = false
        return false
    end if

    return false

end function