# let's the user play the game without wizard of oz  
class TypeGame extends Game
  # after construction
  initialize: (game_length) ->
    super()
    game_length ?= 180
    @set 'remaining', game_length

    # setup a view
    @view = new TypeGameView model:@
    
    # only perform initialization after getting channel token
    Player.getMyChannelToken (token) =>
      console.log "Recieved channel token: #{token}"
      openChannel token, @
      
    # create some elements
    cal = new Calendar
    rabble = new Rabble cal
    guide = new Guide
    @set calendar:cal, rabble:rabble, guide:guide
    
    # debug - begin - add a cover 
    cover = $('<div id="calendarCover">')
    cover.css
      backgroundColor: 'white'
      width: 630
      height: 320
      left: 82
      top: 313
      opacity: 0.25
      zIndex: 10000
    @view.$el.append(cover)
    console.log 'APPENDING CALENDAR COVER'
    console.log cover
    # debug - end
      
    # event handlers
    guide.on 'instructions:add', TypeGame::onAddInstruction, @
  
    # in 1/10 second start the game
    util.later 100, =>
      alert "You have #{@get 'remaining'} seconds to satisfy as many cosntraints as possible. Click to start."

      # add some supplicants
      for ii in [1..30]
        @get('rabble').addRandomSupplicant()
      
      # setup the timer
      @interval_func_id = setInterval (=> @tick()), 1000
          
  # ticks once per second
  tick: ->
    console.log 'tick'
    remaining = @get('remaining') - 1
    @set 'remaining', remaining
    if remaining <= 0
      alert 'Game Over!'
      clearInterval @interval_func_id
    console.log "remaining: #{remaining}"
      
  # called when instructions have been updated
  postSolution: (args) ->
    # debug - begin
    console.log 'TypeGame.updateInstructions'
    console.log args
    # debug - end

    # update the guide
    guide = @get 'guide'
    guide.updateInstruction args.solved_instruction
    guide.updateInstruction args.next_instruction
    
    # update the calendar
    cal = @get 'calendar'
    cal.set args.solved_calendar.attributes

  # called when a new instruction is added
  onAddInstruction: (new_instruction) ->
    # get some stuff 
    calendar = @get('calendar')
    instructions = @get('guide').get('instructions')
    n_instructions = instructions.length
    
    # debug - begin - verify the order
    for index, inst of instructions
      console.log "#{index} : #{inst.get 'uid'} '#{inst.get 'text'}'"
    # debug - end

    # make sure that the new instruction is the last
    util.assertion n_instructions > 0, \
      'Added instruction but array still empty.'
    util.assertion \
      instructions[n_instructions - 1].get('uid') == new_instruction.get('uid'),
      'New instruction is not the last.'

    # update the instruction fields
    if n_instructions == 1
      # this is the first instruction we add
      new_instruction.set 'calendar_uid', calendar.get('uid')
      data_to_send = instruction:new_instruction, calendar:calendar
    else
      prev_instruction = instructions[n_instructions - 2]
      new_instruction.set 'previous_uid', prev_instruction.get('uid')      
      data_to_send = instruction:new_instruction
      
    # enqueue the instruction
    Instruction.enqueueInstruction data_to_send, (update) =>
      # debug - begin
      console.log "got new update"
      console.log update
      # debug - end

      # because instruction can be overriden, we copy it here
      uid = update.get 'uid'
      results = @get('guide').instructions.where uid:uid
      util.assertion (results.length == 1), "UID #{uid} not unique."
      results[0].set update.attributes
    
# viewer for the test game
class TypeGameView extends GameView
  # constructor
  constructor: (options) ->
    options.el = $('#prototypes .typeGameView').clone()[0]
    super options
  
  # after construction
  initialize: (options) ->
    super options
    
    # show remaining
    @model.on 'change:remaining', =>
      @$el.find('#remaining').text @model.get 'remaining'
    
    
      
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


