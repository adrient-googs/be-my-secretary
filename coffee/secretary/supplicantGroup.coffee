class SupplicantGroup extends Backbone.Model
  defaults:
    supplicants: undefined
    an_int: 0
  
  # constructor
  initialize: ->
    # manage supplicants property through private collection
    @supplicants = new Backbone.Collection
    @supplicants.comparator = (sup) -> sup.get 'name'
    @set 'supplicants', @supplicants.models
    @supplicants.on 'all', (args...) => @trigger args...
      
    # create the view
    @view = new SupplicantGroupView model:@
        
  # add a supplicant
  add: (sup) ->
    util.assertion (sup.get('group') is @),
      'Incorrect group.'
    @supplicants.add sup
    
  # adds a random supplicant (not in the group)
  addRandomSupplicant: ->
    possibilities = _.keys SupplicantView.NAMES_AND_AVATARS
    supplicants = @get 'supplicants'
    loop
      name = util.choose possibilities
      break if name not of supplicants
    @add new Supplicant name:name, group:@
    
class SupplicantGroupView extends Backbone.View
  # constructor
  constructor: (args) ->
    args.el = $('#supplicantGroup')
    super args
    
  # after all elements have been set
  initialize: ->
    @model.on 'add', (args...) => @onAddSupplicant(args...)
    
    # debug - begin
    @model.on 'all', (args...) =>
      console.log 'SupplicantGroupView event'
      console.log args
    # debug - end
    
  # called when a upplicant is added
  onAddSupplicant: (sup) ->
    util.vertical_append sup.view.$el, @$el,
      SupplicantView.HEIGHT
      SupplicantView.VERTICAL_MARGIN    
  