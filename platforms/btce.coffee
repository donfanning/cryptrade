_ = require 'underscore'
BTCE = require 'btc-e'
attempt = require 'attempt'
fs = require 'fs'

class Platform
  init: (@config,@pair,@account)->
    unless @account.key and @account.secret
      throw new Error 'Btc-e: key and secret must be provided'
    key = @account.key
    @client = new BTCE @account.key,@account.secret, ->
      if fs.existsSync("nonce_#{key}.json") 
        nonce = JSON.parse(fs.readFileSync("nonce_#{key}.json"))
      else
        nonce = Math.floor(new Date().getTime()/1000)
      nonce++
      fs.writeFile "nonce_#{key}.json",nonce
      nonce

  trade: (order, cb)->
    orderCb = (err,result)->
      if err?
        cb err
      else
        cb null, result.order_id
    if order.maxAmount < parseFloat(@config.min_order[order.asset])
      cb "#{order.type.toUpperCase()} order wasn't created because the amount is less than minimum order amount."
      return
    amount = order.amount or order.maxAmount
    amount = Math.floor(amount * 100000000) / 100000000
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.trade self.pair, order.type, order.price, amount, @
      ,orderCb
      

  isOrderActive: (orderId, cb)->
    self = @
    onError = (err,next)->
      if err == 'no orders'
        cb null,false
      else
        next true
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000,onError:onError},
      ->
        self.client.makeRequest 'ActiveOrders', {}, @
      ,(err,result)->
        if err?
          cb "isOrderActive: reached max retries #{err}"
        else
          cb null, orderId in result
        
    
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
    fixNonce = (err)->
      r = /invalid nonce parameter; on key:(\d+)/
      m = err.toString().match(r)
      if m
        nonce = parseInt(m[1])+1
        fs.writeFile "nonce_#{self.account.key}.json",nonce
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000,onError:fixNonce},
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
            buy: result.ticker.buy
            sell: result.ticker.sell



module.exports = Platform

