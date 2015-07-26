fs = require 'fs'
logger = require 'winston'

misc = require './lib/misc'
pq = require './lib/promise'

module.exports = class Plugin
    constructor: (@bot) ->
        @pattern = null
        @name = null
        @isPrivileged = false
        @warnPrivileged = true
        @isConf = false
        @isAcceptFwd = false
        @sentFiles = misc.loadJson('sentFiles') ? {}

    fixPattern: (pat, onlyBeginning = false) ->
        src = pat.source
            .replace(/\\b/g, '(?:^|$|\\W)')
            .replace(/\\w/g, '[a-zA-Zа-яА-Я0-9]')
            .replace(/\\W/g, '[^a-zA-Zа-яА-Я0-9]')
        if onlyBeginning then src = '^' + src
        #console.log "Fixed: #{pat.source} -> #{src}"
        new RegExp src, 'i'            

    _init: ->
        logger.info("Initializing: #{@name}")
        if @pattern?
            @pattern = @fixPattern @pattern, true
        @init()

    init: ->

    isAcceptMsg: (msg) ->
        @matchPattern(msg, msg.text)

    _onMsg: (msg) ->
        try
            safe = @makeSafe msg
            @onMsg msg, safe
        catch e
            @_onError msg, e

    onMsg: (msg, safe) ->

    _onError: (msg, e) ->
        logger.warn e.stack
        @onError msg

    onError: (msg) ->

    matchPattern: (msg, text) ->
        msg.match = @matchPatternReal(text, @pattern)
        msg.match?

    matchPatternReal: (text, pattern) ->
        if !text? || !pattern?
            null
        else
            pattern.exec text

    isSudo: (msg) ->
        @bot.isSudo(msg)

    checkSudo: (msg) ->
        if !@isSudo(msg)
            logger.info("Sudo failed")
            if @warnPrivileged
                msg.reply("You are not my master!")
            false
        else
            true

    makeSafe: (msg) ->
        (promise) =>
            promise.else (err) => @_onError msg, err

    sendImageFromUrl: (msg, url, options) ->
        misc.download url
        .then (res) ->
            msg.sendPhoto res, options
        , (err) ->
            logger.warn err
            msg.send "Не загружается: #{url}"

    sendAudioFromFile: (msg, fn, options) ->
        df = new pq.Deferred
        fs.readFile fn, (err, data) ->
            if err
                df.reject err
            else
                msg.sendAudio data, options
                .then (res) ->
                    df.resolve res
                , (err) ->
                    df.reject err
        df.promise

    sendStickerFromFile: (msg, fn, options) ->
        #logger.debug "Sending sticker: #{fn}"
        if fn not of @sentFiles
            df = new pq.Deferred
            fs.readFile fn, (err, data) =>
                if errц
                    df.reject err
                else
                    msg.sendStickerFile fn, data, options
                    .then (res) =>
                        @sentFiles[fn] = res.sticker.file_id
                        misc.saveJson 'sentFiles', @sentFiles
                        #logger.debug "Saved: #{fn} - #{res.sticker.file_id}"
                        df.resolve res
                    , (err) ->
                        df.reject err
            df.promise
        else
            logger.debug "Sent: #{fn} - #{@sentFiles[fn]}"
            msg.sendStickerId fn, @sentFiles[fn], options
    
    trigger: (msg, text) ->
        @bot.trigger msg, text

            