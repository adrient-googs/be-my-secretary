from google.appengine.ext import db
from google.appengine.api import users
from chatter import RemoteModel, RemoteMethod, StructuredProperty, Channel
from secretary.player import Player
from secretary.calendar import Calendar

import logging
import random

class Instruction(RemoteModel):
  """A string to apply to a calendar."""
  POSSIBLE_STATES = ['sending', 'processing', 'queued', 'done']

  # basic information
  text = db.StringProperty(required=True, indexed=False)
  state = db.StringProperty(required=True, choices=POSSIBLE_STATES)
  calendar_uid = db.StringProperty() # input calendar
  soln_cal_uid = db.StringProperty() # output calendar

  # uid of this instruction and the previous one in the queue
  uid = db.StringProperty(required=True)
  previous_uid = db.StringProperty()

  # information about this instruction
  created_by = db.UserProperty(required=True, auto_current_user_add=True)
  created_on = db.DateTimeProperty(required=True, auto_now_add=True)
  
  # these are the properties which will be serialized to json
  properties_to_wrap = {'text', 'state', 'calendar_uid', 'uid', 'previous_uid', 'created_by'}
  
  def __init__(self, *args, **kwargs):
    """Constructor - ensures ancestor is current user."""
    if 'created_by' not in kwargs:
      assert 'parent' not in kwargs
      current_player = Player.getCurrentPlayer()
      RemoteModel.__init__(self, *args, parent=current_player, **kwargs)
    else:
      RemoteModel.__init__(self, *args, **kwargs)
    assert self.created_by == self.parent().user
    
  def log(self):
    """Logs information about this insruction."""
    logging.error("instruction: %s", self)
    logging.error(" - text: %s", self.text)
    logging.error(" - state: %s", self.state)
    logging.error(" - calendar_uid: %s", self.calendar_uid)
    logging.error(" - uid: %s", self.uid)
    logging.error(" - previous_uid: %s", self.previous_uid)
    logging.error(" - created_by: %s", self.created_by)
    logging.error(" - created_on: %s", self.created_on)
  
  def previousChainAllDone(self):
    """Returns true if all antecedent instructions are done."""
    prev = Instruction.getBy('uid', self.previous_uid, ancestor=self.parent())
    while True:
      if prev == None:
        return True
      elif prev.state != 'done':
        return False
      prev = Instruction.getBy('uid', prev.previous_uid, ancestor=self.parent())
  
  @classmethod
  def getBy(cls, field, key, ancestor=None):
    query = Instruction.all().filter('%s =' % field, key)
    if ancestor:
      query.ancestor(ancestor)
    return query.get()
    
  @RemoteMethod(static=True, admin=True)
  def getAll(cls):
    """Get all instructions."""
    return cls.all().fetch(1000)
  
  @RemoteMethod(static=True, admin=False)
  def enqueueInstruction(cls, instruction=None, calendar=None):
    """Saves a new instruction."""
    # make sure this instruction really is new
    assert Instruction.getBy('uid', instruction.uid) == None, \
      'Instruction uid:"%s" not unique.' % instruction.uid

    # debug - begin
    instruction.log()
    # debug - end
    
    if instruction.previous_uid == None:
      # first instruction for this game
      assert instruction.calendar_uid == calendar.uid
      def save_instruction_and_calendar(instruction, calendar):
        assert instruction.previousChainAllDone()
        instruction.state = 'processing'
        instruction.put()
        calendar.save()
      db.run_in_transaction(save_instruction_and_calendar, instruction, calendar)
    else:
      # there are previous instructions in this game
      previous = Instruction.getBy('uid', instruction.previous_uid)
      if previous.state == 'done':
        instruction.calendar_uid = previous.soln_cal_uid
        assert instruction.previousChainAllDone()
        instruction.state = 'processing'
      else:
        instruction.state = 'queued'
      instruction.put()
    return instruction

  @RemoteMethod(static=True, admin=False)
  def dequeueInstruction(cls):
    """Returns an instruction and calendar which is being processed."""
    # get the earliest-created instruction to process
    instructions = Instruction.all()
    instructions.filter('state =', 'processing')
    instructions.order('created_on') # earliest first
    instruction = instructions.get()
    
    # if none could be found, then recycle an old one
    if instruction == None:
      instructions = Instruction.all()
      instructions.filter('state =', 'done')
      index = random.randint(0, instructions.count()-1)
      instruction = instructions[index]    
    
    # get the associated calendar
    calendar = Calendar.all().filter('uid =', instruction.calendar_uid).get()
    assert calendar, 'Instruction does not have associated calendar: %s' % \
      instruction.calendar_uid

    # return both
    return [instruction, calendar]
    
  @RemoteMethod(static=True, admin=False)
  def submitSolution(cls, instruction_uid=None, calendar=None):
    """Submits a solution to this do-puzzle, returns information
    about whether the solution is correct."""    
    # get the instruction (and the next instruction if it extists)
    instruction = Instruction.getBy('uid', instruction_uid)
    next_instruction = Instruction.getBy('previous_uid', instruction_uid)
    if next_instruction:
      assert instruction.created_by == next_instruction.created_by
      
    # if the instruction was already completed, then we're done
    if instruction.state == 'done':
      return {
        'submission'  : 'success',
        'next_puzzle' : cls.dequeueInstruction()
      }
      
    # make sure the calendar doesn't exist
    assert Calendar.getBy('uid', calendar.uid) == None
      
    # store the calendar
    calendar.put()

    # indicate that the next instruction should be processed
    def pass_batton(instruction, next_instruction, solution):
      instruction.soln_cal_uid = solution.uid
      instruction.state = 'done'
      instruction.put()
      if not next_instruction:
        return
      next_instruction.calendar_uid = solution.uid
      assert instruction.previousChainAllDone() # <- debug
      next_instruction.state = 'processing'
      next_instruction.put()
    db.run_in_transaction(pass_batton, instruction, next_instruction, calendar)

    # update the player who typed this instruction
    logging.error('notifying: %s' % instruction.created_by)
    player_to_notify = Player.getByUser(instruction.created_by)
    player_channel = player_to_notify.getChannel()
    player_channel.postSolution(solved_instruction=instruction, 
      solved_calendar=calendar, next_instruction=next_instruction)
    
    logging.error("TODO: update the player with a channel")
    # 
    
    # return a new puzzle
    return {
      'submission'  : 'success',
      'next_puzzle' : cls.dequeueInstruction()
    }
    

    
    
    