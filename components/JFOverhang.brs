sub init()
    m.top.id = "overhang"
    ' hide seperators till they're needed
    leftSeperator = m.top.findNode("overlayLeftSeperator")
    leftSeperator.visible = "false"
    rightSeperator = m.top.findNode("overlayRightSeperator")
    rightSeperator.visible = "false"
    ' set font sizes
    optionText = m.top.findNode("overlayOptionsText")
    optionText.font.size = 20
    optionStar = m.top.findNode("overlayOptionsStar")
    optionStar.font.size = 58
    overlayMeridian = m.top.findNode("overlayMeridian")
    overlayMeridian.font.size = 20
    ' get system preference clock format (12/24hr)
    di = CreateObject("roDeviceInfo")
    m.clockFormat = di.GetClockFormat()
    ' grab current time
    currentTime = CreateObject("roDateTime")
    currentTime.ToLocalTime()
    m.currentHours = currentTime.GetHours()
    m.currentMinutes = currentTime.GetMinutes()
    ' start timer
    m.currentTimeTimer = m.top.findNode("currentTimeTimer")
    m.currentTimeTimer.control = "start"
    m.currentTimeTimer.ObserveField("fire", "updateTime")

    updateTimeDisplay()
end sub


sub updateTitle()
    leftSeperator = m.top.findNode("overlayLeftSeperator")
    if m.top.title <> ""
        leftSeperator.visible = "true"
    else
        leftSeperator.visible = "false"
    end if
    title = m.top.findNode("overlayTitle")
    title.text = m.top.title
    resetTime()
end sub

sub updateUser()
    rightSeperator = m.top.findNode("overlayRightSeperator")
    if m.top.currentUser <> ""
        rightSeperator.visible = "true"
    else
        rightSeperator.visible = "false"
    end if
    user = m.top.findNode("overlayCurrentUser")
    user.text = m.top.currentUser
end sub

sub updateTime()
    if (m.currentMinutes + 1) > 59
        m.currentHours = m.currentHours + 1
        m.currentMinutes = 0
    else
        m.currentMinutes = m.currentMinutes + 1
    end if

    updateTimeDisplay()
end sub

sub resetTime()
    m.currentTimeTimer.control = "stop"

    currentTime = CreateObject("roDateTime")
    m.currentTimeTimer.control = "start"

    currentTime.ToLocalTime()

    m.currentHours = currentTime.GetHours()
    m.currentMinutes = currentTime.GetMinutes()

    updateTimeDisplay()
end sub

sub updateTimeDisplay()
    overlayHours = m.top.findNode("overlayHours")
    overlayMinutes = m.top.findNode("overlayMinutes")
    overlayMeridian = m.top.findNode("overlayMeridian")

    if m.clockFormat = "24h"
        overlayMeridian.text = ""
        if m.currentHours < 10
            overlayHours.text = "0" + StrI(m.currentHours).trim()
        else
            overlayHours.text = m.currentHours
        end if
    else
        if m.currentHours < 12
            overlayMeridian.text = "AM"
            if m.currentHours = 0
                overlayHours.text = "12"
            else
                overlayHours.text = m.currentHours
            end if
        else
            overlayMeridian.text = "PM"
            if m.currentHours = 12
                overlayHours.text = "12"
            else
                overlayHours.text = m.currentHours - 12
            end if
        end if
    end if

    if m.currentMinutes < 10
        overlayMinutes.text = "0" + StrI(m.currentMinutes).trim()
    else
        overlayMinutes.text = m.currentMinutes
    end if
end sub

sub updateOptions()
    optionText = m.top.findNode("overlayOptionsText")
    optionStar = m.top.findNode("overlayOptionsStar")
    if m.top.showOptions = true
        optionText.visible = true
        optionStar.visible = true
    else
        optionText.visible = false
        optionStar.visible = false
    end if
end sub