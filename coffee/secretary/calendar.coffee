# holds a series of events
class Calendar extends Backbone.Model
  defaults:
    calEvents: undefined

  # constructor
  constructor: (args...) ->
    super args...

  # after construction
  initialize: ->
    # manage calEvents property through private collection
    @calEvents = new Backbone.Collection
    @calEvents.comparator = (event) -> event.get 'name'
    @set 'calEvents', @calEvents.models
    @calEvents.on 'all', (args...) => @trigger args...
    
    # create a view
    @view = new CalendarView model:@
    console.log 'created a calendar view'
    console.log @view
    
  # add an event
  add: (event) ->
    event.parent = @
    @calEvents.add event
    
class CalendarView extends Backbone.View
  undefined # <- debug
  
  # constructor
  constructor: (args) ->
    args.el = $('#calendar')
    super args
  
  # after construction
  initialize: ->
    @model.on 'add', (event) => @addEvent event
      
  # add a new calendar event
  addEvent: (event) ->
    @$el.append(event.view.el)
    # trigger change event
    event.view.onChange event.attributes