query = require '../lib/query'

module.exports =
    name: 'Debug'
    pattern: /!(getme|import-names|nokey)$/
    isPrivileged: true

    onMsg: (msg) ->
        if msg.match[1] == 'getme'
            query('getMe').then (json) ->
                logger.info JSON.stringify json
        else if msg.match[1] == 'import-names'
            quotes = require '../lib/quotes'
            quotes.init()
            quotes.importSavedNames()
        else if msg.match[1] == 'nokey'
            msg.send('Убираю клавиатуру', replyKeyboard: hide_keyboard: true)
        else
            logger.info "Unknown debug: #{msg.match[1]}"
