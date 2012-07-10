# main function
$ ->
	cal = new Calendar
	rabble = new Rabble cal
	game = new Game cal, rabble
	Backbone.history.start()

# singleton class representing the game state
class Game extends Backbone.Router
	# singleton instance
	@the_game: undefined
	
	routes:
		'test'							 : 'routeTest'
		'getCalendar/:id'		 : 'routeGetCalendar'
	
	# constructor
	constructor: (cal, rabble) ->
		# ensure this object is a singleton
		if Game.the_game?
			throw new Error 'Game is a singleton object.'
		Game.the_game = @

		# set instance objects
		@calendar = cal
		@rabble = rabble
		
		# superclass constructor
		super()
		
	# after construction
	initialize: ->
		console.log "Game.initialize"
		# @sec_remaining = 666
		
	# set up the game area
	setup: (options) ->
		# set the background image
		$('#gameArea').css
		  backgroundImage: "url('/imgs/background-#{options.mode}.png')"
		
		# make everything invisible but the current mode
		for el in $('.modeDependant')
			el = $(el)
			el.css visibility: if el.hasClass "mode-#{options.mode}" \
				then 'visible' else 'hidden'
		
	# player playing the test game
	routeTest: ->
		@setup mode:'test'
		@start()

	# player playing the test game
	routeGetCalendar: (id) ->
		console.log 'GET CALENDAR'
		console.log "id:#{id}"
		
	# starts the game loop
	start: ->
		@rabble.addRandomSupplicant()
		@rabble.addRandomSupplicant()
		# @interval_func_id = setInterval (=> @tick()), 1000 # for now, don't set an interval
		
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
	@showLayout = ->
		colors = ['blue', 'green', 'red', 'yellow', 'purple', 'orange']
		for color in colors
			$(".test-#{color}").css
				backgroundColor: color
