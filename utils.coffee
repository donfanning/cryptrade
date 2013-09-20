https = require 'https'
inspect = require('util').inspect

module.exports =
  inspect: (obj)->
    result = inspect obj,
      colors:true
    result.replace '\n',' '
  downloadURL: (url,cb)->
    req = https.request url, (res)->
      res.on 'data', (data) ->
        cb(null,data)
    req.end()
    req.on 'error', (e)->
      cb(e)

