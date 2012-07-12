# Wrapper around Appengine Channel Functionality #

###
  Opens a channel to the server and delegates message calls to the
  delegate object.
###
openChannel = (token, delegate) ->
  channel = new goog.appengine.Channel token
  channel.open
    onopen:              -> delegate.channel_open?()
    onclose:             -> delegate.channel_close?()
    onerror: (args...)   -> delegate.channel_error?(args...)
    onmessage: (message) ->
      [method, args] = chatter.unwrap(JSON.parse(message.data))
      console.log 'ONMESSAGE'
      console.log method
      console.log args
      console.log _.keys(delegate)
      delegate[method](args)
