from google.appengine.ext import db

class FloatProperty(db.FloatProperty):
  """Like db.FloatProperty, but accepts ints and longs as well."""

  # the data type can be anything that could be in JSON
  data_type = (int, long, float)
  
  def __init__(self, *args, **kwargs):
    db.FloatProperty.__init__(self, *args, **kwargs)
  
  def __get__(self, instance, owner):
    # special case for static call
    if instance == None:
      return self
    # otherwise, return the internal value
    return db.FloatProperty.__get__(self, instance, owner)

  def __set__(self, instance, value):
    # convert the json object to a string and save it
    db.FloatProperty.__set__(self, instance, float(value))
    
  def get_value_for_datastore(self, container):
    # let's see what happens here
    return db.FloatProperty.__get__(self, container, None)
    