misc = require '../lib/misc'

search = ->
    misc.get "https://api.coinmarketcap.com/v1/ticker/",
        json: true

module.exports =
    name: 'CryptoCurrency'
    pattern: /!(coin|койн|коин|к|c)(?:\s+([\d\.]+)?\s*([A-Za-z]+)\s*([A-Za-z]+)?)?\s*$/
    isConf: true

    onMsg: (msg, safe) ->
        if msg.match[3]?
            amount = if msg.match[2]? then Number(msg.match[2]) else 1
            reqFrom = msg.match[3].toUpperCase()
            reqTo = msg.match[4]?.toUpperCase()
            isSpecific = true
        else
            isSpecific = false
        resQuery = safe search()
        resQuery.then (json) =>
            getData = (code) ->
                if not code?
                    return null
                (q for q in json when q.symbol == code)[0]
            try            
                calc = (from, to, amount = 1) ->
                    f = Number from.price_btc
                    t = Number to.price_btc
                    n = (t / f * amount)
                    f = -Math.floor(Math.log10(n)) + 1
                    fix = if f < 2 then 2 else f
                    '*' + n.toFixed(fix) + '*'

                calcUsd = (from, amount = 1) ->
                    n = (Number from.price_usd) * amount
                    f = -Math.floor(Math.log10(n)) + 1
                    fix = if f < 2 then 2 else f
                    '*' + n.toFixed(fix) + '*'

                calcBtc = (from, amount = 1) ->
                    n = (Number from.price_btc) * amount
                    f = -Math.floor(Math.log10(n)) + 3
                    fix = if f < 4 then 4 else f
                    '*' + n.toFixed(fix) + '*'

                if isSpecific
                    if amount > 0 and amount <= 1000000000
                        dataFrom = getData reqFrom
                        dataTo = getData reqTo
                        if dataFrom? and dataTo?
                            txt = """
                                #{amount} #{dataFrom.name} = #{calc(dataTo, dataFrom, amount)} #{dataTo.name}
                                1h: *#{dataFrom.percent_change_1h}* 24h: *#{dataFrom.percent_change_24h}* 7d: *#{dataFrom.percent_change_7d}*"""
                            msg.send txt, parseMode: 'Markdown'
                        else if dataFrom?
                            txt = """
                                #{amount} #{dataFrom.name} = #{calcUsd(dataFrom, amount)}$
                                1h: *#{dataFrom.percent_change_1h}* 24h: *#{dataFrom.percent_change_24h}* 7d: *#{dataFrom.percent_change_7d}*"""
                            msg.send txt, parseMode: 'Markdown'
                        else
                            msg.reply 'Не знаю такой монеты!'
                    else
                        msg.reply 'Не могу посчитать!'
                else
                    txt = """
                        1 Bitcoin = #{calcUsd getData 'BTC'}$
                        1 Bitcoin Cash = #{calcUsd getData 'BCH'}$
                        1 Ethereum = #{calcUsd getData 'ETH'}$
                        1 Litecoin = #{calcBtc getData 'LTC'} BTC
                        1 Dash = #{calcBtc getData 'DASH'} BTC
                        1 Ripple = #{calcBtc getData 'XRP'} BTC"""
                    msg.send txt, parseMode: 'Markdown'
            catch e
                @_onError msg, e

    onError: (msg) ->
        msg.send 'Just HODL man'
