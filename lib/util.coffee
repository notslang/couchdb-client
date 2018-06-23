pickBy = require 'lodash/pickBy'
queryString = require 'querystring'

buildQueryString = (options) ->
  if options.groupLevel?
    options['group_level'] = options.groupLevel
    delete options.groupLevel

  if options.includeDocs?
    options['include_docs'] = options.includeDocs
    delete options.includeDocs

  if Array.isArray(options.endkey)
    options.endkey = JSON.stringify(options.endkey)

  if Array.isArray(options.startkey)
    options.startkey = JSON.stringify(options.startkey)

  # remove undefined vars because `queryString.stringify` doesn't like them
  options = pickBy(options, (value) -> value?)
  if Object.keys(options).length > 0
    '?' + queryString.stringify(options)
  else
    ''

checkStatus = (response) ->
  if response.status >= 200 and response.status < 300
    return response
  else
    error = new Error(response.statusText)
    error.response = response
    throw error

getRequestId = ({headers}) -> headers.get('x-couch-request-id')

module.exports = {buildQueryString, checkStatus, getRequestId}
