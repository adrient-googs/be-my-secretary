import types
import json
import chatter
from google.appengine.ext import db
from google.appengine.api.datastore_types import Text as text_type

class StructuredProperty(db.TextProperty):
  """Looks like a chatter (JSON) object, but maps transparently down to an AppEngine
  TextProperty for storage."""

  # the data type can be anything that could be in JSON
  data_type = (int, long, str, unicode, float, list, dict, bool, types.NoneType)
  
  def __init__(self, *args, **kwargs):
    db.TextProperty.__init__(self, *args, **kwargs)
  
  def __get__(self, instance, owner):
    # special case for static call
    if instance == None:
      return self
    # otherwise, load the string and convert it to a JSON object
    text = db.TextProperty.__get__(self, instance, owner)
    return chatter.unwrap(json.loads(text))

  def __set__(self, instance, value):
    # convert the json object to a string and save it
    text = json.dumps(chatter.wrap(value))
    db.TextProperty.__set__(self, instance, text)
    
  def get_value_for_datastore(self, container):
    # NOTE: Probably could also do...
    # return db.TextProperty.get_value_for_datastore(self, container)
    return text_type(db.TextProperty.__get__(self, container, None))
