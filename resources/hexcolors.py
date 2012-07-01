colors = [
  ('text dark',  '5d5755'),
  ('text light', 'c3b5ae'),
  ('boxes',      'c3b5ae'),

  ('A1',         'fed200'),
  ('A2',         'fabf00'),
  ('A3',         'f8800c'),
  ('A4',         'f09000'),

  ('B1',         'ea7422'),
  ('B2',         'df5a36'),
  ('B3',         'e2013d'),
  ('B4',         'dc006a'),

  ('C1',         'afabb9'),
  ('C2',         '82cbd2'),
  ('C3',         '37b9d1'),
  ('C4',         '2f85cd'),

  ('D1',         'd4a82c'),
  ('D2',         'b1c535'),
  ('D3',         '95bf0a'),
  ('D4',         '84ba64'),
]

for name, color_hex in colors:
  r = int(color_hex[0:2], 16)
  g = int(color_hex[2:4], 16)
  b = int(color_hex[4:6], 16)
  print '[ ] % 10s - % 3s % 3s % 3s' % (name, r, g, b)