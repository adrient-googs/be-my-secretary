from google.appengine.ext import db
from chatter import RemoteModel, RemoteMethod, StructuredProperty, Channel
from secretary.player import Player
import logging

class Calendar(RemoteModel):
  """A collection of calendar events."""
  # special UID for the empty calendar
  EMPTY_UID = "empty_calendar"
  
  calEvents = StructuredProperty(required=True)
  uid = db.StringProperty(required=True)
  
  created_by = db.UserProperty(required=True, auto_current_user_add=True)
  created_on = db.DateTimeProperty(required=True, auto_now_add=True)
  
  # these are the properties which will be serialized to json
  properties_to_wrap = {'calEvents','uid'}
  
  def __init__(self, *args, **kwargs):
    """Constructor - ensures ancestor is current user."""
    if 'created_by' not in kwargs:
      assert 'parent' not in kwargs
      current_player = Player.getCurrentPlayer()
      RemoteModel.__init__(self, *args, parent=current_player, **kwargs)
    else:
      RemoteModel.__init__(self, *args, **kwargs)
    assert self.created_by == self.parent().user
    
  def save(self):
    """Like put(), but prevents overwriting EMPTY_UID."""
    if self.uid != Calendar.EMPTY_UID:
      self.put()
      
  def log(self):
    """Logs information about this calendar."""
    logging.error('calendar uid:%s' % self.uid)
    for ii, event in enumerate(self.calEvents):
      logging.error(" %.2i ->" % ii)
      logging.error("  day    : %s" % event.day)
      logging.error("  time   : %s" % event.time)
      logging.error("  length : %s" % event.length)
      logging.error("  name   : %s" % event.name)
      logging.error("  title  : %s" % event.title)
    

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
    # debug - end
      
    # save
    calendar.put()
    return calendar
    
  @RemoteMethod(static=True, admin=False)
  def getEmptyCalendar(cls):
    """Returns the empty calendar."""
    query = Calendar.all().filter('uid =', Calendar.EMPTY_UID).fetch(2)
    if len(query) == 0:
      empty_calendar = Calendar(calEvents=[], uid=Calendar.EMPTY_UID)
      empty_calendar.put()
    elif len(query) == 1:
      empty_calendar = query[0]
    else:
      raise RuntimeError, 'The empty calendar should be unique.'
    return empty_calendar

  @classmethod
  def getBy(cls, field, value):
    """Returns the first calendar where field=value"""
    if field == 'key':
      field, value = '__key__', db.Key(value)
    return Calendar.all().filter('%s =' % field, value).get()
    
  @RemoteMethod(static=True, admin=True)
  def getCalendar(cls, field=None, value=None):
    """Returns the first calendar where field=value"""
    return Calendar.getBy(field, value)
    
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

