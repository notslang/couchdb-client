{checkStatus} = require './util'

###*
 * Remove a single document from the database.
 * @param {String} id Document id
 * @param {String} revision The specific revison id of the document.
 * @return {Promise}
###
removeDoc = (db, id, revision) ->
  db._fetch(
    "./#{encodeURIComponent(id)}?rev=#{revision}"
    method: 'DELETE'
  ).then(
    checkStatus
  ).then((response) ->
    response.json()
  ).then((response) ->
    delete response.ok # this property is useless because we have a statuscode
    response._id = response.id
    delete response.id
    return response
  )

module.exports = removeDoc
