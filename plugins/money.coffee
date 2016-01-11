misc = require '../lib/misc'
config = require '../lib/config'
pq = require '../lib/promise'

search = ->
    misc.get "https://openexchangerates.org/api/latest.json",
        qs:
            app_id: config.options.exchangekey
        json: true

oil = ->
    misc.get "http://www.forexpf.ru/_informer_/commodities.php"
    .then (first) ->
        id = /comod\.php\?id=(\d+)/.exec(first)[1]
        misc.get "http://www.forexpf.ru/_informer_/comod.php?id=#{id}"
    .then (second) ->
        cbrenta = Number(/document\.getElementById\(\"cbrenta\"\)\.innerHTML=\"([\d\.]+)\"/.exec(second)[1])
        cbrentb = Number(/document\.getElementById\(\"cbrentb\"\)\.innerHTML=\"([\d\.]+)\"/.exec(second)[1])
        (cbrenta + cbrentb) / 2

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
        safe pq.all [search(), oil()]
        .then ([json, oil]) ->
            date = new Date(json.timestamp * 1000)
            calc = (from, to) ->
                f = json.rates[from]
                t = json.rates[to]
                (t / f).toFixed(2)
            txt = """
Курс на #{formatDate(date)}

1 Brent = #{oil.toFixed(2)} $
1 $ = #{calc('USD', 'RUB')} деревяшек
1 Euro = #{calc('EUR', 'RUB')} деревяшек
1 CHF = #{calc('CHF', 'RUB')} деревяшек
1 Bitcoin = #{calc('BTC', 'RUB')} деревяшек
1 гривна = #{calc('UAH', 'RUB')} деревяшек
1 деревяшка = #{calc('RUB', 'BYR')} перков"""
            msg.send txt

    onError: (msg) ->
        msg.send '65 копеек, как у дедов!'