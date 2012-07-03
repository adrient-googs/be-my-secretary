# represents someone asking something
class Supplicant extends Backbone.Model
  defaults:
    status: 'unmatched'
    points: 100
    
  # constructor
  constructor: (args...) ->
    super args...
    
  # after initilization
  initialize: (args) ->
    @cid = args.name
    util.assertion (@cid of SupplicantView.NAMES_AND_AVATARS),
      "Unknown name: #{@cid}."
    @view = new SupplicantView model:@    
    @constraint_view = new SupplicantConstraintView model:@
    
    # event handlers
    @on 'change:calEvent', (sup, calEvent) =>
      @onCalEventChange calEvent

    # # debug - begin
    # @on 'all', (args...) =>
    #   console.log 'SUPPLICANT EVENT'
    #   console.log args
    # # debug - end  
    
  # returns all [day, time] pairs which satisfy this Supplicant
  getAllSatisfyingDates: ->
    satisfying_dates = 
      for day in [0...7]
        for time in [9...17]
          unless @isSatifiedBy {day:day, time:time, length:1}
            continue
          {day:day, time:time}
    return _.flatten satisfying_dates
    
  # returns true if this date satifies the constraints
  isSatifiedBy: (date) ->
    # console.log 'isSatifiedBy'
    # console.log @attributes
    [days, start, end, length] = 
      @get(val) for val in ['days', 'start', 'end', 'length']
    return false unless (
      "#{date.day}" in days.split('') and
      date.length <= length and
      date.time >= start and
      date.time + date.length <= end
    )
    return true
    
  onCalEventChange: (calEvent) ->
    console.log "onCalEventChange (#{@get 'name'}): #{calEvent?.get 'name'}"
    old_status = @get 'status'
    console.log "old_status: #{old_status}"
    if !calEvent?
      @set 'status', 'unmatched'
    else if @isSatifiedBy calEvent.attributes
      console.log "setting status satisfied"
      @set 'status', 'satisfied'
    else
      console.log "setting status unmatched"
      @set 'status', 'matched'

    console.log "new_status: #{@get 'status'}"
    
# shows a little box that summarizes the supplicant
class SupplicantView extends Backbone.View
  # manually specify CSS properties for util.verticalAppend
  @HEIGHT: 46
  @VERTICAL_MARGIN: 14
  
  # status table
  @STATUS_COLORS:
    'unmatched': 'rgb(223, 90, 54)'    # not matched to any event
    'matched':   'rgb(240, 144, 0)'    # matched but not satisfied
    'satisfied': 'rgb(132, 186, 101)'  # matched and satisfied
  
  # returns the filename for a particular avatar
  @avatarImage: (name) ->
    img_file = SupplicantView.NAMES_AND_AVATARS[name]
    return "/imgs/Face-Avatars-by-deleket/#{img_file}"
  
  # constructor
  constructor: (args) ->
    args.el = $('#prototypes .supplicantView').clone()[0]
    super args
    
  # after construction
  initialize: (args) ->
    # set all elements
    @$el.find('#name').text @model.get 'name'
    @$el.find('#points').text "#{@model.get 'points'} pts"
    @$el.find('#avatar').attr
      src: SupplicantView.avatarImage(@model.get 'name')
    @$el.find('#title').text @model.get 'title'
    @$el.find('#constraint1').text "Duration: #{@model.get 'length_str'}"
    @$el.find('#constraint2').text "#{@model.get 'day_str'} #{@model.get 'time_str'}"
    # @$el.find('#constraint1').text "#{@model.get 'time_str'} (#{@model.get 'length_str'})"
    # @$el.find('#constraint2').text @model.get 'day_str'
    @$el.css backgroundColor: SupplicantView.STATUS_COLORS[@model.get 'status']
      
    # event callbacks
    @$el.on 'mouseenter', (event) => @onMouseEnter event
    @$el.on 'mouseleave', (event) => @onMouseLeave event
    @model.on 'change:status', (sup, status) =>
      @onChangeStatus status
    
  # fade in the constraints on hover
  onMouseEnter: (event) ->
    @model.constraint_view.fadeIn()
    
  onMouseLeave: (event) ->
    @model.constraint_view.fadeOut()
  
  onChangeStatus: (status) ->
    css =
      backgroundColor: SupplicantView.STATUS_COLORS[status]
    @$el.css css
    console.log "changing background on #{@model.get('calEvent')?.get('name')}"
    console.log @model.get('calEvent')?.view.$el.css 'background-color'
    @model.get('calEvent')?.view.setStatus status
    console.log @model.get('calEvent')?.view.$el.css 'background-color'
    console.log css
    
# show an outline of possible constraints on the calendar
class SupplicantConstraintView extends Backbone.View
  # constructor
  constructor: (args) ->
    args.el = $('<div class="supplicantConstraintView">')
    super args
    
  # after construction
  initialize: (args) ->
    # give this element an id
    @$el.attr id: @model.get 'name'
    
    # highlight all satisfying dates
    for date in @model.getAllSatisfyingDates()
      @$el.append $('<div class="satisfyingDate">').css
        left: date.day * CalEventView.DAY_WIDTH_PIXELS
        top: (date.time - 9) * CalEventView.HOUR_HEIGHT_PIXELS

    # initially invisible
    @$el.css opacity: 0
    
  # fades the constraint view in
  fadeIn: ->
    # fade in this view while disappearing all others
    constraint_views = $('.supplicantConstraintView')
    for view in constraint_views
      view = $(view)
      view.stop true
      if view.attr('id') == @model.get('name')
        view.animate opacity: 0.25, 200
      else
        view.css opacity: 0
        
  # fades out the constraint
  fadeOut: ->
    @$el.stop true
    @$el.animate opacity: 0, 200
  
# list of all possible supplicants and thier avatrs
SupplicantView.NAMES_AND_AVATARS =
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
  Jalen:   'Males/M03.png'
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