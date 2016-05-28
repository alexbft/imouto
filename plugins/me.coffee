query = require '../lib/query'
tg = require '../lib/tg'

module.exports =
    name: 'Debug'
    pattern: /!(getme|import-names|qname|nokey|leave)(?:\s+(.+))?$/
    isPrivileged: true

    onMsg: (msg) ->
        if msg.match[1] == 'getme'
            query('getMe').then (json) ->
                logger.info JSON.stringify json
        else if msg.match[1] == 'import-names'
            quotes = require '../lib/quotes'
            quotes.init()
            quotes.importSavedNames()
        else if msg.match[1] == 'qname'
            [id, name...] = msg.match[2].split(' ')
            id = Number id
            name = name.join(' ')
            quotes = require '../lib/quotes'
            quotes.init()
            quotes.setSavedName(id, name)
            msg.reply "Set saved name for #{id}: #{name}"
        else if msg.match[1] == 'nokey'
            msg.send('Ставлю клавиатуру', replyKeyboard: keyboard: [['1']]).then ->
                msg.send('Убираю клавиатуру', replyKeyboard: hide_keyboard: true)
        else if msg.match[1] == 'leave'
            tg.leaveChat chat_id: msg.match[2]
        else
            logger.info "Unknown debug: #{msg.match[1]}"
