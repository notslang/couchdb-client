{getRequestId} = require './util'

###*
 * Delete the database on the server.
 * @param {Boolean} [options.errorIfMissing = false] By default, we ignore
   whether or not the database already exists. Setting this to true will cause
   an error to be thrown if the database has already been deleted.
 * @return {Promise}
###
destroy = (db, {errorIfMissing} = {}) ->
  errorIfMissing ?= false
  promise = db._fetch(
    '', method: 'DELETE'
  ).then((response) ->
    {
      status: response.status
      requestId: getRequestId(response)
    }
  )
  if not errorIfMissing
    promise = promise.catch((err) ->
      # ignore "database already exists"
      if err.response.status isnt 404 then throw err
      return {
        status: err.response.status
        requestId: getRequestId(err.response)
      }
    )
  return promise

module.exports = destroy
