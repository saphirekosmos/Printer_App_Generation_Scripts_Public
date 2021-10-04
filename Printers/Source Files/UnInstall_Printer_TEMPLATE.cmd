
set printer=REPLACEME

REM Removes printer if it exists.
rundll32 printui.dll, PrintUIEntry /gd /q /n "%printer%"