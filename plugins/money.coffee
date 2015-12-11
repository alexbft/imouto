misc = require '../lib/misc'
config = require '../lib/config'

search = ->
    misc.get "https://openexchangerates.org/api/latest.json",
        qs:
            app_id: config.options.exchangekey
        json: true

formatDate = (date) ->
    d = date.getDate()
    if d < 10
        d = "0" + d
    m = date.getMonth() + 1
    if m < 10
        m = "0" + m
    y = date.getFullYear()
    "#{d}.#{m}.#{y} " + date.toLocaleTimeString()

module.exports =
    name: 'Currency'
    pattern: /!курс(?:\s+(.+))?/
    isConf: true    

    onMsg: (msg, safe) ->
        safe search()
        .then (json) ->
            date = new Date(json.timestamp * 1000)
            calc = (from, to) ->
                f = json.rates[from]
                t = json.rates[to]
                (t / f).toFixed(2)
            txt = """
Курс на #{formatDate(date)}

1 $ = #{calc('USD', 'RUB')} деревяшек
1 Euro = #{calc('EUR', 'RUB')} деревяшек
1 CHF = #{calc('CHF', 'RUB')} деревяшек
1 Bitcoin = #{calc('BTC', 'RUB')} деревяшек
1 гривна = #{calc('UAH', 'RUB')} деревяшек
1 деревяшка = #{calc('RUB', 'BYR')} перков"""
            msg.send txt

    onError: (msg) ->
        msg.send '65 копеек, как у дедов!'