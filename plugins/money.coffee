logger = require 'winston'

misc = require '../lib/misc'
config = require '../lib/config'
pq = require '../lib/promise'

search = ->
    misc.get "https://openexchangerates.org/api/latest.json",
        qs:
            app_id: config.options.exchangekey
        json: true

getCurrencies = ->
    misc.get "https://openexchangerates.org/api/currencies.json",
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
    pattern: /!(курс|деньги)(?:\s+([\d\.]+)?\s*([A-Za-z]{3})\s*([A-Za-z]{3})?)?\s*$/
    isConf: true    

    searchCached: ->
        if @lastResultTime? and Date.now() - @lastResultTime < 1800 * 1000 # 30 min
            pq.resolved @lastResult
        else
            search()

    onMsg: (msg, safe) ->
        if msg.match[1].toLowerCase() == 'деньги'
            buf = ''
            safe getCurrencies().then (c) ->
                for k, v of c
                    buf += "#{k} - #{v}\n"
                msg.send buf
            return
        if msg.match[3]?
            amount = if msg.match[2]? then Number(msg.match[2]) else 1
            reqFrom = msg.match[3].toUpperCase()
            reqTo = if msg.match[4]? then msg.match[4].toUpperCase() else 'RUB'
            isSpecific = true
        else
            isSpecific = false
        if isSpecific
            resQuery = safe pq.all [@searchCached()]
        else
            resQuery = safe pq.all [search(), oil()]
        resQuery.then ([json, oil]) =>
            try            
                @lastResult = json
                @lastResultTime = Date.now()
                date = new Date(json.timestamp * 1000)
                calc = (from, to, amount = 1) ->
                    f = json.rates[from]
                    t = json.rates[to]
                    '*' + (t / f * amount).toFixed(2) + '*'
                if isSpecific
                    if amount > 0 and amount < 1000000000
                        if reqFrom of json.rates and reqTo of json.rates
                            if reqTo == 'RUB'
                                reqToS = 'деревяшек'
                            else if reqTo == 'BYR'
                                reqToS = 'перков'
                            else
                                reqToS = reqTo
                            txt = "#{amount} #{reqFrom} = #{calc(reqFrom, reqTo, amount)} #{reqToS}"
                            msg.send txt, parseMode: 'Markdown'
                        else
                            msg.reply 'Не знаю такой валюты!'
                    else
                        msg.reply 'Не могу посчитать!'
                else
                    txt = """
                        Курс на *#{formatDate(date)}*

                        1 Brent = *#{oil?.toFixed(2) ? '???'}*$
                        1 $ = #{calc('USD', 'RUB')} деревяшек
                        1 Euro = #{calc('EUR', 'RUB')} деревяшек
                        1 CHF = #{calc('CHF', 'RUB')} деревяшек
                        1 Pound = #{calc('GBP', 'EUR')} евро = #{calc('GBP', 'RUB')} деревяшек
                        1 Bitcoin = #{calc('BTC', 'USD')}$ = #{calc('BTC', 'RUB')} деревяшек
                        1 гривна = #{calc('UAH', 'RUB')} деревяшек
                        1 деревяшка = #{calc('RUB', 'BYR')} перков"""
                    msg.send txt, parseMode: 'Markdown'
            catch e
                @_onError msg, e

    onError: (msg) ->
        msg.send '65 копеек, как у дедов!'
