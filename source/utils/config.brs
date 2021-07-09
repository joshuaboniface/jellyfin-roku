' "Registry" is where Roku stores config


' Generic registry accessors
function registry_read(key, section = invalid)
    if section = invalid then return invalid
    reg = CreateObject("roRegistrySection", section)
    if reg.exists(key) then return reg.read(key)
    return invalid
end function

sub registry_write(key, value, section = invalid)
    if section = invalid then return
    reg = CreateObject("roRegistrySection", section)
    reg.write(key, value)
    reg.flush()
end sub

sub registry_delete(key, section = invalid)
    if section = invalid then return
    reg = CreateObject("roRegistrySection", section)
    reg.delete(key)
    reg.flush()
end sub


' "Jellyfin" registry accessors for the default global settings
function get_setting(key, default = invalid)
    value = registry_read(key, "Jellyfin")
    if value = invalid then return default
    return value
end function

sub set_setting(key, value)
    registry_write(key, value, "Jellyfin")
end sub

sub unset_setting(key)
    registry_delete(key, "Jellyfin")
end sub


' User registry accessors for the currently active user
function get_user_setting(key, default = invalid)
    if get_setting("active_user") = invalid then return default
    value = registry_read(key, get_setting("active_user"))
    if value = invalid then return default
    return value
end function

sub set_user_setting(key, value)
    if get_setting("active_user") = invalid then return
    registry_write(key, value, get_setting("active_user"))
end sub

sub unset_user_setting(key)
    if get_setting("active_user") = invalid then return
    registry_delete(key, get_setting("active_user"))
end sub
