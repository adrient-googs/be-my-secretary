# let's the user play the game without wizard of oz  
class TestGame extends Game
  # after construction
  initialize: (options) ->
    super options

    # setup a view
    @view = new TestGameView model:@
    
    # create some elements
    cal = new Calendar
    rabble = new Rabble cal
    @set calendar:cal, rabble:rabble
    
    # add some supplicants
    for ii in [1..5]
      @get('rabble').addRandomSupplicant()
    
# viewer for the test game
class TestGameView extends GameView
  # constructor
  constructor: (options) ->
    options.el = $('#prototypes .testGameView').clone()[0]
    super options
  
  # after construction
  initialize: (options) ->
    super options
    
    # # setup the add calendar button
    # console.log 'TEST ADD CALENDAR'
    # console.log $('#testAddCalendar')
    # @$el.find('button#testAddCalendar').on 'click', =>
    #   @model.get('calendar').saveNew()
      
# # singleton class representing the game state
# class Game extends Backbone.Router
#   # singleton instance
#   @the_game: undefined
#   
#   routes:
#     'test'         : 'routeTest'     # play the test game
#     'calendar/:id' : 'routeCalendar' # see a calendar
#   
#   # constructor
#   constructor: (cal, rabble, guide) ->
#     # ensure this object is a singleton
#     if Game.the_game?
#       throw new Error 'Game is a singleton object.'
#     Game.the_game = @
# 
#     # set instance objects
#     @calendar = cal
#     @rabble = rabble
#     @guide = guide
#     
#     # TODO - begin - move this to an instance class
#     $('#gameArea').append(@calendar.view.$el)
#     $('#gameArea').append(@rabble.view.$el)
#     $('#gameArea').append(@guide.view.$el)
#     # Game.showLayout()
#     # TODO - end
#     
#     # superclass constructor
#     super()
#     
#   # after construction
#   initialize: ->
#     console.log "Game.initialize"
#     # @sec_remaining = 666
#     
#   # set up the game area
#   setup: (options) ->
#     # set the background image
#     $('#gameArea').css
#       backgroundImage: "url('/imgs/background-#{options.mode}.png')"
#     
#     # make everything invisible but the current mode
#     for el in $('.modeDependant')
#       el = $(el)
#       el.css visibility: if el.hasClass "mode-#{options.mode}" \
#         then 'visible' else 'hidden'
#     
#   # player playing the test game
#   routeTest: ->
#     @setup mode:'test'
#     @start()
# 
#   # see a particular calendar
#   routeCalendar: (id) ->
#     @setup mode:'loading'
#     console.log 'GET CALENDAR'
#     console.log "id:#{id}"
#     
#   # starts the game loop
#   start: ->
#     # @rabble.addRandomSupplicant()
#     # @rabble.addRandomSupplicant()
#     # @interval_func_id = setInterval (=> @tick()), 1000 # for now, don't set an interval
#     
#   # ticks once per second
#   tick: ->
#     console.log 'tick'
#     util.withProbability [0.1, => @get('rabble').addRandomSupplicant()]
#     @sec_remaining -= 1
#     if @sec_remaining <= 0
#       alert 'Game Over!'
#       clearInterval @interval_func_id
#     $('#remaining').text "#{@sec_remaining}"


