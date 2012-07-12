# Fundamentally, a Calendar is a collection of CalEvent objects.
class Calendar extends RemoteModel
  chatter.register(@) # registers the model for unpacking

  # special UID for the empty calendar
  @EMPTY_UID = "<<empty_calendar>>"

  defaults:
    uid: @EMPTY_UID
    calEvents: undefined
        
  # save an instruction
  @saveNewCalendar: RemoteModel.remoteStaticMethod 'saveNewCalendar'
  
  # returns the empty calendar
  @getEmptyCalendar: RemoteModel.remoteStaticMethod 'getEmptyCalendar'
  
  @getCalendar: RemoteModel.remoteStaticMethod 'getCalendar'

  # constructor
  constructor: (attribs={}) ->
    # set the uid
    if attribs.calEvents?
      util.assertion attribs.uid?, 'Cannot define calEvents without UID.'
      @uid = attribs.uid
    else
      util.assertion !attribs.uid?, 'Cannot define UID without calEvents'
      @uid = attribs.uid = Calendar.EMPTY_UID
        
    # superclass constructor
    super attribs
    console.log "new calendar: #{@get 'uid'}"

  # after construction
  initialize: (attribs) ->
    # debug - begin
    console.log "Calendar initialize #{@get 'uid'}, attributes..."
    console.log attribs
    # debug - end

    # manage calEvents property through private collection
    util.setCollectionAsAttribute @, 'calEvents', (attribs.calEvents ? [])
    @calEvents.comparator = (event) -> event.get 'name'
    
    # create a view
    @view = new CalendarView model:@
    
    # event handlers
    @on 'change:calEvents', => @onReplaceCalEvents()
    @calEvents.on 'add remove change', => @onEditCalendar()
    @on 'error', (args...) => @onError args...
    
  # validate this instruction
  validate: (attribs) ->
    # unless we're also setting the calEvents, make sure UID is correct
    unless attribs.calEvents?
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
    
  #####################
  # network functions #
  #####################

  # saves this calendar or fails if this calendar has already been saved
  saveNew: ->
    console.log " _!_!_ SAVING CALENDAR WITH WITH _!_!_ #{@id}"
    util.assertion @isNew(), 'Cannot save a calendar twice.'
    Calendar.saveNewCalendar calendar:@, (new_cal) =>
      # debug - begin
      console.log 'finished saving'
      console.log new_cal
      # debug - end

      @set new_cal.attributes

      # debug - begin
      console.log 'set myself'
      console.log @
      # debug - end
      
  
  ##################
  # event handlers #
  ##################
    
  # triggered the entire calEvents array is repalced
  onReplaceCalEvents: ->
    # make sure the new calendar is valid
    util.assertion not @hasOverlaps(), 'Events cannot overlap.'
    
    # reset the parents
    for calEvent in @calEvents.models
      calEvent.parent = @
      
    # debug - begin
    console.log "calendar rest calevents uid:#{@uid} id:#{@id} getid:#{@get 'id'}"
    # debug - end
    
  # triggered when the user edits the calendar
  onEditCalendar: ->
    # make sure this new calendar is valid
    util.assertion not @hasOverlaps(), 'Events cannot overlap.'
    
    # since calendars are 'immutable' each change sets a new UID
    console.log "calendar old uid:#{@uid} id:#{@id} getid:#{@get 'id'}"
    @uid = util.uid()
    @set 'uid', @uid
    @unset 'id'
    console.log "calendar reset uid:#{@uid} id:#{@id} getid:#{@get 'id'}"

  # called in case of error
  onError: (instruction, error_str) ->
    throw new Error error_str 
    
class CalendarView extends Backbone.View
  # constructor
  constructor: (args) ->
    args.el = $('#prototypes .calendarView').clone()[0]
    super args
  
  # after construction
  initialize: ->
    @model.on 'calEvents:add', (calEvent) => @addEvent calEvent
    @model.on 'calEvents:remove', (calEvent) => @removeEvent calEvent
    @model.on 'change:calEvents', CalendarView::onReplaceCalEvents, @
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
    {left: cal_x, top: cal_y} = @$el.offset()
    click_x = event.pageX - cal_x
    click_y = event.pageY - cal_y
    new_event = @model.addNewEvent
      day: Math.floor(click_x / CalEventView.DAY_WIDTH_PIXELS)
      time: Math.floor(2 * click_y / CalEventView.HOUR_HEIGHT_PIXELS) / 2 + 9
    alert 'Insufficient space to add event.' unless new_event?
    return false
  
  # called when all the entire calEvents arrays is replaced
  onReplaceCalEvents: (args...) ->
    index_by_name = (models) ->
      util.mash ([model.get('name'), model] for model in models)
    old_events = index_by_name @model.previous 'calEvents' 
    new_events = index_by_name @model.get 'calEvents'
    
    # transfer view elements to new events
    for name, new_event of new_events
      console.log "#{new_event.get('name')} -> #{old_event}" # <- debug
      old_event = old_events[name]
      if old_event?
        new_event.view.$el.css
          width: old_event.view.$el.css 'width'
          height: old_event.view.$el.css 'height'
          left: old_event.view.$el.css 'left'
          top: old_event.view.$el.css 'top'
      @$el.append(new_event.view.$el)
      # force view update
      new_event.view.onModelChange new_event.attributes  

    # remove view elements for old events
    for name, old_event of old_events
      old_event.view.$el.detach()

      
      

