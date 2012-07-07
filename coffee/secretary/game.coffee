# main function
$ ->
  cal = new Calendar
  rabble = new Rabble cal
  game = new Game cal, rabble

  # debug - begin
  $('button#bigAddEvent').on 'click', ->
    cal.addNewEvent()
    return false
  # debug - end

  alert 'Click to start.'
  game.start()
  
  # showLayout() # debug

# singleton class w
class Game extends Backbone.Model
  # singleton instance
  @the_game: undefined
  
  # constructor
  constructor: (cal, rabble) ->
    # ensure this object is a singleton
    if Game.the_game?
      throw new Error 'Game is a singleton object.'
    Game.the_game = @
    
    # superclass constructor
    super calendar:cal, rabble:rabble
    
  # after construction
  initialize: (args) ->
    console.log "Game.initialize"
    console.log args
    @sec_remaining = 666
    
  # starts the game loop
  start: ->
    @get('rabble').addRandomSupplicant()
    @get('rabble').addRandomSupplicant()
    @interval_func_id = setInterval (=> @tick()), 1000
    
  # ticks once per second
  tick: ->
    console.log 'tick'
    util.withProbability [0.1, => @get('rabble').addRandomSupplicant()]
    @sec_remaining -= 1
    if @sec_remaining <= 0
      alert 'Game Over!'
      clearInterval @interval_func_id
    $('#remaining').text "#{@sec_remaining}"
  
# this debug function draws a background behind every visible element
# so that they can be laid out
showLayout = ->
  colors = ['blue', 'green', 'red', 'yellow', 'purple', 'orange']
  for color in colors
    $(".test-#{color}").css
      backgroundColor: color
