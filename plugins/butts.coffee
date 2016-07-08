misc = require '../lib/misc'

getJson = (url) ->
    misc.get url, json: true

module.exports =
    pattern: /!butts$/
    name: 'Butts'

    onMsg: (msg, safe) ->
        safe getJson 'http://api.obutts.ru/noise/1'
            .then (json) -> msg.send 'http://media.obutts.ru/' + json[0].preview