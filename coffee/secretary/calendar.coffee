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
    
    # event handlers
    @on 'add change', => @onChange()
    
  # add an event
  add: (event) ->
    event.parent = @
    @calEvents.add event
    return event
    
  ### 
  Adds a non-overlapping event.
  If no date is specified, then finds an available slot.
  Returns the event or undefined if event could not be added.
  ###
  addNewEvent: (attribs = {}) ->
    used_names = @calEvents.pluck('name')
    unless attribs.name?
      all_names = _.keys SupplicantView.NAMES_AND_AVATARS
      attribs.name = util.choose(all_names, used_names)
    util.assertion (attribs.name not in used_names),
      'Cannot duplicate name.'
    if attribs.day?
      if attribs.length?
        ev = new CalEvent attribs
        return undefined if @overlaps ev
        return @add ev
      for length in [2, 1.5, 1]
        length = Math.min length, 17 - attribs.time
        continue if length < 1
        ev = @addNewEvent _.extend length:length, attribs
        return ev if ev?
      return undefined
    for day in [0...7]
      for hour in [9...17]
        for time in [hour, hour+0.5]
          ev = @addNewEvent _.extend day:day, time:time, attribs
          return ev if ev?
    return undefined
      
    
  # triggered when something changed
  onChange: ->
    util.assertion not @hasOverlaps(), 'Events cannot overlap.'
    
  # returns true if the event overlaps this calendar
  overlaps: (ev1, exclude) ->
    exclude = exclude ? ev1
    for ev2 in @calEvents.models when ev2 isnt exclude
      return true if ev2.overlaps ev1
    return false
    
  # returns true if the calendar has overlapping events
  hasOverlaps: ->
    for event in @calEvents.models
      return true if @overlaps event
    return false
    
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
    # force change event
    event.view.onChange event.attributes