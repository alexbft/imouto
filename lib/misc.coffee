request = require 'request'
mime = require 'mime'
Entities = require('html-entities').AllHtmlEntities
logger = require 'winston'
config = require './config'

pq = require './promise'

exports.entities = new Entities

#request.debug = true

exports.fullName = (user) ->
    if user.last_name?
        "#{user.first_name} #{user.last_name}"
    else
        "#{user.first_name}"

_requestRaw = (options, cb) ->
    req = request options, cb
    if not options.silent
        logger.info "#{req.method} #{req.uri.href}"
    req

readStream = (stream, cb) ->
    bufs = []
    stream.on 'error', cb
    stream.on 'data', (d) ->
        bufs.push d
    stream.on 'end', ->
        buf = Buffer.concat(bufs)
        cb(null, buf)

exports.request = _request = (options) ->
    df = new pq.Deferred
    _requestRaw options, (err, code, body) ->
        if err then df.reject(err) else df.resolve(body)
    df.promise

exports.getAsBrowser = _getAsBrowser = (url, options = {}) ->
    options.url = url
    options.headers ?= {}
    options.headers['User-Agent'] = config.options.useragent
    _request options

exports.get = _get = (url, options = {}) ->
    options.method = 'GET'
    options.url = url
    _request options

exports.post = (url, options = {}) ->
    options.method = 'POST'
    options.url = url
    _request options

exports.google = (q) ->
    _get 'http://ajax.googleapis.com/ajax/services/search/web',
        qs: {v: '1.0', q}
    .then (res) ->
        JSON.parse(res).responseData.results

exports.download = (url, options = {}) ->
    df = new pq.Deferred
    options.encoding = null
    options.url = url
    options.headers ?= {}
    options.headers['User-Agent'] = config.options.useragent
    req = _requestRaw options
    req.on 'error', (err) ->
        df.reject err
    req.on 'response', (res) ->
        contentType = res.headers['content-type']
        #console.log("!!! RESPONSE: #{contentType}")
        readStream res, (err, data) ->
            if err
                df.reject err
            else
                ext = mime.extension contentType
                logger.info("Downloaded: #{url} - #{data.length} bytes (#{contentType}, #{ext})")
                if ext == 'jpe'
                    ext = 'jpeg'
                df.resolve
                    value: data
                    options:
                        filename: 'temp.' + ext
                        contentType: contentType
    df.promise

exports.random = random = (x) ->
    Math.floor Math.random() * x

exports.randomChoice = (a) ->
    a[random(a.length)]

exports.tryParseInt = (s) ->
    if not s?
        return null
    x = parseInt(s, 10)
    if not isNaN(x) and x.toString() == s
        x
    else
        null