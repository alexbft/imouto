#todo send image by id

fs = require 'fs'
logger = require 'winston'

misc = require './lib/misc'
tg = require './lib/tg'
msgCache = require './lib/msg_cache'
Plugin = require './plugin'

module.exports = class Bot
    constructor: ->
        @plugins = []
        @sudoList = []
        @bannedIds = []
        @startDate = Date.now()
        @callbacks = {}

    processUpdate: (u) ->
        if u.message?
            @onMessage u.message
        if u.edited_message?
            @onEditedMessage u.edited_message
        if u.callback_query?
            @onCallback u.callback_query

    onMessage: (msg) ->
        msgCache.add(msg)
        @logMessage(msg)
        if !@isValidMsg msg
            logger.debug 'Invalid message'
            return
        if @isQuietMode() and !@isSudo(msg)
            return
        @extendMsg msg
        if msg.from.id in @bannedIds or (not @isSudo(msg) and msg.chat.id in @bannedIds)
            return
        # if msg.text == '!!r' && @isSudo(msg)
        #     @reloadPlugins()
        #     msg.send 'Перезагрузила'
        #     return
        for plugin in @plugins
            try
                if msg.forward_from and not plugin.isAcceptFwd
                    continue
                if plugin.isAcceptMsg(msg)
                    if not plugin.isPrivileged or plugin.checkSudo(msg)
                        if plugin.isConf and not msg.chat.title? and not plugin.isSudo(msg)
                            msg.reply "Эта команда только для конференций. Извини!"
                        else
                            plugin._onMsg msg
            catch e
                logger.error e.stack
        return

    onEditedMessage: (msg) ->
        msgCache.add(msg)
        msg.isEdited = true
        @logMessage msg
        return

    onCallback: (cb) ->
        @logCallback cb
        msgId = cb.message?.message_id
        if msgId of @callbacks
            if @callbacks[msgId](cb) == false
                delete @callbacks[msgId]
        return

    logCallback: (cb) ->
        buf = []
        buf.push "(#{cb.from.id})#{misc.fullName(cb.from)}"
        buf.push "(callback for ##{cb.message.message_id})"
        buf.push ">>>"
        if cb.data?
            buf.push "#{cb.data}"
        else
            buf.push "(no text)"
        logger.inMsg buf.join(" ")

    logMessage: (msg) ->
        buf = []
        date = new Date(msg.date * 1000)
        buf.push "[#{date.toLocaleTimeString()}]"
        if msg.chat.title?
            buf.push "(#{msg.chat.id})#{msg.chat.title}"
        buf.push "(#{msg.from.id})#{misc.fullName(msg.from)}"
        if msg.forward_from?
            buf.push "(from #{misc.fullName(msg.forward_from)})"
        if msg.isEdited
            buf.push "(edit)"
        buf.push ">>>"
        if msg.text?
            buf.push msg.text
        else if msg.new_chat_member?
            buf.push "(added user #{misc.fullName(msg.new_chat_participant)})"
        else if msg.left_chat_member?
            buf.push "(removed user #{misc.fullName(msg.left_chat_participant)})"
        else if msg.new_chat_title?
            buf.push "(renamed chat to #{msg.new_chat_title})"
        else if msg.audio?
            buf.push "(audio)"
        else if msg.document?
            buf.push "(document)"
        else if msg.photo?
            buf.push "(photo)"
        else if msg.sticker?
            buf.push "(sticker)"
        else if msg.video?
            buf.push "(video)"
        else if msg.contact?
            buf.push "(contact: #{msg.contact.first_name} #{msg.contact.phone_number})"
        else if msg.location?
            buf.push "(location: #{msg.location.longitude} #{msg.location.latitude})"
        else if msg.venue?
            buf.push "(venue)"
        else if msg.pinned_message?
            buf.push "(pinned_message: #{msg.pinned_message.text})"
        else
            buf.push "(no text)"
        logger.inMsg buf.join(" ")

    answerCallbackQuery: (cb, text, options = {}) ->
        args =
            callback_query_id: cb.id
            text: text
        if options.showAlert?
            args.show_alert = options.showAlert
        tg.answerCallbackQuery args

    extendMsg: (msg) ->
        bot = this
        msg.send = (text, options = {}) ->
            args =
                chat_id: @chat.id
                text: text
            if options.reply?
                args.reply_to_message_id = options.reply
            if options.preview?
                args.disable_web_page_preview = !options.preview
            if options.replyMarkup?
                args.reply_markup = Object.assign {}, args.reply_markup, options.replyMarkup
            if options.inlineKeyboard?
                args.reply_markup = Object.assign {}, args.reply_markup, {inline_keyboard: options.inlineKeyboard}
            if options.parseMode?
                args.parse_mode = options.parseMode
            tg.sendMessage(args).then (res) =>
                if res.message_id? and options.callback?
                    bot.extendMsg res
                    logger.debug "set callback for #{res.message_id}"
                    bot.callbacks[res.message_id] = (cb) -> 
                        cb.answer = (text, options) -> bot.answerCallbackQuery cb, text, options
                        options.callback cb, res
                res

        msg.edit = (text, options = {}) ->
            args =
                chat_id: @chat.id
                text: text
                message_id: @message_id
            if options.preview?
                args.disable_web_page_preview = !options.preview
            if options.replyMarkup?
                args.reply_markup = Object.assign {}, args.reply_markup, options.replyMarkup
            if options.inlineKeyboard?
                args.reply_markup = Object.assign {}, args.reply_markup, {inline_keyboard: options.inlineKeyboard}
            if options.parseMode?
                args.parse_mode = options.parseMode
            tg.editMessageText(args).then (res) =>
                if res.message_id? and options.callback?
                    bot.extendMsg res
                    logger.debug "set callback for #{res.message_id}"
                    bot.callbacks[res.message_id] = (cb) -> 
                        cb.answer = (text, options) -> bot.answerCallbackQuery cb, text, options
                        options.callback cb, res
                res

        msg.reply = (text, options = {}) ->
            options.reply = @message_id
            @send text, options

        msg.sendPhoto = (photo, options = {}) ->
            args =
                chat_id: @chat.id
                photo: photo
            if options.reply?
                args.reply_to_message_id = options.reply
            if options.caption?
                args.caption = options.caption
            tg.sendPhoto args

        msg.forward = (msg_id, from_chat_id, options = {}) ->
            args =
                chat_id: @chat.id
                from_chat_id: from_chat_id
                message_id: msg_id
            # if options.replyKeyboard?
            #     args.reply_markup = options.replyKeyboard
            tg.forwardMessage args

        msg.sendAudio = (audio, options = {}) ->
            args =
                chat_id: @chat.id
                audio:
                    value: audio
                    options:
                        contentType: 'audio/ogg'
                        filename: 'temp.ogg'
            tg.sendAudio args

        msg.sendVoice = (audio, options = {}) ->
            args =
                chat_id: @chat.id
                voice:
                    value: audio
                    options:
                        contentType: 'audio/ogg'
                        filename: 'temp.ogg'
            tg.sendVoice args            

        msg.sendStickerFile = (fn, data, options = {}) ->
            args =
                chat_id: @chat.id
                sticker:
                    value: data
                    options:
                        contentType: 'image/webp'
                        filename: misc.basename fn
            if options.reply?
                args.reply_to_message_id = options.reply
            tg.sendSticker args, misc.basename fn

        msg.sendStickerId = (fn, id, options = {}) ->
            args =
                chat_id: @chat.id
                sticker: id
            if options.reply?
                args.reply_to_message_id = options.reply
            tg.sendSticker args, misc.basename fn

        return

    reloadPlugins: ->
        logger.info("Reloading plugins...")
        @plugins = []
        files = fs.readdirSync(__dirname + '/plugins').filter (fn) -> fn.endsWith('.js')
        for _fn in files
            fn = './plugins/' + _fn
            try
                data = require fn
                #src = fs.readFileSync fn, encoding: 'utf8'
                #fun = new Function 'require', 'plugin', src
                #fun require, (data) =>
                if data.name?
                    pl = new Plugin(this)
                    for k, v of data
                        pl[k] = v
                    pl._init()
                    @plugins.push pl
                else
                    logger.warn "Skipped: #{_fn}"
            catch e
                logger.warn "Error loading: #{_fn}"
                logger.error e.stack

    isValidMsg: (msg) ->
        msg.from.id != 777000 && (Date.now() - msg.date * 1000) <= 300000

    isSudo: (msg) ->
        msg.from.id in @sudoList

    trigger: (msg, text) ->
        if @isQuietMode() and !@isSudo(msg)
            return
        for plugin in @plugins
            try
                if plugin.matchPattern(msg, text)
                    if not plugin.isPrivileged or plugin.checkSudo(msg)
                        if plugin.isConf and not msg.chat.title? and not plugin.isSudo(msg)
                            msg.reply "Эта команда только для конференций. Извини!"
                        else
                            plugin._onMsg msg
            catch e
                logger.error e.stack

    setQuietMode: (date) ->
        logger.info "Quiet mode until #{new Date(date).toLocaleTimeString()}!"
        @quietModeUntil = date

    isQuietMode: ->
        @quietModeUntil? and Date.now() < @quietModeUntil

