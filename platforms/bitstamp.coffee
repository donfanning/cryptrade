_ = require 'underscore'
Bitstamp = require 'bitstamp'
Platform = require '../platform'
attempt = require 'attempt'

class BitstampPlatform extends Platform
  init: (@config,@pair,@account)->
    unless @account.clientid and @account.key and @account.secret 
      throw new Error 'BistampPlatform: client id, API key and secret must be provided'
    @client = new Bitstamp @account.clientid,@account.key,@account.secret
  trade: (order, cb)->
    if order.maxAmount * order.price < parseFloat(@config.min_order)
      cb "#{order.type.toUpperCase()} order wasn't created because the amount is less than minimum order amount #{@config.min_order} USD"
      return
    orderCb = (err,result)->
      if err?
        cb err
      else
        if result.error?
          cb result.error
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
          cb "isOrderActive: reached max retries #{err}"
        else
          order = _.find result, (order)->
            order.id == orderId
          cb null,order?

  cancelOrder: (orderId, cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.cancel_order orderId, @
      ,(err,result)->
        if err?
          cb "cancelOrder: reached max retries #{err}"
        if cb?
          cb null

  getPositions: (positions,cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.balance @
      ,(err,data)->
        if err?
          cb "getPositions: reached max retries #{err}"
        else
          if data.error?
            cb "getPositions: #{result.error}"
          else
            result = {}
            for item, amount of data
              if item.indexOf 'available' != -1
                curr = item.substr(0, 3)
                if curr in positions
                  result[curr] = parseFloat(amount)
            cb null, result
      
  getTicker: (cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.ticker @
      ,(err,result)->
        if err?
          cb "getTicker: reached max retries #{err}"
        else
          cb null,
            buy: parseFloat(result.bid)
            sell: parseFloat(result.ask)


module.exports = BitstampPlatform
    
