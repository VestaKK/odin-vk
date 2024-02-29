@echo off

set CommonCompilerFlags= -define:MATT_INTERNAL=1 -define:MATT_SLOW=1 -define:MATT_WIN32=1

REM Is this possible to do without setting environment variables?
odin.exe build src -debug %CommonCompilerFlags% -out:..\..\build\matt.exe

REM -thread-count:12
