_ = require 'underscore'
fs = require 'fs'
basename = require('path').basename
io = require('socket.io-client')
CoffeeScript = require 'coffee-script'
program = require 'commander'
logger = require 'winston'
CSON = require 'cson'
inspect = require('./utils').inspect
utils = require './utils'
Trader = require './trader'

logger.remove logger.transports.Console
logger.add logger.transports.Console,{level:'verbose',colorize:true,timestamp:true}

version = require('./package.json').version
  
  
if require.main == module
  program = require('commander')
  program
    .usage('[options] <filename or backtest url in format https://cryptotrader.org/backtests/<id>>')
    .option('-c,--config [value]','Load configuration file')
    .option('-p,--platform [value]','Trade at specified platform')
    .option('-i,--instrument [value]','Trade instrument (ex. btc_usd)')
    .option('-t,--period [value]','Trading period (ex. 1h)')
    .parse process.argv
  config = CSON.parseFileSync './config.cson'
  if program.config?
    logger.info "Loading configuration file configs/#{program.config}.cson.."
    anotherConfig = CSON.parseFileSync 'configs/'+program.config+'.cson'
    config = _.extend config,anotherConfig
  keys = CSON.parseFileSync 'keys.cson'
  unless keys?
    logger.error 'Unable to open keys.cson'
    process.exit 1
  if program.args.length > 1
    logger.error "Too many arguments"
    process.exit 1
  if program.args.length < 1
    logger.error "Either filename or url must be specified to load trader source code from"
    process.exit 1
  source = program.args[0]
  if source.indexOf('https://') == 0
    rx = /https?:\/\/cryptotrader.org\/backtests\/(\w+)/
    m = source.match rx
    unless m?
      logger.error 'Backtest URL should be in format https://cryptotrader.org/backtests/<id>'
      process.exit 1
    logger.verbose 'Downloading source from '+source 
    source = "https://cryptotrader.org/backtests/#{m[1]}/json"
    await utils.downloadURL source, defer err,data
    backtest = JSON.parse data
    platform = backtest.platform
    instrument = backtest.instrument
    period = backtest.period
    name = m[1]
    code = backtest.code
  else 
    code = fs.readFileSync source,
      encoding: 'utf8'
    name = basename source,'.coffee'
  unless code?
    logger.error "Unable load source code from #{source}"
    process.exit 1
  config.platform = program.platform or config.platform or platform
  config.instrument = program.instrument or config.instrument or instrument
  config.period = program.period or config.period or period
  if not fs.existsSync 'logs'
    fs.mkdirSync 'logs'
  logger.add logger.transports.File,{level:'verbose',filename:"logs/#{name}.log"}
  logger.info "Initializing new trader instance ##{name} [#{config.platform}/#{config.instrument}/#{config.period}]"
  script = CoffeeScript.compile code,
    bare:true
  logger.info 'Connecting to data provider..'
  client = io.connect config.data_provider, config.socket_io
  trader = undefined
  client.socket.on 'connect', ->
    logger.info "Subscribing to data source #{config.platform} #{config.instrument} #{config.period}"
    client.emit 'subscribeDataSource', version, keys.cryptotrader.api_key,
      platform:config.platform
      instrument:config.instrument
      period:config.period
      limit:config.init_data_length
  client.on 'data_message', (msg)->
    logger.warn 'Server message: '+err
  client.on 'data_error', (err)->
    logger.error err
  client.on 'data_init',(bars)->
    logger.verbose "Received historical market data #{bars.length} bar(s)"
    trader = new Trader name,config,keys[config.platform],script
    logger.info "Pre-initializing trader with historical market data"
    trader.init(bars)
  client.on 'data_update',(bars)->
    logger.verbose "Market data update #{bars.length} bar(s)"
    if trader?
      for bar in bars
        trader.handle bar
  client.on 'error', (err)->
    logger.error err
  client.on 'disconnect', ->
    logger.warn 'Disconnected'




