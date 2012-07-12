from google.appengine.ext import db
from google.appengine.api import users
from chatter import RemoteModel, RemoteMethod, StructuredProperty, Channel
import logging

class Player(db.Model):
  user = db.UserProperty(required=True, auto_current_user_add=True)
  score = db.IntegerProperty(required=True, default=0)
  
  @classmethod
  def getCurrentPlayer(cls):
    current_user = users.get_current_user()
    current_player = Player.all().filter('user =', current_user).get()
    if not current_player:
      current_player = Player()
      assert current_player.user == current_user
      current_player.put()
    return current_player
  