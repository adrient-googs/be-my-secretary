# stores a single instruction
class Instruction extends RemoteModel
  chatter.register(@) # registers the model for unpacking

  defaults:
    state: 'sending'
    
  # Get all instructions
  @getAll: RemoteModel.remoteStaticMethod 'getAll'
  
  # save an instruction
  @enqueueInstruction: RemoteModel.remoteStaticMethod 'enqueueInstruction'
  
  # Returns an instruction and calendar which is being processed.
  @dequeueInstruction: RemoteModel.remoteStaticMethod 'dequeueInstruction'
  
  #Submits a solution to this do-puzzle
  @submitSolution: RemoteModel.remoteStaticMethod 'submitSolution'  
  
  # constructor
  constructor: (attribs={}, @view_type=InstructionView) ->
    # set the uid
    attribs.uid ?= "#{(new Date).getTime()}-#{util.uid()}"
    @original_uid = attribs.uid
        
    # superclass constructor
    super attribs
    console.log "new instruction: #{@get 'uid'}"
    
  # after construction
  initialize: ->
    # create the various views
    @view = new @view_type model:@
    
    # event handlers
    @on 'error', (args...) => @onError args...
    
  # # validate this instruction
  # validate: (attribs) ->
  #   console.log "validating instruction"
  #   console.log attribs
  #   # make sure UID is correct
  #   if attribs.uid? and attribs.uid != @original_uid
  #     return "Incorrect UID: #{attribs.uid}"
    
  # called in case of error
  onError: (instruction, error_str) ->
    @set 'state', "Error: #{error_str}"
    
# small insruction view (in type mode)
class InstructionView extends Backbone.View
  @COLORS:
    error_string: 'rgb(226, 1, 61)'
  
  # constructor
  constructor: (args) ->
    args.el = $('#prototypes .instructionView').clone()[0]
    super args

  # called after all variables are set
  initialize: (model) ->
    # direct access to html elements
    @text = @$el.find('#text')
    @state = @$el.find('#state')
    @actions = @$el.find('#actions')
    
    # event handlers
    @model.on 'change:state', InstructionView::onChangeStatus, @
    
  # render this instruction
  render: ->
    # set the text fields
    @text.text @model.get 'text'
    @state.text @model.get 'state'
    @actions.text "" #cancel" # <- debug - for now no actions

  # called when the state chages
  onChangeStatus: (model, new_state) ->
    if new_state[...5] == 'Error'
      @state.css color: InstructionView.COLORS.error_string
    @render()
    
# big instruction view (in do mode)
class DoInstructionView extends Backbone.View
  @COLORS:
    error_string: 'rgb(226, 1, 61)'

  # constructor
  constructor: (args) ->
    args.el = $('#prototypes .doInstructionView').clone()[0]
    super args

  # called after all variables are set
  initialize: (model) ->
    
    # direct access to html elements
    @player = @$el.find('#player')
    @text = @$el.find('#text')

    # event handlers
    @model.on 'change', DoInstructionView::render, @

  # render this instruction
  render: ->
    @player.text @model.get 'created_by'
    @text.text @model.get 'text'

  # # called when the state chages
  # onChangeStatus: (model, new_state) ->
  #   # debug - begin
  #   console.log "DoInstructionView.onChangeStatus()"
  #   console.log new_state
  #   return 
  #   # debug - end
  # 
  #   if new_state[...5] == 'Error'
  #     @state.css color: InstructionView.COLORS.error_string
  #   @render()