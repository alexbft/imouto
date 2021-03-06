// Generated by CoffeeScript 1.12.6
var Entities, _cloudRaw, _get, _getAsBrowser, _getAsCloud, _request, _requestRaw, cloudscraper, config, fs, logger, mime, path, pq, random, readStream, request;

request = require('request');

mime = require('mime');

Entities = require('html-entities').AllHtmlEntities;

logger = require('winston');

config = require('./config');

fs = require('fs');

path = require('path');

cloudscraper = require('cloudscraper');

pq = require('./promise');

exports.entities = new Entities;

exports.fullName = function(user) {
  if (global.userNameHack(user.id) != null) {
    return global.userNameHack(user.id);
  }
  if (user.last_name != null) {
    return user.first_name + " " + user.last_name;
  } else {
    return "" + user.first_name;
  }
};

_requestRaw = function(options, cb) {
  var req;
  req = request(options, cb);
  if (!options.silent) {
    logger.info(req.method + " " + req.uri.href);
  }
  return req;
};

_cloudRaw = function(options, cb) {
  var req;
  req = cloudscraper.request(options, cb);
  if (!options.silent) {
    logger.info("(cloud) " + options.url);
  }
  return req;
};

readStream = exports.readStream = function(stream, cb) {
  var bufs;
  bufs = [];
  stream.on('error', cb);
  stream.on('data', function(d) {
    return bufs.push(d);
  });
  return stream.on('end', function() {
    var buf;
    buf = Buffer.concat(bufs);
    return cb(null, buf);
  });
};

exports.request = _request = function(options) {
  var df;
  df = new pq.Deferred;
  _requestRaw(options, function(err, code, body) {
    if (err != null) {
      return df.reject(err);
    } else {
      return df.resolve(body);
    }
  });
  return df.promise;
};

exports.getAsBrowser = _getAsBrowser = function(url, options) {
  if (options == null) {
    options = {};
  }
  options.method = 'GET';
  options.url = url;
  if (options.headers == null) {
    options.headers = {};
  }
  options.headers['User-Agent'] = config.options.useragent;
  return _request(options);
};

exports.get = _get = function(url, options) {
  if (options == null) {
    options = {};
  }
  options.method = 'GET';
  options.url = url;
  return _request(options);
};

exports.post = function(url, options) {
  if (options == null) {
    options = {};
  }
  options.method = 'POST';
  options.url = url;
  return _request(options);
};

exports.getAsCloud = _getAsCloud = function(url, options) {
  var df;
  if (options == null) {
    options = {};
  }
  options.method = 'GET';
  options.url = url;
  df = new pq.Deferred;
  _cloudRaw(options, function(err, code, body) {
    if (err != null) {
      logger.warn(JSON.stringify(err));
      return df.reject(err);
    } else {
      return df.resolve(body);
    }
  });
  return df.promise;
};

exports.google = function(q) {
  return _get('http://ajax.googleapis.com/ajax/services/search/web', {
    qs: {
      v: '1.0',
      q: q
    }
  }).then(function(res) {
    return JSON.parse(res).responseData.results;
  });
};

exports.download = function(url, options) {
  var df, req;
  if (options == null) {
    options = {};
  }
  df = new pq.Deferred;
  options.encoding = null;
  options.url = url;
  if (options.headers == null) {
    options.headers = {};
  }
  options.headers['User-Agent'] = config.options.useragent;
  req = _requestRaw(options);
  req.on('error', function(err) {
    return df.reject(err);
  });
  req.on('response', function(res) {
    var contentType;
    contentType = res.headers['content-type'];
    return readStream(res, function(err, data) {
      var ext;
      if (err) {
        return df.reject(err);
      } else {
        ext = mime.extension(contentType);
        if ((ext == null) && contentType.indexOf('/') !== -1) {
          logger.warn("Unknown extension for type: " + contentType);
          ext = contentType.split('/')[1];
        }
        logger.info("Downloaded: " + url + " - " + data.length + " bytes (" + contentType + ", " + ext + ")");
        if (ext === 'jpe') {
          ext = 'jpeg';
        }
        return df.resolve({
          value: data,
          options: {
            filename: 'temp.' + ext,
            contentType: contentType
          }
        });
      }
    });
  });
  return df.promise;
};

exports.random = random = function(x) {
  return Math.floor(Math.random() * x);
};

exports.randomChoice = function(a) {
  return a[random(a.length)];
};

exports.tryParseInt = function(s) {
  var x;
  if (s == null) {
    return null;
  }
  x = parseInt(s, 10);
  if (!isNaN(x) && x.toString() === s) {
    return x;
  } else {
    return null;
  }
};

exports.dataFn = function(name) {
  return path.resolve(__dirname, '..', 'data', name);
};

exports.loadJson = function(fileId) {
  var content, fn;
  fn = __dirname + ("/../data/" + fileId + ".json");
  if (fs.existsSync(fn)) {
    content = fs.readFileSync(fn, {
      encoding: 'utf8'
    });
    return JSON.parse(content);
  } else {
    return null;
  }
};

exports.saveJson = function(fileId, data) {
  var fn;
  fn = __dirname + ("/../data/" + fileId + ".json");
  fs.writeFileSync(fn, JSON.stringify(data), {
    encoding: 'utf8'
  });
};

exports.basename = function(fn) {
  return path.basename(fn);
};
