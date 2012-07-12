# Fundamentally, a Rabble is a collection of Supplicant objects.
class Rabble extends Backbone.Model
  # constructor
  constructor: (@calendar) ->
    super
  
  # after construction
  initialize: ->
    # manage supplicants property through private collection
    util.setCollectionAsAttribute @, 'supplicants'
    @supplicants.comparator = (sup) -> sup.get 'name'

    # create the view
    @view = new RabbleView model:@
    
    # event handlers
    @calendar.on 'change:calEvents', => @resetMapping()
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
    attribs.title = CalEvent.TITLES[0]
      # util.choose [1...CalEvent.TITLES.length]
    # # title
    # attribs.title =
    #   util.choose CalEvent.TITLES[1...CalEvent.TITLES.length]
    
    [attribs.days, attribs.day_str] =
      util.withProbability [
        0.08, -> ['1',     '--']
        0.08, -> ['2',     '--']
        0.08, -> ['3',     '--']
        0.08, -> ['4',     '--']
        0.08, -> ['5',     '--']
        0.08, -> ['12',    '--']
        0.08, -> ['23',    '--']
        0.08, -> ['34',    '--']
        0.08, -> ['45',    '--']
        0.08, -> ['123',   '--']
        0.08, -> ['234',   '--']
        0.08, -> ['345',   '--']
        null, -> ['1',     '--']
      ]
    [attribs.start, attribs.end, attribs.time_str] =
      util.withProbability [
        0.25, -> [ 9, 13, 'Morning']
        0.25, -> [13, 17, 'Afternoon']
        0.50, -> [ 9, 17, 'Any Time']
      ]
    
    # length
    attribs.length = 4
    util.assertion 1 <= attribs.length <= attribs.end - attribs.start,
      "Invalid length: #{attribs.length} (start:#{attribs.start} end:#{attribs.end})"
    attribs.length_str = if attribs.length == 1 then "1 hr" else "#{attribs.length} hrs"
    
    # add it in
    @add new Supplicant attribs
    
  # compute the mapping between supplicants and calEvents
  resetMapping: ->
    console.log "  _!_!_ RESET MAPPING _!_!_"
    
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
        
        # calEvent.view.setStatus sup.checkStatus calEvent
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
  constructor: (options) ->
    options.el = $('#prototypes .rabbleView').clone()[0]
    super options

  # after all elements have been set
  initialize: ->
    @container = @$el.find('#container')
    @model.on 'supplicants:add', (sup) => @onAddSupplicant sup

    # # debug - begin
    # @model.on 'all', (args...) =>
    #   console.log 'RabbleView event'
    #   console.log args
    # # debug - end

  # called when a upplicant is added
  onAddSupplicant: (sup) ->
    util.verticalAppend sup.view.$el, @container,
      SupplicantView.HEIGHT
      SupplicantView.VERTICAL_MARGIN
    @model.calendar.view.$el.prepend(sup.constraint_view.el)
