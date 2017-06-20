logger = require 'winston'
tz = require 'coordinate-tz'
moment = require 'moment-timezone'

misc = require '../lib/misc'
config = require '../lib/config'
states = require '../lib/country_codes'
cities = require '../lib/users_cities'

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

forecast = (cityName, lat, lon, lang) ->
  qs =
    units: 'metric'
    lang: lang
    appid: config.options.weathermap

  if cityName? then qs.q = cityName else
    qs.lat = lat
    qs.lon = lon

  misc.get 'http://api.openweathermap.org/data/2.5/forecast',
    qs: qs
    json: true

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
    
keyboard = [
  [
    {text: 'На вечер', callback_data: 'evening'},
    {text: 'Сейчас', callback_data: 'now'},
    {text: 'На завтра', callback_data: 'tomorrow'}
  ]
]

getWeatherFull = (data) ->
  if not data? or not data['weather']?
    return

  type = icon data['weather'][0]['icon']
  zone = timezone data['coord']['lat'], data['coord']['lon']
  sunrise = sunset = offset zone

  """
          #{data.name}, #{states[data.sys.country]} #{if data.jsdt then data.jsdt.fromNow() else ''}

          #{type} #{data.weather[0].description}
          🌡 #{addSign Math.round data.main.temp} °C
          💦 #{data.main.humidity}%
          💨 #{data.wind.speed} км/ч, #{degToCard data.wind.deg}
          🌅 #{sunrise(data.sys.sunrise * 1000).format('LT')}
          🌄 #{sunset(data.sys.sunset * 1000).format('LT')}
        """

module.exports =
  name: 'Weather'
  pattern: /!(weather|погода|!погода|!weather)(?: (.+))?/

  init: ->
    cities.init()

  onMsg: (msg, safe) ->
    cmd = msg.match[1].toLowerCase()
    userId = msg.from.id
    lang = if cmd == 'weather' or cmd == '!weather' then 'en' else 'ru'
    inlineMode = cmd in ['!погода', '!weather']

    moment.locale lang
    txt = msg.match[2]

    if txt?
      cities.add(userId, txt, null, null)
    else
      user = cities.get(userId)
      if not user?
        return

      {name: txt, lat, lon} = user

    res = weather(txt, lat, lon, lang)
    forecst = forecast(txt, lat, lon, lang)

    safe(res).then (data) =>
      if data.cod != 200
        logger.debug data
        msg.reply 'Город не найден.'
      else
        if inlineMode
          @sendInline msg, data, safe(forecst)
        else
          msg.send getWeatherFull(data)
  
  sendInlineInstead: (msg, data, forecast) ->
    context =
      current: data
      now: data
    msg.edit getWeatherFull(data),
      inlineKeyboard: keyboard,
      callback: (cb, msg) => @onCallback context, cb, msg, forecast

  sendInline: (msg, data, forecast) ->
    context =
      current: data
      now: data
    msg.send getWeatherFull(data),
      inlineKeyboard: keyboard,
      callback: (cb, msg) => @onCallback context, cb, msg, forecast

  updateInline: (context, data) ->
    context.msg.edit getWeatherFull(data),
      inlineKeyboard: keyboard
    .then (res) ->
      if res?.message_id?
        context.current = data
    return

  onCallback: (context, cb, msg, forecast) ->
    tomorrow = moment.unix(context.now.dt).add(1, 'days').startOf('day')
    context.msg = msg

    fiveDays = forecast.then (res) ->
      res.list.map((v) -> Object.assign(v, {
        coord: context.now.coord,
        name: res.city.name,
        sys: Object.assign(v.sys, {
          country: res.city.country,
          sunrise: context.now.sys.sunrise,
          sunset: context.now.sys.sunset
        })
        jsdt: moment.unix(v.dt)
      }))

    filterBy = (promise, predicate) -> promise.then (res) -> res.filter(predicate)

    switch cb.data
      when 'now'
        @updateInline context, context.now

      when 'evening'
        filterBy(fiveDays, ({jsdt}) -> jsdt.isBefore(tomorrow)).then (res) =>
          @updateInline context, res[res.length - 1]

      when 'tomorrow'
        filterBy(fiveDays, ({jsdt}) -> jsdt.isAfter(tomorrow)).then (res) =>
          @updateInline context, res[1]
    return

  onError: (msg) ->
    msg.reply 'Кажется, дождь начинается.'

  weather: weather

  forecast: forecast

  getWeatherFull: getWeatherFull
