class Platform
  init: (config)->
    throw new Error 'Not implemented' 
  trade: (order, cb)->
    throw new Error 'Not implemented' 
  isOrderActive: (orderId, cb)->
    throw new Error 'Not implemented' 
  cancelOrder: (orderId, cb)->
    throw new Error 'Not implemented' 
  getPositions: (positions,cb)->
    throw new Error 'Not implemented' 
  getTicker: (cb)->
    throw new Error 'Not implemented' 


module.exports = Platform
        
