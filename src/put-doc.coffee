BPromise = require 'bluebird'
isEqual = require 'lodash/isEqual'

getDoc = require './get-doc'
{checkDoc, getRequestId} = require './util'

###*
 * @param {Object} doc
 * @param {Function} options.resolveConflict
 * @param {Boolean} options.assumeConflict Assume that there will be a
   conflict (like the document already existing & `doc._rev` not being
   passed). In this case we don't try to do a PUT right from the start - we
   do a GET and then run the resolveConflict function on that. This saves us 1
   HTTP request if we're correct about it not existing, or it costs us one if
   we're wrong.
 * @return {Promise}
###
putDoc = (db, doc, {resolveConflict, assumeConflict} = {}) ->
  checkDoc(doc)
  assumeConflict ?= false
  {_id, _rev} = doc
  if not _id?
    return BPromise.reject('You need to define doc._id to use PUT. To have
    CouchDB generate an id for you, use POST.')
  if assumeConflict and not resolveConflict?
    return BPromise.reject('You must define a resolveConflict function if you
    are going to use `assumeConflict: true`.')
  if assumeConflict and _id is '_security'
    return BPromise.reject('The `_security` document is not a versioned doc,
    so there is no need to use `assumeConflict: true`')

  handleResolution = (resolution) ->
    if resolution isnt false
      # prevent these properties from being modified
      resolution._id = _id
      resolution._rev = _rev
      putDoc(db, resolution, {resolveConflict})
    else
      return {updated: false, _rev}

  if assumeConflict
    getDoc(db, _id).then((response) ->
      oldDoc = response.doc
      {_rev} = oldDoc
      delete oldDoc._rev # remove temporarily for equality test
      if isEqual(oldDoc, doc)
        # no update to be made
        false
      else
        oldDoc._rev = _rev
        resolveConflict(oldDoc, doc)
    ).then(
      handleResolution
    ).catch((err) ->
      if err.response?.status isnt 404 then throw err
      # we were wrong with `assumeConflict: true`, try again with false
      putDoc(db, doc, {resolveConflict})
    )
  else
    requestId = undefined
    db._fetch(
      encodeURIComponent(_id)
      method: 'PUT'
      body: JSON.stringify(doc)
    ).then((response) ->
      requestId = getRequestId(response)
      response.json()
    ).then((response) ->
      {updated: true, _rev: response.rev, requestId}
    ).catch((err) ->
      if err.response?.status is 409
        # we were wrong with `assumeConflict: false`, or the doc changed on the
        # server before we could update it. try to run `resolveConflict` and
        # re-post the doc
        if resolveConflict?
          putDoc(doc, {resolveConflict, assumeConflict: true})
        else
          # we can't resolve the conflict, give up
          {updated: false, requestId: getRequestId(err.response)}
      else
        throw err
    )

module.exports = putDoc
