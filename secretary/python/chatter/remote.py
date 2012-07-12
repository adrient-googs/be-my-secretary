"""Basically inclues two big concepts:

RemoteMethod - a function dectorator to enable remove invoation
RemoteModel - a model which can be called on-line
"""

import webapp2
import logging
import json
import inspect
import traceback
import types
from google.appengine.ext import db
from google.appengine.api import users

# chatter classes
from structuredProperty import StructuredProperty
import chatter

__all__ = ['RemoteException', 'RemoteMethod', 'RemoteModel', 'getAllRemoteHandlers']

class RemoteException(Exception):
  """Can be called to set an http status code."""
  def __init__(self, error_code, msg):
    Exception.__init__(self, msg)
    self.error_code = error_code

class RemoteMethod(object):
  """
  Function decorator allowing remote invocation.
  """
  def __init__(self, static=False, admin=True):
    """
    Constructor.
    
    static     - the method should be treated as a classmethod
    admin      - only admins can access this mehtod
    """
    self.static = static
    self.admin = admin
  
  def __call__(self, method):
    """Binds the method."""
    self.method = method
    return self
    
  def getMethod(self, model):
    """Returns an instance method which wraps the underling function."""
    if self.static:
      return types.MethodType(self.method, model)
    else:
      return self.method
    
  def getHandler(self, model):
    """Returns a (url, RequestHandler) pair for remote invocation."""
    # get a url to route this method
    if self.static:
      url = '/%s/method/%s' % (model.__name__, self.method.__name__)
    else:
      url = '/%s/method/%s/(.*)' % (model.__name__, self.method.__name__)

    # create a request handler to handle these requests
    remote = self
    class RequestHandler(webapp2.RequestHandler):
      def post(self, key=None):
        """Decodes the arguments, calls the underlying method, then
        encodes the result to send back."""
        try:
          if remote.admin and not users.is_current_user_admin():
            raise RemoteException(403, 'Must be admin.')

          # get the request and respons objects
          request = chatter.unwrap(json.loads(self.request.body))
          response = {}

          # simple case for static method calls
          if remote.static:
            xx = model
          elif request['sync_before']:
            request['self'].put()
            xx = request['self']
          else:
            xx = model.get(key)
          response['return_val'] = remote.method(xx, **request['args'])
          if (not remote.static) and request['sync_after']:
            response['self'] = xx

          # write it all out
          self.response.headers['Content-Type'] = 'text/json'
          self.response.out.write(json.dumps(chatter.wrap(response)))
        except RemoteException, exc:
          self.error(exc.error_code)
          self.response.headers['Content-Type'] = 'text/plain'
          traceback.print_exc(file=self.response.out)
    return (url,  RequestHandler)
    
class MetaRemoteModel(db.Model.__metaclass__):
  """Metaclass for RemoteModel."""
  
  # each RemoteModelSublass is created, it registers it's handlers here
  subclass_handlers = []
  
  def __new__(meta, name, bases, dict):
    """Create a new class of RemoteModel or one of its subclasses."""
    # create the class
    new_class = super(MetaRemoteModel, meta).__new__(meta, name, bases, dict)

    # don't process the base class
    if name == 'RemoteModel':
      return new_class    

    # expose all remote methods as handlers
    for key, method in dict.items():
      if not isinstance(method, RemoteMethod):
        continue
      setattr(new_class, key, method.getMethod(new_class))
      MetaRemoteModel.subclass_handlers.append(method.getHandler(new_class))
        
    # give this class it's own RequestHandler for get/put/delete/post
    class RequestHandler(webapp2.RequestHandler):
      """Defines get/put/delete/post for this Seriliazable model."""
      def get(self, key):
        """Gets an existing entity."""
        entity = new_class.get(key)
        if not entity:
          return self.error(404) # can't find the entity
        self.response.headers['Content-Type'] = 'text/json'
        self.response.out.write(json.dumps(chatter.wrap(entity)))

      def put(self, key):
        """Updates an existing entity."""
        try:
          entity = chatter.unwrap(json.loads(self.request.body))
          assert entity.is_saved()
          entity.put()
          self.response.headers['Content-Type'] = 'text/json'
          self.response.out.write(json.dumps(chatter.wrap(entity)))
        except RemoteException, exc:
          self.error(exc.error_code)
          self.response.headers['Content-Type'] = 'text/plain'
          traceback.print_exc(file=self.response.out)

      def post(self):
        """Creates a new entity."""
        try:
          entity = chatter.unwrap(json.loads(self.request.body))
          assert not entity.is_saved()
          entity.put()
          self.response.headers['Content-Type'] = 'text/json'
          self.response.out.write(json.dumps(chatter.wrap(entity)))
        except RemoteException, exc:
          self.error(exc.error_code)
          self.response.headers['Content-Type'] = 'text/plain'
          traceback.print_exc(file=self.response.out)
        
      def delete(self, key):
        entity = new_class.get(key)
        if not entity:
          return self.error(404) # can't find the entity
        entity.delete()
        self.response.headers['Content-Type'] = 'text/json'
        
    MetaRemoteModel.subclass_handlers.append(('/%s/datastore/(.*)' % name, RequestHandler))
    MetaRemoteModel.subclass_handlers.append(('/%s/datastore' % name, RequestHandler))
    
    # make the class serializable and deserializable
    def wrap(self):
      """Returns a JSON-encodable version of this instance."""
      try:
        self_json = {'id':chatter.wrap(self.key())}
      except db.NotSavedError:
        self_json = {}
      # try:
      #   self_json = {'id':chatter.wrap(self.key())}
      # except Exception, e:
      #   logging.error("%s" % e)
      #   logging.error("%s" % dir(e))
      #   raise 
      self_json.update((name, chatter.wrap(getattr(self, name)))
        for name in type(self).properties_to_wrap)
      return self_json
    
    def unwrap(self_json):
      """Takes a JSON-encodable object returns an instance of this class."""
      attribs = types.DictType((k, chatter.unwrap(v)) for (k,v) in self_json.iteritems())
      if 'id' in attribs:
        entity = new_class.get(attribs['id'])
        if not entity:
          raise RemoteException(404, 'Cannot find entity with ID %s' % attribs['id'])
        for key, value in attribs.iteritems():
          if key != 'id':
            setattr(entity, key, value)
      else:
        entity = new_class(**attribs)
      return entity

    chatter.register(new_class, wrap, unwrap)

    # a new class is born!
    return new_class
    
class RemoteModel(db.Model):
  """
  Sublasses can be serialized and deserialized using 
  
  chatter.wrap() and chatter.unwrap()
  
  as long as this class defines the properties_to_wrap static
  variable. Also, subclasses make the following methods available.

  /ModelName/datastore               - put
  /ModelName/datastore/id            - get/post/delete
  /ModelName/method/methodName/id    - instance methods
  /ModelName/method/methodName       - class methods
  
  For the latter two, decorate the method with @RemoteMethod
  or @RemoteMethod(static=True)
  """
  __metaclass__ = MetaRemoteModel
  
  # handlers for all remote-invocable methods of subclasses of this RemoteModel
  __subclass_handlers = []
  
  def __init__(self, *args, **kwargs):
    db.Model.__init__(self, *args, **kwargs)    


def getAllRemoteHandlers():
  """Returns a list with elements of type (url_string,
  request_handler). These will contain all handlers for sublcasses
  of RemoteModel and can be passed into the constructor of
  webapp2.WSGIApplication."""
  return MetaRemoteModel.subclass_handlers