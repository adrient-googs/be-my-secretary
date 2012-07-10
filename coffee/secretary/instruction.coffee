# stores a single instruction
class Instruction extends RemoteModel
  chatter.register(@) # registers the model for unpacking

  defaults:
    status: 'sending'
  
  # save an instruction
  @saveNewInstruction: RemoteModel.remoteStaticMethod 'saveNewInstruction'
  
  # constructor
  constructor: (attribs) ->
    # set the uid
    attribs.uid ?= util.uid()
    @original_uid = attribs.uid
        
    # superclass constructor
    super attribs
    console.log "new instruction: #{@get 'uid'}"
    
  # after construction
  initialize: ->
    # create the various views
    @view = new InstructionView model:@
    
    # event handlers
    @on 'error', (args...) => @onError args...
    
  # validate this instruction
  validate: (attribs) ->
    # make sure UID is correct
    if attribs.uid? and attribs.uid != @original_uid
      return "Incorrect UID: #{attribs.uid}"
    
  # called in case of error
  onError: (instruction, error_str) ->
    @set 'status', "Error: #{error_str}"
    
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
    @status = @$el.find('#status')
    @actions = @$el.find('#actions')
    
    # event handlers
    @model.on 'change:status', InstructionView::onChangeStatus, @
    
  # render this instruction
  render: ->
    # set the text fields
    @text.text @model.get 'text'
    @status.text @model.get 'status'
    @actions.text "cancel"  

  # called when the status chages
  onChangeStatus: (model, new_status) ->
    if new_status[...5] == 'Error'
      @status.css color: InstructionView.COLORS.error_string
    @render()