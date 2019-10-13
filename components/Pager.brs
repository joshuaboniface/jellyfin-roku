sub init()
    m.top.currentPage = 0
    m.top.maxPages = 0
    m.top.layoutDirection = "horiz"
    m.top.horizAlignment = "center"
    m.top.vertAlignment = "center"
end sub

sub recountPages()
    if m.top.currentPage = 0 or m.top.maxPages = 0
        return
    end if
    while m.top.getChildCount() > 0
        m.top.removeChildIndex(0)
    end while

    currentPage = m.top.currentPage
    maxPages = m.top.maxPages

    minShown = 1
    maxShown = maxPages

    if currentPage > 1
        addPage("<")
        minShown = currentPage - 3
    end if

    if minShown <= 0 then minShown = 1

    if currentPage < maxPages then maxShown = currentPage + 3
    if maxShown >= maxPages then maxShown = maxPages

    for i=minShown to maxShown step 1
        addPage(i)
    end for

    if currentPage <> maxPages
        addPage(">")
    end if

    m.top.pageFocused = m.top.findNode(stri(currentPage).trim())

    m.top.pageFocused.color = "#00ff00ff"

    updateLayout()
end sub

sub updateLayout()
    dimensions = m.top.getScene().currentDesignResolution
    height = 115
    m.top.translation = [dimensions.width / 2, dimensions.height - (height / 2)]
end sub

sub addPage(i)
    p = CreateObject("roSGNode", "Label")
    p.height = 50
    p.width = 50
    p.color = "#a1a1a1FF"
    if type(i) = "roInt"
        i = stri(i).trim()
    end if
    p.id = i
    p.text = i
    m.top.appendChild(p)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "OK"
        m.top.pageSelected = m.top.focusedChild
        return true
    else if key = "left"
        focusPrev()
        return true
    else if key = "right"
        focusNext()
        return true
    else if key = "up"
        if m.top.getParent().lastFocus <> invalid
          m.top.getParent().lastFocus.setFocus(true)
        else
          m.top.getParent().setFocus(true)
        end if
        return true
    end if

    return false
end function

sub focusNext()
    i = getFocusIndex()
    if (i + 1) = m.top.getChildCount() then return

    m.top.pageFocused.color = "#a1a1a1FF"
    m.top.pageFocused = m.top.getChild(i + 1)
    m.top.pageFocused.color = "#00ff00ff"
    m.top.pageFocused.setFocus(true)
end sub

sub focusPrev()
    i = getFocusIndex()
    if i = 0 then return

    m.top.pageFocused.color = "#a1a1a1FF"
    m.top.pageFocused = m.top.getChild(i - 1)
    m.top.pageFocused.color = "#00ff00ff"
    m.top.pageFocused.setFocus(true)
end sub

function getFocusIndex()
    for i=0 to m.top.getChildCount() step 1
        if m.top.getChild(i).id = m.top.pageFocused.id then return i
    end for
    return invalid
end function