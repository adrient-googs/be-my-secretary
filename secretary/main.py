import webapp2
from google.appengine.api import users
from google.appengine.ext.webapp import template

import os
import sys
import logging

# include this project's python libraries
sys.path.append(os.path.join(os.path.dirname(__file__), 'python'))
import chatter
import secretary

class MainPage(webapp2.RequestHandler):
  """The principal interface through which the player accesses the game."""
  def get(self):
    user = users.get_current_user()
    if user:
      path = os.path.join(os.path.dirname(__file__), 'templates/game.html')
      template_values = {
        'nickname': user.nickname(),
        'logout_url': users.create_logout_url('/'),
      }
      self.response.headers['Content-Type'] = 'text/html'
      self.response.out.write(template.render(path, template_values))
    else:
      self.redirect(users.create_login_url(self.request.uri))

# every widget provides a mapping of its own request handlers
handlers = chatter.getAllRemoteHandlers()

# handler for the main page
handlers.extend([
  ('/', MainPage),
  ('/.*', MainPage),
])
  
# Log all handlers.
logging.info('Mapped the followning handlers:')
for handler in handlers:
  logging.info('%s : %s' % handler)

# create the app
app = webapp2.WSGIApplication(handlers, debug=True)
