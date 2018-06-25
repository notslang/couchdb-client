REPLICATION_STATS_NAME_MAP = require './replication-stats-name-map'

DB_NOT_FOUND_RE = /^db_not_found: /

getReplicationStatus = (db, id) ->
  @replicatorDB.getDoc(id).then((res) ->
    status =
      _id: res._id
      _rev: res._rev
      replicationState: res['_replication_state']
      replicationStateTime: res['_replication_state_time']
      replicationId: res['_replication_id']

    if status.replicationState is 'completed'
      for newName, oldName of REPLICATION_STATS_NAME_MAP
        status[newName] = res['_replication_stats'][oldName]
      status.replicationStateTime = new Date(status.replicationStateTime)
    else if status.replicationState is 'error'
      message = res['_replication_state_reason']
      if DB_NOT_FOUND_RE.test(message)
        throw new Error(message.replace(DB_NOT_FOUND_RE, ''))
      else
        throw new Error(message)
    else if status.replicationState? and
            status.replicationState isnt 'triggered'
      throw new Error(
        "Unknown replication state: '#{status.replicationState}'"
      )
    return status
  )

pollTillReplicationCompleted = (db, id, timeStarted) ->
  currentTime = (new Date()).getTime()
  timeStarted ?= currentTime
  @getReplicationStatus(id).then((status) =>
    if not status.replicationState? and timeStarted - currentTime > 5 * 1000
      throw new Error('Replication has not been triggered after 5 seconds of
      waiting. Check the _replication database for another replication job
      that may be preventing this one from being started.')

    if status.replicationState is 'completed'
      status
    else
      BPromise.delay(
        if timeStarted - currentTime < 10 * 1000
          500
        else
          2000
      ).then(
        @pollTillReplicationCompleted.bind(this, id, timeStarted)
      )
  )

replicate = (db, {target, source, createTarget}) ->
  createTarget ?= false
  if target? and source?
    return BPromise.reject(
      'setting both target and source isn\'t supported yet'
    )

  if not target? and not source?
    return BPromise.reject(
      'you must set either target or source with a CouchDB object'
    )

  jobDoc = {target, source}
  jobDoc['create_target'] = createTarget
  jobDoc['user_ctx'] = {roles: ['_admin']}

  # if either target or source is omitted, then we assume that this database
  # is the omitted field.
  if jobDoc.target?
    jobDoc.source = @dbName
  else
    jobDoc.target = @dbName

  stats = undefined
  @replicatorDB.postDoc(jobDoc).then((res) =>
    @pollTillReplicationCompleted(res._id)
  ).then((statsObj) =>
    stats = statsObj
    @replicatorDB.removeDoc(stats._id, stats._rev)
  ).then( ->
    stats
  )

module.exports = {getReplicationStatus, replicate}
