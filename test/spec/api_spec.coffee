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
request = require('supertest')
EventSource = require('eventsource')

unless process.env.STREAM_SERVER?
  console.log "You need to set STREAM_SERVER so we know what to test against!"
  process.exit(1)
server = url.parse(process.env.STREAM_SERVER)
request = request(server.hostname)

describe 'SUBSCRIBE endpoints', ->

  describe 'HEAD /subscribe/*', ->
    before ->
      @options = {method: 'HEAD', host: server.hostname, port: server.port, path: '/subscribe/eps'}

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
    before ->
      url = server.href + 'subscribe/raw'
      @es = new EventSource(url)
    it 'should get a message back', (done) ->
      @es.onmessage = (e) =>
        @msg = e
        @es.close()
        done()

    it 'should send properly formatted SSE messages'
    it 'should send messages WITH a data field', ->
      expect(@msg.data).to.not.be.undefined
    it 'should send messages WITHOUT an event field'
    it 'should send messages WITHOUT an ID field'
    it 'each msg `data:` should contain a unified codepoint ID'

  describe 'GET /subscribe/eps', ->
    before ->
      url = server.href + 'subscribe/eps'
      @es = new EventSource(url)
    it 'should get a normal data message back', (done) ->
      @es.onmessage = (e) =>
        @msg = e
        @es.close()
        done()

    it 'should send properly formatted SSE messages'
    it 'should send messages WITH a data field', ->
      expect(@msg.data).to.not.be.undefined
    it 'should send messages WITHOUT an event field'
    it 'should send messages WITHOUT an ID field'
    it 'each msg `data:` should be a JSON key/value map of uid=>scoreIncrease'

  describe 'GET /subscribe/details/:id', ->
    before ->
      url = server.href + 'subscribe/details/2665'
      @es = new EventSource(url)
    it 'should get an event scoped message back', (done) ->
      @es.addEventListener 'stream.tweet_updates.2665', (e) =>
        @msg = e
        @es.close()
        done()

    it 'should send properly formatted SSE messages'
    it 'should send messages WITH a data field', ->
      expect(@msg.data).to.not.be.undefined
    it 'should send messages WITH an event field'
    it 'should send messages WITHOUT an ID field'
    it 'should include an event of format `stream.tweet_updates.ID`'
    it 'each msg `data:` should include a ensmallened JSON representation of matching tweet'

describe 'ADMIN endpoints', ->

  # describe 'GET /admin/node.json', ->
  #   before ->
  #     @nudez = {method: 'GET', host: server.hostname, port: server.port, path: '/subscribe/admin/node.json'}
  #
  #   it 'should return results', (done) ->
  #     req = http.request @nudez, (res) =>
  #       @res2 = res
  #       done()
  #     req.end
  #   it 'should send utf-8 encoded JSON', ->
  #     expect(@res2.headers['content-type']).to.equal 'application/json'
  #     expect(@res2.headers['content-type']).to.equal 'charset=utf8'
