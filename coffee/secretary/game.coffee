# main function
$ ->
  # debug - begin - create a calendar event
  e = new CalEvent 
  $('#calendarArea').append(e.view.el)
  # debug - end
  console.log "event #{e}"

  # showLayout() # <- debug
  
# this debug function draws a background behind every visible element
# so that they can be laid out
showLayout = ->
  colors = ['blue', 'green', 'red', 'yellow']
  for color in colors
    $(".test_#{color}").css
      backgroundColor: color
