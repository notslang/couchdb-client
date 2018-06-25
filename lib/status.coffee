mapKeys = require 'lodash.mapkeys'
camelCase = require 'lodash.camelcase'

status = (db) ->
  db._fetch(
    './', method: 'GET'
  ).then((response) ->
    response.json()
  ).then((status) ->
    status = mapKeys(status, (value, key) -> camelCase(key))

    # instanceStartTime is in microseconds
    status.instanceStartTime = new Date(
      parseInt(status.instanceStartTime) / 1000
    )
    return status
  )

module.exports = status
