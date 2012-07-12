# main function
$ ->
  # routing strings
  routes =
    'test'                    : TestGame
    'do'                      : DoGame
    'admin'                   : AdminGame
    'admin/:func'             : AdminGame
    'admin/:func/:arg0'       : AdminGame
    'admin/:func/:arg0/:arg1' : AdminGame
    
  # attach these routes to the router
  Game.router = new Backbone.Router
  create_game = (game_type) =>
    (args...) => Game.instantiate game_type, args...
  for name, game_type of routes
    Game.router.route name, '', create_game game_type
    
  # default route
  Game.router.route '', '', =>
    Game.router.navigate 'test', trigger: true
    
  # start routing
  Backbone.history.start()

# subclass of all game objects
class Game extends Backbone.Model
  # the instance that is being viewd
  @game: undefined
  
  # sets the game which the player sees
  @instantiate: (game_type, args...) ->
    if @game?
      console.log "_!_!_!_ DELETING PREVIOUS GAME _!_!_!_"
      @game.view.$el.remove()

    console.log "_!_!_!_ CREATING NEW GAME _!_!_!_ : #{game_type.name}"
    @game = new game_type args...
    console.log "appending"
    console.log @game.view.$el
    $('#gameArea').prepend(@game.view.$el)
  
class GameView extends Backbone.View
  initialize: (options) ->
    super options
    @model.on 'change', GameView::onChange, @
    
  # called when an element was added to the view
  onChange: (model, options) ->
    console.log 'TODO: remove the previous version of whatever it was'
    for attrib in _.keys options.changes
      new_view = @model.get(attrib).view
      console.log "ADDING VIEW: #{util.typeName new_view}"
      @$el.append new_view.$el
      
  # this debug function draws a background behind every visible element
  # so that they can be laid out
  @showDebugColors: ->
    colors = ['blue', 'green', 'red', 'yellow', 'purple', 'orange']
    for color in colors
      $(".test-#{color}").css
        backgroundColor: color