sub initGlobal()
    if m.globals = invalid
        m.globals = CreateObject("roAssociativeArray")
    end if
end sub

function getGlobal(key = "" as string) as dynamic
    initGlobal()
    return m.globals[key]
end function

sub setGlobal(key = "" as string, value = invalid as dynamic)
    initGlobal()
    m.globals[key] = value
end sub
