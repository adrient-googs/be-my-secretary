from google.appengine.ext import db
from google.appengine.api import users, channel
from chatter import RemoteModel, RemoteMethod, StructuredProperty, Channel
import logging

class Player(RemoteModel):
  user = db.UserProperty(required=True, auto_current_user_add=True)
  score = db.IntegerProperty(required=True, default=0)
  
  def getChannel(self):
    """Returns a channel for this player."""
    return Channel(str(self.key()))
  
  @classmethod
  def getCurrentPlayer(cls):
    current_user = users.get_current_user()
    current_player = Player.getByUser(current_user)
    if not current_player:
      current_player = Player()
      assert current_player.user == current_user
      current_player.put()
    return current_player
    
  @classmethod
  def getByUser(cls, user):
    """Returns a player object for this user."""
    return Player.all().filter('user =', user).get()
    
  @RemoteMethod(static=True, admin=False)
  def getMyChannelToken(cls):
    """Opens a channel associated with this player and returns a
    token for that channel."""
    current_player = Player.getCurrentPlayer()
    return channel.create_channel(str(current_player.key()))
    
  