BPromise = require 'bluebird'

CouchDB = require '../database'
destroy = require '../destroy'

command = 'rmdb'

addCommand = (argparser) ->
  subcommand = argparser.addParser(
    command
    addHelp: true
    description: 'Create one or more databases.'
  )
  subcommand.addArgument(
    'dbs'
    help: 'The name(s) of the database(s) to destroy.'
    metavar: 'DATABASE'
    nargs: '+'
  )
  subcommand.addArgument(
    ['--error-if-missing']
    action: 'storeTrue'
    dest: 'errorIfMissing'
    help: 'Don\'t ignore the database already being gone.'
  )

run = ({dbs, url, errorIfMissing}) ->
  BPromise.map(dbs, (dbName) ->
    db = new CouchDB("#{url}/#{dbName}")
    destroy(db, {errorIfMissing})
  )

module.exports = {addCommand, command, run}
