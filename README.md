# Colloquy Push API
API docs for handling registration for, and using, Colloquy's Push API.

## Push API: Colloquy to Bouncer
### When Push Is Enabled
Colloquy will send a series of commands when connecting to a bouncer and push is enabled. These commands can be intercepted by any bouncer and use our API to send push notifications.

```
PUSH add-device [device-token] :[device-name]
PUSH service colloquy.mobi 7906
PUSH connection [connection-id] :[connection-name]
PUSH highlight-word :[highlight-word]
PUSH highlight-sound :[sound-name]
PUSH message-sound :[sound-name]
PUSH end-device
```

### If Push Is Disabled
When push is disabled for a connection, Colloquy will send a single command to remove the device. This is the bouncer’s cue to stop sending push notifications.

```
PUSH remove-device [device-token]
```

## Push API: Bouncer to Colloquy Push Server
The server protocol is [JSON](http://json.org/) over an SSL connection to colloquy.mobi over port 7906. An example push looks somthing like this:
```javascript
{
  "device-token": "abcdef123456789…",
  "message": "kiji: Hello!",
  "sender": "jane",
  "room": "#colloquy-mobile",
  "server": "irc.freenode.net",
  "badge": 1,
  "sound": "Beep 1.aiff"
}
```

The server will take care of formatting the message (emoji substitution, etc.) and making sure it is truncated to fit Apple's push notification character limit of 2048 bytes.

The `message`, `sender`, `room`, `server`, `badge` and `sound` fields are all optional, and may be omitted as required by the message being sent, or desired by someone's settings.

To reset the badge, for example, if multiple clients are connected to a bouncer and activity comes in from one of them, you may send a push notification with the badge count of 0:
```javascript
{
  "device-token": "abcdef123456789…",
  "badge": 1,
}
```

The Colloquy push server does not acccept connections over unsafe SSL protocols, such as [SSLv2](https://drownattack.com).

## Implementations
- [Colloquy](http://colloquy.info)'s built-in bouncer
- The [reference implementation](perl-reference-implementation/ColloquyPush.pm) we provide in, in Perl
- The [colloquypush](https://github.com/colloquy/colloquypush) plugin for [ZNC](http://wiki.znc.in/ZNC)
- A [script](http://static.ssji.net/colloquy_push.pl.txt) for [irssi](https://irssi.org)

## Further Help
Please stop by our IRC channel, [irc://chat.freenode.com/colloquy-mobile](irc://chat.freenode.com/colloquy-mobile), or file on our [trac](http://colloquy.info/?bug).
