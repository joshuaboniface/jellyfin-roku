sub init()
    m.top.functionName = "getTextSize"
end sub

sub getTextSize()

    reg = CreateObject("roFontRegistry")
    font = reg.GetDefaultFont(m.top.fontsize, false, false)

    res = []

    for each line in m.top.text
        res.push(font.GetOneLineWidth(line, m.top.maxWidth))
    end for

    m.top.height = font.GetOneLineHeight()


    m.top.width = res

end sub