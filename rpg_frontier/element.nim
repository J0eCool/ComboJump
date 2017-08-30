import
  rpg_frontier/[
    percent,
  ]

type
  Element* = enum
    physical
    fire
    ice
  ElementSet*[T] = array[Element, T]

proc newElementSet*[T](): ElementSet[T] =
  discard

proc newElementSet*[T](initVal: T): ElementSet[T] =
  for e in Element:
    result[e] = initVal

proc init*[T](elements: ElementSet[T], element: Element, val: T): ElementSet[T] =
  result = elements
  result[element] = val

proc `*`*[T](elements: ElementSet[T], pcts: ElementSet[Percent]): ElementSet[T] =
  for e in Element:
    result[e] = elements[e] * pcts[e]
proc `+`*[T](elements: ElementSet[T], pcts: ElementSet[Percent]): ElementSet[T] =
  for e in Element:
    result[e] = elements[e] + pcts[e]
