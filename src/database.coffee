BPromise = require 'bluebird'
JSONStream = require 'JSONStream'
fetch = require 'node-fetch'
map = require 'through2'
url = require 'url'

{buildQueryString, checkStatus} = require './util'

# hardcoded for now
MAX_RETRIES = 10
RETRY_DELAY = 1000

class CouchDB
  auth: null
  dbName: null
  _sessionCookie: null
  _sessionStartTime: null
  sessionTimeout: null
  url: null

  _outstandingCookieAuthRequests: null

  ###*
   * @param {String} rawUrl
   * @param {Integer} options.sessionTimeout = 600000 The session timeout set on
     the server. Providing this accurately lets us know that a session has
     expired before we send a request that fails, letting us preemtively get a
     new token.
   * @return {undefined}
  ###
  constructor: (rawUrl, {@sessionTimeout = 600000} = {}) ->
    urlObj = url.parse(rawUrl)
    @dbName = urlObj.pathname[1...] # cut off leading slash
    @auth = urlObj.auth
    urlObj.auth = ''
    @url = url.format(urlObj) + '/'

    if @dbName isnt '_replicator'
      urlObj.pathname = '_replicator'
      @replicatorDB = new CouchDB(url.format(urlObj))

  _getFetchOptions: ({authType, method, body}) =>
    if @auth? then authType ?= 'cookie'

    # construct the options object from scratch to avoid cloning
    options = {method, body}
    options.headers =
      'Accept': 'application/json'
      'Content-Type': 'application/json'

    if authType is 'cookie'
      return @_cookieAuth().then(({sessionCookie}) ->
        options.headers['Cookie'] = sessionCookie
        return options
      )

    if authType is 'basic'
      options.headers['Authorization'] = (
        "Basic #{new Buffer(@auth).toString('base64')}"
      )
      options.credentials ?= 'include'
    Promise.resolve(options)

  ###*
   * This is a wrapper function that checks on the sessionCookie to ensure it's
     not expired, checks to see if we are waiting for a `/_session` request to
     finish (reusing the existing request if we are), and if needed, makes a new
     request for an updated sessionCookie.
   * @return {Promise} A promise for the updated sessionCookie.
  ###
  _cookieAuth: =>
    # subtract 500ms to account for incorrect clocks and request time
    if @_sessionCookie? and
       (Date.now() - @_sessionStartTime) < (@sessionTimeout - 500)
      return Promise.resolve(sessionCookie: @_sessionCookie)

    if @_outstandingCookieAuthRequests is null
      @_outstandingCookieAuthRequests = []
      @_updateCookieAuth().then(({sessionCookie}) =>
        @_sessionCookie = sessionCookie
        @_sessionStartTime = Date.now()
        resolve({sessionCookie}) for {resolve} in @_outstandingCookieAuthRequests
        @_outstandingCookieAuthRequests = null
        return
      ).catch((err) =>
        reject(err) for {reject} in @_outstandingCookieAuthRequests
        @_outstandingCookieAuthRequests = null
        return
      )

    # wait for the result of the request to `/_session` that we've already made
    new Promise((resolve, reject) =>
      @_outstandingCookieAuthRequests.push({resolve, reject})
    )

  # do the actual request
  _updateCookieAuth: =>
    [name, password] = @auth.split(':')
    @_fetch(
      '/_session'
      authType: false
      method: 'POST'
      body: JSON.stringify({name, password})
    ).then((response) ->
      return {sessionCookie: response.headers.get('set-cookie')}
    )

  ###*
   * Runs fetch on a given URL, but injects database-specific auth / headers,
     handles retries, and checks the response status code.
   * @param {String} urlSegment [description]
   * @param {Object} options = {} The options to be passed to fetch.
   * @return {Promise}
  ###
  _fetch: (urlSegment, options = {}) =>
    wrappedFetch = (n) =>
      @_getFetchOptions(options).then((fetchOptions) =>
        fetch(url.resolve(@url, urlSegment), fetchOptions)
      ).then(
        checkStatus
      ).catch((err) ->
        if n is 0 or (err.response?.status? and err.response.status isnt 500)
          err.retries = MAX_RETRIES - n
          return Promise.reject(err)
        BPromise.delay(RETRY_DELAY).then( -> wrappedFetch(--n))
      )
    wrappedFetch(MAX_RETRIES)

  ###*
   * Query the database
   * @param {[type]} view [description]
   * @return {Stream} A stream containing the results of the query.
  ###
  query: (options) =>
    {
      design
      endkey
      groupLevel
      includeDocs
      limit
      reduce
      startkey
      view
    } = options

    isAllDocs = false
    if design? and view?
      queryUrl = "#{@url}/_design/#{design}/_view/#{view}"
    else
      isAllDocs = true
      queryUrl = "#{@url}/_all_docs"

    queryUrl += buildQueryString(
      {startkey, endkey, limit, reduce, groupLevel, includeDocs}
    )
    output = JSONStream.parse('rows.*', (res) ->
      if isAllDocs and res.id[0] is '_'
        # all_docs queries include design docs, which is weird
        return null
      return res
    )
    BPromise.resolve(
      fetch(queryUrl, headers: @_getFetchOptions(), credentials: 'include')
    ).then(
      checkStatus
    ).then((response) ->
      response.body.pipe(output)
    ).catch((err) ->
      output.emit('error', err)
    ).done()
    return output

  ###*
   * Query the database
   * @return {Promise} A promise for the requested value
  ###
  queryOne: ({design, view, startkey, endkey, limit, reduce, groupLevel}) =>
    if view? and not design?
      return BPromise.reject(new Error('In order to use a view, you must pass
      the id of the design document that the view is a part of.'))

    if design? and view?
      queryUrl = "#{@url}/_design/#{design}/_view/#{view}"
      queryUrl += buildQueryString(
        {startkey, endkey, limit, reduce, groupLevel}
      )

    BPromise.resolve(
      fetch(queryUrl, headers: @_getFetchOptions(), credentials: 'include')
    ).then(
      checkStatus
    ).then((response) ->
      response.json()
    ).then(({rows}) ->
      if rows.length > 1
        throw new Error('query returned multiple rows')
      rows[0]
    )

  ###*
   * Send a request to the _bulk_docs endpoint.
   * @param {String} docBuffer A stringified array of docs
   * @return {Promise}
  ###
  _bulkDocs: (docs) =>
    fetch(
      "#{@url}/_bulk_docs"
      method: 'POST'
      body: "{\"docs\":#{docs}}"
      headers: @_getFetchOptions()
      credentials: 'include'
    ).then(
      checkStatus
    ).then((response) ->
      response.json()
    )

  ###*
   * @param {Number} [options.bufferSize=10000] The length of the buffer
     measured in chars. The buffer is built of stringified JSON documents, so
     this setting offers _rough_ control over the size of each request. We try
     to reach this buffer length before sending a request, but we will exceed it
     by up to `JSON.stringify(doc).length - 1` and the last request we send will
     be shorter. Increasing this will result in fewer requests, more memory
     usage, and (probably) faster throughput. Decreasing this will lower your
     time between requests (assuming a consistent stream speed), and reduce
     memory usage.
   * @return {DuplexStream} An objectMode stream that we can write documents to
     and read conflicts/errors from. Non-fatal errors (like conflicts) are
     emitted from the stream as objects because you can fix conflicts and
     resubmit the doc. Writing to this stream does not gaurentee that the
     document will be written to the DB. You need to make sure that the stream
     ends correctly or docs at the end could be lost.
  ###
  put: ({bufferSize} = {}) =>
    bufferSize ?= 10000
    buffer = ''
    flushBuffer = (cb, push) =>
      if buffer is '' then return cb()
      @_bulkDocs("[#{buffer}]").then((res) ->
        # it worked, clear out the buffer. if we ever decided to do concurrent
        # requests this part would have to change, but since we don't take in
        # any docs while the request is being made we can safely empty the
        # buffer here
        buffer = ''
        push(entry) for entry in res
        cb(null)
      ).catch((err) ->
        cb(err)
      )

    handleDoc = (doc, enc, cb) ->
      # we build up a string as we go to prevent the docs from being mutated &
      # because we would need to stringify it anyway before calling _bulkDocs
      doc = JSON.stringify(doc)
      buffer += if buffer is '' then doc else ",#{doc}"
      if buffer.length > bufferSize
        flushBuffer(cb, @push.bind(this))
      else
        cb()

    map(objectMode: true, handleDoc, (cb) -> flushBuffer(cb, @push.bind(this)))

  ###*
   * Post a single document to the database.
   * @param {Object} doc The document to post. `doc._id` cannot be defined
     because POST is used when you want CouchDB to create the id for you.
   * @return {Promise}
  ###
  postDoc: (doc) ->
    if doc._id?
      return BPromise.reject("You have passed a doc._id. Since you know the _id,
      you should use PUT, rather than POST.")

    BPromise.resolve(
      fetch(
        @url
        method: 'POST'
        body: JSON.stringify(doc)
        headers: @_getFetchOptions()
        credentials: 'include'
      )
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

module.exports = CouchDB
