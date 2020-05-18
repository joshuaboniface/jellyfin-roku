sub init()
	m.top.overhangTitle = "Home"
	m.top.optionsAvailable = true
end sub

function refresh()
	m.top.findNode("homeRows").callFunc("updateHomeRows")
end function