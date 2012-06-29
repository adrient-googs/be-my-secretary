"""Wrapper around the appengine channel method. Allows named method calls."""

import json
import chatter
from google.appengine.api import channel

class Channel(object):
  def __init__(self, client_id):
    self.client_id = client_id
  
  def __getattr__(self, name):
    """A function call invoked on this object will be routed to the
    client using the chatter protocol."""
    def func_stub(**kwargs):
      msg = json.dumps(chatter.wrap([name, kwargs]))
      channel.send_message(self.client_id, msg)
    return func_stub
