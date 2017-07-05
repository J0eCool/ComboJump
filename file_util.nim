import os

proc filesInDirWithExtension*(dir, ext: string): seq[string] =
  result = @[]
  for path in os.walkDir(dir):
    if path.kind == pcFile:
      let split = os.splitFile(path.path)
      if split.ext == ext:
        result.add path.path

