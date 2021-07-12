function get_token(user as string, password as string)
    url = "Users/AuthenticateByName?format=json"
    req = APIRequest(url)

    json = postJson(req, FormatJson({ "Username": user, "Pw": password }))

    if json = invalid then return invalid

    userdata = CreateObject("roSGNode", "UserData")
    userdata.json = json

    userdata.callFunc("setActive")
    userdata.callFunc("saveToRegistry")
    return userdata
end function

function AboutMe()
    id = get_setting("active_user")
    url = Substitute("Users/{0}", id)
    resp = APIRequest(url)
    return getJson(resp)
end function

sub SignOut()
    if get_setting("active_user") <> invalid
        unset_user_setting("token")
        unset_setting("username")
        unset_setting("password")
    end if
    unset_setting("active_user")
    m.overhang.currentUser = ""
    m.overhang.showOptions = false
    m.scene.unobserveField("optionsPressed")
end sub

function AvailableUsers()
    users = parseJson(get_setting("available_users", "[]"))
    return users
end function

sub PickUser(id as string)
    this_user = invalid
    for each user in AvailableUsers()
        if user.id = id then this_user = user
    end for
    if this_user = invalid then return
    set_setting("active_user", this_user.id)
    set_setting("server", this_user.server)
end sub

sub RemoveUser(id as string)
    user = CreateObject("roSGNode", "UserData")
    user.id = id
    user.callFunc("removeFromRegistry")

    if get_setting("active_user") = id then SignOut()
end sub

function ServerInfo()
    url = "System/Info/Public"
    req = APIRequest(url)

    req.setMessagePort(CreateObject("roMessagePort"))
    req.AsyncGetToString()

    ' wait 15 seconds for a server response
    resp = wait(35000, req.GetMessagePort())

    ' handle unknown errors
    if type(resp) <> "roUrlEvent"
        return { "Error": true, "ErrorMessage": "Unknown" }
    end if

    ' check for a location redirect header in the response
    headers = resp.GetResponseHeaders()
    if headers <> invalid and headers.location <> invalid

        ' only follow redirect if it the API Endpoint path is the same (/System/Info/Public)
        ' set the server to new location and try again
        if right(headers.location, 19) = "/System/Info/Public"
            set_setting("server", left(headers.location, len(headers.location) - 19))
            info = ServerInfo()
            if info.Error
                info.UpdatedUrl = left(headers.location, len(headers.location) - 19)
                info.ErrorMessage = info.ErrorMessage + " (Note: Server redirected us to " + info.UpdatedUrl + ")"
            end if
            return info
        end if
    end if

    ' handle any non 200 responses, returning the error code and message
    if resp.GetResponseCode() <> 200
        return { "Error": true, "ErrorCode": resp.GetResponseCode(), "ErrorMessage": resp.GetFailureReason() }
    end if

    ' return the parsed response string
    responseString = resp.GetString()
    if responseString <> invalid and responseString <> ""
        result = ParseJson(responseString)
        if result <> invalid
            result.Error = false
            return result
        end if
    end if

    ' otherwise return error message
    return { "Error": true, "ErrorMessage": "Does not appear to be a Jellyfin Server" }

end function

function GetPublicUsers()
    url = "Users/Public"
    resp = APIRequest(url)
    return getJson(resp)
end function

' Load and parse Display Settings from server
sub LoadUserPreferences()
    id = get_setting("active_user")
    ' Currently using client "emby", which is what website uses so we get same Display prefs as web.
    ' May want to change to specific Roku display settings
    url = Substitute("DisplayPreferences/usersettings?userId={0}&client=emby", id)
    resp = APIRequest(url)
    jsonResponse = getJson(resp)

    if jsonResponse <> invalid and jsonResponse.CustomPrefs <> invalid and jsonResponse.CustomPrefs["landing-livetv"] <> invalid
        set_user_setting("display.livetv.landing", jsonResponse.CustomPrefs["landing-livetv"])
    else
        unset_user_setting("display.livetv.landing")
    end if
end sub