sub init()
  m.top.itemComponentName = "HomeItem"
  ' how many rows are visible on the screen
  m.top.numRows = 2

  m.top.rowFocusAnimationStyle = "fixedFocusWrap"
  m.top.vertFocusAnimationStyle = "fixedFocus"

  m.top.showRowLabel = [true]
  m.top.rowLabelOffset = [0, 20]
  m.top.showRowCounter = [true]

  updateSize()

  m.top.setfocus(true)

  m.top.observeField("rowItemSelected", "itemSelected")

  ' Load the Libraries from API via task
  m.LoadLibrariesTask = createObject("roSGNode", "LoadItemsTask")
  m.LoadLibrariesTask.observeField("content", "onLibrariesLoaded")
  ' set up tesk nodes for other rows
  m.LoadContinueTask = createObject("roSGNode", "LoadItemsTask")
  m.LoadContinueTask.itemsToLoad = "continue"
  m.LoadNextUpTask = createObject("roSGNode", "LoadItemsTask")
  m.LoadNextUpTask.itemsToLoad = "nextUp"
  m.LoadFavTask = createObject("roSGNode", "LoadItemsTask")
  m.LoadFavTask.itemsToLoad = "Favorites"
end sub

function loadLibraries()
  m.LoadLibrariesTask.control = "RUN"
end function

sub updateSize()
  sideborder = 100
  m.top.translation = [111, 180]

  itemWidth = 480
  itemHeight = 330

  'Set width of Rows to cut off at edge of Safe Zone
  m.top.itemSize = [1703, itemHeight]

  ' spacing between rows
  m.top.itemSpacing = [0, 105]

  ' spacing between items in a row
  m.top.rowItemSpacing = [20, 0]

  m.top.visible = true
end sub

sub onLibrariesLoaded()
  ' save data for other functions
  m.libraryData = m.LoadLibrariesTask.content
  m.LoadLibrariesTask.unobserveField("content")
  m.LoadLibrariesTask.content = []
  ' create My Media, Continue Watching, and Next Up rows
  content = CreateObject("roSGNode", "ContentNode")
  mediaRow = content.CreateChild("HomeRow")
  mediaRow.title = tr("My Media")
  favRow = content.CreateChild("HomeRow")
  favRow.title = tr("My Favorites")
  continueRow = content.CreateChild("HomeRow")
  continueRow.title = tr("Continue Watching")
  nextUpRow = content.CreateChild("HomeRow")
  nextUpRow.title = tr("Next Up >")
  sizeArray = [
    [464, 311], ' My Media
    [464, 311], ' My Favorites
    [464, 331], ' Continue Watching
    [464, 331]  ' Next Up
  ]
  ' validate library data
  if (m.libraryData <> invalid and m.libraryData.count() > 0) then
    userConfig = m.top.userConfig
    ' populate My Media row
    filteredMedia = filterNodeArray(m.libraryData, "id", userConfig.MyMediaExcludes)
    for each item in filteredMedia
      mediaRow.appendChild(item)
    end for
    ' create a "Latest In" row for each library
    filteredLatest = filterNodeArray(m.libraryData, "id", userConfig.LatestItemsExcludes)
    for each lib in filteredLatest
      if lib.collectionType <> "boxsets" and lib.collectionType <> "livetv" then
        latestInRow = content.CreateChild("HomeRow")
        latestInRow.title = tr("Latest in") + " " + lib.name + " >"
        sizeArray.Push([464, 331])
      end if
    end for
  end if

  m.top.rowItemSize = sizeArray
  m.top.content = content
  
  ' Load the Continue Watching Data
  m.LoadContinueTask.observeField("content", "updateContinueItems")
  m.LoadContinueTask.control = "RUN"
end sub

function updateHomeRows()
  m.LoadContinueTask.observeField("content", "updateContinueItems")
  m.LoadContinueTask.control = "RUN"
end function

