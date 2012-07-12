# Represents the player state.
class Player extends RemoteModel
  chatter.register(@) # registers the model for unpacking

  # save an instruction
  @getMyChannelToken: RemoteModel.remoteStaticMethod 'getMyChannelToken'
  