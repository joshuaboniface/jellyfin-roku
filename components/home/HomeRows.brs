sub init()
  m.top.itemComponentName = "HomeItem"
  ' how many rows are visible on the screen
  m.top.numRows = 2

  m.top.rowFocusAnimationStyle = "fixedFocusWrap"
  m.top.vertFocusAnimationStyle = "fixedFocus"

  m.top.showRowLabel = [true]
  m.top.rowLabelOffset = [0, 20]
  m.top.showRowCounter = [true]

  m.libariesToLoad = 0

  updateSize()

  m.top.setfocus(true)

  m.top.observeField("rowItemSelected", "itemSelected")

  ' Load the Libraries from API via task
  m.LoadLibrariesTask = createObject("roSGNode", "LoadItemsTask")
  m.LoadLibrariesTask.observeField("content", "onLibrariesLoaded")
  m.LoadLibrariesTask.control = "RUN"
  ' set up tesk nodes for other rows
  m.LoadContinueTask = createObject("roSGNode", "LoadItemsTask")
  m.LoadContinueTask.itemsToLoad = "continue"
  m.LoadNextUpTask = createObject("roSGNode", "LoadItemsTask")
  m.LoadNextUpTask.itemsToLoad = "nextUp"
end sub

sub updateSize()
  sideborder = 100
  m.top.translation = [111, 180]

  itemWidth = 480
  itemHeight = 330

  m.top.rowCounterRightOffset = 80
  m.top.itemSize = [1920 - 111 - 27, itemHeight]
  ' spacing between rows
  m.top.itemSpacing = [0, 105]

  ' spacing between items in a row
  m.top.rowItemSpacing = [20, 0]

  m.top.visible = true
end sub

sub onLibrariesLoaded()
  m.libraryData = m.LoadLibrariesTask.content

  m.sizeArray = [[464, 311]]
  m.top.rowItemSize = m.sizeArray

  m.LoadLibrariesTask.unobserveField("content")

  if (m.libraryData <> invalid and m.libraryData.count() > 0) then

    'Add the Libraries Row
    m.data = CreateObject("roSGNode", "ContentNode")
    row = m.data.CreateChild("HomeRow")
    row.title = tr("My Media")

    for each item in m.libraryData
      row.appendChild(item)
    end for

  end if

  ' Load the Continue Watching Data
  m.top.content = m.data

  m.LoadContinueTask.observeField("content", "updateContinueItems")
  m.LoadContinueTask.control = "RUN"
end sub

function updateHomeRows()
  m.LoadContinueTask.observeField("content", "updateContinueItems")
  m.LoadContinueTask.control = "RUN"
end function

function updateContinueItems()
  m.LoadContinueTask.unobserveField("content")
  itemData = m.LoadContinueTask.content

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

  m.LoadNextUpTask.observeField("content", "updateNextUpItems")
  m.LoadNextUpTask.control = "RUN"
end function

function updateNextUpItems()
  m.LoadNextUpTask.unobserveField("content")
  itemData = m.LoadNextUpTask.content

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
      row.appendChild(item)
    end for

    if nextUpRowIndex = invalid then
      ' insert new row under "Continue Watching if it exists"
      tmpRow = homeRows.getChild(1)
      if tmpRow <> invalid and tmpRow.title = tr("Continue Watching") then
        updateSizeArray(itemSize, 2)
        homeRows.insertChild(row, 2)
      else
        updateSizeArray(itemSize, 1)
        homeRows.insertChild(row, 1)
      end if
    else
      ' replace the old row
      homeRows.replaceChild(row, nextUpRowIndex)
    end if
  end if

  ' Update "Latest in" for all libraries
  for each lib in m.libraryData
    if lib.collectionType <> "livetv" then
      loadLatest = createObject("roSGNode", "LoadItemsTask")
      loadLatest.itemsToLoad = "latest"
      loadLatest.itemId = lib.id

      metadata = { "title" : lib.name }
      metadata.Append({ "contentType" : lib.json.CollectionType })
      loadLatest.metadata = metadata

      loadLatest.observeField("content", "updateLatestItems")
      loadLatest.control = "RUN"
      m.libariesToLoad += 1
    end if
  end for
end function

function updateLatestItems(msg)
  itemData = msg.GetData()

  data = msg.getField()
  node = msg.getRoSGNode()
  node.unobserveField("content")

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
      row.appendChild(item)
    end for

    if rowIndex = invalid then
      ' append new row
      ' todo: insert row based on user settings
      updateSizeArray(itemSize)
      homeRows.appendChild(row)
    else
      ' replace the old row
      homeRows.replaceChild(row, rowIndex)
    end if
  end if

  m.libariesToLoad -= 1
  if m.libariesToLoad = 0 and m.global.app_loaded = false then
    m.top.signalBeacon("AppLaunchComplete") ' Roku Performance monitoring
    m.global.app_loaded = true
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

sub updateSizeArray(rowItemSize, rowIndex = invalid, action = "add")
  sizeArray = m.top.rowItemSize
  ' append by default
  if rowIndex = invalid then
    rowIndex = sizeArray.count()
  end if

  newSizeArray = []
  for i = 0 to sizeArray.count()
    if rowIndex = i then
      if action = "add" then
        ' insert new row size
        newSizeArray.Push(rowItemSize)
        if sizeArray[i] <> invalid then
          ' copy row size
          newSizeArray.Push(sizeArray[i])
        end if
      end if
    else if sizeArray[i] <> invalid then
      ' copy row size
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
  return false
end function
