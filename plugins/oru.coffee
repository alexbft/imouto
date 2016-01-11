module.exports = {}
_unused =
  name: 'Oru'

  init: ->
    @pattern = @fixPattern /\bору\b/

  onMsg: (msg) ->
    msg.reply("Не ори.")