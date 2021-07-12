sub init()
    m.top.functionName = "loadItems"
end sub

sub loadItems()

    results = []

    sort_field = m.top.sortField

    if m.top.sortAscending = true
        sort_order = "Ascending"
    else
        sort_order = "Descending"
    end if


    params = {
        limit: m.top.limit,
        StartIndex: m.top.startIndex,
        parentid: m.top.itemId,
        SortBy: sort_field,
        SortOrder: sort_order,
        recursive: m.top.recursive,
        Fields: "Overview"
    }

    filter = m.top.filter
    if filter = "All" or filter = "all"
        ' do nothing
    else if filter = "Favorites"
        params.append({ Filters: "IsFavorite" })
    end if

    if m.top.ItemType <> ""
        params.append({ IncludeItemTypes: m.top.ItemType })
    end if

    if m.top.ItemType = "LiveTV"
        url = "LiveTv/Channels"
    else
        url = Substitute("Users/{0}/Items/", get_setting("active_user"))
    end if
    resp = APIRequest(url, params)
    data = getJson(resp)

    if data.TotalRecordCount <> invalid
        m.top.totalRecordCount = data.TotalRecordCount
    end if

    for each item in data.Items

        tmp = invalid
        if item.Type = "Movie"
            tmp = CreateObject("roSGNode", "MovieData")
        else if item.Type = "Series"
            tmp = CreateObject("roSGNode", "SeriesData")
        else if item.Type = "BoxSet"
            tmp = CreateObject("roSGNode", "CollectionData")
        else if item.Type = "TvChannel"
            tmp = CreateObject("roSGNode", "ChannelData")
        else if item.Type = "Folder" or item.Type = "ChannelFolderItem" or item.Type = "CollectionFolder"
            tmp = CreateObject("roSGNode", "FolderData")
        else if item.Type = "Video"
            tmp = CreateObject("roSGNode", "VideoData")
        else
            print "[LoadItems] Unknown Type: " item.Type
        end if

        if tmp <> invalid

            tmp.json = item
            results.push(tmp)

        end if
    end for

    m.top.content = results

end sub