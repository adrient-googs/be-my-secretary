###
Useful Utilities
###

# create a "module" called util
util = util ? {}

util.assertion = (condition, err_msg) ->
  unless condition
    alert err_msg
    throw new Error err_msg

# Flips the arguments to a function
util.flip = (func) ->
  (args...) ->
    func args[...].reverse()...

# perform an action later, but not in the current thread
# util.later 1000, func - peform the action in 1 second
# util.later func       - peform the action in 1 millisecond
util.later = (args...) ->
  if args.length == 1
    [func, ms] = [args[0], 1]
  else if args.length == 2
    [func, ms] = [args[1], args[0]]
  else
    throw new Error 'util.later takes 1 or 2 arguments only.'
  setTimeout func, ms
  
# converts a string To Title Case
util.titleCase = (str) ->
  str.replace /\w\S*/g, (txt) ->
    txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()

# adrient@google.com -> adrient
util.prettyUsername = (name) ->
  at_index = name.indexOf('@')
  if at_index > 0 then name[0...at_index] else name
  
###########
# OBJECTS #
###########

# Converts: [[k1,v1], [k2,v2], ...]
# To:       {k1:v1, k2:v2, ...}
util.mash = (array) ->
  dict = {}
  for key_value in array
    [key, value] = key_value
    dict[key] = value
  return dict

# returns true if the argument is an integer
util.isInteger = (obj) ->
  _.isNumber(obj) and (obj % 1 == 0)

util.typeName = (obj) ->
  if !obj?
    return 'undefined'
  return obj.__proto__.constructor.name
    
############
# BACKBONE #
############

# sets it up so that the model uses a Backbone.Collection
# as an attribute, i.e.
#
# model[collection_name]    -> the_collection
# model.get collection_name -> the_collection.models
#
# Also sets up event handlers so that:
#
# 1. The collection and model stay in synch.
# 2. Collection events route to the model as "collection_name:event"
util.setCollectionAsAttribute = (model, collection_name, initial_elts=[]) ->
  # setup the collection and add is as an attribute
  collection = new Backbone.Collection initial_elts  
  model[collection_name] = collection
  model.set collection_name, collection.models
  
  # changes to the collection are reflected in the model
  collection.on 'add remove change', =>
    console.log " --- updating #{util.typeName model} based on collection change" # <- debug
    model.attributes[collection_name] = collection.models
  
  # changes to the model are reflected in the collection
  model.on "change:#{collection_name}", =>
    console.log " --- updating collection based on #{util.typeName model} change" # <- debug
    collection.reset model.attributes[collection_name]
  
  # send all collection events to the model
  collection.on 'all', (type, args...) => model.trigger "#{collection_name}:#{type}", args...
  
########
# DATE #
########

# converts a float to a time string
util.timeStr = (hour) ->
  return 'noon' if hour == 12
  [hour, suf] = 
    if hour < 12 then [hour, 'am']
    else if hour < 13 then [hour, 'pm'] 
    else [hour - 12, 'pm'] 
  if util.isInteger(hour) then "#{hour}#{suf}"
  else "#{Math.floor(hour)}:30#{suf}"

util.WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
  
##########
# RANDOM #
##########
  
# random integer in interval [0,max)
util.randInt = (max) ->
  Math.floor(Math.random() * max)
  
# pick a random element from an array not in the exclude array
util.choose = (array, exclude=[]) ->
  loop
    elt = array[util.randInt array.length]
    return elt unless elt in exclude
    
    
# returns a unique identifier
util.uid = ->
  'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
    r = util.randInt 16
    (if (c == 'x') then r else (r&0x3|0x8)).toString(16)
    
###
  Performs each action with a given probability, e.g.

    util.withProbability [
      0.25, -> action A
      0.50, -> action B
      null, -> action C
    ]

  performs action A with probability 0.25, action B with
  probability 0.5 and action C with the remaining 0.25
  probability.
###
util.withProbability = (actions) ->
  random = Math.random()
  for ii in [0...actions.length] by 2
    [prob, action] = actions[ii..ii+1]
    return action() if !prob? or (random -= prob) < 0
    
###############
# HTML LAYOUT #
###############
  
###
  Appends an element to a div assuming all elements are laid
  out as follows:

    ELT   height
    SPACE vertical_margin
    ELT   height
    SPACE vertical_margin
    ELT   height

  Also, resizes the containing div.
###
util.verticalAppend = (elt, container, height, vertical_margin) ->
  n_children = container.children().length
  elt.css
    height: height
    top: n_children * (height + vertical_margin)
  container.css height: 
    height * (n_children + 1) + vertical_margin * n_children
  container.append(elt)