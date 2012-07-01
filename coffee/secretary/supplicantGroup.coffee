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
      
    # get a view
    @view = new SupplicantGroupView model:@
    
    
  # add a supplicant
  add: (sup) -> @supplicants.add sup
    # name = supplicant.get 'name'
    # supplicants = @get 'supplicants'
    # util.assertion (name not of supplicants),
    #   'Cannot add two of the same supplicant.'
    # supplicants[name] = supplicant
    # return supplicant
    
  # adds a random supplicant (not in the group)
  addRandomSupplicant: ->
    possibilities = _.keys Supplicant.NAMES_AND_AVATARS
    supplicants = @get 'supplicants'
    loop
      name = util.choice possibilities
      break if name not of supplicants
    @add new Supplicant name:name, group:@
    
    # # manually trigger change events
    # changes = changes: {supplicants:true}
    # @trigger 'change:supplicants', @, supplicants, changes
    # @trigger 'change', @, changes
    
class SupplicantGroupView extends Backbone.View
  # constructor
  constructor: (args) ->
    args.el = $('#supplicantGroup')
    super args
    
  # after all elements have been set
  initialize: ->
      @model.on 'add', (args...) => @onAddSupplicant(args...)
    
  # called when a upplicant is added
  onAddSupplicant: (args...) ->
    console.log 'onAddSupplicant'
    console.log @
    console.log args
    console.log args[0].get 'name'
    console.log args[0].cid
    
  