sub init()
    m.top.overhangTitle = "Home"
    m.top.optionsAvailable = true
end sub

sub refresh()
    m.top.findNode("homeRows").callFunc("updateHomeRows")
end sub

sub loadLibraries()
    m.top.findNode("homeRows").callFunc("loadLibraries")
end sub