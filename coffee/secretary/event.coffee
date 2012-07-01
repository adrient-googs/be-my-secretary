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
    'change' : => @change
  
  # constructor
  constructor: (args) ->
    args.el = $('#prototypes .calEventView').clone()[0]
    super args
  
  # called after all variables are set
  initialize: (model) ->
    # set the model
    super model: model
      
    # avatar
    img_file = CalEvent.NAMES_AND_AVATARS[@model.get('name')]
    @$el.find('#avatar').attr
      src: "/imgs/Face-Avatars-by-deleket/#{img_file}"
    @$el.find('#name').text @model.get('name')
    
    # set the background color
    background_colors =
      satisfied: 'rgb(129, 167, 83)'
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
    @model.on 'change', (model, arg) => @change arg.changes
    
    # initial placement
    @change @model.attributes
      
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
      500, 'easeOutElastic'
      
  # render the time
  renderTime: (coords) ->
    timeStr = (hour) ->
      if hour == 12
        return 'noon'
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
  change: (changes) -> 
    changes = _.keys(changes)
    
    # if the day/time/length changed, then move the event
    time_changes = ['day', 'time', 'length']
    unless _.isEmpty _.intersection(changes, time_changes)
      @renderTime @model.attributes
      @coordsToPos()
    
CalEvent.NAMES_AND_AVATARS =
  Joel:    'Males/A01.png'
  Seth:    'Males/A02.png'
  James:   'Males/A03.png'
  Ted:     'Males/A04.png'
  Alan:    'Males/A05.png'
  Karl:    'Males/B01.png'
  Ian:     'Males/B02.png'
  Dale:    'Males/B03.png'
  Ivan:    'Males/B04.png'
  Sean:    'Males/B05.png'
  Eric:    'Males/C01.png'
  Todd:    'Males/C02.png'
  Kurt:    'Males/C03.png'
  Jose:    'Males/C04.png'
  Joe:     'Males/C05.png'
  Kirk:    'Males/D01.png'
  Jack:    'Males/D02.png'
  Kevin:   'Males/D03.png'
  Jason:   'Males/D04.png'
  Marc:    'Males/D05.png'
  Ryan:    'Males/E01.png'
  Tony:    'Males/E02.png'
  Lee:     'Males/E03.png'
  Andy:    'Males/E04.png'
  Mike:    'Males/E05.png'
  Don:     'Males/F01.png'
  Leon:    'Males/F02.png'
  Bill:    'Males/F03.png'
  Roy:     'Males/F04.png'
  Erik:    'Males/F05.png'
  Jeff:    'Males/G01.png'
  Wade:    'Males/G02.png'
  Fred:    'Males/G03.png'
  Juan:    'Males/G04.png'
  Brian:   'Males/G05.png'
  Max:     'Males/H01.png'
  Luis:    'Males/H02.png'
  Hugh:    'Males/H03.png'
  Kent:    'Males/H04.png'
  Chad:    'Males/H05.png'
  Allen:   'Males/I01.png'
  Jesse:   'Males/I02.png'
  Randy:   'Males/I03.png'
  Billy:   'Males/I04.png'
  Danny:   'Males/I05.png'
  Larry:   'Males/J01.png'
  Bryan:   'Males/J02.png'
  Jerry:   'Males/J03.png'
  Shawn:   'Males/J04.png'
  Aaron:   'Males/J05.png'
  Jacob:   'Males/K01.png'
  Glenn:   'Males/K02.png'
  Roger:   'Males/K03.png'
  Ricky:   'Males/K04.png'
  Harry:   'Males/K05.png'
  Eddie:   'Males/L01.png'
  Peter:   'Males/L02.png'
  Jimmy:   'Males/L03.png'
  Scott:   'Males/L04.png'
  Mario:   'Males/L05.png'
  Chris:   'Males/M01.png'
  Keith:   'Males/M02.png'
  Jesus:   'Males/M03.png'
  Craig:   'Males/M04.png'
  Edwin:   'Males/M05.png'
  Terry:   'Males/N01.png'
  Frank:   'Males/N02.png'
  Barry:   'Males/N03.png'
  Bruce:   'Males/N04.png'
  Steve:   'Males/N05.png'
  Wayne:   'Males/O01.png'
  Henry:   'Males/O02.png'
  Ralph:   'Males/O03.png'
  Louis:   'Males/O04.png'
  Bobby:   'Males/O05.png'
  Lena:    'Females/FA01.png'
  Lynn:    'Females/FA02.png'
  Lois:    'Females/FA03.png'
  May:     'Females/FA04.png'
  Emma:    'Females/FA05.png'
  Lisa:    'Females/FB01.png'
  Eve:     'Females/FB02.png'
  Jane:    'Females/FB03.png'
  Ruby:    'Females/FB04.png'
  Anne:    'Females/FB05.png'
  Dora:    'Females/FC01.png'
  Jean:    'Females/FC02.png'
  Judy:    'Females/FC03.png'
  Olga:    'Females/FC04.png'
  Vera:    'Females/FC05.png'
  Jill:    'Females/FD01.png'
  Mary:    'Females/FD02.png'
  Rae:     'Females/FD03.png'
  June:    'Females/FD04.png'
  Lucy:    'Females/FD05.png'
  Cora:    'Females/FE01.png'
  Sara:    'Females/FE02.png'
  Leah:    'Females/FE03.png'
  Nora:    'Females/FE04.png'
  Rosa:    'Females/FE05.png'
  Joan:    'Females/FG01.png'
  Liz:     'Females/FG02.png'
  Tia:     'Females/FG03.png'
  Eva:     'Females/FG04.png'
  Kim:     'Females/FG05.png'
  Rose:    'Females/FH01.png'
  Tara:    'Females/FH02.png'
  Luz:     'Females/FH03.png'
  Edna:    'Females/FH04.png'
  Ella:    'Females/FH05.png'
  Ada:     'Females/FI01.png'
  Ana:     'Females/FI02.png'
  Toni:    'Females/FI03.png'
  Erin:    'Females/FI04.png'
  Mia:     'Females/FI05.png'