# fundamentally, a Guide is a collection of Instruction objects.
class Guide extends Backbone.Model
  defaults:
    instructions: undefined

  # constructor
  constructor: (args...) ->
    super args...

  # after construction
  initialize: ->
    # manage instructions property through private collection
    @instructions = new Backbone.Collection
    @set 'instructions', @instructions.models
    @instructions.on 'all', (args...) => @trigger args...
    
    # create a view
    @view = new GuideView model:@
    console.log @view # <- debug    
        
class GuideView extends Backbone.View
  events:
    'change #instructionInput': 'onNewInput'
  
  # constructor
  constructor: (args) ->
    args.el = $('#guide')
    super args

  # after construction
  initialize: ->
    # direct link to html elements
    @input = $ @$el.find '#instructionInput'
    @list = $ @$el.find '#instructionList'
    
    console.log "GuideView.initialize..."
    console.log @list

    # figure out which events 
    @input.on 'change', => console.log "input change"
    @model.on 'add', (instruction) => @onAdd instruction
    
    # put event handlers here
    # @model.on 'add', (calEvent) => @addEvent calEvent
    # @model.on 'remove', (calEvent) => @removeEvent calEvent
    # @$el.on 'click', (args...) => @onClick args...
    
  # called when enter is pressed to create a new instruction
  onNewInput: ->
    text = $.trim @input.val()
    if text.length > 0
      # empty the text field
      @input.val '' 
      
      # post the new instruction
      instruction = new Instruction text:text
      @model.instructions.add instruction
      instruction.save()

  # called when a new instruction is added
  onAdd: (instruction) ->
    # add the element
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