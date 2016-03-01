misc = require '../lib/misc'
config = require '../lib/config'

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
      emoji =
        "☀️": "#{data['main']['temp']} °C",
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