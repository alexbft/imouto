misc = require '../lib/misc'
msgCache = require '../lib/msg_cache'
Xor4k = require '../lib/xor4096'

iq = (s) ->
    xorgen = new Xor4k(s + 'sas' + new Date().toDateString())
    res = xorgen.double()
    if res < 0.5
        30 + Math.round(res * 100)
    else
        80 + Math.round(res * 100)

module.exports =
    pattern: /\/iq/
    name: 'IQ Test'

    onMsg: (msg) ->
        msg.reply "Ваш IQ: #{iq(misc.fullName(msg.from))}"
