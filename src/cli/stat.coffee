BPromise = require 'bluebird'
JSONStream = require 'JSONStream'
from = require 'from2-array'
map = require 'through2'
pumpCb = require 'pump'

CouchDB = require '../database'
Server = require '../server'
{databaseListArg, humanReadableArg} = require './util'
status = require '../status'

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
      status(new CouchDB("#{url}/#{db}")).then((res) ->
        cb(null, res)
      ).catch((err) ->
        cb(err)
      )
    )
    JSONStream.stringify('[', ',\n', ']\n')
    process.stdout
  )

module.exports = {addCommand, command, run}
