BPromise = require 'bluebird'
JSONStream = require 'JSONStream'
from = require 'from2-array'
map = require 'through2'
pumpCb = require 'pump'

CouchDB = require '../database'
Server = require '../server'
{databaseListArg, humanReadableArg} = require './util'

command = 'stat'
pump = BPromise.promisify(pumpCb)

addCommand = (argparser) ->
  subcommand = argparser.addParser(
    command
    addHelp: true
    description: 'Print stats for each database.'
  )
  databaseListArg(subcommand)
  humanReadableArg(subcommand)

run = ({dbs, url}) ->
  pump(
    (
      if dbs is null
        (new Server(url)).list()
      else
        from(dbs)
    )
    map(objectMode: true, (db, enc, cb) ->
      (new CouchDB("#{url}/#{db}")).status().then((res) -> cb(null, res))
    )
    JSONStream.stringify('[', ',\n', ']\n')
    process.stdout
  )

module.exports = {addCommand, command, run}
