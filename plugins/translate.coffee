misc = require '../lib/misc'

translate = (src, dest, txt) ->
    misc.getAsBrowser "http://translate.google.com/translate_a/single",
        qs:
            client: 't'
            ie: 'UTF-8'
            oe: 'UTF-8'
            dt: 't'
            sl: src
            tl: dest
            text: txt
    .then (res) ->
        evalFn = new Function "return " + res
        json = evalFn()
        (d[0] for d in json[0]).join("")

module.exports =
    name: 'Translate'
    pattern: /!(переведи|translate|перевод|расшифруй)( [a-z]{2})?( [a-z]{2})?(?: ([^]+))?$/

    onMsg: (msg, safe) ->
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
            msg.reply("Перевод: #{res}")

    onError: (msg) ->
        msg.send 'Не понимаю я эти ваши иероглифы.'
