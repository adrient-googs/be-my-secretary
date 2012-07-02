# main function
$ ->
  # m1 = new Backbone.Model an_int:123
  # console.log m1.get 'an_int'
  # m1.on 'change', (model, options) ->
  #   console.log "CHANGE"
  #   console.log m1.get 'an_int'
  #   console.log m1.previousAttributes()
  # m1.set 'an_int', 777
  # return
  
  # debug - begin - create a supplicant
  group = new SupplicantGroup
  group.addRandomSupplicant()
  group.addRandomSupplicant()
  group.addRandomSupplicant()
  group.addRandomSupplicant()
  # debug - end
  
  # debug - begin - create a calendar and add an event
  c = new Calendar
  console.log "created calendar #{c}"
  c.addNewEvent()
  # debug - end
  
  # set up the addEvent button
  $('button#bigAddEvent').on 'click', ->
      c.addNewEvent()
      return false
  
  # s = new Supplicant
  # # $('#calendar').append(e.view.el)
  # console.log 'supplicant'
  # console.log s
  # debug - end

  # showLayout() # <- debug
  
# this debug function draws a background behind every visible element
# so that they can be laid out
showLayout = ->
  colors = ['blue', 'green', 'red', 'yellow', 'purple', 'orange']
  for color in colors
    $(".test-#{color}").css
      backgroundColor: color
