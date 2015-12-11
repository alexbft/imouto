logger = require 'winston'

misc = require '../lib/misc'

translate = (src, dest, txt) ->
    misc.getAsBrowser "http://translate.google.com/translate_a/single",
        qs:
            client: 'your_mom'
            ie: 'UTF-8'
            oe: 'UTF-8'
            dt: 't'
            sl: src
            tl: dest
            q: txt
    .then (res) ->
        try
            evalFn = new Function "return " + res
            json = evalFn()
            (d[0] for d in json[0]).join("")
        catch ex
            logger.debug res
            null

module.exports =
    name: 'Translate'
    pattern: /!(переведи|translate|перевод|расшифруй)( [a-z]{2})?( [a-z]{2})?(?: ([^]+))?$/

    onMsg: (msg, safe) ->
        if msg.match[2]? and not msg.match[3]?
            src = 'auto'
            dest = msg.match[2].trim()
        else
            src = (msg.match[2] ? 'auto').trim()
            dest = (msg.match[3] ? 'ru').trim()
        if src == 'auto' and msg.match[1].toLowerCase() == 'расшифруй'
            src = 'ja'
        if msg.match[4]?
            text = msg.match[4].trim()
        else if msg.reply_to_message?.text?
            text = msg.reply_to_message.text
        else
            return
        safe translate src, dest, text
        .then (res) ->
            if res?
                msg.reply("Перевод: #{res}")
            else
                msg.send "Сервис недоступен."

    onError: (msg) ->
        msg.send 'Не понимаю я эти ваши иероглифы.'
