# stores a single calendar event
class CalEvent extends Backbone.Model    
  defaults:
    day: 0
    time: 9
    length: 2
    name: 'Alan'
    title: 'No Activity'
  
  # constructor
  initialize: ->
    # create the various views
    @view = new CalEventView model:@
    @edit_view = new EditCalEventView model:@

  # validate this event
  validate: (attribs) ->
    # invalid in case of overlap
    if @parent.overlaps attribs, @
      return 'overlap'
      
  ###
  Returns true if this event overaps another.
  Overlaps happen because of shared name or overlapping time.
  ###
  overlaps: (ev) ->
    attribs = ev.attributes ? ev
    # check for name overlap
    return true if attribs.name is @get('name')
    
    # check for day overlap
    return false if attribs.day isnt @get('day')
    
    # check for time overlap
    {time:start1, length:len1} = @.attributes
    {time:start2, length:len2} = attribs
    [end1, end2] = [start1 + len1, start2 + len2]
    return true if start1 <= start2 < end1
    return true if start2 <= start1 < end2
    return false
  
    
class CalEventView extends Backbone.View
  # constants
  @DAY_WIDTH_PIXELS: 90
  @HOUR_HEIGHT_PIXELS: 40
    
  # constructor
  constructor: (args) ->
    args.el = $('#prototypes .calEventView').clone()[0]
    super args
  
  # called after all variables are set
  initialize: (model) ->
    # unsatisfied by default
    @setStatus 'unmatched'

    # make it draggable and resizable
    @$el.draggable
      containment: 'parent'
      drag: => @posToDate()
      stop: => @trigger 'stop'
    @$el.resizable
      minWidth: CalEventView.DAY_WIDTH_PIXELS
      maxWidth: CalEventView.DAY_WIDTH_PIXELS
      minHeight: CalEventView.HOUR_HEIGHT_PIXELS
      containment: 'parent'
      handles: 'n,s,se'
      resize: => @posToDate()
      stop: => @trigger 'stop'
    @$el.css position: 'absolute'

    # bind events
    @model.on 'change', (model, arg) => @onModelChange arg.changes
    @model.on 'error', (model, type) => @onError type 
    @on 'stop', => @model.set @posToDate()
    @$el.on 'click', (event) => @onClick(event)
          
  # converts position to day/time/length
  posToDate: ->
    # stop any animations to prevent flicker
    @$el.stop true
    
    # get the position
    x = @$el.position().left
    y = @$el.position().top
    h = @$el.height()
    
    # convert to coordinates
    new_date = 
      day:    Math.floor(x / CalEventView.DAY_WIDTH_PIXELS + 0.5)
      time:   Math.floor(2 * y / CalEventView.HOUR_HEIGHT_PIXELS + 0.5) / 2 + 9
      length: Math.floor(2 * h / CalEventView.HOUR_HEIGHT_PIXELS + 0.5) / 2
    new_date.length = Math.max(new_date.length, 1.0)
    @renderTime new_date
    return new_date
    
  # converts day/time/length to position
  dateToPos: (date) -> 
    date = date ? @model.attributes
    
    # start a new animation
    util.later =>
      @$el.animate
        left: date.day * CalEventView.DAY_WIDTH_PIXELS
        top: (date.time - 9) * CalEventView.HOUR_HEIGHT_PIXELS
        width: CalEventView.DAY_WIDTH_PIXELS
        height: date.length * CalEventView.HOUR_HEIGHT_PIXELS,
        500, 'easeOutExpo'
      
  # render the time
  renderTime: (date) ->
    from_time = util.timeStr(date.time)
    to_time = util.timeStr(date.time + date.length)
    coord_str = "#{util.WEEKDAYS[date.day]} #{from_time} - #{to_time}"
    @$el.find('#time').text coord_str    
    
  setStatus: (status) ->
    console.log "SETTING STATUS (#{@model.get 'name'}): #{status}"
    console.log "new background color: #{SupplicantView.STATUS_COLORS[status]}"
    # based on the mood
    @$el.css backgroundColor: SupplicantView.STATUS_COLORS[status]
    
  # called when something changed
  onModelChange: (changes) -> 
    # if the day/time/length changed, then move the event
    changes = _.keys(changes)
    
    if 'name' in changes
      @$el.find('#avatar').attr
        src: SupplicantView.avatarImage @model.get 'name'
      @$el.find('#name').text @model.get('name')
        
    if 'title' in changes
      @$el.find('#title').text @model.get('title')
    
    time_changes = ['day', 'time', 'length']
    unless _.isEmpty _.intersection(changes, time_changes)
      @renderTime @model.attributes
      @dateToPos()
      
  # called when there's an error
  onError: (type) ->
    console.log "CalEventView: Error type: #{type}"
    # revert to previous position
    @dateToPos() if type == 'overlap'
  
  # called when the user clicks on this event
  onClick: (event) ->
    @model.edit_view.show()
    return false
    
