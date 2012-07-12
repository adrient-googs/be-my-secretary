from google.appengine.ext import db
from chatter import RemoteModel, RemoteMethod, StructuredProperty, Channel
import logging

class Calendar(RemoteModel):
  """A collection of calendar events."""
  # special UID for the empty calendar
  EMPTY_UID = "<<empty_calendar>>"
  
  calEvents = StructuredProperty(required=True)
  uid = db.StringProperty(required=True)
  
  created_by = db.UserProperty(required=True, auto_current_user_add=True)
  created_on = db.DateTimeProperty(required=True, auto_now_add=True)
  
  # these are the properties which will be serialized to json
  properties_to_wrap = {'calEvents','uid'}

  @RemoteMethod(static=True, admin=False)
  def saveNewCalendar(cls, calendar=None):
    """Saves a new calendar."""
    # make sure this instruction really is new
    query = Calendar.all(keys_only=True).filter('uid =', calendar.uid)
    assert len(query.fetch(1)) == 0, \
      'Instruction uid:"%s" not unique.' % instruction.uid
    
    # debug - begin
    try:
      logging.error("saveNewCalendar: %s (key:%s)" % (calendar.uid, calendar.key()))
      logging.error("oldID: %s" % Calendar.all().filter('key =', calendar.key()).get().uid)
    except db.NotSavedError:
      logging.error("saveNewCalendar: %s (not saved)" % (calendar.uid))
    calEvents = calendar.calEvents
    for ii, event in enumerate(calEvents):
      logging.error("%.2i : %s" % (ii, event))
      logging.error(" day    : %s" % event.day)
      logging.error(" time   : %s" % event.time)
      logging.error(" length : %s" % event.length)
      logging.error(" name   : %s" % event.name)
      logging.error(" title  : %s" % event.title)
    # debug - end
      
    # save
    calendar.put()
    return calendar
    
  @RemoteMethod(static=True, admin=False)
  def getEmptyCalendar(cls):
    """Returns the empty calendar."""
    query = Calendar.all.filter('uid =', EMPTY_UID)
    if len(query) == 0:
      empty_calendar = Calendar(calEvents=[], uid=EMPTY_UID)
      empty_calendar.put()
    elif len(query) == 1:
      empty_calendar = query.get()
    else:
      raise RuntimeError, 'The empty calendar should be unique.'
    return empty_calendar
    
  @RemoteMethod(static=True, admin=True)
  def getCalendar(cls, field=None, value=None):
    """Returns the first calendar where field=value"""
    if field == 'key':
      field, value = '__key__', db.Key(value)
    logging.error('getting calendar with %s=%s' % (field, value))
    logging.error(str(Calendar.all().filter('%s =' % field, value).get()))
    return Calendar.all().filter('%s =' % field, value).get()
    
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
