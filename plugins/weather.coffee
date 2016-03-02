logger = require 'winston'
tz = require 'coordinate-tz'
moment = require 'moment-timezone'

misc = require '../lib/misc'
config = require '../lib/config'
states = require '../lib/country_codes'

moment.locale 'ru'

degToCard = (deg) ->
  sectionDegrees = 360 / 16
  section = Math.round(deg / sectionDegrees) % 16
  directions = ['С','ССВ','СВ','ВСВ','В','ВЮВ','ЮВ','ЮЮВ','Ю','ЮЮЗ','ЮЗ','ЗЮЗ','З','ЗСЗ','СЗ','ССЗ']
  directions[section]

icon = (type) ->
  switch type
    when "01d" then "☀️"
    when "01n" then "☀"
    when "02d" then "🌤"
    when "02n" then "🌤"
    when "03d" then "☁️"
    when "03n" then "☁️"
    when "04d" then "☁️"
    when "04n" then "☁️"
    when "09d" then "🌧"
    when "09n" then "🌧"
    when "10d" then "🌦"
    when "10n" then "🌦"
    when "11d" then "🌩"
    when "11n" then "🌩"
    when "13d" then "🌨"
    when "13n" then "🌨"
    when "50d" then "🌫"
    when "50n" then "🌫"

timezone = (lat, lon) ->
  tz.calculate(lat, lon).timezone

offset = (timezone) ->
  (date) ->
    tzdate = moment date
    tzdate.tz timezone

weather = (cityName, lat, lon, lang) ->
  qs =
    units: 'metric'
    lang: lang
    appid: config.options.weathermap

  if cityName? then qs.q = cityName else
    qs.lat = lat
    qs.lon = lon

  misc.get 'http://api.openweathermap.org/data/2.5/weather',
    qs: qs
    json: true

addSign = (x) ->
  if x > 0
    "+#{x}"
  else
    "#{x}"

module.exports =
  name: 'Weather'
  pattern: /!(weather|погода)(?: (.+))?/
  isConf: true

  isAcceptMsg: (msg) ->
    msg.location? or @matchPattern(msg, msg.text)

  onMsg: (msg, safe) ->
    if msg.location?
      {latitude, longitude} = msg.location
      res = weather(null, latitude, longitude, 'ru')
    else
      lang = if msg.match[1].toLowerCase() == 'weather' then 'en' else 'ru'
      txt = msg.match[2]
      res = weather(txt, null, null, lang)

      if not txt?
        return

    safe(res).then (data) ->
      if data.cod != 200
        logger.debug data
        msg.reply 'Город не найден.'
      else
        type = icon data['weather'][0]['icon']
        zone = timezone data['coord']['lat'], data['coord']['lon']
        sunrise = sunset = offset zone

        desc = """
          #{data.name}, #{states[data.sys.country]}

          #{type} #{data.weather[0].description}
          🌡 #{addSign Math.round data.main.temp} °C
          💦 #{data.main.humidity}%
          💨 #{data.wind.speed} км/ч, #{degToCard data.wind.deg}
          🌅 #{sunrise(data.sys.sunrise * 1000).format('LT')}
          🌄 #{sunset(data.sys.sunset * 1000).format('LT')}
        """
        msg.send desc

  onError: (msg) ->
    msg.reply 'Кажется, дождь начинается.'
