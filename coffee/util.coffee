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
  
# pick a random element from an array
util.choice = (array) ->
  index = Math.floor(Math.random() * array.length)
  return array[index]