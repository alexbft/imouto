logger = require 'winston'

pq = require '../lib/promise'
quotes = require '../lib/quotes'
msgCache = require '../lib/msg_cache'
misc = require '../lib/misc'
config = require '../lib/config'

CB_DELAY = 1500

formatDate = (date) ->
    d = date.getDate()
    if d < 10
        d = "0" + d
    m = date.getMonth() + 1
    if m < 10
        m = "0" + m
    y = date.getFullYear() % 100
    "#{d}.#{m}.#{y}"

sanitizeHtml = (html) ->
    html.replace(/\>/g, '&gt;').replace(/\</g, '&lt;').replace(/\&/g, '&amp;')

keyboard = [
                [
                    {text: quotes.THUMBS_UP, callback_data: 'up'},
                    {text: quotes.THUMBS_DOWN, callback_data: 'down'}],
                [
                    {text: 'media', callback_data: 'media'}
                    {text: '<', callback_data: 'prev'},
                    {text: '?', callback_data: 'random'},
                    {text: '>', callback_data: 'next'},
                    {text: '>|', callback_data: 'last'},
                    {text: '[x]', callback_data: 'close'}]]

keyboard2 = [[
    {text: quotes.THUMBS_UP, callback_data: 'up'},
    {text: quotes.THUMBS_DOWN, callback_data: 'down'}]]

