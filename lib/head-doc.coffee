{getRequestId} = require './util'

headDoc = (db, id) ->
  db._fetch(
    "#{encodeURIComponent(id)}"
    method: 'HEAD'
  ).then((response) ->
    {
      status: response.status
      requestId: getRequestId(response)
    }
  )

module.exports = headDoc
