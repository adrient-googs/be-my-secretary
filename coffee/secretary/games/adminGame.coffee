# let's the user play the game without wizard of oz  
class AdminGame extends Game
  # after construction
  initialize: (func, args...) ->
    # setup a view
    @view = new AdminGameView model:@
    super()
    
    # create the calendar
    @set calendar:(new Calendar)
    
    # call the function
    @[func](args...)

  ############################
  # Administrative Functions #
  ############################
    
  # gets a calendar where field=id
  getCalendar: (field, id) ->
    Calendar.getCalendar field:field, value:id, (cal) =>
      if cal?
        @get('calendar').set cal.attributes
        @view.log "uid: #{cal.uid}"
      else
        alert "No calendar with #{field}=#{id}."
    
# viewer for the test game
class AdminGameView extends GameView
  # constructor
  constructor: (options) ->
    options.el = $('#prototypes .adminGameView').clone()[0]
    super options

  # after construction
  initialize: (options) ->
    super options
    
    # store the console
    @console = @$el.find('#console')
    
  # writes a string to the console
  log: (str) ->
    @console.append $('<div>').text str

