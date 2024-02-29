@echo off

echo -------
echo -------

set Wildcard=*.odin

echo TODOS FOUND:
findstr -s -n -i -l "TODO" %Wildcard%

echo -------
echo -------
