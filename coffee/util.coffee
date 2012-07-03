###
Useful Utilities
###

# create a "module" called util
util = util ? {}

util.assertion = (condition, err_msg) ->
  (throw new Error err_msg) unless condition

# Flips the arguments to a function
util.flip = (func) ->
  (args...) ->
    func args[...].reverse()...

# converts a string To Title Case
util.titleCase = (str) ->
  str.replace /\w\S*/g, (txt) ->
    txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()

# perform an action later (in 1ms), but not in the current thread
util.later = (func) ->
  setTimeout func, 1
  
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
  return obj.__proto__.constructor.name
  
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
  
###############
# PROBABILITY #
###############
  
# random integer in interval [0,max)
util.randInt = (max) ->
  Math.floor(Math.random() * max)
  
# pick a random element from an array not in the exclude array
util.choose = (array, exclude=[]) ->
  loop
    elt = array[util.randInt array.length]
    return elt unless elt in exclude
    
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