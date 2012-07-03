# Fundamentally, a Rabble is a collection of Supplicant objects.
class Rabble extends Backbone.Model
  # constructor
  constructor: (@calendar) ->
    super
  
  # after construction
  initialize: ->
    # manage supplicants property through private collection
    @supplicants = new Backbone.Collection
    @supplicants.comparator = (sup) -> sup.get 'name'
    @set 'supplicants', @supplicants.models
    @supplicants.on 'all', (args...) => @trigger args...

    # create the view
    @view = new RabbleView model:@
    
    # event handlers
    @calendar.calEvents.on 'add remove change:name', => @resetMapping()
    
  # add a supplicant
  add: (sup) ->
    sup.parent = @
    @supplicants.add sup

  # adds a random supplicant (not in the group)
  addRandomSupplicant: ->
    attribs = {}
    
    # name
    all_names = _.keys SupplicantView.NAMES_AND_AVATARS
    used_names = @supplicants.pluck('name')
    attribs.name = util.choose all_names, used_names
    
    # title
    attribs.title =
      util.choose CalEvent.TITLES[1...CalEvent.TITLES.length]
    
    # day and time
    util.withProbability [
      0.9, ->
        # normal day
        [attribs.days, attribs.day_str] =
          util.withProbability [
            0.40, -> ['12345', 'Weekday'    ]
            0.15, -> ['06'   , 'Weekend'    ]
            0.15, -> ['135'  , 'M/W/F']
            0.15, -> ['24'   , 'Tue/Thu'    ]
            0.15, -> ['45'   , 'Thu/Fri'    ]
          ]
        [attribs.start, attribs.end, attribs.time_str] =
          util.withProbability [
            0.25, -> [ 9, 12, 'Morning']
            0.25, -> [11, 14, 'Midday' ]
            0.25, -> [15, 17, 'Late'   ]
            0.25, -> [ 9, 17, 'Any Time']
          ]
      null, ->
        # otherwise, pick a weird time
        attribs.days = "#{util.choose [0...7]}"
        attribs.day_str = util.WEEKDAYS[parseInt attribs.days]
        attribs.start = util.choose [9...17]
        attribs.end = util.choose [(attribs.start+1)..17]
        attribs.time_str = "#{util.timeStr(attribs.start)}-#{util.timeStr(attribs.end)}"
    ]
    
    # length
    attribs.length = 0.5 * util.choose [2 .. 2 * (attribs.end - attribs.start)]
    util.assertion 1 <= attribs.length <= attribs.end - attribs.start,
      "Invalid length: #{attribs.length} (start:#{attribs.start} end:#{attribs.end})"
    attribs.length_str = if attribs.length == 1 then "1 hr" else "#{attribs.length} hrs"
    
    # add it in
    @add new Supplicant attribs
    
  # compute the mapping between supplicants and calEvents
  resetMapping: ->
    # call this function to link/unlink a supplicant/calEvent pair
    link = (sup, calEvent) ->
      if !calEvent?
        # unlink calEvent from supplicant
        sup.unset 'calEvent'
        sup.constraint_view.fadeOut()
      else if !sup?        
        # unlink supplicant from calEvent
        calEvent.view.setStatus 'unmatched'
        calEvent.off 'change', Supplicant::onCalEventChange
        calEvent.view.$el.off 'mouseenter'
        calEvent.view.$el.off 'mouseleave'
      else 
        # link supplicant and calEvent
        console.log "linking #{sup.get 'name'} <-> #{calEvent.get 'name'}"
        sup.set 'calEvent', calEvent
        
        calEvent.view.setStatus sup.checkStatus calEvent
        calEvent.on 'change', Supplicant::onCalEventChange, sup
        calEvent.view.$el.on 'mouseenter', => sup.constraint_view.fadeIn()
        calEvent.view.$el.on 'mouseleave', => sup.constraint_view.fadeOut()
   
    # clear the previous mapping
    for sup in @supplicants.models
      link sup, undefined
    
    # construct a new mapping
    for calEvent in @calendar.calEvents.models
      sup = @supplicants.getByCid calEvent.get 'name'
      link sup, calEvent

class RabbleView extends Backbone.View
  # constructor
  constructor: (args) ->
    args.el = $('#rabble')
    super args

  # after all elements have been set
  initialize: ->
    @model.on 'add', (sup) => @onAddSupplicant sup

    # # debug - begin
    # @model.on 'all', (args...) =>
    #   console.log 'RabbleView event'
    #   console.log args
    # # debug - end

  # called when a upplicant is added
  onAddSupplicant: (sup) ->
    util.verticalAppend sup.view.$el, @$el,
      SupplicantView.HEIGHT
      SupplicantView.VERTICAL_MARGIN
    $('#calendar').prepend(sup.constraint_view.el)
