# stores a single instruction
class Instruction extends RemoteModel
  defaults:
    nothing: undefined
  
  @testMethod: RemoteModel.remoteStaticMethod 'testMethod'
  
  # constructor
  constructor: (attribs) ->
    attribs.uid ?= util.uid()
    super attribs
    console.log "new instruction: #{@get 'uid'}"
    
  # after construction
  initialize: ->
    # create the various views
    # do this first to capture the status change
    @view = new InstructionView model:@

    # set the elements
    @set 'status', 'sending'
    
    # debug - begin
    console.log 'creating test method...'
    Instruction.testMethod (args...) => (console.log 'testMethod result' ; console.log args)
    # debug - end
    
class InstructionView extends Backbone.View
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
    
  # called when the status chages
  onChangeStatus: (model, new_status) ->
    # set the text fields
    @text.text @model.get 'text'
    @status.text @model.get 'status'
    @actions.text "cancel"