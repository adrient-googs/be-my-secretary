# Fundamentally, a Calendar is a collection of CalEvent objects.
class Calendar extends RemoteModel
  chatter.register(@) # registers the model for unpacking

  defaults:
    calEvents: undefined
        
  # save an instruction
  @saveNewCalendar: RemoteModel.remoteStaticMethod 'saveNewCalendar'
  
  # returns the empty calendar
  @getEmptyCalendar: RemoteModel.remoteStaticMethod 'getEmptyCalendar'

  # constructor
  constructor: ->
    # set the uid
    @uid = util.uid()
        
    # superclass constructor
    super uid:@uid
    console.log "new calendar: #{@get 'uid'}"

  # after construction
  initialize: ->
    # manage calEvents property through private collection
    @calEvents = new Backbone.Collection
    @calEvents.comparator = (event) -> event.get 'name'
    @set 'calEvents', @calEvents.models
    @calEvents.on 'add remove change', => @set 'calEvents', @calEvents.models
    @calEvents.on 'all', (type, args...) => @trigger "calEvents:#{type}", args...
    
    # create a view
    @view = new CalendarView model:@
    console.log 'created a calendar view'
    console.log @view
    
    # event handlers
    @on 'calEvents:add calEvents:change', => @onChangeCalEvents()
    @on 'error', (args...) => @onError args...
    
  # validate this instruction
  validate: (attribs) ->
    # make sure UID is correct
    if attribs.uid? and attribs.uid != @uid
      return "Incorrect UID: #{attribs.uid}"
    
  # add an event
  add: (event) ->
    event.parent = @
    @calEvents.add event
    
    # debug - begin
    console.log "ADDDING EVENT len:#{@calEvents.models.length}"
    console.log event
    for ii, event of @calEvents.models
      console.log "-- #{ii}"
      console.log event
    # debug - end
    
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
    
  # triggered when a calevent changed
  onChangeCalEvents: ->
    util.assertion not @hasOverlaps(), 'Events cannot overlap.'
    
    console.log "calendars onChangeCalEvents" # <- debug
    
    # since calendars are 'immutable' each change sets a new UID
    @uid = util.uid()
    @set 'uid', @uid
    console.log "calendar reset uid : #{@uid}"

  # called in case of error
  onError: (instruction, error_str) ->
    throw new Error error_str 
    
class CalendarView extends Backbone.View
  # constructor
  constructor: (args) ->
    args.el = $('#calendar')
    super args
  
  # after construction
  initialize: ->
    @model.on 'calEvents:add', (calEvent) => @addEvent calEvent
    @model.on 'calEvents:remove', (calEvent) => @removeEvent calEvent
    @$el.on 'click', (args...) => @onClick args...
      
  # add a new calendar event
  addEvent: (calEvent) ->
    # calEvent.view
    @$el.append(calEvent.view.el)
    # force change event
    calEvent.view.onModelChange calEvent.attributes
    
  # removes a calendar event
  removeEvent: (calEvent) ->
    calEvent.view.$el.remove()
    
  # called when the user clicks on the calendar
  onClick: (event) ->
    # figure out where the click happened
    {left: cal_x, top: cal_y} = $('#calendar').offset()
    click_x = event.pageX - cal_x
    click_y = event.pageY - cal_y
    new_event = @model.addNewEvent
      day: Math.floor(click_x / CalEventView.DAY_WIDTH_PIXELS)
      time: Math.floor(2 * click_y / CalEventView.HOUR_HEIGHT_PIXELS) / 2 + 9
    alert 'Insufficient space to add event.' unless new_event?
    return false