_ = require 'underscore'
talib = require 'talib'
Future = require 'fibers/future'

talibWrapper = (func)-> 
  (params)->
    output = null
    future = new Future()
    caller = (params)->
      params = _.extend params,
        name: func.name
      talib.execute params, (data)->
        if data.error
          console.log data.error
          throw new Error(data.error)
        else
          outputs = _.keys(data.result)
          results = {}
          for output in outputs
            results[output] = data.result[output]
          if outputs.length == 1
            output = results[outputs[0]]
          else
            output = results
          future.return()
    caller(params)
    future.wait()
    output
    
exports = {}
for f in talib.functions
  exports[f.name] = talibWrapper(f)
   
module.exports = exports
