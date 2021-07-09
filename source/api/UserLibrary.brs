function MarkItemFavorite(id as string)
    url = Substitute("Users/{0}/FavoriteItems/{1}", get_setting("active_user"), id)
    resp = APIRequest(url)
    return postJson(resp)
end function

function UnmarkItemFavorite(id as string)
    url = Substitute("Users/{0}/FavoriteItems/{1}", get_setting("active_user"), id)
    resp = APIRequest(url)
    resp.setRequest("DELETE")
    return getJson(resp)
end function

sub MarkItemWatched(id as string)
    date = CreateObject("roDateTime")
    dateStr = stri(date.getYear()).trim()
    dateStr += leftPad(stri(date.getMonth()).trim(), "0", 2)
    dateStr += leftPad(stri(date.getDayOfMonth()).trim(), "0", 2)
    dateStr += leftPad(stri(date.getHours()).trim(), "0", 2)
    dateStr += leftPad(stri(date.getMinutes()).trim(), "0", 2)
    dateStr += leftPad(stri(date.getSeconds()).trim(), "0", 2)

    url = Substitute("Users/{0}/PlayedItems/{1}", get_setting("active_user"), id)
    APIRequest(url, { "DatePlayed": dateStr })
end sub

function UnmarkItemWatched(id as string)
    url = Substitute("Users/{0}/PlayedItems/{1}", get_setting("active_user"), id)
    resp = APIRequest(url)
    resp.setRequest("DELETE")
    return getJson(resp)
end function
