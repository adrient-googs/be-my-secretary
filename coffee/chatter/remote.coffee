###
Enables serialization (wrapping) and deserialization (unwrapping) of
arbitrary objects according to the chatter protocol.
###
    
###
Enables entities and methods to be serialized across the internet.
###
class RemoteModel extends Backbone.Model
  
  # Returns the url root for get/put/post/delete requests.
  urlRoot: ->
    "#{@__proto__.constructor.name}/datastore"
    
  # parses this object
  parse: (obj) ->
    my_name = @__proto__.constructor.name
    [type_name, data] = obj
    util.assertion (my_name is type_name),
      "#{my_name} cannot parse #{type_name}"
    util.mash ([key, chatter.unwrap(value)] for key, value of data)
    
  # converts this object to json
  toJSON: ->
    my_name = @__proto__.constructor.name
    
    # debug  - begin
    console.log "RemoteModel wrapping #{my_name} attribs: #{_.keys @attributes}"
    if @attributes.calEvents?
      console.log "HAS calEvents, length:#{@attributes.calEvents.length}"
    # debug - end
    
    wrapped_attribs = for key, value of @attributes
      [key, chatter.wrap(value)]
    return [my_name, util.mash wrapped_attribs]
        
  # an alternative to toJSON (used by chatter)
  wrap: -> @toJSON()

  ###
  To declare a remote static method:
    @funcName: RemoteModel.remoteStaticMethod 'funcName'
  To catch errors, bind an object to the "ajaxError" event.
  ###
  @remoteStaticMethod = (name) =>
    (args...) ->
      # parse multiple arguments
      [method_args, done] = switch args.length
        when 0 then [{}, ->]
        when 1 then (if _.isFunction(args[0]) then [{}, args[0]] else [args[0], ->])
        when 2 then args
        else throw new Error 'Too many arguements.'
      $.post "#{@::constructor.name}/method/#{name}",
        JSON.stringify(chatter.wrap({args: method_args}))
        (response) -> done chatter.unwrap(response).return_val

  ###
  To declare a remote instance method:

    funcName: RemoteModel.remoteInstanceMethod 'funcName', options

  Options:
  
    sync_before (default=false) : save to server before remote method invocation
    sync_after (default=false)  : fetch from server after remote method invocation

  To catch errors, bind an object to the "ajaxError" event.
  ###
  @remoteInstanceMethod = (name, options={}) =>
    (args...) ->
      [method_args, done] = switch args.length
        when 0 then [{}, ->]
        when 1 then (if _.isFunction(args[0]) then [{}, args[0]] else [args[0], ->])
        when 2 then args
        else throw new Error 'Too many arguements.'
      request =
        args: method_args
        sync_before: options.sync_before ? false
        sync_after: options.sync_after ? false
      if request.sync_before
        request.self = @
      $.post "#{@__proto__.constructor.name}/method/#{name}/#{@id}",
        JSON.stringify(chatter.wrap(request))
        (response) =>
          response = chatter.unwrap response
          if request.sync_after
            util.assertion (response.self.id == @id), 'ID cannot be reset.'
            @set response.self.attributes
          done response.return_val
