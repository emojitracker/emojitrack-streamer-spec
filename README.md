# emojitrack-streamer-spec

Attempt to define the API spec for emojitrack-streamer, and offer an acceptance test to be run against staging/production servers to verify they meet it.

Mainly useful as we experiment with different routing layers and with rewriting emojitrack-streamer on different platforms.


## Streaming API
All endpoints are normal HTTP connections, which emit EventSource/SSE formatted data.

CORS headers are set to `*` so anyone can play, please don't abuse the privilege.

_Note to hackers: if you just want to get some data out of emojitracker and don't need to stream realtime data, you are probably looking for the [normal web API](#TODO)._

### Endpoints
#### `/subscribe/eps`

Emits a JSON blob every 17ms (1/60th of a second) containing the unicode IDs that have incremented and the amount they have incremented.

Example:

    data:{'1F4C2':2,'2665':3,'2664':1,'1F65C':1}

If there have been no updates in that period, in lieu of an empty array, no message will be sent.  Therefore, do not rely on this for timing data.

#### `/subscribe/details/:id`

Get every single tweet that pertains to the emoji glyph represented by the unified `id`.

Example:

    event:stream.tweet_updates.2665
    data:{"id":"451196288952844288","text":"유졍여신에게 화유니가아~♥\n햇살을 담은 my only one\n그대인거죠 선물같은 사람 달콤한 꿈속\n주인공처럼 영원히 with you♥\nAll about-멜로디데이\n@GAEBUL_Chicken ♥ @shy1189\n화윤애끼미랑평생행쇼할텨~?♥\n#화융자트","screen_name":"snowflake_Du","name":"잠수탄✻눈꽃두준✻☆글확인","links":[],"profile_image_url":"http://pbs.twimg.com/profile_images/437227370248806400/aP0fFJOk_normal.jpeg","created_at":"2014-04-02T03:15:52+00:00"}

*** More information to go here.

#### `/subscribe/raw`

*** Description.

This endpoint can be disabled in configuration.

## Compliance testing

    $ STREAM_SERVER=http://host:port npm test
