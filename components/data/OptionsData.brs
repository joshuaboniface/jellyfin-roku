sub init()
    m.top.value_index = 0
end sub

sub update_title()
    if m.top.choices.count() = 0
        m.top.title = m.top.base_title + ": <none>"
        return
    end if

    for i = 0 to m.top.choices.count() - 1
        if m.top.choices[i].value = m.top.value
            m.top.value_index = i
            exit for
        end if
    end for
    m.top.title = m.top.base_title + ": " + m.top.choices[m.top.value_index].display
end sub

sub press()
    max_opt = m.top.choices.count()
    i = m.top.value_index + 1
    while i >= max_opt
        i = i - max_opt
    end while

    m.top.value_index = i
    m.top.value = m.top.choices[m.top.value_index].value

    if m.top.config_key = "" or m.top.config_key = invalid
        return
    end if
    if m.top.global_setting
        set_setting(m.top.config_key, m.top.value)
    else
        set_user_setting(m.top.config_key, m.top.value)
    end if
end sub