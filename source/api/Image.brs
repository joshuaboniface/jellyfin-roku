function ItemImages(id = "" as string, params = {} as object)
  ' This seems to cause crazy core dumps
  ' if there is a conflict between on disk images, and library.db
  resp = APIRequest(Substitute("Items/{0}/Images", id))
  data = getJson(resp)
  if data = invalid then return invalid

  results = []
  for each item in data
    tmp = CreateObject("roSGNode", "ImageData")
    tmp.json = item
    tmp.url = ImageURL(id, tmp.imagetype, params)
    results.push(tmp)
  end for
  return results
end function


function PosterImage(id as string, params = {} as object, priority = ["Primary", "Logo", "Thumb"] )
  images = ItemImages(id, params)
  if images = invalid then return invalid
  primary_image = invalid

  for each image in images
    if image.imagetype = priority[0] then 
      primary_image = image
    else
      for i = 1 to priority.count() - 1
        if image.imagetype = priority[i] and primary_image = invalid
          primary_image = image
        end if
      end for
    end if
  end for

  return primary_image
end function

function ImageURL(id, version = "Primary", params = {})
  ' set defaults
  if params.maxHeight = invalid then
    param = { "maxHeight" : "384" }
    params.append(param)
  end if
  if params.maxWidth = invalid then
    param = { "maxWidth" : "196" }
    params.append(param)
  end if
  if params.quality = invalid then
    param = { "quality" : "90" }
    params.append(param)
  end if
  url = Substitute("Items/{0}/Images/{1}", id, version)
  ' ?maxHeight=384&maxWidth=256&tag=<tag>&quality=90"
  return buildURL(url, params)
end function