# dialog so that the user can edit an event
class EditCalEventView extends Backbone.View
  events:
    'click #ok'    : 'onClickOk'
    'click #delete': 'onClickDelete'
    'change #title': 'onModelChange'
    'change #name' : 'onModelChange'

  # constructor
  constructor: (options) ->
    options.el = $('#prototypes .editCalEventView').clone()[0]
    super options
    
  # after construction
  initialize: ->
    @title_input = @$el.find('input#title')
    @name_input = @$el.find('input#name')
    
    # get tab cycling to work properly
    @$el.find('#delete').on 'keydown', (event) =>
      if event.keyCode == 9 # tab
        @name_input.select() ; false
    
  # shows this dialog
  show: ->
    # cover the rest of the screen
    $('#cover').css visibility: 'visible'
    
    # force change event to set the fields
    @title_input.val @model.get 'title'
    @name_input.val @model.get 'name'
    
    # construct the set of names
    all_names = _.keys SupplicantView.NAMES_AND_AVATARS
    used_names = @model.parent.calEvents.pluck('name')
    available_names = _.difference all_names, used_names
    available_names.push @model.get 'name'
    
    # set autocomplete
    @title_possibe_values = CalEvent.TITLES
    @name_possibe_values = available_names
    @title_input.autocomplete
      select: => @onModelChange()
      source: @title_possibe_values
    @name_input.autocomplete
      select: => @onModelChange()
      source: @name_possibe_values
    
    # set the dialog position
    view = @model.view.$el
    view_middle = view.offset().top + view.height() / 2
    @$el.css
      top: view_middle - 72
      left: view.offset().left + view.width() - 3
    $("body").append(@el)
      
    # make the dialog bounce in
    container = @$el.find('#widgets')
    container.css visibility: 'hidden'
    @$el.effect 'scale',
      origin: ['middle','center'],
      from: {width: 0,height: 0}
      percent: 100, 
      easing: 'easeOutBounce'
      500, => 
        container.css visibility: 'visible'
        @name_input.select()

  # hides this dialog
  hide: ->
    # get rid of autocomplete
    @title_input.autocomplete('destroy')
    @name_input.autocomplete('destroy')
    
    # make it bounce away
    container = @$el.find('#widgets')
    container.css visibility: 'hidden'
    original_size = 
      width: @$el.css 'width'
      height: @$el.css 'height'
    @$el.effect 'scale'
        origin: ['middle','center']
        percent: 0
        easing: "easeInBack"
        300, =>
          @$el.detach()
          @$el.css original_size
          $('#cover').css visibility: 'hidden'    
  
  # when the user clicks ok
  onClickOk: ->
    @hide()
    
  # when the user clicks delete
  onClickDelete: ->
    @model.parent.calEvents.remove @model
    @hide()
    
  # Sets the model attributes and updates the view to indicate input
  # validity. Returns true if all fields are valid.
  onModelChange: ->
    # assume all fields are valid
    @$el.find('#ok').removeAttr 'disabled'
    @$el.find('input').css backgroundColor: 'white'
    
    # invalidate fields if necessary
    for field in ['title', 'name']
      input = @["#{field}_input"]
      input.val util.titleCase input.val()
      if input.val() in @["#{field}_possibe_values"]
        @model.set field, input.val()
      else
        input.css backgroundColor: 'rgb(223, 188, 178)'
        @$el.find('#ok').attr disabled: 'disabled'
        valid = false
    return false    
    
CalEvent.TITLES = [
  'No Activity'
  'Costume Party'
  'Snack'
  'People Watch'
  'Tennis'
  'Pedicure'
  'Climb A Tree'
  'Breakfast'
  'Lunch'
  'Henna Tattoos'
  'Opera'
  'Paint'
  'Shopping'
  'Ice Cream'
  'Long Walk'
  'Picnic'
  'Drinking Contest'
  'Scavenger Hunt'
  'Play Catch'
  'Fruit Smoothies'
]