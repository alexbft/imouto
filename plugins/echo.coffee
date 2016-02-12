misc = require '../lib/misc'

module.exports =
    name: 'Echo'
    pattern: /!(echo|скажи|ня) (.+)/

    onMsg: (msg) ->
        txt = msg.match[2].trim()
        if msg.match[1] == 'ня'
            nya = misc.randomChoice ['ня', 'ня', 'ня', 'ня', 'ня', 'ня', 'ня', 'десу', 'Карл']
            txt = txt.replace /([\!\?\.\,])/g, " #{nya}$1"
            if not /([\!\?\.\,])$/.test(txt)
                txt = txt + " #{nya}!"
        i = 0
        while i < txt.length
            if txt.charAt(i) not in '_*`['
                break
            i += 1
        if i < txt.length
            txt = txt.substr(0, i) + txt.charAt(i).toUpperCase() + txt.substr(i + 1)
        if /\<\w+\>.*\<\/\w+\>/.test(txt)
            parseMode = 'HTML'
        else
            parseMode = 'Markdown'
        if /н[я]+$/i.test(txt)
            txt += " ❤"
        msg.send txt, parseMode: parseMode