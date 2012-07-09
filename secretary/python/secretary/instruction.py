from google.appengine.ext import db
from chatter import RemoteModel, RemoteMethod, JSONProperty, Channel
import logging

class Instruction(RemoteModel):
  """A string to apply to a calendar."""
  POSSIBLE_STATUSES = ['sending', 'queued']
  
  text = db.StringProperty(required=True)
  uid = db.StringProperty(required=True)
  status = db.StringProperty(required=True, choices=POSSIBLE_STATUSES)

  created_by = db.UserProperty(required=True, auto_current_user_add=True)
  created_on = db.DateTimeProperty(required=True, auto_now_add=True)
  
  # these are the properties which will be serialized to json
  properties_to_wrap = {'text', 'uid', 'status'}
  
  @RemoteMethod(static=True, admin=False)
  def saveNewInstruction(cls, instruction=None):
    """Saves a new instruction."""
    # make sure this instruction really is new
    query = Instruction.all(keys_only=True).filter('uid =', instruction.uid)
    assert len(query.fetch(1)) == 0, \
      'Instruction uid:"%s" not unique.' % instruction.uid
      
    # update the status and save
    assert instruction.status == 'sending', \
      'Instruction uid:"%s" must have status "sending."' % instruction.uid
    instruction.status = 'queued'
    instruction.put()
    return instruction
    
    
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
