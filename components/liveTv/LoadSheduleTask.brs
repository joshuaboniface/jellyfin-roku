sub init()
    m.top.functionName = "loadSchedule"
end sub

sub loadSchedule()

    results = []

    params = {
        UserId: get_setting("active_user"),
        SortBy: "startDate",
        EnableImages: false
        EnableTotalRecordCount: false,
        EnableUserData: false
        channelIds: m.top.channelIds
        MaxStartDate: m.top.endTime,
        MinEndDate: m.top.startTime
    }

    url = "LiveTv/Programs"

    resp = APIRequest(url)
    data = postJson(resp, FormatJson(params))

    if data = invalid
        m.top.schedule = results
        return
    end if

    results = []

    for each item in data.Items
        program = createObject("roSGNode", "ScheduleProgramData")
        program.json = item
        results.push(program)
    end for


    m.top.schedule = results

end sub