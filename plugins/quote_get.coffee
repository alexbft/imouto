pq = require '../lib/promise'
quotes = require '../lib/quotes'
msgCache = require '../lib/msg_cache'
misc = require '../lib/misc'
config = require '../lib/config'

module.exports =
    name: 'Quotes (get)'
    pattern: /!(q|qq|ц|цц|цитата|quote|удали|del|delete|stats)(?:\s+(.+))?$/

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
        quotes.updateUsers()
        if msg.match[2]?
            txt = msg.match[2].trim()
            num = null
            if txt.endsWith('+')
                num = misc.tryParseInt(txt.substr(0, txt.length - 1))
                if num?
                    quote = quotes.getByNumberPlus(num)
            if not num?
                num = misc.tryParseInt(txt)
                if num?
                    quote = quotes.getByNumber(num)
                else
                    quote = quotes.getByText(msg.match[2].trim(), ownerId)
        else
            if ownerId?
                quote = quotes.getByOwnerId(ownerId)
            else
                quote = quotes.getRandom(onlyPositive: cmd in ['qq', 'цц'])
        if quote?
            hdr = "Цитата №#{quote.num}"
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
            hdr += " [ #{ratingStr} ]"
            if quote.posterName?
                hdr += " от #{quote.posterName}"
            hdr += " #{quotes.THUMBS_UP} /Opy_#{quote.num} #{quotes.THUMBS_DOWN} /He_opu_#{quote.num}"
            quotes.setLastQuote(msg.chat.id, quote.num)
            msg.send(hdr).then =>
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
                                buf = "<#{kekerName.replace('_', ' ')}>\n\n"
                                if message.text?
                                    buf += message.text
                                    msg.send(buf).then ->
                                        fwdFunc(msgIndex + 1)
                                else
                                    fwdFunc(msgIndex + 1)
                        fwdFunc(0)
                    else
                        kekerName = quote.saved_name ? quote.sender_name
                        buf = "<#{kekerName.replace('_', ' ')}>\n\n"
                        if quote.reply_text?
                            buf += '> ' + quote.reply_text.replace(/\n/g, '\n> ') + "\n\n"
                        buf += quote.text
                        msg.send(buf)
        else
            msg.reply('Цитата не найдена :(')

    isSudo: (msg) ->
        @bot.isSudo(msg) or msg.from.id in @sudoList
