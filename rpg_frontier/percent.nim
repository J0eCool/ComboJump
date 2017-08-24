type
  Percent* = distinct int

proc `-`*(pct: Percent): Percent =
  Percent(-pct.int)

proc `*`*(pct: Percent, n: int): int =
  (n * pct.int) div 100
proc `*`*(n: int, pct: Percent): int =
  pct * n
proc `*`*(pct: Percent, n: float): float =
  n * pct.float / 100.0
proc `*`*(n: float, pct: Percent): float =
  pct * n

proc `+`*(n: int, pct: Percent): int =
  n * (100 + pct.int) div 100
proc `-`*(n: int, pct: Percent): int =
  n * (100 - pct.int) div 100

