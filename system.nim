import macros

import entity

macro defineSystem*(body: untyped): untyped =
  var ps = body[0].params
  ps[0] = ident("Events")
  ps.insert 1, newIdentDefs(ident("entities"), ident("Entities"))
  return body
