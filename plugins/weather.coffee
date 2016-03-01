misc = require '../lib/misc'
config = require '../lib/config'

getIcon = (type) ->
  switch type
    when "01d" then "☀️"
    when "01n" then ""

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

weather = (cityName) ->
  misc.get 'http://api.openweathermap.org/data/2.5/weather',
    qs:
      q: cityName
      units: 'metric'
      appid: config.options.weathermap
    json: true
  .then (res) ->
    if res.cod isnt 200
      throw new Error res.message

    res


module.exports =
  name: 'Weather'
  pattern: /!(weather|погода)(?: (.+))?/
  isConf: true

  onMsg: (msg, safe) ->
    txt = msg.match[2]
    if not txt?
      return
    res = weather(txt)

    safe(res).then (data) ->
      icon = getIcon data['weather'][0]['icon']
      emoji =
        "#{icon}": "#{data['main']['temp']} °C",
        "💦": "#{data['main']['humidity']}%",
        "💨": "#{data['wind']['speed']} km/h / #{data['wind']['deg']} deg",
        "🌅": "#{new Date(data['sys']['sunrise'] * 1000).toLocaleTimeString()}",
        "🌄": "#{new Date(data['sys']['sunset'] * 1000).toLocaleTimeString()}"

      desc = """
#{data['name']}, #{data['sys']['country']} - #{data['weather'][0]['main']}
#{data['weather'][0]['description']}
"""
      Object.keys(emoji).map (e) ->
        desc += "\n#{e}: #{emoji[e]}"

      msg.reply desc



  onError: (msg) ->
    msg.reply 'Город не найден.'