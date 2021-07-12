sub init()

    m.options = m.top.findNode("options")
    m.tvGuide = invalid

    m.itemGrid = m.top.findNode("itemGrid")
    m.backdrop = m.top.findNode("backdrop")
    m.newBackdrop = m.top.findNode("backdropTransition")
    m.emptyText = m.top.findNode("emptyText")

    m.swapAnimation = m.top.findNode("backroundSwapAnimation")
    m.swapAnimation.observeField("state", "swapDone")

    m.loadedRows = 0
    m.loadedItems = 0

    m.data = CreateObject("roSGNode", "ContentNode")

    m.itemGrid.content = m.data
    m.itemGrid.setFocus(true)

    m.itemGrid.observeField("itemFocused", "onItemFocused")
    m.itemGrid.observeField("itemSelected", "onItemSelected")
    m.newBackdrop.observeField("loadStatus", "newBGLoaded")

    'Background Image Queued for loading
    m.queuedBGUri = ""

    'Item sort - maybe load defaults from user prefs?
    m.sortField = "SortName"
    m.sortAscending = true

    m.filter = "All"

    m.loadItemsTask = createObject("roSGNode", "LoadItemsTask2")

end sub

'
'Load initial set of Data
sub loadInitialItems()

    if m.top.parentItem.backdropUrl <> invalid
        SetBackground(m.top.parentItem.backdropUrl)
    end if

    m.loadItemsTask.itemId = m.top.parentItem.Id
    m.loadItemsTask.sortField = m.sortField
    m.loadItemsTask.sortAscending = m.sortAscending
    m.loadItemsTask.filter = m.filter
    m.loadItemsTask.startIndex = 0

    if m.top.parentItem.collectionType = "movies"
        m.loadItemsTask.itemType = "Movie"
    else if m.top.parentItem.collectionType = "tvshows"
        m.loadItemsTask.itemType = "Series"
    else if m.top.parentItem.collectionType = "livetv"
        m.loadItemsTask.itemType = "LiveTV"

        'For LiveTV, we want to "Fit" the item images, not zoom
        m.top.imageDisplayMode = "scaleToFit"

        if get_user_setting("display.livetv.landing") = "guide"
            showTvGuid()
        end if

    else if m.top.parentItem.collectionType = "CollectionFolder" or m.top.parentItem.collectionType = "boxsets" or m.top.parentItem.Type = "Folder" or m.top.parentItem.Type = "Channel"
        ' Non-recursive, to not show subfolder contents
        m.loadItemsTask.recursive = false
    else if m.top.parentItem.collectionType = "Channel"
        m.top.imageDisplayMode = "scaleToFit"
    else
        print "[ItemGrid] Unknown Type: " m.top.parentItem
    end if

    m.loadItemsTask.observeField("content", "ItemDataLoaded")
    m.loadItemsTask.control = "RUN"

    SetUpOptions()

end sub

