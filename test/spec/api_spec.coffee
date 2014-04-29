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

Error.stackTraceLimit = 0

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
    it 'MUST send status code 200', ->
      @res.statusCode.should.equal 200
    it 'SHOULD set Content-Type: text/event-stream; charset=utf-8', ->
      expect(@res.headers['content-type']).to.match /text\/event-stream;\s?charset=utf-8/
    it 'SHOULD set Cache-Control: no-cache', ->
      expect(@res.headers['cache-control']).to.equal 'no-cache'
    it 'SHOULD set a proper keep-alive header', ->
      expect(@res.headers['connection']).to.equal 'keep-alive'
    it 'SHOULD set proper CORS headers', ->
      expect(@res.headers['access-control-allow-origin']).to.equal '*'


  describe 'GET /subscribe/raw', ->
    before ->
      url = server.href + 'subscribe/raw'
      @es = new EventSource(url)
    it 'should get a normal data message back', (done) ->
      @es.onmessage = (e) =>
        @msg = e
        @es.close()
        done()

    # all of this block is meaningless if testing from the eventsource-node event
    describe 'wirespec details', ->
      it 'MUST send properly formatted SSE messages'
      it 'MUST send messages WITH a data field'
      it 'SHOULD send messages WITHOUT an event field'
      it 'SHOULD send messages WITHOUT an ID field'

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

    # all of this block is meaningless if testing from the eventsource-node event
    describe 'wirespec details', ->
      it 'MUST send properly formatted SSE messages'
      it 'MUST send messages WITH a data field'
      it 'SHOULD send messages WITHOUT an event field'
      it 'SHOULD send messages WITHOUT an ID field'

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
      @es.onmessage = (e) =>
        # if eventsource-node returns a normal message, it means it got something
        # without an event field.
        @es.close()
        done(new Error('got a message without an event field'))


    # all of this block is meaningless if testing from the eventsource-node event
    describe 'wirespec details', ->
      it 'MUST send properly formatted SSE messages'
      it 'MUST send messages WITH a data field'
      it 'SHOULD send messages WITH an event field'
      it 'SHOULD send messages WITHOUT an ID field'

    it 'should include an event of format `stream.tweet_updates.ID`'
    it 'each msg `data:` should include a ensmallened JSON representation of matching tweet'

describe 'ADMIN endpoints', ->

  describe 'GET /admin/node.json', ->
    before (done) ->
      @nodez = {
        method: 'GET',
        host: server.hostname,
        port: server.port,
        path: '/admin/status.json'
      }

      #make SSE connection so we are guaranted at least one active conn in pool
      url = server.href + 'subscribe/details/1F680'
      @es = new EventSource(url)
      @es.onopen = -> done()

    after ->
      # clean up after ourselves and close the eventsource connection
      @es.close()

    it 'MUST return results', (done) ->
      req = http.get @nodez, (res) =>
        @res = res
        @body = ""
        res.on 'data', (chunk) =>
          @body += chunk
        res.on 'end', =>
          done()

    it 'SHOULD set content-type as JSON', ->
      expect(@res.headers['content-type']).to.match /application\/json/

    describe 'status message body', ->
      it 'MUST be valid parseable JSON', ->
        @doc = JSON.parse(@body)
      it 'MUST report the node name', ->
        expect(@doc.node).to.be.a 'String'
        expect(@doc.node).to.match /^\w+-\w+-\w+\.\d+$/
      it 'SHOULD contain a status field and be OK', ->
        expect(@doc.status).to.equal "OK"
      it 'SHOULD contain a Unix timestamp of the report', ->
        expect(@doc.reported_at).to.be.a 'Number'
      it 'MUST contain an array of active connections', ->
        expect(@doc.connections).to.be.a 'Array'
      describe 'connection pool status', ->
        before ->
          @c = @doc.connections[0]
        it 'MUST contain a request_path', ->
          expect(@c.request_path).to.be.a 'String'
        it 'MUST contain a namespace', ->
          expect(@c.namespace).to.be.a 'String'
        it 'MAY contain a `tag` field (DEPRECATED)'
        it 'MUST contain a created_at as valid Unix timestamp', ->
          expect(@c.created_at).to.be.a 'Number'
        it 'MAY contain an age field in seconds (DEPRECATED)'
        it 'SHOULD contain the client_ip', ->
          expect(@c.client_ip).to.be.a 'String'
        it 'SHOULD contain the user_agent', ->
          expect(@c.user_agent).to.be.a 'String'
