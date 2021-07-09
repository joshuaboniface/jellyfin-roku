sub init()
    m.top.observeField("state", "onState")
    m.bufferPercentage = 0 ' Track whether content is being loaded
    m.top.transcodeReasons = []

end sub


'
' When Video Player state changes
sub onState(msg)

    ' When buffering, start timer to monitor buffering process
    if m.top.state = "buffering" and m.bufferCheckTimer <> invalid

        ' start timer
        m.bufferCheckTimer = m.top.findNode("bufferCheckTimer")
        m.bufferCheckTimer.control = "start"
        m.bufferCheckTimer.ObserveField("fire", "bufferCheck")
    else if m.top.state = "error"

        ' If an error was encountered, Display dialog
        dialog = createObject("roSGNode", "Dialog")
        dialog.title = tr("Error During Playback")
        dialog.buttons = [tr("OK")]
        dialog.message = tr("An error was encountered while playing this item.")
        dialog.observeField("buttonSelected", "dialogClosed")
        m.top.getScene().dialog = dialog

        ' Stop playback and exit player
        m.top.control = "stop"
        m.top.backPressed = true
    end if

end sub

'
' Check the the buffering has not hung
sub bufferCheck(msg)

    if m.top.state <> "buffering"
        ' If video is not buffering, stop timer
        m.bufferCheckTimer.control = "stop"
        m.bufferCheckTimer.unobserveField("fire")
        return
    end if

    if m.top.bufferingStatus <> invalid

        ' Check that the buffering percentage is increasing
        if m.top.bufferingStatus["percentage"] > m.bufferPercentage
            m.bufferPercentage = m.top.bufferingStatus["percentage"]
        else
            ' If buffering has stopped Display dialog
            dialog = createObject("roSGNode", "Dialog")
            dialog.title = tr("Error Retrieving Content")
            dialog.buttons = [tr("OK")]
            dialog.message = tr("There was an error retrieving the data for this item from the server.")
            dialog.observeField("buttonSelected", "dialogClosed")
            m.top.getScene().dialog = dialog

            ' Stop playback and exit player
            m.top.control = "stop"
            m.top.backPressed = true
        end if
    end if

end sub

'
' Clean up on Dialog Closed
sub dialogClosed(msg)
    sourceNode = msg.getRoSGNode()
    sourceNode.unobserveField("buttonSelected")
    sourceNode.close = true
end sub



function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if m.top.Subtitles.count() and key = "down"
        m.top.selectSubtitlePressed = true
        return true
    end if

    return false
end function
