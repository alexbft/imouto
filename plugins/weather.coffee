weather_command = require './weather_command'
cities = require '../lib/users_cities'
logger = require 'winston'

module.exports =
  onLocation: (msg, location_msg, safe) ->
    userId = location_msg.from.id
    {latitude, longitude} = location_msg.location
    res = weather_command.weather(null, latitude, longitude, 'ru')
    forecst = weather_command.forecast(null, latitude, longitude, 'ru')

    cities.add(userId, null, latitude, longitude)

    safe(res).then (data) =>
      if data.cod != 200
        logger.debug data
        location_msg.reply 'Город не найден.'
      else
          weather_command.sendInlineInstead msg, data, safe(forecst)
    