misc = require '../lib/misc'

module.exports =
    pattern: /!dogify (.+)/
    name: 'Dogify'

    onMsg: (msg, safe) ->
        phrases = msg.match[1].trim().split(',')
        for phrase, index in phrases
            phrases[index] = encodeURIComponent(phrase.trim())
        msg.send 'http://dogr.io/' + phrases.join('/') + '.png?split=false&.png'