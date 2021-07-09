' Functions for making requests to the API
function buildParams(params = {} as object) as string
    ' Take an object of parameters and construct the URL query
    req = createObject("roUrlTransfer") ' Just so we can use it for escape

    param_array = []
    for each field in params.items()
        item = ""
        if type(field.value) = "String" or type(field.value) = "roString"
            item = field.key + "=" + req.escape(field.value.trim())
            'item = field.key + "=" + field.value.trim()
        else if type(field.value) = "roInteger" or type(field.value) = "roInt"
            item = field.key + "=" + stri(field.value).trim()
            'item = field.key + "=" + str(field.value).trim()
        else if type(field.value) = "roFloat"
            item = field.key + "=" + stri(int(field.value)).trim()
        else if type(field.value) = "LongInteger"
            item = field.key + "=" + field.value.toStr().trim()
        else if type(field.value) = "roArray"
            ' TODO handle array params
        else if type(field.value) = "roBoolean"
            if field.value
                item = field.key + "=true"
            else
                item = field.key + "=false"
            end if
        else if field.value = invalid
            item = field.key + "=null"
        else if field <> invalid
            print "Unhandled param type: " + type(field.value)
            item = field.key + "=" + req.escape(field.value)
            'item = field.key + "=" + field.value
        end if

        if item <> "" then param_array.push(item)
    end for

    return param_array.join("&")
end function

function buildURL(path as string, params = {} as object) as string

    ' Add intial '/' if path does not start with one
    if path.Left(1) = "/"
        full_url = get_url() + path
    else
        full_url = get_url() + "/" + path
    end if

    if params.count() > 0
        full_url = full_url + "?" + buildParams(params)
    end if

    return full_url
end function

function APIRequest(url as string, params = {} as object)
    req = createObject("roUrlTransfer")
    req.setCertificatesFile("common:/certs/ca-bundle.crt")

    full_url = buildURL(url, params)
    req.setUrl(full_url)
    req = authorize_request(req)

    return req
end function

function getJson(req)
    'req.retainBodyOnError(True)
    'print req.GetToString()
    data = req.GetToString()
    if data = invalid or data = ""
        return invalid
    end if
    json = ParseJson(data)
    return json
end function

function postVoid(req, data = "" as string)
    status = req.PostFromString(data)
    if status = 200
        return true
    else
        return false
    end if
end function

function postJson(req, data = "" as string)
    req.setMessagePort(CreateObject("roMessagePort"))
    req.AddHeader("Content-Type", "application/json")
    req.AsyncPostFromString(data)
    resp = wait(30000, req.GetMessagePort())
    if type(resp) <> "roUrlEvent"
        return invalid
    end if

    if resp.getString() = ""
        return invalid
    end if

    json = ParseJson(resp.GetString())

    return json
end function

function get_url()
    base = get_setting("server")
    if base.right(1) = "/"
        base = base.left(base.len() - 1)
    end if

    ' append http:// to the start if not specified
    if base.left(7) <> "http://" and base.left(8) <> "https://"
        base = "http://" + base
    end if

    return base

end function

function authorize_request(request)
    devinfo = CreateObject("roDeviceInfo")
    appinfo = CreateObject("roAppInfo")

    auth = "MediaBrowser"

    client = "Jellyfin Roku"
    auth = auth + " Client=" + Chr(34) + client + Chr(34)

    device = devinfo.getModelDisplayName()
    friendly = devinfo.getFriendlyName()
    ' remove special characters
    regex = CreateObject("roRegex", "[^a-zA-Z0-9\ \-\_]", "")
    friendly = regex.ReplaceAll(friendly, "")
    auth = auth + ", Device=" + Chr(34) + device + " (" + friendly + ")" + Chr(34)

    device_id = devinfo.getChannelClientID()
    if get_setting("active_user") = invalid or get_setting("active_user") = ""
        device_id = devinfo.GetRandomUUID()
    end if
    auth = auth + ", DeviceId=" + Chr(34) + device_id + Chr(34)

    version = appinfo.GetVersion()
    auth = auth + ", Version=" + Chr(34) + version + Chr(34)

    user = get_setting("active_user")
    if user <> invalid and user <> ""
        auth = auth + ", UserId=" + Chr(34) + user + Chr(34)
    end if

    token = get_user_setting("token")
    if token <> invalid and token <> ""
        auth = auth + ", Token=" + Chr(34) + token + Chr(34)
    end if

    request.AddHeader("X-Emby-Authorization", auth)
    return request
end function
