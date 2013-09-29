Obviously the thing to do was to be bullish in a bull market and bearish in a bear market.


  *Reminiscences of a Stock Operator by J. Livermore*

cryptrade
=========

NodeJS trading client for Cryptotrader.org


Cryptrade is a standalone client for Cryptotrader.org. The main purpose of this tool is to allow automated trading at 
popular exchanges such as MtGox and Bitstamp. 

## Features
  - Support for 125+ [Talib](http://ta-lib.org/) indicators such as EMA, MACD, etc. 
  - Real time trading at Mtgox & Bitstamp
  - Compatible with Cryptotrader.org API

## Installation

  - Make sure you have [Node](http://nodejs.org/) installed 
  - Install cryptrade tool
    
        git clone https://github.com/pulsecat/cryptrade.git
        cd cryptrade
        npm install

  - Open keys.cson and put your API keys of the exchanges you want to trade on. 
    *Private keys are never sent to the server*
  
## Usage
  To start trading bot, just type
  
    ./cryptrade.sh https://cryptotrader.org/backtests/6uGwz2NfNsbkuapop
    
  The above command will start EMA 10/21 algorithm to trade at Mtgox BTC/USD with trading period set to 1h. 
  Also, you can run the tool with an algorithm stored locally. In this case your algorithm won't be sent to the server:
  
    ./cryptrade.sh examples/ema_10_21.coffee
  
        
   Default configuration can be overriden by command line options:
  
    Usage: cryptrade.coffee [options] <filename or backtest url in format https://cryptotrader.org/backtests/<id>>

    Options:

      -h, --help               output usage information
      -c,--config [value]      Load configuration file
      -p,--platform [value]    Trade at specified platform
      -i,--instrument [value]  Trade instrument (ex. btc_usd)
      -t,--period [value]      Trading period (ex. 1h)
      
  For example, to start the above algorithm at Bitstamp with trading period set to 2 hours use the following command:
    
    ./cryptrade.sh -p bitstamp -t 2h examples/ema_10_21.coffee
    
    

**This is beta software, use it at your own risk**
