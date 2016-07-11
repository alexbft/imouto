misc = require '../lib/misc'
config = require '../lib/config'

APIUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
PhotoAPIUrl = 'https://maps.googleapis.com/maps/api/place/photo'
DetailAPIUrl = 'https://maps.googleapis.com/maps/api/place/details/json'
APIKey = config.options.googlekey

radiusKeyboard = [
  [
    {text: '1km', callback_data: '1000'},
    {text: '2km', callback_data: '2000'},
    {text: '5km', callback_data: '5000'},
    {text: '10km', callback_data: '10000'}
  ]
]

priceLevels = ['бесплатно', 'недорого', 'среднее по цене', 'дорого', 'очень дорого']

normalizeDistance = (distance) ->
  if distance < 1
    (distance * 1000).toFixed() + 'м'
  else
    distance.toFixed(2) + 'км'

getDistanceFromLatLonInKm = (lat1, lon1, lat2, lon2) ->
  R = 6371
  dLat = deg2rad lat2 - lat1 
  dLon = deg2rad lon2 - lon1 
  a = 
    Math.sin(dLat / 2) * Math.sin(dLat/2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * 
    Math.sin(dLon/2) * Math.sin(dLon/2)

  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  R * c

getDetailInfo = (placeid) ->
  qs = {
    key: APIKey,
    placeid: placeid,
    language: 'ru'
  }
  misc.get DetailAPIUrl,
    qs: qs,
    json: true

deg2rad = (deg) ->
  deg * (Math.PI/180)

getPhotoByReference = (reference) ->
  misc.get PhotoAPIUrl,
    qs: {
      key: APIKey,
      photoreference: reference,
      maxwidth: 800
    }

findEfoos = (cb, msg, location) ->
  qs = {
    key: APIKey,
    location: location.latitude + ',' + location.longitude,
    radius: cb.data,
    language: 'ru',
    types: 'lawyer|bar|cafe|restaurant'
  }

  misc.get APIUrl,
    qs: qs,
    json: true

getEfoosByReq = (datas, reqData, cb) ->
  index = reqData.current - 1
  data = datas[index]

  if data.opening_hours?
    openNow = if data.opening_hours.open_now then 'Да' else 'Нет'
  else
    openNow = 'Нет информации'

  if data.price_level?
    priceLevel = priceLevels[data.price_level]
  else
    priceLevel = 'Нет информации'

  rating = 0
  rating = data.rating if data.rating?

  distance = getDistanceFromLatLonInKm reqData.location.latitude, reqData.location.longitude,
    data.geometry.location.lat, data.geometry.location.lng
  distance = normalizeDistance distance

  getDetailInfo(data.place_id)
  .then (response) =>
    if response.result?
      result = response.result

      phoneNumber = 'Нет информации'
      phoneNumber = result.international_phone_number if result.international_phone_number?

      address = 'Нет информации'
      address = result.formatted_address if result.formatted_address?

      raw = """
        #{reqData.current}/#{reqData.total}
        Название: #{data.name}
        Открыт: #{openNow}
        Уровень цен: #{priceLevel}
        Рейтинг: #{rating}
        Расстояние: #{distance}
        Телефон: #{phoneNumber}
        Адрес: #{address}
      """

      keyboard = [
        [
          {text: '<<', callback_data: 'prev'},
          {text: 'Карта', url: result.url},
          {text: 'Фото', callback_data: 'photo'},
          {text: '>>', callback_data: 'next'}
        ]
      ]

      cb({
        raw: raw,
        keyboard: keyboard
      })


module.exports =
  onLocation: (msg, location_msg) ->
    @changeToRadiusInline msg, location_msg.location

  changeToRadiusInline: (msg, location) ->
    msg.edit 'Выберите радиус поиска.',
      inlineKeyboard: radiusKeyboard,
      callback: (_cb, _msg) => @findEfoos _cb, _msg, location

  findEfoos: (cb, msg, location) ->
    findEfoos cb, msg, location
    .then (data) => @displayFirst msg, data, location

  displayFirst: (msg, data, location) ->
    if data.results? and data.results.length > 0
      reqData = {
        current: 1,
        total: data.results.length,
        location: location
      }
      getEfoosByReq data.results, reqData, (efoos) =>
        msg.edit efoos.raw,
          inlineKeyboard: efoos.keyboard,
          callback: (_cb, _msg) => @viewAction _cb, _msg, data, reqData

  viewAction: (cb, msg, data, reqData) ->
    if cb.data is 'prev' and reqData.current > 1
      reqData.current--
      getEfoosByReq data.results, reqData, (efoos) =>
        msg.edit efoos.raw,
          inlineKeyboard: efoos.keyboard
    else if cb.data is 'next' and reqData.current < reqData.total
      reqData.current++
      getEfoosByReq data.results, reqData, (efoos) =>
        msg.edit efoos.raw,
          inlineKeyboard: efoos.keyboard
    else if cb.data is 'photo' and data.results[reqData.current - 1].photos.length > 0
      @sendImageFromUrl msg, "#{PhotoAPIUrl}?key=#{APIKey}&photoreference=#{data.results[reqData.current - 1].photos[0].photo_reference}&maxwidth=800"

  sendImageFromUrl: (msg, url, options) ->
    misc.download url
    .then (res) ->
      msg.sendPhoto res, options
    , (err) ->
      logger.warn err
      msg.send "Не загружается: #{url}"

