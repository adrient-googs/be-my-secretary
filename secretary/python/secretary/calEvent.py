from google.appengine.ext import db
from chatter import RemoteModel, RemoteMethod, StructuredProperty, Channel
import logging

class CalEvent(RemoteModel):
  """A calendar event. We subclass RemoteModel only for
  serialization purposes, but these are never actually stored."""

  def put(self):
    """Throws an exception to prevent this class from ever actually
    being written to the database."""
    raise RuntimeError, 'CalEvents cannot directly be stored. ' \
      '(They must be stored through a Calendar.)'