misc = require './misc'

initialized = false
cities = {}

loadCities = ->
  cities = misc.loadJson('users_cities') ? {}

saveCities = ->
  misc.saveJson 'users_cities', cities

exports.init = ->
  if not initialized
    loadCities()
    initialized = true
  return

exports.add = (userId, cityName, lat, lon) ->
  cities[userId] = { name: cityName, lat, lon }
  saveCities()

exports.get = (userId) ->
  cities[userId]