module.exports =
    name: 'Quotes (get)'
    pattern: /!(q|!q|qq|ц|!ц|цц|цитата|quote|удали|del|delete|stats)(?:\s+(.+))?$/

    init: ->
        quotes.init()
        @sudoList = config.toIdList(config.options.quotes_sudo)        
        # @vote =
        #     keyboard: [[quotes.THUMBS_UP, quotes.THUMBS_DOWN]]
        #     resize_keyboard: true
        #     one_time_keyboard: true

    onMsg: (msg) ->
        cmd = msg.match[1].toLowerCase()
        if cmd in ['удали', 'del', 'delete']
            if !@checkSudo(msg)
                return
            num = misc.tryParseInt(msg.match[2])
            if not num?
                return
            quote = quotes.getByNumber(num)
            if not quote?
                msg.reply("Цитата с номером #{num} не найдена.")
                return
            if quote.posterId != msg.from.id and not @bot.isSudo(msg)
                msg.reply("Нельзя удалять чужие цитаты.")
                return
            quotes.delQuote(num)
            msg.reply("Цитата #{num} удалена.")
            return
        if msg.reply_to_message?
            reply = msg.reply_to_message
            if reply.forward_from?
                ownerId = reply.forward_from.id
            else
                ownerId = reply.from.id
        else
            ownerId = null
        if cmd == 'stats'
            msg.send quotes.getStats ownerId, msg.match[2]
            return
        inlineMode = cmd not in ['!q', '!ц']
        quotes.updateUsers()
        queryInfo = null
        if msg.match[2]?
            txt = msg.match[2].trim()
            num = null
            if txt.endsWith('+')
                num = misc.tryParseInt(txt.substr(0, txt.length - 1))
                if num?
                    queryInfo = "Начиная с №#{num}"
                    quoteSet = quotes.getByNumberPlusAll(num)
                    quote = misc.randomChoice quoteSet
            if not num?
                num = misc.tryParseInt(txt)
                if num?
                    quoteSet = quotes.getRandomAll()
                    quote = quotes.getByNumber(num)
                else
                    queryInfo = "Содержит: '#{msg.match[2].trim()}'"
                    if ownerId?
                        queryInfo += " Автор: #{quotes.getUserNameById(ownerId)}"
                    quoteSet = quotes.getByTextAll(msg.match[2].trim(), ownerId)
                    quote = misc.randomChoice quoteSet
        else
            if ownerId?
                queryInfo = "Автор: #{quotes.getUserNameById(ownerId)}"
                quoteSet = quotes.getByOwnerIdAll(ownerId)
                quote = misc.randomChoice quoteSet
            else
                onlyPositive = cmd in ['qq', 'цц']
                if onlyPositive
                    queryInfo = "Только с положительным рейтингом"                
                quoteSet = quotes.getRandomAll(onlyPositive: onlyPositive)
                quote = misc.randomChoice quoteSet
        if quote?
            if inlineMode
                @sendInline msg, quote, quoteSet, queryInfo
            else
                hdr = @getQuoteHeader quote, false
                quotes.setLastQuote(msg.chat.id, quote.num)
                msg.send(hdr, parseMode: 'HTML').then =>
                    if quote.version >= 5
                        fwdFunc = (msgIndex) =>
                            if msgIndex < quote.messages.length
                                msg.forward(quote.messages[msgIndex].id, quote.messages[msgIndex].chat_id).then ->
                                    fwdFunc(msgIndex + 1)
                        fwdFunc(0)
                    else
                        if quote.version >= 3
                            fwdFunc = (msgIndex) =>
                                if msgIndex < quote.messages.length
                                    message = quote.messages[msgIndex]
                                    kekerName = message.saved_name ? message.sender_name
                                    buf = "<i>#{kekerName.replace('_', ' ')}</i>\n"
                                    if message.text?
                                        buf += message.text
                                        msg.send(buf, parseMode: 'HTML').then ->
                                            fwdFunc(msgIndex + 1)
                                    else
                                        fwdFunc(msgIndex + 1)
                            fwdFunc(0)
                        else
                            kekerName = quote.saved_name ? quote.sender_name
                            buf = ''
                            if quote.reply_text?
                                buf += '&gt; ' + quote.reply_text.replace(/\n/g, '\n> ') + "\n\n"
                            buf += "<i>#{kekerName.replace('_', ' ')}</i>\n"
                            buf += quote.text
                            msg.send(buf, parseMode: 'HTML')
        else
            msg.reply('Цитата не найдена :(')

    getQuoteHeader: (quote, inlineMode) ->
        hdr = "<b>Цитата №#{quote.num}</b>"
        if not inlineMode
            if quote.version <= 2
                savedName = quote.saved_name
            else
                _savedNames = quote.messages.map((mm) -> mm.saved_name).filter((n) -> n?)
                _last = null
                savedNames = []
                for sn in _savedNames
                    if sn != _last
                        _last = sn
                        savedNames.push sn
                savedName = savedNames.join(", ")
        if quote.version < 5
            hdr += " (архив)"
        else
            if savedName? and savedName != ""
                hdr += " (#{savedName})"
        rating = quotes.getRating(quote.num)
        if rating > 0
            ratingStr = "+#{rating}"
        else
            ratingStr = "#{rating}"
        if quote.date?
            hdr += ", сохранена #{formatDate(new Date quote.date)}"
        if quote.posterName?
            hdr += ", от <i>#{quote.posterName}</i>"
        hdr += "\nРейтинг цитаты: <b>[ #{ratingStr} ]</b>"
        if not inlineMode
            hdr += " #{quotes.THUMBS_UP} /Opy_#{quote.num} #{quotes.THUMBS_DOWN} /He_opu_#{quote.num}"
        hdr

    getQuoteText: (quote) ->
        if quote.version >= 3
            parts = []
            for message in quote.messages
                kekerName = sanitizeHtml message.saved_name ? message.sender_name
                buf = "<i>#{kekerName.replace('_', ' ')}</i>\n"
                if message.text?
                    buf += sanitizeHtml message.text
                else
                    buf += '[media]'
                parts.push buf
            parts.join '\n\n'
        else
            kekerName = sanitizeHtml quote.saved_name ? quote.sender_name
            buf = ''
            if quote.reply_text?
                buf += '&gt; ' + sanitizeHtml(quote.reply_text.replace(/\n/g, '\n&gt; ')) + "\n\n"
            buf += "<i>#{kekerName.replace('_', ' ')}</i>\n"
            buf += sanitizeHtml quote.text
            buf

    getQuoteFull: ({quote, quoteSet, queryInfo}) ->
        prefix = "<code>Всего: #{quoteSet.length}</code>"
        if queryInfo?
            prefix = "<code>#{queryInfo}</code>\n#{prefix}"
        "#{prefix}\n\n#{@getQuoteHeader(quote, true)}\n\n#{@getQuoteText(quote)}"

    sendInline: (msg, quote, quoteSet, queryInfo) ->
        context =
            quote: quote
            quoteSet: quoteSet
            index: quoteSet.indexOf(quote)
            queryInfo: queryInfo
            mediaForwarded: {}
            keyboard: keyboard
        msg.send @getQuoteFull(context), 
            parseMode: 'HTML'
            preview: false
            inlineKeyboard: keyboard
            callback: (cb, msg) => @onCallback context, cb, msg

    onCallback: (context, cb, msg) ->
        if not @bot.isSudo cb
            now = Date.now()
            if @lastClick? and now - @lastClick < CB_DELAY
                cb.answer 'Слишком много запросов, подождите 3 секунды...'
                return
            @lastClick = now
        context.msg = msg
        switch cb.data
            when 'up'
                @vote context, cb, true
            when 'down'
                @vote context, cb, false
            when 'prev'
                if context.index > 0
                    context.index -= 1
                else
                    context.index = context.quoteSet.length - 1
                context.quote = context.quoteSet[context.index]
                @updateInline context
                cb.answer ''
            when 'next'
                if context.index + 1 < context.quoteSet.length
                    context.index += 1
                else
                    context.index = 0
                context.quote = context.quoteSet[context.index]
                @updateInline context
                cb.answer ''
            when 'random'
                index = misc.random context.quoteSet.length
                if index != context.index
                    context.index = index
                    context.quote = context.quoteSet[context.index]
                    @updateInline context
                cb.answer ''
            when 'last'
                index = context.quoteSet.length - 1
                if index != context.index
                    context.index = index
                    context.quote = context.quoteSet[context.index]
                    @updateInline context
                cb.answer ''
            when 'media'
                if not context.mediaForwarded[context.index]
                    context.mediaForwarded[context.index] = true
                    @forwardMedia msg, context.quote
                cb.answer ''
            when 'close'
                context.keyboard = keyboard2
                @updateInline context, true
                cb.answer ''
            else
                logger.warn 'unknown data'
        return

    forwardMedia: (msg, quote) ->
        if quote.version >= 5
            fwdFunc = (msgIndex) =>
                while msgIndex < quote.messages.length
                    message = quote.messages[msgIndex]
                    if not message.text?
                        msg.forward(message.id, message.chat_id).then ->
                            fwdFunc(msgIndex + 1)
                        break
                    else
                        msgIndex += 1
            fwdFunc(0)
        return

    vote: (context, cb, isUp) ->
        num = context.quote.num
        if quotes.vote(num, null, cb.from.id, isUp)?
            rating = quotes.getRating(num)
            if rating > 0
                rating = "+#{rating}"            
            cb.answer "Ваш голос #{if isUp then quotes.THUMBS_UP else quotes.THUMBS_DOWN} учтён. Рейтинг цитаты №#{num}: [ #{rating} ]"
            @updateInline(context, true)
        return

    updateInline: (context, force = false) ->
        if not force and context.quoteSet.length <= 1
            return
        context.msg.edit @getQuoteFull(context),
            parseMode: 'HTML'
            preview: false
            inlineKeyboard: context.keyboard
        .then (res) =>
            if not res?.message_id?
                @lastClick = Date.now() + 10000
        return

    isSudo: (msg) ->
        @bot.isSudo(msg) or msg.from.id in @sudoList
