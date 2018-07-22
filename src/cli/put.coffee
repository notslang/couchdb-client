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
  subcommand.addArgument(
    ['--buffer-size']
    dest: 'bufferSize'
    metavar: 'CHARS'
    help: 'The length of the buffer measured in chars. The buffer is built of
    stringified JSON documents, so this setting offers _rough_ control over the
    size of each request. We try to reach this buffer length before sending a
    request, but we will exceed it by up to `JSON.stringify(doc).length - 1`
    and the last request we send will be shorter. Increasing this will result in
    fewer requests, more memory usage, and (probably) faster throughput.
    Decreasing this will lower your time between requests (assuming a consistent
    stream speed), and reduce memory usage.'
    defaultValue: 10000
  )

run = ({db, url, bufferSize}) ->
  pump(
    process.stdin
    JSONStream.parse()
    (new CouchDB("#{url}/#{db}")).put(bufferSize)
    JSONStream.stringify('[', ',\n', ']\n')
    process.stdout
  )

module.exports = {addCommand, command, run}
