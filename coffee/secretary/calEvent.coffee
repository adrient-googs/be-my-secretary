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
    @view = new CalEventView model:@
    
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
      drag: => @posToCoords()
      stop: => @model.set @posToCoords()
    @$el.resizable
      minWidth: CalEventView.DAY_WIDTH_PIXELS
      maxWidth: CalEventView.DAY_WIDTH_PIXELS
      minHeight: CalEventView.HOUR_HEIGHT_PIXELS
      containment: 'parent'
      handles: 'n,s,se'
      resize: => @posToCoords()
      stop: => @model.set @posToCoords()
      
    # bind events
    @model.on 'change', (model, arg) => @onChange arg.changes
    
    # initial placement
    @onChange @model.attributes
      
  # converts position to day/time/length
  posToCoords: ->
    # get the position
    x = @$el.position().left
    y = @$el.position().top
    h = @$el.height()
    
    # convert to coordinates
    new_coords = 
      day:    Math.floor(x / CalEventView.DAY_WIDTH_PIXELS + 0.5)
      time:   Math.floor(2 * y / CalEventView.HOUR_HEIGHT_PIXELS + 0.5) / 2 + 9
      length: Math.floor(2 * h / CalEventView.HOUR_HEIGHT_PIXELS + 0.5) / 2
    new_coords.length = Math.max(new_coords.length, 1.0)
    @renderTime new_coords
    return new_coords
    
  # converts day/time/length to position
  coordsToPos: (coords) -> 
    coords = coords ? @model.attributes

    # stop any animations to prevent flicker
    @$el.stop true

    # start a new animation
    @$el.animate
      left: coords.day * CalEventView.DAY_WIDTH_PIXELS
      top: (coords.time - 9) * CalEventView.HOUR_HEIGHT_PIXELS
      width: CalEventView.DAY_WIDTH_PIXELS
      height: coords.length * CalEventView.HOUR_HEIGHT_PIXELS,
      500, 'easeOutExpo'
      
  # render the time
  renderTime: (coords) ->
    timeStr = (hour) ->
      return 'noon' if hour == 12
      [hour, suf] = 
        if hour < 12 then [hour, 'am']
        else if hour < 13 then [hour, 'pm'] 
        else [hour - 12, 'pm'] 
      if util.isInteger(hour) then "#{hour}#{suf}"
      else "#{Math.floor(hour)}:30#{suf}"
    from_time = timeStr(coords.time)
    to_time = timeStr(coords.time + coords.length)
    days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    coord_str = "#{days[coords.day]} #{from_time} - #{to_time}"
    @$el.find('#time').text coord_str
    
  # called when something changed
  onChange: (changes) -> 
    changes = _.keys(changes)
    
    # if the day/time/length changed, then move the event
    time_changes = ['day', 'time', 'length']
    unless _.isEmpty _.intersection(changes, time_changes)
      @renderTime @model.attributes
      @coordsToPos()