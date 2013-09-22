_ = require 'underscore'
MtGoxClient = require 'mtgox-apiv2'
Platform = require '../platform'
attempt = require 'attempt'
logger = require 'winston'

class MtGoxPlatform extends Platform
  init: (@config)->
    pair = @config.instrument.replace('_','').toUpperCase()
    unless @config.mtgox.key or @config.mtgox.secret
      throw new Error 'MtgoxPlatform: key and secret must be provided'
    @client = new MtGoxClient @config.mtgox.key,@config.mtgox.secret,pair

  getPositions: (positions,cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.info @
      ,(err,response)->
        if err?
          logger.error "getPositions: reached max retries #{err}"
        else
          result = {}
          for curr, wallet of response.data.Wallets
            curr = curr.toLowerCase()
            if curr in positions
              result[curr] = parseFloat(wallet.Balance.value)
          cb(result)
    
  trade: (order, cb)->
    if order.maxAmount >= @config.min_order
      amount = order.amount or 10000
      switch order.type
        when 'buy'
          @createOrder 'bid',amount,cb
          break
        when 'sell'
          @createOrder 'ask',amount,cb
          break
    else
      logger.verbose "#{order.type.toUpperCase()} order wasn't created because the amount is less than minimum order amount #{@config.min_order} BTC"

  createOrder: (type, amount, cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.add type, amount, null, @
      ,(err,result)->
        if err?
          logger.error 'createOrder: reached max retries'
          cb err,null
        else
          cb null,result.data
  isOrderActive: (orderId, cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.orders @
      ,(err,result)->
        if err?
          logger.error 'isOrderActive: reached max retries'
        else
          order = _.find result.data, (order)->
            order.oid == orderId
          cb order?

  cancelOrder: (orderId,cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.cancel orderId, @
      ,(err,result)->
        if err?
          logger.error "cancelOrder: reached max retries #{err}"
        else
          if cb?
            cb()
        
    
  getTicker: (cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.tickerFast @
      ,(err,result)->
        if err?
          logger.error "getTicker: reached max retries #{err}"
        else
          cb
            buy: parseFloat(result.data.buy.value)
            sell: parseFloat(result.data.sell.value)
    


module.exports = MtGoxPlatform
