import macros, os

macro importAllTests*(folderPath: string): untyped =
  result = newNimNode(nnkStmtList)
  for f in walkDir(folderPath.strVal):
    result.add newTree(nnkImportStmt, ident(f.path))

importAllTests("tests")
