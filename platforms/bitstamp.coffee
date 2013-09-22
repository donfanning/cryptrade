_ = require 'underscore'
Bitstamp = require 'bitstamp'
Platform = require '../platform'
attempt = require 'attempt'
logger = require 'winston'

class BitstampPlatform extends Platform
  init: (@config)->
    unless @config.bitstamp.user or @config.bitstamp.password
      throw new Error 'BistampPlatform: user and password must be provided'
    @client = new Bitstamp @config.bitstamp.user,@config.bitstamp.password
  trade: (order, cb)->
    if order.maxAmount * order.price < @config.min_order
      logger.verbose "#{order.type.toUpperCase()} order wasn't created because the amount is less than minimum order amount #{@config.min_order} USD"
      return
    orderCb = (err,result)->
      if err?
        logger.error err
      else
        if result.error?
          logger.error result.error
        else
          cb null, result.id
    self = @
    amount = (order.amount or order.maxAmount) * 0.995
    amount = parseFloat amount.toFixed(8)
    switch order.type
      when 'buy'
        attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
          ->
            self.client.buy amount, order.price, @
          ,orderCb
        break
      when 'sell'
        attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
          ->
            self.client.sell amount, order.price, @
          ,orderCb
        break
  isOrderActive: (orderId, cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.open_orders @
      ,(err,result)->
        if err?
          logger.error "isOrderActive: reached max retries #{err}"
        else
          order = _.find result, (order)->
            order.id == orderId
          cb order?

  cancelOrder: (orderId, cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.cancel_order orderId, @
      ,(err,result)->
        if err?
          logger.error "cancelOrder: reached max retries #{err}"
        if cb?
          cb()

  getPositions: (positions,cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.balance @
      ,(err,data)->
        if err?
          logger.error "getPositions: reached max retries #{err}"
        else
          if data.error?
            logger.error "getPositions: #{result.error}"
          else
            result = {}
            for item, amount of data
              if item.indexOf 'available' != -1
                curr = item.substr(0, 3)
                if curr in positions
                  result[curr] = parseFloat(amount)
            cb result
      
  getTicker: (cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.ticker @
      ,(err,result)->
        if err?
          logger.error "getTicker: reached max retries #{err}"
        else
          cb
            buy: parseFloat(result.bid)
            sell: parseFloat(result.ask)


module.exports = BitstampPlatform
    
