misc = require '../lib/misc'

getJson = (url) ->
    misc.get url, json: true

module.exports =
    pattern: /!qr (.+)/
    name: 'QR'

    onMsg: (msg, safe) ->
        encoded = encodeURIComponent('https://api.qrserver.com/v1/create-qr-code/?size=500x500&format=png&data=' + msg.match[1])
        safe getJson 'https://www.lknsuite.com/shortener/api/create?url=' + encoded
            .then (json) -> msg.send json.url