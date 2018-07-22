databaseArg = (parser) ->
  parser.addArgument(
    'db'
    help: 'The name of the database to use.'
    metavar: 'DATABASE'
  )

databaseListArg = (parser) ->
  parser.addArgument(
    'dbs'
    help: 'The name(s) of the database(s) to use. If omitted, all databases will
    be used.'
    metavar: 'DATABASE'
    nargs: '+'
  )

handlePromisedJson = (res) ->
  console.log(JSON.stringify(res))

humanReadableArg = (parser) ->
  parser.addArgument(
    ['-b', '--bytes']
    action: 'storeTrue'
    defaultValue: false
    help: 'Print sizes in bytes, rather than human readable formats'
  )

module.exports = {
  databaseArg
  databaseListArg
  handlePromisedJson
  humanReadableArg
}
