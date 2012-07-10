from google.appengine.ext import db
from chatter import RemoteModel, RemoteMethod, FloatProperty
import logging

class CalEvent(RemoteModel):
  """A calendar event. We subclass RemoteModel only for
  serialization purposes, but these are never actually stored."""
  
  day = db.IntegerProperty(required=True)
  time = FloatProperty(required=True)
  length = FloatProperty(required=True)
  name = db.StringProperty(required=True)
  title = db.StringProperty(required=True)
    
  properties_to_wrap = {'day', 'time', 'length', 'name', 'title'}

  def put(self):
    """Throws an exception to prevent this class from ever actually
    being written to the database."""
    raise RuntimeError, 'CalEvents cannot directly be stored. ' \
      '(They must be stored through a Calendar.)'