BPromise = require 'bluebird'
JSONStream = require 'JSONStream'
fetch = require 'node-fetch'
url = require 'url'

{checkStatus} = require './util'

class Server
  auth: ''
  dbName: ''
  url: ''

  constructor: (rawUrl) ->
    urlObj = url.parse(rawUrl)
    @auth = urlObj.auth
    urlObj.auth = ''
    @url = url.format(urlObj)[...-1] # cut off the trailing slash

  _getHeaders: ->
    headers =
      'Accept': 'application/json'
      'Content-Type': 'application/json'
    if @auth?
      headers['Authorization'] = "Basic #{new Buffer(@auth).toString('base64')}"
    return headers

  list: ->
    output = JSONStream.parse('*')
    BPromise.resolve(
      fetch("#{@url}/_all_dbs", headers: @_getHeaders(), credentials: 'include')
    ).then(
      checkStatus
    ).then((response) ->
      response.body.pipe(output)
    ).catch((err) ->
      output.emit('error', err)
    ).done()
    return output

  status: ->
    fetch(
      @url
      method: 'GET'
      headers: @_getHeaders()
      credentials: 'include'
    ).then(
      checkStatus
    ).then((response) ->
      response.json()
    ).then((status) ->
      delete status.couchdb # probably useless welcome message
      return status
    )

module.exports = Server
