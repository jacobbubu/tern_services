ContentTypes = 
  'image/png'       : 'png' 
  'image/jpeg'      : 'jpg'
  'image/gif'       : 'gif'
  'audio/mpeg'      : 'mp3' 
  'video/h264'      : 'mp4'
  'video/mp4'       : 'mp4'
  'video/quicktime' : 'mov'
  'video/x-m4v'     : 'm4v'

SupportedContentType = Object.keys(ContentTypes)

module.exports.isSupported = (contentType) ->
  return contentType in SupportedContentType

module.exports.all = SupportedContentType