function updateContinueItems()
  itemData = m.LoadContinueTask.content
  m.LoadContinueTask.unobserveField("content")
  m.LoadContinueTask.content = []

  if itemData = invalid then return false

  homeRows = m.top.content
  continueRowIndex = getRowIndex("Continue Watching")

  if itemData.count() < 1 then
    if continueRowIndex <> invalid then
      ' remove the row
      deleteFromSizeArray(continueRowIndex)
      homeRows.removeChildIndex(continueRowIndex)
    end if
  else
    ' remake row using the new data
    row = CreateObject("roSGNode", "HomeRow")
    row.title = tr("Continue Watching")
    itemSize = [464, 331]
    for each item in itemData
      item.usePoster = row.usePoster
      item.imageWidth = row.imageWidth
      row.appendChild(item)
    end for

    if continueRowIndex = invalid then
      ' insert new row under "My Media"
      updateSizeArray(itemSize, 1)
      homeRows.insertChild(row, 1)
    else
      ' replace the old row
      homeRows.replaceChild(row, continueRowIndex)
    end if
  end if

  
   ' Load the Favorites Data
   m.LoadFavTask.observeField("content", "updateFavItems")
   m.LoadFavTask.control = "RUN"
end function

' get Favorites
function updateFavRows()
  m.LoadFavTask.observeField("content", "updateFavItems")
  m.LoadFavTask.control = "RUN"
end function

function updateFavItems()
  itemData = m.LoadFavTask.content
  m.LoadFavTask.unobserveField("content")
  m.LoadFavTask.content = []

  if itemData = invalid then return false

  homeRows = m.top.content
  favRowIndex = getRowIndex("My Favorites")

  if itemData.count() < 1 then
    if favRowIndex <> invalid then
      ' remove the row
      deleteFromSizeArray(favRowIndex)
      homeRows.removeChildIndex(favRowIndex)
    end if
  else
    ' remake row using the new data
    row = CreateObject("roSGNode", "HomeRow")
    row.title = tr("My Favorites")
    itemSize = [464, 331]
    for each item in itemData
      item.usePoster = row.usePoster
      item.imageWidth = row.imageWidth
      row.appendChild(item)
    end for

    if favRowIndex = invalid then
      ' insert new row under "Continue Watching"
      updateSizeArray(itemSize, 1)
      homeRows.insertChild(row, 1)
    else
      ' replace the old row
      homeRows.replaceChild(row, favRowIndex)
    end if
  end if

  m.LoadNextUpTask.observeField("content", "updateNextUpItems")
  m.LoadNextUpTask.control = "RUN"
end function

function updateNextUpItems()
  itemData = m.LoadNextUpTask.content
  m.LoadNextUpTask.unobserveField("content")
  m.LoadNextUpTask.content = []

  if itemData = invalid then return false

  homeRows = m.top.content
  nextUpRowIndex = getRowIndex("Next Up >")

  if itemData.count() < 1 then
    if nextUpRowIndex <> invalid then
      ' remove the row
      deleteFromSizeArray(nextUpRowIndex)
      homeRows.removeChildIndex(nextUpRowIndex)
    end if
  else
    ' remake row using the new data
    row = CreateObject("roSGNode", "HomeRow")
    row.title = tr("Next Up") + " >"
    itemSize = [464, 331]
    for each item in itemData
      item.usePoster = row.usePoster
      item.imageWidth = row.imageWidth
      row.appendChild(item)
    end for

    if nextUpRowIndex = invalid then
      ' insert new row under "Continue Watching"
      continueRowIndex = getRowIndex("Continue Watching")
      if continueRowIndex <> invalid then
        updateSizeArray(itemSize, continueRowIndex + 2)
        homeRows.insertChild(row, continueRowIndex + 2)
      else
        ' insert it under My Favorites
        updateSizeArray(itemSize, 2)
        homeRows.insertChild(row, 2)
      end if
    else
      ' replace the old row
      homeRows.replaceChild(row, nextUpRowIndex)
    end if
  end if

  ' consider home screen loaded when above rows are loaded
  if m.global.app_loaded = false then
    m.top.signalBeacon("AppLaunchComplete") ' Roku Performance monitoring
    m.global.app_loaded = true
  end if


  ' create task nodes for "Latest In" rows
  userConfig = m.top.userConfig
  filteredLatest = filterNodeArray(m.libraryData, "id", userConfig.LatestItemsExcludes)
  for each lib in filteredLatest
    if lib.collectionType <> "livetv" and lib.collectionType <> "boxsets" then
      loadLatest = createObject("roSGNode", "LoadItemsTask")
      loadLatest.itemsToLoad = "latest"
      loadLatest.itemId = lib.id

      metadata = { "title" : lib.name }
      metadata.Append({ "contentType" : lib.json.CollectionType })
      loadLatest.metadata = metadata

      loadLatest.observeField("content", "updateLatestItems")
      loadLatest.control = "RUN"
    end if
  end for
