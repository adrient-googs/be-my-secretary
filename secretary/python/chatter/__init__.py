"""

The chatter package provides a set of wrappers around appengine
basically to allow named method calls.

"""

from chatter import wrap, unwrap, register
from jsonProperty import JSONProperty
from remote import RemoteModel, RemoteMethod, getAllRemoteHandlers
from channel import Channel

