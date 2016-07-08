misc = require '../lib/misc'

getJson = (url) ->
    misc.get url, json: true

module.exports =
    pattern: /!boobs$/
    name: 'Boobs'

    onMsg: (msg, safe) ->
        safe getJson 'http://api.oboobs.ru/noise/1'
            .then (json) -> msg.send 'http://media.oboobs.ru/' + json[0].preview