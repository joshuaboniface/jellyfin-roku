sub init()

    m.top.focusable = true

    m.menubg = m.top.findNode("menubg")

    m.focusRing = m.top.findNode("focus")
    m.buttonGroup = m.top.findNode("buttonGroup")
    m.focusAnim = m.top.findNode("moveFocusAnimation")
    m.focusAnimTranslation = m.top.findNode("focusLocation")
    m.focusAnimWidth = m.top.findNode("focusWidth")
    m.focusAnimHeight = m.top.findNode("focusHeight")

    ' Set button color to global
    m.focusRing.color = m.global.constants.colors.button

    m.buttonCount = 0
    m.selectedFocusedIndex = 0

    m.textSizeTask = createObject("roSGNode", "TextSizeTask")

    m.top.observeField("focusedChild", "focusChanged")
    m.top.enableRenderTracking = true
    m.top.observeField("renderTracking", "renderChanged")

end sub

'
' When Selected Index set, ensure it is the one Focused
sub selectedIndexChanged()
    m.selectedFocusedIndex = m.top.selectedIndex
end sub

'
' When options are fully displayed, set focus and selected option
sub renderChanged()
    if m.top.renderTracking = "full"
        highlightSelected(m.selectedFocusedIndex, false)
        m.top.setfocus(true)
    end if
end sub


sub updateButtons()
    m.textSizeTask.fontsize = 40
    m.textSizeTask.text = m.top.buttons
    m.textSizeTask.name = m.buttonCount
    m.textSizeTask.observeField("width", "showButtons")
    m.textSizeTask.control = "RUN"
end sub

sub showButtons()

    totalWidth = 110 ' track for menu background width - start with side padding

    for i = 0 to m.top.buttons.count() - 1
        m.buttonCount = m.buttonCount + 1
        l = m.buttonGroup.createChild("Label")
        l.text = m.top.buttons[i]
        l.font.size = 40
        l.translation = [0, 10]
        l.height = m.textSizeTask.height
        l.width = m.textSizeTask.width[i] + 50
        l.horizAlign = "center"
        l.vertAlign = "center"
        totalWidth = totalWidth + l.width + 45
    end for

    m.menubg.width = totalWidth
    m.menubg.height = m.textSizeTask.height + 40

end sub

' Highlight selected menu option
sub highlightSelected(index as integer, animate = true)

    val = m.buttonGroup.getChild(index)
    rect = val.ancestorBoundingRect(m.top)

    if animate = true
        m.focusAnimTranslation.keyValue = [m.focusRing.translation, [rect.x - 25, rect.y - 30]]
        m.focusAnimWidth.keyValue = [m.focusRing.width, val.width + 50]
        m.focusAnimHeight.keyValue = [m.focusRing.height, val.height + 60]
        m.focusAnim.control = "start"
    else
        m.focusRing.translation = [rect.x - 25, rect.y - 30]
        m.focusRing.width = val.width + 50
        m.focusRing.height = val.height + 60
    end if

end sub

' Change opacity of the highlighted menu item based on focus
sub focusChanged()
    if m.top.isInFocusChain()
        m.focusRing.opacity = 1
    else
        m.focusRing.opacity = 0.6
    end if
end sub


function onKeyEvent(key as string, press as boolean) as boolean

    if not press then return false

    if key = "left"
        if m.selectedFocusedIndex > 0 then m.selectedFocusedIndex = m.selectedFocusedIndex - 1
        highlightSelected(m.selectedFocusedIndex)
        m.top.focusedIndex = m.selectedFocusedIndex
        return true
    else if key = "right"
        if m.selectedFocusedIndex < m.buttonCount - 1 then m.selectedFocusedIndex = m.selectedFocusedIndex + 1
        highlightSelected(m.selectedFocusedIndex)
        m.top.focusedIndex = m.selectedFocusedIndex
        return true
    else if key = "OK"
        m.top.selectedIndex = m.selectedFocusedIndex
        return true
    end if
    return false
end function
