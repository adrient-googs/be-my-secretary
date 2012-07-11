# fundamentally, a Guide is a collection of Instruction objects.
class Guide extends Backbone.Model
  # constructor
  constructor: (args...) ->
    super args...

  # after construction
  initialize: ->
    # manage instructions property through private collection
    util.setCollectionAsAttribute @, 'instructions'
    @instructions.comparator = (instruction) -> instruction.get 'uid'
    
    # create a view
    @view = new GuideView model:@
    console.log @view # <- debug
    
    # event handlers
    @on 'instructions:add', (instruction) => @onAdd instruction
    
  # called when a new instruction is added
  onAdd: (instruction) ->
    # because instruction can be overriden, we copy it here
    Instruction.saveNewInstruction instruction:instruction, (update) =>
      uid = update.get 'uid'
      results = @instructions.where uid:uid
      util.assertion (results.length == 1), "UID #{uid} not unique."
      results[0].set update.attributes
      
    # debug - begin - verify the order
    for index, instruction of @instructions.models
      console.log "#{index} : #{instruction.get 'uid'} '#{instruction.get 'text'}'"
    # debug - end
        
class GuideView extends Backbone.View
  events:
    'change #instructionInput': 'onNewInput'
  
  # constructor
  constructor: (args) ->
    args.el = $('#prototypes .guideView').clone()[0]
    super args

  # after construction
  initialize: ->
    # direct link to html elements
    @input = $ @$el.find '#instructionInput'
    @list = $ @$el.find '#instructionList'
    
    # figure out which events 
    @model.on 'instructions:add', (instruction) => @onAdd instruction
    
  # called when enter is pressed to create a new instruction
  onNewInput: ->
    console.log "ON NEW INPUT"
    text = $.trim @input.val()
    if text.length > 0
      # empty the text field
      @input.val '' 
      
      # post the new instruction
      @model.instructions.add new Instruction text:text

  # called when a new instruction is added
  onAdd: (instruction) ->
    # add the element
    instruction.view.render()
    @list.append instruction.view.$el

    # scroll to view the element
    [bottom, top] = [Number.POSITIVE_INFINITY, Number.NEGATIVE_INFINITY]
    for el in @list.children()
      bottom = Math.min bottom, $(el).position().top
      top = Math.max top, $(el).position().top + $(el).height()
    inner_height = top - bottom
    container_height = @list.height()   
    @list.stop true
    @list.animate
      scrollTop: inner_height - container_height
      1400, 'easeOutQuint'