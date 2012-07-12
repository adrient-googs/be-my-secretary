"""Maintains a list of serializable objects as well as serialization / deserialization methods.

The basic format for a payload is: [type_name, data].

"""

import types
import logging
from google.appengine.ext import db
from google.appengine.api import users
from google.appengine.api.datastore_types import Text as appengine_text_type

__all__ = ['wrap', 'unwrap', 'register']

def wrap(obj):
  """Serializes Python object into a JSON object."""
  try:
    return __wrap_table[type(obj)](obj)
  except KeyError:
    raise RuntimeError, (
      'Type "%s" not registered. '
      'Use chatter.register() to register new types for serialization.'
    ) % type(obj).__name__
  
def unwrap(obj):
  """Deserializes a JSON object into a python object."""
  type_name, data = obj
  try:
    return __unwrap_table[type_name](data)
  except KeyError:
    logging.error("ERROR UNWRAPPING: '%s'" % repr(obj))
    raise RuntimeError, (
      'Type "%s" not registered. '
      'Use chatter.register() to register new types for serialization.'
    ) % type_name
  
__wrap_table   = {} # maps types to wrapping function
__unwrap_table = {} # maps type_names to unwrapping function
  
def register(serializable_type, wrap_func, unwrap_func):
  """Registers a type for serialization and deserialization."""
  # adds type information to the object serialization
  type_name = serializable_type.__name__
  typed_wrap = lambda obj: [type_name, wrap_func(obj)]

  # update the wrap table to serialize this type
  __wrap_table[serializable_type] = typed_wrap
  __unwrap_table[type_name] = unwrap_func
  
def registerCast(serializable_type, cast_to, conversion_func=None):
  """Registers a class which should be cast to a simpler type. For
  example, keys are mapped to strings."""
  type_name = cast_to.__name__
  if conversion_func == None:
    conversion_func = cast_to
  typed_wrap = lambda obj: [type_name, conversion_func(obj)]
  
  # update only the wrap table
  __wrap_table[serializable_type] = typed_wrap

# identity function
__identity = lambda x: x

# register a bunch of primitive types
register(int, __identity, int)
register(long, __identity, long)
register(str, __identity, str)
register(unicode, __identity, unicode)
register(bool, __identity, bool)
register(float, __identity, float)
register(list,
  lambda python_list: [wrap(x) for x in python_list],
  lambda json_list: [unwrap(x) for x in json_list])
register(dict,
  lambda python_dict: wrap(map(list, python_dict.items())),
  lambda json_dict: dict(unwrap(json_dict)))
register(types.NoneType,
  lambda python_None: '',
  lambda json_none: None)
registerCast(db.Key, str)
registerCast(users.User, str, lambda u: str(u.nickname()))