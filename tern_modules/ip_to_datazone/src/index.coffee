DBClass   = require('node-iplookup').DB
Path      = require 'path'

geoDB = new DBClass(Path.resolve __dirname, '../IpToCountry.csv')

getPattern = ->
  octet = '(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])'
  ip    = '(?:' + octet + '\\.){3}' + octet
  quad  = '(?:\\[' + ip + '\\])|(?:' + ip + ')' 
  new RegExp( '(' + quad + ')' )

ipPattern = getPattern()

DEFAULT_DATA_ZONE = 'virginia'

CODE_TO_ZONE = 
  'BR': 'sao_paulo'
  'CN': 'beijing'
  'GB': 'ireland'
  'JP': 'tokyo'
  'SG': 'singapore'
  'US': 'virginia'

ipToDataZone = (ip, next) ->
  if ipPattern.test(ip) is false
    throw new Error("Bad ip format: #{ip}")

  geoDB.lookup ip, (err, result) ->
    console.log ip

    return next null, DEFAULT_DATA_ZONE if err?
    
    country_code = result.code
    data_zone = CODE_TO_ZONE[country_code]

    data_zone = DEFAULT_DATA_ZONE unless data_zone?

    return next null, data_zone

fourthOctets = 256 * 256 * 256
thirdOctets = 256 * 256
secondOctets =  256

InternalAClasses =
  min: 10 * fourthOctets + 0 * thirdOctets + 0 * secondOctets + 0
  max: 10 * fourthOctets + 255 * thirdOctets + 255 * secondOctets + 255

InternalBClasses =
  min: 172 * fourthOctets + 16 * thirdOctets + 0 * secondOctets + 0
  max: 172 * fourthOctets + 31 * thirdOctets + 255 * secondOctets + 255

InternalCClasses =
  min: 192 * fourthOctets + 168 * thirdOctets + 0 * secondOctets + 0
  max: 192 * fourthOctets + 168 * thirdOctets + 255 * secondOctets + 255

isInternalIP = (ip) ->
  if ipPattern.test(ip) is false
    throw new Error("Bad ip format: #{ip}")

  ipArray = ip.split '.'
  ipNumber = Number(ipArray[0]) * fourthOctets + Number(ipArray[1]) * thirdOctets + Number(ipArray[2]) * secondOctets + Number(ipArray[3])

  if (InternalAClasses.min <= ipNumber <= InternalAClasses.max) or (InternalBClasses.min <= ipNumber <= InternalBClasses.max) or (InternalCClasses.min <= ipNumber <= InternalCClasses.max)
    true
  else 
    false

LoopbackIP = 
  min: 127 * fourthOctets + 0 * thirdOctets + 0 * secondOctets + 1
  max: 127 * fourthOctets + 255 * thirdOctets + 255 * secondOctets + 254

isLoopbackIP = (ip) ->
  if ipPattern.test(ip) is false
    throw new Error("Bad ip format: #{ip}")

  ipArray = ip.split '.'
  ipNumber = Number(ipArray[0]) * fourthOctets + Number(ipArray[1]) * thirdOctets + Number(ipArray[2]) * secondOctets + Number(ipArray[3])

  if (LoopbackIP.min <= ipNumber <= LoopbackIP.max)
    true
  else
    false

module.exports.lookup = (ip, next) ->
  ipToDataZone ip, (err, data_zone) ->
    next err, data_zone if next?

module.exports.isInternalIP = isInternalIP
module.exports.isLoopbackIP = isLoopbackIP
