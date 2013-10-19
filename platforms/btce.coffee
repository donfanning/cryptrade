_ = require 'underscore'
BTCE = require 'btc-e'
attempt = require 'attempt'

class Platform
  init: (@config,@pair,@account)->
    unless @account.key and @account.secret
      throw new Error 'Btc-e: key and secret must be provided'
    @client = new BTCE @account.key,@account.secret

  trade: (order, cb)->
    orderCb = (err,result)->
      if err?
        cb err
      else
        console.log result
        cb null, result.order_id
    if order.maxAmount * order.price < parseFloat(@config.min_order)
      cb "#{order.type.toUpperCase()} order wasn't created because the amount is less than minimum order amount #{@config.min_order} USD"
      return
    amount = order.amount or order.maxAmount
    amount = Math.floor(amount * 100000000) / 100000000
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.trade @pair, order.type, order.price, amount, @
      ,orderCb
      

  isOrderActive: (orderId, cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.makeRequest 'activeOrders', {}, @
      ,(err,result)->
        if err?
          cb "isOrderActive: reached max retries #{err}"
        else
          order = _.find result, (order)->
            order.id == orderId
          cb null, order?
        
    
  cancelOrder: (orderId, cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.cancelOrder orderId, @
      ,(err,result)->
        if err?
          cb "cancelOrder: reached max retries #{err}"
        if cb?
          cb null

  getPositions: (positions,cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.getInfo @
      ,(err,result)->
        if err?
          cb "getPositions: reached max retries #{err}"
        else
          positions = {}
          for asset,amount of result.funds
            positions[asset] = amount
          cb null, positions

  getTicker: (cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.ticker self.pair,@
      ,(err,result)->
        if err?
          cb "getTicker: reached max retries #{err}"
        else
          cb null,
            buy: result.data.buy
            sell: result.data.sell



module.exports = Platform

