misc = require '../lib/misc'

module.exports =
    name: 'Dice Roll'
    pattern: /!(roll|ролл|кубик)(?:\s+(d)?(\d+)\s*(?:(d|-)?\s*(\d+))?\s*)?$/

    onMsg: (msg) ->
        if msg.match[2] == 'd'
            if msg.match[3]? and not msg.match[4]? and not msg.match[5]?
                @rollDice msg, 1, misc.tryParseInt(msg.match[3])
            return
        if not msg.match[3]?
            @rollDice msg, 1, 20
        else if msg.match[4]?.toLowerCase() == 'd'
            @rollDice msg, misc.tryParseInt(msg.match[3]), misc.tryParseInt(msg.match[5])
        else if msg.match[5]?
            @rollRandom msg, misc.tryParseInt(msg.match[3]), misc.tryParseInt(msg.match[5])
        else
            @rollRandom msg, 1, misc.tryParseInt(msg.match[3])

    rollDice: (msg, num, faces) ->
        if num? and num > 0 and faces? and faces > 0
            dices = (@rnd(1, faces) for i in [0...num])
            sum = 0
            for d in dices
                sum += d
            if num > 1
                text = "#{dices.join(' + ')} = #{sum} (#{num}d#{faces})"
            else
                if sum <= 20
                    @sendStickerFromFile msg, misc.dataFn("dice/#{sum}.webp"), reply: msg.message_id
                    return
                text = "#{sum} (d#{faces})"
            msg.reply text

    rollRandom: (msg, a, b) ->
        if a? and b? and a < b
            msg.reply "#{@rnd a, b} (#{a}-#{b})"

    rnd: (a, b) ->
        a + misc.random(b - a + 1)