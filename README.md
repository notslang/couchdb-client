# couchdb client

[![Build Status](http://img.shields.io/travis/slang800/slang-couchdb.svg?style=flat-square)](https://travis-ci.org/slang800/slang-couchdb) [![NPM version](http://img.shields.io/npm/v/slang-couchdb.svg?style=flat-square)](https://www.npmjs.org/package/slang-couchdb) [![NPM license](http://img.shields.io/npm/l/slang-couchdb.svg?style=flat-square)](https://www.npmjs.org/package/slang-couchdb)

## why?

There are a few other libraries, but nothing I liked. This is what I've done differently:

- Everything is handled through streams and promises.
- Authentication and retries are handled transparently by the client.
- Property naming matches JavaScript's style and is consistent. `_id` is the document id everywhere (including status messages) and snake_case names are corrected to camelCase.
- Optimize to make the fewest requests possible... tracking cookie timeouts to avoid retries, allowing you to specify if a conflict is likely to happen, and get the doc to apply your changes before attempting an update, using the `_bulk_docs` endpoint for post streams, and combining duplicate requests in get/head streams.

## install

CouchDB Client is an [npm](http://npmjs.org/package/slang-couchdb) package, so it can be installed into your project like this:

```bash
npm install slang-couchdb --save
```

## usage

If you want pretty printing, pipe the output into [jq](https://stedolan.github.io/jq/manual/).

## similar tools

- [couchdb-utils](https://github.com/awilliams/couchdb-utils)
- [futon (cli)](https://www.npmjs.com/package/futon)
