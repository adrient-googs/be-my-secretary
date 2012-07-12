# stores a single calendar event
class CalEvent extends RemoteModel
  chatter.register(@) # registers the model for unpacking
  
  defaults:
    day: 0
    time: 9
    length: 4
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

    # invalid if length is not 4
    if attribs.length != 4
      return 'length must be 4'
      
    # invalid if activity is not "NO ACTIVITY"
    if attribs.title != CalEvent.TITLES[0]
      return "activity must be #{CalEvent.TITLES[0]}"
      
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
  @COLORS:
    satisfies: 'rgb(132, 186, 101)'
    unmatched: 'rgb(223, 90, 54)'
    error: 'rgb(240, 144, 0)'
    error_string: 'rgb(226, 1, 61)'
    
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
    # @$el.resizable
    #   minWidth: CalEventView.DAY_WIDTH_PIXELS
    #   maxWidth: CalEventView.DAY_WIDTH_PIXELS
    #   minHeight: CalEventView.HOUR_HEIGHT_PIXELS
    #   containment: 'parent'
    #   handles: 'n,s,se'
    #   resize: => @posToDate()
    #   stop: => @trigger 'stop'
    @$el.css position: 'absolute'

    # bind events
    @model.on 'change', (model, arg) => @onModelChange arg.changes
    @model.on 'error', (model, type) => @onError type 
    @on 'stop', => @onStop()
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
      time:   Math.floor(y / (CalEventView.HOUR_HEIGHT_PIXELS * 4) + 0.5) * 4 + 9
      length: 4 # Math.floor(2 * h / CalEventView.HOUR_HEIGHT_PIXELS + 0.5) / 2
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
    is_dragging = @$el.hasClass 'ui-draggable-dragging'
    time_div = @$el.find('#time')
    error_color = CalEventView.COLORS.error_string
    if is_dragging
      from_time = util.timeStr(date.time)
      to_time = util.timeStr(date.time + date.length)
      time_text = "#{util.WEEKDAYS[date.day]} #{from_time} - #{to_time}"
      time_color = if @hasError 'date' then error_color else 'black'
    else
      duration = if (date.length == 1) then '1 hr' \
        else "#{date.length} hrs"
      time_text = "Duration: #{duration}"
      console.log "status:#{@status} length_error:#{@hasError 'length'}"
      time_color = if @hasError 'length' then error_color else 'black'
    time_div.text time_text
    time_div.css color: time_color
    
  setStatus: (status) ->
    @status = status
    colors = CalEventView.COLORS
    switch status
      when 'satisfies'
        bg_color = colors.satisfies
        title_color = 'black'
      when 'unmatched'
        bg_color = colors.unmatched
        title_color = 'black'
      else
        bg_color = colors.error
        title_color = \
          if @hasError 'title' then colors.error_string \
          else 'black'
    @$el.css backgroundColor: bg_color
    @$el.find('#title').css color: title_color
    @renderTime @model.attributes
    
    # debug - begin
    console.log "SETTING STATUS (#{@model.get 'name'}): #{status}" # <- debug
    console.log "bg_color: #{bg_color}"
    console.log "title_color: #{title_color}"
    # debug - end
    
  # returns true if @status indicates the given error
  hasError: (error) ->
    if @status.indexOf('error:') != 0
      return false
    else
      return error in @status[6..].split(',')
    
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
    # debug - begin
    console.log "CalEventView: Error type: #{type}"
    console.log 'THE EVENTS'
    console.log @model.parent.calEvents.models
    # debug - end
    
    # revert to previous position
    @dateToPos()
  
  # called when the user clicks on this event
  onClick: (event) ->
    @model.edit_view.show()
    return false
    
  # called when the user stopped dragging or resizing
  onStop: ->
    @model.set @posToDate()
    util.later =>
      @renderTime @model.attributes
    
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
    @title_select = @$el.find('input#title')
    @name_select = @$el.find('select#name')
    
    # get tab cycling to work properly
    @$el.find('#delete').on 'keydown', (event) =>
      if event.keyCode == 9 # tab
        @name_select.select() ; false
    
  # shows this dialog
  show: ->
    # cover the rest of the screen
    $('#cover').css visibility: 'visible'
    
    # force change event to set the fields
    @title_select.val @model.get 'title'
    
    # construct the set of names
    all_names = _.keys SupplicantView.NAMES_AND_AVATARS
    used_names = @model.parent.calEvents.pluck('name')
    available_names = _.difference all_names, used_names
    available_names.push @model.get 'name'
    available_names.sort()

    my_name = @model.get 'name'
    for ii, name of available_names
      @name_select.append("<option value='#{name}'>#{name}</option>")
      if name == my_name
        selected_index = ii
    # @name_select.el.options[selected_index].selected="true"
    @name_select.val my_name
    # @name_select.val 
    
    # set autocomplete
    @title_possibe_values = CalEvent.TITLES
    @name_possibe_values = available_names
    # @title_select.autocomplete
    #   select: => @onModelChange()
    #   source: @title_possibe_values
    # @name_select.autocomplete
    #   select: => @onModelChange()
    #   source: @name_possibe_values
    
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
        @name_select.focus()

  # hides this dialog
  hide: ->
    # get rid of autocomplete
    @title_select.empty()
    # @title_select.autocomplete('destroy')
    # @name_select.autocomplete('destroy')
    
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
    console.log 'ON MODEL CHANGE'
    # assume all fields are valid
    @$el.find('#ok').removeAttr 'disabled'
    @$el.find('input').css backgroundColor: 'white'
    
    @model.set 'name', @name_select.val()
    
    # # invalidate fields if necessary
    # for field in ['title', 'name']
    #   input = @["#{field}_select"]
    #   input.val util.titleCase input.val()
    #   if input.val() in @["#{field}_possibe_values"]
    #     @model.set field, input.val()
    #   else
    #     input.css backgroundColor: 'rgb(223, 188, 178)'
    #     @$el.find('#ok').attr disabled: 'disabled'
    #     valid = false
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