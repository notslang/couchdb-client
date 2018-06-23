BPromise = require 'bluebird'
fetch = require 'node-fetch'
{checkStatus} = require './util'

headDoc = (db, id) =>
  BPromise.resolve(
    fetch(
      "#{db.url}/#{encodeURIComponent(id)}"
      credentials: 'include'
      headers: db._getHeaders()
      method: 'HEAD'
    )
  ).then(
    checkStatus
  ).then((response) ->
    {}
  )

module.exports = headDoc
