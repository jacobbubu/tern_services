crypto = require('crypto')
zlib = require('zlib')

key = "8eb5575e94"
#iv = "1f07c9e9866d53cf5f1005464fc8f474"
iv = "1f07c9"

#cipher = crypto.createCipheriv("aes-128-cbc", new Buffer(key, "hex").toString("binary"), new Buffer(iv, "hex").toString("binary"))
#decipher = crypto.createDecipheriv("aes-128-cbc", new Buffer(key, "hex").toString("binary"), new Buffer(iv, "hex").toString("binary"))

cipher = crypto.createCipher("rc4-40", new Buffer(key, "hex").toString("binary"))
decipher = crypto.createDecipher("rc4-40", new Buffer(key, "hex").toString("binary"))

text = """
  {
    request: {
      'method': 'auth.signup',
      'req_ts': '1337687706833',
      'data':
      { 
          'user_id'     : 'flyingtern',
          'password'    : '1BigPassword',
        'locale'    : 'zh_Hans',
          'data_zone'   : 'beijing',
        }
      }
     }
"""
###
text = """
  {
    'req_ts': '1337687706833'
    'method': 'auth.signup',
    'status' :  -1,
    'error': {
      'user_id': [
        "REQUIRED",
        "LENGTH",
        "PATTERN"
      ],
      "password": [
        "REQUIRED",
        "LENGTH",  
        "DIGIT",   
        "CAPITAL", 
        "LOWERCASE",
        "SAME_AS_USER_ID"
      ],
      "locale": [
        "REQUIRED",
        "LANG",     
        "SCRIPT",
        "REGION"
      ],
      "data_zone": [
        "REQUIRED",
        "LENGTH",
        "UNSUPPORTED"
      ]
    }       
  }
"""
###

#deflate = zlib.createDeflate({})
zlib.deflate text, (err, buffer) ->
  if !err
    console.log 'deflate:' + buffer.length
    crypted = cipher.update(buffer, 'binary', 'binary')
    crypted += cipher.final('binary')

    console.log()
    console.log "Text: #{text.length}, Deflated: #{buffer.length} Crypted: #{crypted.length}"

    console.log "typeof crypted " + typeof crypted, Buffer.isBuffer crypted

    uncryptedBuf = decipher.update(crypted, 'binary', 'binary')
    uncryptedBuf += decipher.final('binary')

    console.log "typeof uncryptedBuf " + typeof uncryptedBuf

    zlib.unzip new Buffer(uncryptedBuf, 'binary'), (err, buffer) ->
      if !err
        uncrypted = buffer.toString()
        console.log "Length #{uncrypted.length}: " + uncrypted.slice(1, 20) + "..." + uncrypted.slice(-15)
      else
        console.log err

###
crypted = cipher.update(text,'utf8', 'binary')
crypted += cipher.final('binary')

console.log()
console.log "Text Length: #{text.length}, Crypted Length: #{crypted.length}"

decipher = crypto.createDecipheriv("aes-128-cbc", new Buffer(key, "hex").toString("binary"), new Buffer(iv, "hex").toString("binary"))
uncrypted = decipher.update(crypted, 'binary', 'utf8')
uncrypted += decipher.final('utf8')
console.log "Length #{uncrypted.length}: " + uncrypted.slice(1, 20) + "..." + uncrypted.slice(-15)
#console.log uncrypted.slice(-10, -1)
###