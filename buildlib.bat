rename testlib.dll testlib_old.dll
nim c --app:lib testlib.nim
sleep 5
rm testlib_old.dll
