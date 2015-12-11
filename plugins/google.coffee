misc = require '../lib/misc'

module.exports =
    name: 'Google'
    pattern: /!(поиск|ищи|найди|гугл|g|поищи|найти|gg)(?: ([^]+))?/

    onMsg: (msg, safe) ->
        cmd = msg.match[1]
        txt = msg.match[2]
        reply_to_id = msg.message_id
        if not txt? and msg.reply_to_message?.text?
            txt = msg.reply_to_message.text
            reply_to_id = msg.reply_to_message.message_id
        if not txt?
            return
        safe misc.google txt
        .then (results) ->
            if results.length == 0
                msg.send 'Ничего не найдено!', reply: reply_to_id
            else
                result = results[0]
                url = result.unescapedUrl
                if cmd == 'gg'
                    answer = "#{result.titleNoFormatting}\n#{url}"
                else
                    answer = url
                msg.send answer, reply: reply_to_id

    onError: (msg) ->
        msg.send 'Поиск не удался...'