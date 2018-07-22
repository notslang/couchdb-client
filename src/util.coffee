pickBy = require 'lodash/pickBy'
queryString = require 'querystring'

DB_NAME_RE = /^[a-z][a-z0-9_$()+/-]*$/

buildQueryString = (options) ->
  {
    _rev
    batch
    endkey
    groupLevel
    includeDocs
    keys
    limit
    reads
    replicas
    shards
    stale
    startkey
    writes
  } = options
  searchObject = {limit}

  if reads? then searchObject.r = reads
  if writes? then searchObject.w = writes

  if replicas? then searchObject.n = replicas
  if shards? then searchObject.q = shards

  if _rev? then searchObject.rev = _rev
  if groupLevel? then searchObject['group_level'] = groupLevel

  # only include if it doesn't match the default
  if includeDocs is true then searchObject['include_docs'] = true
  if stale is true then searchObject.stale = 'ok'
  if batch is true then searchObject.batch = 'ok'

  if keys? and Array.isArray(keys)
    if keys.length is 1
      searchObject.key =  JSON.stringify keys[0]
    else
      searchObject.keys = JSON.stringify keys

  if endkey? and Array.isArray(endkey)
    searchObject.endkey = JSON.stringify endkey

  if startkey? and Array.isArray(startkey)
    searchObject.startkey = JSON.stringify startkey

  # remove undefined vars because `queryString.stringify` doesn't like them
  searchObject = pickBy(searchObject, (value) -> value?)
  if Object.keys(searchObject).length > 0
    '?' + queryString.stringify(searchObject)
  else
    ''

###*
 * Check the given document for simple mistakes before sending to the server
 * @param {Object} doc
 * @return {undefined} No return value, only response will be a thrown Error
###
checkDoc = (doc) ->
  # TODO: add regex for document _id
  if doc._id? and typeof doc._id isnt 'string'
    throw new TypeError("doc._id must be a string")

checkStatus = (response) ->
  if response.status >= 200 and response.status < 300
    return response
  else
    error = new Error(response.statusText)
    error.response = response
    throw error

fixResponseStatus = (response) ->
  # this property is useless, we have a status code right in the headers
  delete response.ok

  response._id = response.id
  delete response.id

  if response.rev?
    response._rev = response.rev
    delete response.rev
  if response.error is 'conflict' and
     response.reason is 'Document update conflict.'
    delete response.reason
  return response

getRequestId = ({headers}) -> headers.get('x-couch-request-id')

module.exports = {
  DB_NAME_RE
  buildQueryString
  checkDoc
  checkStatus
  fixResponseStatus
  getRequestId
}
