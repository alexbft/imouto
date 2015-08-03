config = require '../lib/config'
quotes = require '../lib/quotes'
msgCache = require '../lib/msg_cache'

module.exports =
    name: 'Quotes (save)'
    pattern: /!?(запомни|сохрани|запиши|save)\b/
    isAcceptFwd: true
    isPrivileged: true
    warnPrivileged: false

    init: ->
        quotes.init()
        @timers = {}
        @sudoList = config.toIdList(config.options.quotes_sudo)

    isAcceptMsg: (msg) ->
        msg.forward_from? and msg.chat.first_name? or
            not msg.forward_from? and msg.reply_to_message? and @matchPattern(msg, msg.text)

    onMsg: (msg) ->
        quotes.updateUsers()
        if msg.forward_from?
            quoteMsg = msg
        else
            quoteMsg = msgCache.tryResolve msg.reply_to_message
        if quoteMsg.forward_from?
            msgAuthorId = quoteMsg.forward_from.id
        else
            msgAuthorId = quoteMsg.from.id
        if msgAuthorId == msg.from.id and not @bot.isSudo(msg)
            msg.reply("Сам себя не похвалишь - никто не похвалит, да?")
            return
        posterId = msg.from.id
        num = quotes.add(quoteMsg, posterId)
        if @timers[posterId]?
            clearTimeout(@timers[posterId])
        @timers[posterId] = setTimeout =>
            msg.reply("Запомнила под номером #{num}.")
            @timers[posterId] = null
        , quotes.QUOTE_MERGE_TIMEOUT

    isSudo: (msg) ->
        @bot.isSudo(msg) or msg.from.id in @sudoList