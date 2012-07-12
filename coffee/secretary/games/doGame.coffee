# adminstrative interface
class DoGame extends Game
  # after construction
  initialize: ->
    # setup a view
    @view = new DoGameView model:@
    super()
    
    # create the interface elements
    inst = new Instruction {}, DoInstructionView
    cal = new Calendar
    
    # create the calendar
    @set instruction:inst, calendar:cal
    
    # dequeue an instruction
    @dequeueInstruction()
    
  # gets a new instruction and calendar from the server
  dequeueInstruction: ->
    console.log "ABOUT TO DEQUEUE INSTRUCTION"
    Instruction.dequeueInstruction (rv) =>
      [instruction, calendar] = rv
      util.assertion instruction.get('state') == 'processing',
        "Dequeued instruction with incorrect state " + \
        "'#{instruction.get('state')}' (uid:#{instruction.get('uid')})"
      @get('instruction').set instruction.attributes
      @get('calendar').set calendar.attributes
    
  # send in the current solution
  submitSolution: ->
    console.log 'submit solution'
    Instruction.submitSolution
      instruction_uid: @get('instruction').get('uid')
      calendar: @get('calendar')
      (args...) =>
        console.log "finished submitting solution rv..."
        console.log args
    
# viewer for the test game
class DoGameView extends GameView
  # constructor
  constructor: (options) ->
    options.el = $('#prototypes .doGameView').clone()[0]
    super options

  # after construction
  initialize: ->
    super()
    
    # setup the buttons
    add_event = @$el.find 'button#addEvent'
    undo = @$el.find 'button#undo'
    skip = @$el.find 'button#skip'
    submit = @$el.find 'button#submit'

    undo.attr disabled: 'disabled'
    skip.attr disabled: 'disabled'
    # submit.attr disabled: 'disabled'

    # event handler
    add_event.on 'click', => @model.get('calendar').addNewEvent()
    submit.on 'click', => @model.submitSolution()
    
    # util.later =>
    #   console.log "ABOUT TO SHOW DEBUG COLORS"
    #   GameView.showDebugColors()


