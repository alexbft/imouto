module.exports =
    name: 'Echo'
    pattern: /!(echo|скажи) (.+)/

    onMsg: (msg) ->
        txt = msg.match[2].trim()
        if not txt.startsWith('/') and not txt.startsWith('!')
            txt = txt.charAt(0).toUpperCase() + txt.substr(1)
            if /н[я]+$/i.test(txt)
                txt += " ❤"
            msg.send(txt)