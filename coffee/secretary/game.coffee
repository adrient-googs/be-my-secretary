# main function
$ ->
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
  c.add new CalEvent 
  # $('#calendar').append(e.view.el)
  # debug - end
  
  # set up the addEvent button
  $('button#bigAddEvent').on 'click', ->
    c.add new CalEvent
    # showLayout()
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