' Data to display when options button selected
sub SetUpOptions()

    options = {}
    options.filter = []

    'Movies
    if m.top.parentItem.collectionType = "movies"
        options.views = [
            { "Title": tr("Movies"), "Name": "movies" },
        ]
        options.sort = [
            { "Title": tr("TITLE"), "Name": "SortName" },
            { "Title": tr("IMDB_RATING"), "Name": "CommunityRating" },
            { "Title": tr("CRITIC_RATING"), "Name": "CriticRating" },
            { "Title": tr("DATE_ADDED"), "Name": "DateCreated" },
            { "Title": tr("DATE_PLAYED"), "Name": "DatePlayed" },
            { "Title": tr("OFFICIAL_RATING"), "Name": "OfficialRating" },
            { "Title": tr("PLAY_COUNT"), "Name": "PlayCount" },
            { "Title": tr("RELEASE_DATE"), "Name": "PremiereDate" },
            { "Title": tr("RUNTIME"), "Name": "Runtime" }
        ]
        options.filter = [
            { "Title": tr("All"), "Name": "All" },
            { "Title": tr("Favorites"), "Name": "Favorites" }
        ]
        'Boxsets
    else if m.top.parentItem.collectionType = "boxsets"
        options.views = [{ "Title": tr("Shows"), "Name": "shows" }]
        options.sort = [
            { "Title": tr("TITLE"), "Name": "SortName" },
            { "Title": tr("DATE_ADDED"), "Name": "DateCreated" },
            { "Title": tr("DATE_PLAYED"), "Name": "DatePlayed" },
            { "Title": tr("RELEASE_DATE"), "Name": "PremiereDate" },
        ]
        options.filter = [
            { "Title": tr("All"), "Name": "All" },
            { "Title": tr("Favorites"), "Name": "Favorites" }
        ]
        'TV Shows
    else if m.top.parentItem.collectionType = "tvshows"
        options.views = [{ "Title": tr("Shows"), "Name": "shows" }]
        options.sort = [
            { "Title": tr("TITLE"), "Name": "SortName" },
            { "Title": tr("IMDB_RATING"), "Name": "CommunityRating" },
            { "Title": tr("DATE_ADDED"), "Name": "DateCreated" },
            { "Title": tr("DATE_PLAYED"), "Name": "DatePlayed" },
            { "Title": tr("OFFICIAL_RATING"), "Name": "OfficialRating" },
            { "Title": tr("RELEASE_DATE"), "Name": "PremiereDate" },
        ]
        options.filter = []
        'Live TV
    else if m.top.parentItem.collectionType = "livetv"
        options.views = [
            { "Title": tr("Channels"), "Name": "livetv" },
            { "Title": tr("TV Guide"), "Name": "tvGuide", "Selected": get_user_setting("display.livetv.landing") = "guide" }
        ]
        options.sort = [
            { "Title": tr("TITLE"), "Name": "SortName" }
        ]
        options.filter = []
    else
        options.views = [
            { "Title": tr("Default"), "Name": "default" }
        ]
        options.sort = [
            { "Title": tr("TITLE"), "Name": "SortName" }
        ]
        options.filter = []
    end if

    for each o in options.sort
        if o.Name = m.sortField
            o.Selected = true
            o.Ascending = m.sortAscending
        end if
    end for

    for each o in options.filter
        if o.Name = m.filter
            o.Selected = true
        end if
    end for

    m.options.options = options

end sub


'
'Handle loaded data, and add to Grid
sub ItemDataLoaded(msg)

    itemData = msg.GetData()
    m.loadItemsTask.unobserveField("content")
    m.loadItemsTask.content = []

    if itemData = invalid
        m.Loading = false
        return
    end if

    for each item in itemData
        m.data.appendChild(item)
    end for

    'Update the stored counts
    m.loadedItems = m.itemGrid.content.getChildCount()
    m.loadedRows = m.loadedItems / m.itemGrid.numColumns
    m.Loading = false

    'If there are no items to display, show message
    if m.loadedItems = 0
        m.emptyText.text = tr("NO_ITEMS").Replace("%1", m.top.parentItem.Type)
        m.emptyText.visible = true
    end if

    m.itemGrid.setFocus(true)

end sub

'
'Set Background Image
sub SetBackground(backgroundUri as string)

    'If a new image is being loaded, or transitioned to, store URL to load next
    if m.swapAnimation.state <> "stopped" or m.newBackdrop.loadStatus = "loading"
        m.queuedBGUri = backgroundUri
        return
    end if

    m.newBackdrop.uri = backgroundUri
end sub

