misc = require '../lib/misc'

module.exports =
    pattern: /!(кот|киса|cat)$/
    name: 'Cats'

    onMsg: (msg, safe) ->
        @sendImageFromUrl msg, 'http://thecatapi.com/api/images/get'
        