headDoc = (db, id) ->
  db._fetch(
    "#{encodeURIComponent(id)}"
    method: 'HEAD'
  ).then(({status, headers}) ->
    {
      status
      requestId: headers.get('x-couch-request-id')
    }
  )

module.exports = headDoc
