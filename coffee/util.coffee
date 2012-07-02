###
Useful Utilities
###

# create a "module" called util
util = util ? {}

# Converts: [[k1,v1], [k2,v2], ...]
# To:       {k1:v1, k2:v2, ...}
util.mash = (array) ->
  dict = {}
  for key_value in array
    [key, value] = key_value
    dict[key] = value
  return dict

util.assertion = (condition, err_msg) ->
  (throw new Error err_msg) unless condition

# Flips the arguments to a function
util.flip = (func) ->
  (args...) ->
    func args[...].reverse()...

# returns true if the argument is an integer
util.isInteger = (obj) ->
  _.isNumber(obj) and (obj % 1 == 0)
  
# pick a random element from an array not in the exclude array
util.choose = (array, exclude=[]) ->
  loop
    index = Math.floor(Math.random() * array.length)
    elt = array[index]
    return elt unless elt in exclude
  
###
  Appends an element to a div assuming all elements are laid out as follows:
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