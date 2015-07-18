misc = require '../lib/misc'

answers = ['параноик', 'параноик', 'параноик', 'параноик', 'невротик', 'аутист', 'психопат', 'странный', 'лучше всех', 'гений', 'социофоб', 'аспергер', 'шизоид', 'шизан', 'мамино счастье', 'нацист', 'мозгоправ', 'социопатопат', 'наркоман', 'упоротый', 'трапоеб']

module.exports =
    name: 'Johnny'
    pattern: /!(джон|john|лестер)/

    onMsg: (msg) ->
        who = msg.match[1]
        if who.toLowerCase() == 'лестер'
            who = 'Алексей'
        else
            who = 'Джонни'
        answer = misc.randomChoice answers
        msg.send "#{who} - #{answer}!"