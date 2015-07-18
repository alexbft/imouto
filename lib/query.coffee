logger = require 'winston'

misc = require './misc'
pq = require './promise'
config = require './config'

token = config.options.token

module.exports = query = (method, args = {}, options = {}) ->
    reqOptions = {}
    myOptions = {}
    for k, v of options
        if k == 'multipart'
            myOptions[k] = v
        else
            reqOptions[k] = v
    if myOptions.multipart
        reqOptions.formData = args
    else
        reqOptions.form = args
    reqOptions.silent = true
    misc.post "https://api.telegram.org/bot#{token}/#{method}", reqOptions
    .then (d) ->
        try
            data = JSON.parse d
        catch e
            logger.error "Unexpected data: #{d}"
            if d.indexOf('502 Bad Gateway') != -1
                return {'error': 502}
            else
                return {'error': 'Unexpected data'}
        if data.ok
            data.result
        else
            logger.error data.description
            return {'error': data.description}
