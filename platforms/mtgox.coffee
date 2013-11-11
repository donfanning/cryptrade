_ = require 'underscore'
MtGoxClient = require 'mtgox-apiv2'
Platform = require '../platform'
attempt = require 'attempt'

class MtGoxPlatform extends Platform
  init: (@config,@pair,@account)->
    pair = @pair.replace('_','').toUpperCase()
    unless @account.key and @account.secret
      throw new Error 'MtgoxPlatform: key and secret must be provided'
    @client = new MtGoxClient @account.key,@account.secret,pair

  getPositions: (positions,cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.info @
      ,(err,response)->
        if err?
          cb "getPositions: reached max retries #{err}"
        else
          result = {}
          for curr, wallet of response.data.Wallets
            curr = curr.toLowerCase()
            if curr in positions
              result[curr] = parseFloat(wallet.Balance.value)
          cb(err,result)
    
  trade: (order, cb)->
    if order.maxAmount >= parseFloat(@config.min_order[order.asset])
      amount = order.amount or 10000
      switch order.type
        when 'buy'
          @createOrder 'bid',amount,cb
          break
        when 'sell'
          @createOrder 'ask',amount,cb
          break
    else
      cb "#{order.type.toUpperCase()} order wasn't created because the amount is less than minimum order amount"

  createOrder: (type, amount, cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.add type, amount, null, @
      ,(err,result)->
        if err?
          cb "createOrder: reachange max retries #{err}"
        else
          cb null,result.data
  isOrderActive: (orderId, cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.orders @
      ,(err,result)->
        if err?
          cb 'isOrderActive: reached max retries'
        else
          order = _.find result.data, (order)->
            order.oid == orderId
          cb null,order?

  getOrders: (cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.orders @
      ,(err,result)->
        if err?
          cb 'getOrders: reached max retries'
        else
          orders = []
          _.each result.data, (order)->
            orders.push order.oid
          cb(orders)
            
  cancelOrder: (orderId,cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.cancel orderId, @
      ,(err,result)->
        if err?
          cb "cancelOrder: reached max retries #{err}"
        else
          if cb?
            cb null
        
    
  getTicker: (cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.tickerFast @
      ,(err,result)->
        if err?
          cb "getTicker: reached max retries #{err}"
        else
          cb null,
            buy: parseFloat(result.data.buy.value)
            sell: parseFloat(result.data.sell.value)
    


module.exports = MtGoxPlatform
