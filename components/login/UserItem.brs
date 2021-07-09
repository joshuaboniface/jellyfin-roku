sub init()
end sub

sub itemContentChanged()
    itemData = m.top.itemContent
    if itemData = invalid then return

    profileImage = m.top.findNode("profileImage")
    profileName = m.top.findNode("profileName")

    if itemData.imageURL = ""
        profileImage.uri = "pkg://images/baseline_person_white_48dp.png"
    else
        profileImage.uri = itemData.imageURL
    end if
    profileName.text = itemData.name
end sub
