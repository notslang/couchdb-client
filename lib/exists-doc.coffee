headDoc = require './head-doc'
{getRequestId} = require './util'

existsDoc = (db, _id) ->
  headDoc(db, _id).then(({status, requestId}) ->
    {requestId, result: true, status}
  ).catch((err) ->
    if err.response?.status isnt 404 then throw err
    {requestId: getRequestId(err.response), result: false, status: 404}
  )

module.exports = existsDoc
