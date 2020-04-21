sub init()
	m.top.overhangTitle = "Home"
end sub

function refresh()
	m.top.findNode("homeRows").callFunc("updateHomeRows")
end function