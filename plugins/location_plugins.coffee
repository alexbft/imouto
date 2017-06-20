weather = require './weather'
eat = require './eat'

keyboard = [
  [
    {text: 'Погода', callback_data: 'weather'},
    {text: 'Еда', callback_data: 'eat'}
  ]
]

module.exports =
  name: 'Location plugins'
  isConf: false

  isAcceptMsg: (msg) ->
    msg.location?

  onMsg: (msg, safe) ->
    msg.send 'Выберите действие.',
      inlineKeyboard: keyboard,
      callback: (_cb, _msg) => @onCallback _cb, _msg, msg, safe

  onCallback: (cb, msg, location_msg, safe) ->
    if cb.data?
      if cb.data is 'weather'
        weather.onLocation msg, location_msg, safe
      else if cb.data is 'eat'
        eat.onLocation msg, location_msg, safe