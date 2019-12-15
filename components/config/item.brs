sub init()
  m.name = m.top.findNode("label")
  m.value = m.top.findNode("value")

  m.name.width = 240
  m.name.height = 75

  m.name.vertAlign = "center"
  m.name.horizAlign = "center"

  m.value.hintText = "Enter a value..."
  m.value.maxTextLength = 120
end sub

sub itemContentChanged()
  data = m.top.itemContent

  m.name.text = data.label
  if data.type = "password"
    m.value.secureMode = true
  end if

  m.value.text = data.value
end sub

sub setColors()
  if m.top.itemHasFocus
    color = "#101010FF"
  else
    color = "#ffffffFF"
  end if

  m.name.color = color
  m.value.textColor = color

end sub
