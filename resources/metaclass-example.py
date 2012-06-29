class AMeta(type):
  def __new__(meta, name, bases, dict):
    print 'AMeta.__new__ meta:', meta
    print 'AMeta.__new__ name:', name
    print 'AMeta.__new__ bases:', bases
    print 'AMeta.__new__ dict:', dict
    dict.update({'a_dict':{}})
    return super(AMeta, meta).__new__(meta, name, bases, dict)

class A(object):
  __metaclass__ = AMeta

  
class B(A):
  a_dict = {}
  a_dict['a'] = 'hello'
  
class C(A):
  a_dict = {}
  a_dict['b'] = 'world'
  
print B.a_dict
print C.a_dict
