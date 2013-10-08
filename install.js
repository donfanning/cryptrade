var fs = require('fs');
var CSON = require('cson');

if (!fs.existsSync('keys.cson')) {
  keys = {
    cryptotrader: {
      api_key: 'demo'
    },
    mtgox: {
      key: '',
      secret: ''
    },
    bitstamp: {
      clientid: '',
      key: '',
      secret: ''
    },
  } 
  CSON.stringify(keys, function(err,str) {
    if (err) {
      console.log(err);
    } else {
      console.log('Creating API keys storage..');
      fs.writeFile('keys.cson',str,function(err) {
        if (err) {
          console.log(err);
        }
      });
    }
  });
}
