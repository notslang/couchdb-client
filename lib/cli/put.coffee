BPromise = require 'bluebird'
JSONStream = require 'JSONStream'
pumpCb = require 'pump'

CouchDB = require '../database'
{databaseArg} = require './util'

command = 'put'
pump = BPromise.promisify(pumpCb)

addCommand = (argparser) ->
  subcommand = argparser.addParser(
    command
    addHelp: true
    description: 'Reads JSON documents from STDIN and put them in the database'
  )
  databaseArg(subcommand)

run = ({dbs, url}) ->
  #BPromise.map(dbs, (db) ->
  #  (new CouchDB("#{url}/#{db}")).createDatabase()
  #)

module.exports = {addCommand, command, run}
