{buildQueryString, getRequestId} = require './util'

###*
 * Create the database on the server.
 * @param {Object} db
 * @param {Boolean} [options.errorIfExists = false] By default, we ignore
   whether or not the database already exists. Setting this to true will cause
   an error to be thrown if the database has already been created.
 * @return {Promise}
###
create = (db, {errorIfExists, replicas, shards} = {}) ->
  errorIfExists ?= false
  promise = db._fetch(
    buildQueryString({replicas, shards})
    method: 'PUT'
  ).then((response) ->
    {
      status: response.status
      requestId: getRequestId(response)
    }
  )
  if not errorIfExists
    promise = promise.catch((err) ->
      # ignore "database already exists"
      if err.response.status isnt 412 then throw err
      return {
        status: err.response.status
        requestId: getRequestId(err.response)
      }
    )
  return promise

module.exports = create
