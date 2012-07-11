###
Enables serialization (wrapping) and deserialization (unwrapping) of
arbitrary objects according to the chatter protocol.
###

# create a "module"
chatter = chatter ? {}

# table used to map back to types
chatter.unwrap_table = {}

# register a type in the unwrap table
chatter.register = (type) ->
  chatter.unwrap_table[type.name] = type

# heper function

# serializes to a json object
chatter.wrap = (obj) ->
  # console.log "about to wrap: #{util.typeName obj}"
  # if _.isObject(obj)
  #   console.log "keys: #{_.keys obj}"
  
  if _.isFunction(obj?.wrap)
    obj.wrap()
  else if _.isUndefined(obj)
    ['NoneType', '']
  else if _.isNull(obj)
    ['NoneType', '']
  else if _.isBoolean(obj)
    ['bool', obj]
  else if util.isInteger(obj)
    ['int', obj]
  else if _.isNumber(obj)
    ['float', obj] 
  else if _.isString(obj)
    ['str', obj]
  else if _.isArray(obj)
    ['list', (chatter.wrap(x) for x in obj)]
  else if _.isObject(obj)
    console.log "wrapping object keys: #{_.keys obj}"
    ['dict', chatter.wrap ([key, value] for key, value of obj)]
  else
    throw new Error "cannot wrap #{obj}"

# deserializes a json object
chatter.unwrap = (obj) ->
  [type_name, data] = obj
  type = chatter.unwrap_table[type_name]
  if type?
    attribs = util.mash ([key, chatter.unwrap(value)] for key, value of data)
    
    # debug - begin
    console.log "unwrapping!!! #{type.name}"
    # console.log attribs
    # debug - end
    
    return new type attribs
  else switch type_name
    when 'list' then (chatter.unwrap(x) for x in data)
    when 'dict' then util.mash chatter.unwrap data
    when 'int', 'long', 'unicode', 'str', 'float' then data
    when 'NoneType' then undefined

    else throw new Error "type_name \"#{type_name}\" not understood"
      
      


