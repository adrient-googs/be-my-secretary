from google.appengine.ext import db
from chatter import RemoteModel, RemoteMethod, JSONProperty, Channel

class Instruction(RemoteModel):
  """A test class."""
  text = db.StringProperty(required=True)
  uid = db.StringProperty(required=True)
  created_by = db.UserProperty(required=True, auto_current_user_add=True)
  # an_int_list = JSONProperty(required=True)
  
  # these are the properties which will be serialized to json
  properties_to_wrap = {'text'}
  
  @RemoteMethod(static=True, admin=False)
  def testMethod(cls, keys=None):
    """Returns an array with all items in this class."""
    return 'hello world'
    
  # @RemoteMethod(static=True, admin=False)
  # def getChannelToken(cls):
  #   return channel.create_channel('dummy_client')
  #   
  # @RemoteMethod(static=True, admin=False)
  # def sendMessage(cls, a_message='<dummy message>'):
  #   logging.error('about to do a call on Channel')
  #   my_channel = Channel('dummy_client')
  #   my_channel.hello(msg=a_message.upper())
  #   my_channel.goodbye(msg=a_message.upper())
  #   for ii in xrange(10):
  #     my_channel.goodbye(msg=str(ii))
  #   logging.error('just finished call on Channel')
  #   
  # @RemoteMethod(admin=False)
  # def mungeUp(self, mungeString=False):
  #   if mungeString:
  #     self.a_string = self.a_string.upper()
  #   self.put()
  #   return '//%s//%s//' % (self.an_int, self.a_string)
  #   
  # @RemoteMethod(admin=False)
  # def sortList(self):
  #   self.an_int_list = list(sorted(self.an_int_list))
  #   self.put()
