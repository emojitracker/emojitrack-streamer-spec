################################################################################
# API specification test for the server.  This is to ease making sure things are
# consistent from an API perspective across different implementations of the
# Emojitrack streaming servers.
#
# This should be run AGAINST STAGING/PRODUCTION, not dev, since the routing
# layer will affect things.
#
# Set STREAM_SERVER env var to be equal to the proper server to test against.
################################################################################

url  = require('url')
http = require('http')
chai = require('chai')
chai.should()
expect = chai.expect

unless process.env.STREAM_SERVER?
  console.log "You need to set STREAM_SERVER so we know what to test against!"
  process.exit(1)
server = url.parse(process.env.STREAM_SERVER)

describe 'SUBSCRIBE endpoints', ->

  describe 'HEAD /subscribe/*', ->
    before ->
      @options = {method: 'HEAD', host: server.host, port: server.port, path: '/subscribe/eps'}

    it 'should close after sending headers, not remain open', (done) ->
      req = http.request @options, (res) =>
        @res = res
        done()
      req.end()
    it 'should send status code 200', ->
      @res.statusCode.should.equal 200
    it 'should set Content-Type: text/event-stream; charset=utf-8', ->
      expect(@res.headers['content-type']).to.equal 'text/event-stream;charset=utf-8'
    it 'should set Cache-Control: no-cache', ->
      expect(@res.headers['cache-control']).to.equal 'no-cache'
    it 'should set a proper keep-alive header', ->
      expect(@res.headers['connection']).to.equal 'keep-alive'
    it 'should set proper CORS headers', ->
      expect(@res.headers['access-control-allow-origin']).to.equal '*'


  describe 'GET /subscribe/raw', ->
    it 'should send properly formatted SSE messages'
    it 'should send messages without events'
    it 'each msg `data:` is just a unified codepoint ID'

  describe 'GET /subscribe/eps', ->
    it 'should send properly formatted SSE messages'
    it 'should send messages without events'
    it 'each msg `data:` should be a JSON key/value map of uid=>scoreIncrease'

  describe 'GET /subscribe/details/:id', ->
    it 'should send properly formatted SSE messages'
    it 'should send messages WITH event ids'
    it 'should include an event of format `stream.score_updates.ID`'
    it 'each msg `data:` should include a ensmallened JSON representation of matching tweet'

describe 'ADMIN endpoints', ->

  describe 'GET /admin/node.json', ->
    it 'should return a JSON representation of shit'
