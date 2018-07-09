# Emojitracker Streaming API :dizzy:

Defines the API spec for the Emojitracker Streaming API, and offer an acceptance
test to be run against staging/production servers to verify they meet it.

## Stream API Specifications

All endpoints are normal HTTP connections, which emit EventSource/SSE formatted
data.

CORS headers are set to `*` so anyone can play, please don't abuse the
privilege.

### When to use the Streaming API

In general, use the [REST API][rest-api] to build an initial snapshot state for
a page (or get a one-time use data grab), then use the Streaming API to keep it
up to date.

Do not repeatedly poll the REST API.  It is intentionally aggressively cached in
such a way to discourage this, in that the scores will only update at a lower
rate (a few times per minute), meaning you _have_ to use the Streaming API to
get fast realtime data updates.

(Note that this is a design decision, not a server performance issue.)

[rest-api]: https://github.com/emojitracker/emojitrack-rest-api

### Working with Server Sent Events

SSE is pretty magic. All that talk you've heard of WebSockets? Well they're
great for bidirectional data, but for unidirectional data flow, SSE/EventSource
is your new best friend.

["Stream Updates with Server Sent Events"][1] by Eric Bidleman from 2010 is
still one of the best introductions to SSE in general, and how it compares to
WebSockets.

> SSEs are sent over traditional HTTP. That means they do not require a special
> protocol or server implementation to get working. WebSockets on the other
> hand, require full-duplex connections and new Web Socket servers to handle the
> protocol. In addition, Server-Sent Events have a variety of features that
> WebSockets lack by design such as automatic reconnection, event IDs, and the
> ability to send arbitrary events.

[1]: https://www.html5rocks.com/en/tutorials/eventsource/basics/

The Emojitracker Streaming API takes advantage of many of these things. Notably,
unlike the opaque binary format for Websockets, you you can simply curl any
Emojitracker Streaming API endpoint and read the results with your own eyes.

Try it! It's as simple as `curl https://stream.emojitracker.com/eps`.

Now say you want to hook into this with JavaScript? For the most part you
can just let the browser's built-in support handle everything for you:

```js
const endpoint = "https://stream.emojitracker.com";
let evsource = new EventSource(`${endpoint}/subscribe/eps`);
evsource.onmessage = function(event) {
    console.log(`Received a data update: ${event.data}`);
}
```

You automatically get things like reconnection on disconnect, with zero
libraries required.

Some other helpful references on SSE/EventSource:

- [MDN: Using Server-Sent Events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events)
- [MDN: EventSource](https://developer.mozilla.org/en-US/docs/Web/API/EventSource)


### Streaming API Endpoints

Production endpoint is: `https://stream.emojitracker.com`. All Streaming API
endpoints adhere to the _Server Sent Events_ standard. The Emojitracker Streaming
API endpoint is not currently versioned, so there are as of yet no guarantees
against breaking changes (but we try to be reasonable).

#### `/subscribe/eps`

Emits a JSON blob every 17ms (1/60th of a second) containing the unicode IDs
that have incremented and the amount they have incremented during that period.

Example:

    data:{'1F4C2':2,'2665':3,'2664':1,'1F65C':1}

If there have been no updates in that period, in lieu of an empty array, no
message will be sent.  Therefore, do not rely on this for timing data.

Sample usage (ES6 Javascript):

```js
const endpoint = "https://stream.emojitracker.com";
let evsource = new EventSource(`${endpoint}/subscribe/eps`);
evsource.onmessage = function(event) {
    const updates = JSON.parse(event.data);
    for (const [k, v] of Object.entries(updates)) {
        console.log(`Emoji with id ${k} got score increase of ${v}`);
    }
}
```

#### `/subscribe/details/:id`

Get every single tweet as it happens that pertains to the emoji glyph
represented by the unified `id`.

The tweets are "ensmallened" and contain only the absolute minimum amount of
information needed to re-construct the visual display of the tweet without
additional API calls to Twitter (for example, the tweet URL is omitted as it can
easily be reconstructed on the client side using only the screen_name and tweet
ID number).

Example:

    event:stream.tweet_updates.2665
    data:{"id":"451196288952844288","text":"유졍여신에게 화유니가아~♥\n햇살을 담은 my only one\n그대인거죠 선물같은 사람 달콤한 꿈속\n주인공처럼 영원히 with you♥\nAll about-멜로디데이\n@GAEBUL_Chicken ♥ @shy1189\n화윤애끼미랑평생행쇼할텨~?♥\n#화융자트","screen_name":"snowflake_Du","name":"잠수탄✻눈꽃두준✻☆글확인","links":[],"profile_image_url":"http://pbs.twimg.com/profile_images/437227370248806400/aP0fFJOk_normal.jpeg","created_at":"2014-04-02T03:15:52+00:00"}

The SSE "event" field is set with with the namespace, so that you can easily
bind to it in Javascript with the built-in EventSource.

Sample usage (ES6 Javascript):

```js
// logs all tweets containing 🍑 in realtime
const endpoint = "https://stream.emojitracker.com";
let evsource = new EventSource(`${endpoint}/subscribe/details/1F351`);
evsource.addEventListener("stream.tweet_updates.1F351", event => {
    update = JSON.parse(event.data);
    console.log(`${update.name} tweeted: ${update.text}`);
});
```

## Server/Endpoint Development

### Streaming API Endpoints

The current production implementation of the Emojitracker Streaming API
endpoints is handled by [emojitrack-gostreamer]. Go there if you are looking to
hack on the implementation details.

[emojitrack-gostreamer]: https://github.com/emojitracker/emojitrack-gostreamer

(There were also Ruby and NodeJS implementations, now deprecated.)

### Compliance Testing

There are some (incomplete) integration tests to verify a Streaing API endpoint
server in staging/production, including more detail about HTTP headers, etc.

This was mainly useful as we experiment with different routing layers and with
rewriting emojitrack-streamer on different platforms.

    $ STREAM_SERVER=http://host:port npm test
