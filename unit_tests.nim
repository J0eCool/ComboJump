import macros, os

macro importAllTests*(folderPath: string): untyped =
  echo folderPath.treeRepr
  result = newNimNode(nnkStmtList)
  for f in walkDir(folderPath.strVal):
    result.add newTree(nnkImportStmt, ident(f.path))
  echo result.treeRepr

importAllTests("tests")
