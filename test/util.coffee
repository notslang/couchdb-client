{buildQueryString} = require '../lib/util'

describe 'buildQueryString', ->
  it 'should convert camelCased names', ->
    buildQueryString(limit: 10).should.equal('?limit=10')
    buildQueryString(includeDocs: true).should.equal('?include_docs=true')
    buildQueryString(groupLevel: 2).should.equal('?group_level=2')
