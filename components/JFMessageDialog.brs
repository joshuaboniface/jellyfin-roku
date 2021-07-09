sub init()
    options = m.top.findNode("optionList")
    options.focusBitmapBlendColor = "0x0cb0e8"
    options.color = "0xffffff"
    options.focusedColor = "0xffffff"
    options.setFocus(true)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if key = "back"
        m.top.backPressed = true
        return true
    end if
    return false
end function

sub updateOptions()
    for each item in m.top.options
        row = CreateObject("roSGNode", "ContentNode")
        row.title = item
        m.top.findNode("content").appendChild(row)
    end for
    redraw()
end sub

sub updateMessage()
    message = m.top.findNode("messageText")
    message.text = m.top.message
    redraw()
end sub

sub redraw()
    boxWidth = 900
    border = 40
    itemSpacing = 40
    optionHeight = 60
    maxRows = 9

    bg = m.top.findNode("dialogBackground")
    text = m.top.findNode("messageText")
    options = m.top.findNode("optionList")
    fontHeight = m.top.fontHeight
    fontWidth = m.top.fontWidth

    if text.text.len() > 0
        textWidth = boxWidth - (border * 2)
        text.width = textWidth
        text.numLines = int(fontWidth / textWidth) + 1
        text.translation = [border, border]
        textHeight = (fontHeight * text.numLines)
    else
        textHeight = 0
        itemSpacing = border
    end if

    options.translation = [border * 2, textHeight + itemSpacing]
    options.itemSize = [boxWidth - (border * 4), optionHeight]
    options.itemSpacing = "[0,20]"

    options.numRows = m.top.options.count()
    if options.numRows > maxRows
        options.numRows = maxRows
        options.wrapDividerHeight = 0
        options.vertFocusAnimationStyle = "fixedFocusWrap"
    end if

    boxHeight = options.translation[1] + (options.itemSize[1] * options.numRows) + (options.itemSpacing[1] * (options.NumRows - 1)) + border

    bg.width = boxWidth
    bg.height = boxHeight

    m.top.translation = [(1920 - boxWidth) / 2, (1080 - boxHeight) / 2]
end sub
