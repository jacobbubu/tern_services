getPattern = ->
  octet = '(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])'
  ip    = '(?:' + octet + '\\.){3}' + octet
  quad  = '(?:\\[' + ip + '\\])|(?:' + ip + ')' 
  new RegExp( '(' + quad + ')' )

ipPattern = getPattern()
module.exports.verify =  (ipAddress) -> ipPattern.test ipAddress