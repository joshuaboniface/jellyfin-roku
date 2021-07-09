sub init()

    m.scheduleGrid = m.top.findNode("scheduleGrid")
    m.detailsPane = m.top.findNode("detailsPane")

    m.detailsPane.observeField("watchSelectedChannel", "onWatchChannelSelected")

    m.gridStartDate = CreateObject("roDateTime")
    m.scheduleGrid.contentStartTime = m.gridStartDate.AsSeconds() - 1800
    m.gridEndDate = createObject("roDateTime")
    m.gridEndDate.FromSeconds(m.gridStartDate.AsSeconds() + (24 * 60 * 60))

    m.scheduleGrid.observeField("programFocused", "onProgramFocused")
    m.scheduleGrid.observeField("programSelected", "onProgramSelected")
    m.scheduleGrid.observeField("leftEdgeTargetTime", "onGridScrolled")
    m.scheduleGrid.channelInfoWidth = 350

    m.gridMoveAnimation = m.top.findNode("gridMoveAnimation")
    m.gridMoveAnimationPosition = m.top.findNode("gridMoveAnimationPosition")

    m.LoadChannelsTask = createObject("roSGNode", "LoadChannelsTask")
    m.LoadChannelsTask.observeField("channels", "onChannelsLoaded")
    m.LoadChannelsTask.control = "RUN"

    m.top.lastFocus = m.scheduleGrid

    m.channelIndex = {}
end sub

' Initial list of channels loaded
sub onChannelsLoaded()
    gridData = createObject("roSGNode", "ContentNode")

    counter = 0
    channelIdList = ""

    for each item in m.LoadChannelsTask.channels
        gridData.appendChild(item)
        m.channelIndex[item.Id] = counter
        counter = counter + 1
        channelIdList = channelIdList + item.Id + ","
    end for

    m.scheduleGrid.content = gridData

    m.LoadScheduleTask = createObject("roSGNode", "LoadScheduleTask")
    m.LoadScheduleTask.observeField("schedule", "onScheduleLoaded")

    m.LoadScheduleTask.startTime = m.gridStartDate.ToISOString()
    m.LoadScheduleTask.endTime = m.gridEndDate.ToISOString()
    m.LoadScheduleTask.channelIds = channelIdList
    m.LoadScheduleTask.control = "RUN"

    m.LoadProgramDetailsTask = createObject("roSGNode", "LoadProgramDetailsTask")
    m.LoadProgramDetailsTask.observeField("programDetails", "onProgramDetailsLoaded")

    m.scheduleGrid.setFocus(true)
    m.top.signalBeacon("EPGLaunchComplete") ' Required Roku Performance monitoring
    m.LoadChannelsTask.channels = []
end sub

' When LoadScheduleTask completes (initial or more data) and we have a schedule to display
sub onScheduleLoaded()

    for each item in m.LoadScheduleTask.schedule

        channel = m.scheduleGrid.content.GetChild(m.channelIndex[item.ChannelId])

        if channel.PosterUrl <> ""
            item.channelLogoUri = channel.PosterUrl
        end if
        if channel.Title <> ""
            item.channelName = channel.Title
        end if

        channel.appendChild(item)
    end for

    m.scheduleGrid.showLoadingDataFeedback = false
    m.scheduleGrid.setFocus(true)
    m.LoadScheduleTask.schedule = []
end sub

sub onProgramFocused()

    m.top.watchChannel = invalid
    channel = m.scheduleGrid.content.GetChild(m.scheduleGrid.programFocusedDetails.focusChannelIndex)
    m.detailsPane.channel = channel

    ' Exit if Channels not yet loaded
    if channel.getChildCount() = 0
        m.detailsPane.programDetails = invalid
        return
    end if

    prog = channel.GetChild(m.scheduleGrid.programFocusedDetails.focusIndex)

    if prog <> invalid and prog.fullyLoaded = false
        m.LoadProgramDetailsTask.programId = prog.Id
        m.LoadProgramDetailsTask.channelIndex = m.scheduleGrid.programFocusedDetails.focusChannelIndex
        m.LoadProgramDetailsTask.programIndex = m.scheduleGrid.programFocusedDetails.focusIndex
        m.LoadProgramDetailsTask.control = "RUN"
    end if

    m.detailsPane.programDetails = prog
end sub

' Update the Program Details with full information
sub onProgramDetailsLoaded()
    if m.LoadProgramDetailsTask.programDetails = invalid then return
    channel = m.scheduleGrid.content.GetChild(m.LoadProgramDetailsTask.programDetails.channelIndex)

    ' If TV Show does not have its own image, use the channel logo
    if m.LoadProgramDetailsTask.programDetails.PosterUrl = invalid or m.LoadProgramDetailsTask.programDetails.PosterUrl = ""
        m.LoadProgramDetailsTask.programDetails.PosterUrl = channel.PosterUrl
    end if

    channel.ReplaceChild(m.LoadProgramDetailsTask.programDetails, m.LoadProgramDetailsTask.programDetails.programIndex)
    m.LoadProgramDetailsTask.programDetails = invalid
end sub


sub onProgramSelected()
    ' If there is no program data - view the channel
    if m.detailsPane.programDetails = invalid
        m.top.watchChannel = m.scheduleGrid.content.GetChild(m.scheduleGrid.programFocusedDetails.focusChannelIndex)
        return
    end if

    ' Move Grid Down
    focusProgramDetails(true)
end sub

' Move the TV Guide Grid down or up depending whether details are selected
sub focusProgramDetails(setFocused)

    h = m.detailsPane.height
    if h < 400 then h = 400
    h = h + 160 + 80

    if setFocused = true
        m.gridMoveAnimationPosition.keyValue = [[0, 600], [0, h]]
        m.detailsPane.setFocus(true)
        m.detailsPane.hasFocus = true
        m.top.lastFocus = m.detailsPane
    else
        m.detailsPane.hasFocus = false
        m.gridMoveAnimationPosition.keyValue = [[0, h], [0, 600]]
        m.scheduleGrid.setFocus(true)
        m.top.lastFocus = m.scheduleGrid
    end if

    m.gridMoveAnimation.control = "start"
end sub

' Handle user selecting "Watch Channel" from Program Details
sub onWatchChannelSelected()

    if m.detailsPane.watchSelectedChannel = false then return

    ' Set focus back to grid before showing channel, to ensure grid has focus when we return
    focusProgramDetails(false)

    m.top.watchChannel = m.detailsPane.channel
end sub

' As user scrolls grid, check if more data requries to be loaded
sub onGridScrolled()

    ' If we're within 12 hours of end of grid, load next 24hrs of data
    if m.scheduleGrid.leftEdgeTargetTime + (12 * 60 * 60) > m.gridEndDate.AsSeconds()

        ' Ensure the task is not already (still) running,
        if m.LoadScheduleTask.state <> "run"
            m.LoadScheduleTask.startTime = m.gridEndDate.ToISOString()
            m.gridEndDate.FromSeconds(m.gridEndDate.AsSeconds() + (24 * 60 * 60))
            m.LoadScheduleTask.endTime = m.gridEndDate.ToISOString()
            m.LoadScheduleTask.control = "RUN"
        end if
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "back" and m.detailsPane.isInFocusChain()
        focusProgramDetails(false)
        return true
    end if

    return false
end function
