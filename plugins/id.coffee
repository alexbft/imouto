msgCache = require '../lib/msg_cache'

module.exports =
    pattern: /!id$/
    name: 'ID'

    onMsg: (msg) ->
        if msg.reply_to_message?
            tmp = msgCache.tryResolve msg.reply_to_message
            if tmp?
                if tmp.forward_from?
                    msg.reply "#{tmp.forward_from.id}"
                else
                    msg.reply "#{tmp.from.id}"
            else
                msg.reply "Нет данных..."
        else
            msg.reply "#{msg.from.id}"