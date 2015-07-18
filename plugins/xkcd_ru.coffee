misc = require '../lib/misc'
pq = require '../lib/promise'
logger = require 'winston'

nums = null

getNums = ->
    if nums?
        pq.resolved(nums)
    else
        nums = []
        logger.info "Reloading russian xkcd nums..."
        misc.get "http://xkcd.ru/num/"
        .then (page) ->
            re = /<li class="real "><a href="\/(\d+)\//g
            while (mm = re.exec(page))?
                nums.push Number mm[1]
            nums

search = (num) ->
    misc.get "http://xkcd.ru/#{num}/"
    .then (page) ->
        title: page.match(/<h1>(.*?)<\/h1>/)[1]
        img: "http://xkcd.ru/i/" + page.match(/<img border=0 src="http:\/\/xkcd\.ru\/i\/(.+?)"/)[1]
        alt: page.match(/<div class="comics_text">([^]*?)<\/div>/)[1]

module.exports = 
    name: 'XKCD (ru)'
    pattern: /!xkcd(?: (\d+))?$/

    onMsg: (msg, safe) ->
        safe(getNums()).then (nums) =>
            num = misc.tryParseInt msg.match[1]
            if not num?
                num = misc.randomChoice nums
            else if num not in nums
                return @trigger msg, "!xkcd en #{num}"
            safe(search(num)).then (res) ->
                msg.send "#{num}. #{res.title}\n#{res.img}"
                .then (sent) ->
                    msg.send res.alt, reply: sent.message_id, preview: false

    onError: (msg) ->
        msg.send "Комикс не найден."