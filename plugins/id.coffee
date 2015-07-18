module.exports =
    pattern: /!id$/
    name: 'ID'

    onMsg: (msg) ->
        msg.reply "#{msg.from.id}"