'
'Handle new item being focused
sub onItemFocused()

    focusedRow = CInt(m.itemGrid.itemFocused / m.itemGrid.numColumns) + 1

    itemInt = m.itemGrid.itemFocused

    ' If no selected item, set background to parent backdrop
    if itemInt = -1
        return
    end if

    ' Set Background to item backdrop
    SetBackground(m.itemGrid.content.getChild(m.itemGrid.itemFocused).backdropUrl)

    ' Load more data if focus is within last 3 rows, and there are more items to load
    if focusedRow >= m.loadedRows - 3 and m.loadeditems < m.loadItemsTask.totalRecordCount
        loadMoreData()
    end if
end sub

'
'When Image Loading Status changes
sub newBGLoaded()
    'If image load was sucessful, start the fade swap
    if m.newBackdrop.loadStatus = "ready"
        m.swapAnimation.control = "start"
    end if
end sub

'
'Swap Complete
sub swapDone()

    if m.swapAnimation.state = "stopped"

        'Set main BG node image and hide transitioning node
        m.backdrop.uri = m.newBackdrop.uri
        m.backdrop.opacity = 0.25
        m.newBackdrop.opacity = 0

        'If there is another one to load
        if m.newBackdrop.uri <> m.queuedBGUri and m.queuedBGUri <> ""
            SetBackground(m.queuedBGUri)
            m.queuedBGUri = ""
        end if
    end if
end sub

'
'Load next set of items
sub loadMoreData()

    if m.Loading = true then return

    m.Loading = true
    m.loadItemsTask.startIndex = m.loadedItems
    m.loadItemsTask.observeField("content", "ItemDataLoaded")
    m.loadItemsTask.control = "RUN"
end sub

'
'Item Selected
sub onItemSelected()
    m.top.selectedItem = m.itemGrid.content.getChild(m.itemGrid.itemSelected)
end sub


'
'Check if options updated and any reloading required
sub optionsClosed()

    if m.options.view = "tvGuide"
        showTVGuid()
        return
    else if m.tvGuide <> invalid
        ' Try to hide the TV Guide
        m.top.removeChild(m.tvGuide)
    end if

    reload = false
    if m.options.sortField <> m.sortField or m.options.sortAscending <> m.sortAscending
        m.sortField = m.options.sortField
        m.sortAscending = m.options.sortAscending
        reload = true
    end if
    if m.options.filter <> m.filter
        m.filter = m.options.filter
        reload = true
    end if
    if reload
        m.loadedRows = 0
        m.loadedItems = 0
        m.data = CreateObject("roSGNode", "ContentNode")
        m.itemGrid.content = m.data
        loadInitialItems()
    end if
    m.itemGrid.setFocus(true)
end sub

sub showTVGuid()
    m.top.signalBeacon("EPGLaunchInitiate") ' Required Roku Performance monitoring
    if m.tvGuide = invalid
        m.tvGuide = createObject("roSGNode", "Schedule")
    end if
    m.tvGuide.observeField("watchChannel", "onChannelSelected")
    m.top.appendChild(m.tvGuide)
    m.tvGuide.lastFocus.setFocus(true)
end sub

sub onChannelSelected(msg)
    node = msg.getRoSGNode()
    m.top.lastFocus = lastFocusedChild(node)
    if node.watchChannel <> invalid
        ' Clone the node when it's reused/update in the TimeGrid it doesn't automatically start playing
        m.top.selectedItem = node.watchChannel.clone(false)
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean

    if not press then return false

    if key = "options"
        if m.options.visible = true
            m.options.visible = false
            m.top.removeChild(m.options)
            optionsClosed()
        else
            m.options.visible = true
            m.top.appendChild(m.options)
            m.options.setFocus(true)
        end if
        return true
    else if key = "back"
        if m.options.visible = true
            m.options.visible = false
            optionsClosed()
            return true
        end if
    else if key = "play"
        markupGrid = m.top.getChild(2)
        itemToPlay = markupGrid.content.getChild(markupGrid.itemFocused)
        if itemToPlay <> invalid and (itemToPlay.type = "Movie" or itemToPlay.type = "Episode")
            m.top.quickPlayNode = itemToPlay
        end if
        return true
    end if
    return false
end function