end function

function updateLatestItems(msg)
  itemData = msg.GetData()

  data = msg.getField()
  node = msg.getRoSGNode()
  node.unobserveField("content")
  node.content = []

  if itemData = invalid then return false

  homeRows = m.top.content
  rowIndex = getRowIndex(tr("Latest in") + " " + node.metadata.title + " >")

  if itemData.count() < 1 then
    ' remove row
    if rowIndex <> invalid then
      deleteFromSizeArray(rowIndex)
      homeRows.removeChildIndex(rowIndex)
    end if
  else
    ' remake row using new data
    row = CreateObject("roSGNode", "HomeRow")
    row.title = tr("Latest in") + " " + node.metadata.title + " >"
    row.usePoster = true
    ' Handle specific types with different item widths
    if node.metadata.contentType = "movies" then
      row.imageWidth = 180
      itemSize = [188, 331]
    else if node.metadata.contentType = "music" then
      row.imageWidth = 261
      itemSize = [261, 331]
    else
      row.imageWidth = 464
      itemSize = [464, 331]
    end if

    for each item in itemData
      item.usePoster = row.usePoster
      item.imageWidth = row.imageWidth
      row.appendChild(item)
    end for

    if rowIndex = invalid then
      ' append new row
      updateSizeArray(itemSize)
      homeRows.appendChild(row)
    else
      ' replace the old row
      updateSizeArray(itemSize, rowIndex, "replace")
      homeRows.replaceChild(row, rowIndex)
    end if
  end if
end function

function getRowIndex(rowTitle as string)
  rowIndex = invalid
  for i = 1 to m.top.content.getChildCount() - 1
    ' skip row 0 since it's always "My Media"
    tmpRow = m.top.content.getChild(i)
    if tmpRow.title = rowTitle then
      rowIndex = i
      exit for
    end if
  end for
  return rowIndex
end function

sub updateSizeArray(rowItemSize, rowIndex = invalid, action = "insert")
  sizeArray = m.top.rowItemSize
  ' append by default
  if rowIndex = invalid then
    rowIndex = sizeArray.count()
  end if

  newSizeArray = []
  for i = 0 to sizeArray.count()
    if rowIndex = i then
      if action = "replace" then
        newSizeArray.Push(rowItemSize)
      else if action = "insert" then
        newSizeArray.Push(rowItemSize)
        if sizeArray[i] <> invalid then
          newSizeArray.Push(sizeArray[i])
        end if
      end if
    else if sizeArray[i] <> invalid then
      newSizeArray.Push(sizeArray[i])
    end if
  end for
  m.top.rowItemSize = newSizeArray
end sub

sub deleteFromSizeArray(rowIndex)
  updateSizeArray([0, 0], rowIndex, "delete")
end sub

function itemSelected()
  m.top.selectedItem = m.top.content.getChild(m.top.rowItemSelected[0]).getChild(m.top.rowItemSelected[1])
end function

function onKeyEvent(key as string, press as boolean) as boolean
  handled = false
  if press then
    if key = "play" then
      itemToPlay = m.top.content.getChild(m.top.rowItemFocused[0]).getChild(m.top.rowItemFocused[1])
      if itemToPlay <> invalid and (itemToPlay.type = "Movie" or itemToPlay.type = "Episode") then
        m.top.quickPlayNode = itemToPlay
      end if
      handled = true
    end if
  end if
  return handled
end function

function filterNodeArray(nodeArray as object, nodeKey as string, excludeArray as object) as object
  if excludeArray.IsEmpty() then return nodeArray

  newNodeArray = []
  for each node in nodeArray
    excludeThisNode = false
    for each exclude in excludeArray
      if node[nodeKey] = exclude then
        excludeThisNode = true
      end if
    end for
    if excludeThisNode = false then
      newNodeArray.Push(node)
    end if
  end for
  return newNodeArray
end function
