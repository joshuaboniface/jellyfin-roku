sub init()
    m.top.optionsAvailable = false
end sub

sub setSeason()
    m.top.overhangTitle = m.top.seasonData.SeriesName + " - " + m.top.seasonData.name
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    handled = false
    if press
        if key = "play"
            itemToPlay = m.top.focusedChild.content.getChild(m.top.focusedChild.rowItemFocused[0]).getChild(0)
            if itemToPlay <> invalid and itemToPlay.id <> ""
                m.top.quickPlayNode = itemToPlay
            end if
            handled = true
        end if
    end if
    return handled
end function
