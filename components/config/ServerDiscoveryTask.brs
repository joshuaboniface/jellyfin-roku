'
' Task used to discover jellyfin servers on the local network
'
sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    m.servers = []
    m.serverUrlMap = {}
    m.locationUrlMap = {}
    'send both requests at the same time
    SendSSDPBroadcast()
    SendClientDiscoveryBroadcast()

    ts = CreateObject("roTimespan")
    maxTimeMs = 2200

    'monitor each port and collect messages
    while True
        elapsed = ts.TotalMilliseconds()
        if elapsed >= maxTimeMs
            exit while
        end if

        msg = Wait(100, m.ssdp.port)
        if msg <> invalid
            ProcessSSDPResponse(msg)
        end if

        msg = Wait(100, m.clientDiscovery.port)
        if msg <> invalid
            ProcessClientDiscoveryResponse(msg)
        end if

    end while

    m.top.content = m.servers
    print m.servers[0], m.servers[1], m.servers[2]
end sub

sub AddServer(server)
    if m.serverUrlMap[server.baseUrl] = invalid
        m.serverUrlMap[server.baseUrl] = true
        m.servers.push(server)
    end if
end sub

sub SendClientDiscoveryBroadcast()
    m.clientDiscovery = {
        port: CreateObject("roMessagePort"),
        address: CreateObject("roSocketAddress"),
        socket: CreateObject("roDatagramSocket"),
        urlTransfer: CreateObject("roUrlTransfer")
    }
    m.clientDiscovery.address.SetAddress("255.255.255.255:7359")
    m.clientDiscovery.urlTransfer.SetPort(m.clientDiscoveryPort)
    m.clientDiscovery.socket.SetMessagePort(m.clientDiscovery.port)
    m.clientDiscovery.socket.SetSendToAddress(m.clientDiscovery.address)
    m.clientDiscovery.socket.NotifyReadable(true)
    m.clientDiscovery.socket.SetBroadcast(true)
    m.clientDiscovery.socket.SendStr("Who is JellyfinServer?")
end sub

sub ProcessClientDiscoveryResponse(message)
    if Type(message) = "roSocketEvent" and message.GetSocketId() = m.clientDiscovery.socket.GetId() and m.clientDiscovery.socket.IsReadable()
        try
            responseJson = m.clientDiscovery.socket.ReceiveStr(4096)
            server = ParseJson(responseJson)
            AddServer({
                name: server.Name,
                baseUrl: server.Address,
                'hardcoded icon since this service doesn't include them
                iconUrl: "pkg:/images/logo-icon120.jpg",
                iconWidth: 120,
                iconHeight: 120
            })
            print "Found Jellyfin server using client discovery at " + server.Address
        catch e
            print "Error scanning for jellyfin server", message
        end try
    end if
end sub

sub SendSSDPBroadcast()
    m.ssdp = {
        port: CreateObject("roMessagePort"),
        address: CreateObject("roSocketAddress"),
        socket: CreateObject("roDatagramSocket"),
        urlTransfer: CreateObject("roUrlTransfer")
    }
    m.ssdp.address.SetAddress("239.255.255.250:1900")
    m.ssdp.socket.SetMessagePort(m.ssdp.port)
    m.ssdp.socket.SetSendToAddress(m.ssdp.address)
    m.ssdp.socket.NotifyReadable(true)
    m.ssdp.urlTransfer.SetPort(m.ssdp.port)

    'brightscript can't escape characters in strings, so create a few vars here so we can use them in the strings below
    Q = Chr(34)
    CRLF = Chr(13) + Chr(10)

    ssdpStr = "M-SEARCH * HTTP/1.1" + CRLF
    ssdpStr += "HOST: 239.255.255.250:1900" + CRLF
    ssdpStr += "MAN: " + Q + "ssdp:discover" + Q + CRLF
    ssdpStr += "ST:urn:schemas-upnp-org:device:MediaServer:1" + CRLF
    ssdpStr += "MX: 2" + CRLF
    ssdpStr += CRLF

    m.ssdp.socket.SendStr(ssdpStr)
end sub

sub ProcessSSDPResponse(message)
    locationUrl = invalid
    if Type (message) = "roSocketEvent" and message.GetSocketId() = m.ssdp.socket.GetId() and m.ssdp.socket.IsReadable()
        recvStr = m.ssdp.socket.ReceiveStr(4096)
        match = CreateObject("roRegex", "\r\nLocation:\s*(.*?)\s*\r\n", "i").Match(recvStr)
        if match.Count() = 2
            locationUrl = match[1]
        end if
    end if

    if locationUrl = invalid
        return
    else if m.locationUrlMap[locationUrl] <> invalid
        print "Already discovered this location " + locationUrl
        return
    end if

    m.locationUrlMap[locationUrl] = true

    http = CreateObject("roUrlTransfer")
    http.SetUrl(locationUrl)
    responseText = http.GetToString()
    xml = CreateObject("roXMLElement")
    'if we successfully parsed the response, process it
    if xml.Parse(responseText)
        deviceNode = xml.GetNamedElementsCi("device")[0]
        manufacturer = deviceNode.GetNamedElementsCi("manufacturer").GetText()
        'only process jellyfin servers
        if lcase(manufacturer) = "jellyfin"
            'find the largest icon
            width = 0
            server = invalid
            icons = deviceNode.GetNamedElementsCi("iconList")[0].GetNamedElementsCi("icon")
            for each iconNode in icons
                iconUrl = iconNode.GetNamedElementsCi("url").GetText()
                baseUrl = invalid
                match = CreateObject("roRegex", "(.*?)\/dlna\/", "i").Match(iconUrl)
                if match.Count() = 2
                    baseUrl = match[1]
                end if
                loopResult = {
                    name: deviceNode.GetNamedElementsCi("friendlyName").GetText(),
                    baseUrl: baseUrl,
                    iconUrl: iconUrl,
                    iconWidth: iconNode.GetNamedElementsCi("width")[0].GetText().ToInt(),
                    iconHeight: iconNode.GetNamedElementsCi("height")[0].GetText().ToInt()
                }
                if baseUrl <> invalid and loopResult.iconWidth > width
                    width = loopResult.iconWidth
                    server = loopResult
                end if
            end for
            AddServer(server)
            print "Found jellyfin server using SSDP and DLNA at " + server.baseUrl
        end if
    end if
end sub
