# stores a single calendar event
class CalEvent extends Backbone.Model    
  defaults:
    day: 0
    time: 9
    length: 2
    mode: 'satisfied'
    name: 'Alan'
  
  # constructor
  initialize: ->
    # create a view
    @view = new CalEventView model:@

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
  
  events:
    undefined
    # 'change' : => @change
  
  # constructor
  constructor: (args) ->
    args.el = $('#prototypes .calEventView').clone()[0]
    super args
  
  # called after all variables are set
  initialize: (model) ->
    # set the model
    super model: model
      
    # avatar
    @$el.find('#avatar').attr
      src: SupplicantView.avatarImage @model.get 'name'
    @$el.find('#name').text @model.get('name')
    
    # set the background color
    background_colors =
      satisfied: 'rgb(132, 186, 101)'
    @$el.css
      backgroundColor: background_colors[@model.get('mode')]
      
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

    # bind events
    @model.on 'change', (model, arg) => @onChange arg.changes
    @model.on 'error', (model, type) => @onError type 
    @on 'stop', => @model.set @posToDate()
          
  # converts position to day/time/length
  posToDate: ->
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

    # stop any animations to prevent flicker
    @$el.stop true

    # start a new animation
    @$el.animate
      left: date.day * CalEventView.DAY_WIDTH_PIXELS
      top: (date.time - 9) * CalEventView.HOUR_HEIGHT_PIXELS
      width: CalEventView.DAY_WIDTH_PIXELS
      height: date.length * CalEventView.HOUR_HEIGHT_PIXELS,
      500, 'easeOutExpo'
      
  # render the time
  renderTime: (date) ->
    timeStr = (hour) ->
      return 'noon' if hour == 12
      [hour, suf] = 
        if hour < 12 then [hour, 'am']
        else if hour < 13 then [hour, 'pm'] 
        else [hour - 12, 'pm'] 
      if util.isInteger(hour) then "#{hour}#{suf}"
      else "#{Math.floor(hour)}:30#{suf}"
    from_time = timeStr(date.time)
    to_time = timeStr(date.time + date.length)
    days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    coord_str = "#{days[date.day]} #{from_time} - #{to_time}"
    @$el.find('#time').text coord_str    
    
  # called when something changed
  onChange: (changes) -> 
    # if the day/time/length changed, then move the event
    changes = _.keys(changes)
    time_changes = ['day', 'time', 'length']
    unless _.isEmpty _.intersection(changes, time_changes)
      @renderTime @model.attributes
      @dateToPos()
      
  # called when there's an error
  onError: (type) ->
    console.log "CalEventView: Error type: #{type}"
    # revert to previous position
    @dateToPos() if type == 'overlap'
