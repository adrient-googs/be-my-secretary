# main function
$ ->
  cal = new Calendar
  
  supplicants = new Rabble cal
  supplicants.addRandomSupplicant()
    
  # set up the addEvent button
  $('button#bigAddEvent').on 'click', ->
    cal.addNewEvent()
    return false

  
# this debug function draws a background behind every visible element
# so that they can be laid out
showLayout = ->
  colors = ['blue', 'green', 'red', 'yellow', 'purple', 'orange']
  for color in colors
    $(".test-#{color}").css
      backgroundColor: color
