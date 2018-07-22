{getRequestId} = require './util'

###*
 * Get a single document from the database.
 * @param {String} id Document id
 * @param {String} [options.revision] The specific revision id to get.
 * @return {Promise}
###
getDoc = (db, _id, {_rev} = {}) ->
  url = encodeURIComponent(_id)
  if _rev? then url += "?rev=#{_rev}"
  requestId = undefined
  retries = undefined
  status = undefined
  db._fetch(
    url, method: 'GET'
  ).then((response) ->
    requestId = getRequestId(response)
    retries = response.retries
    status = response.status
    return response.json()
  ).then((doc) ->
    {doc, requestId, retries, status}
  )

module.exports = getDoc
