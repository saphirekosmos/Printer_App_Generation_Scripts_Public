
set printer=REPLACEME

REM Removes printer if it exists.
rundll32 printui.dll, PrintUIEntry /gd /q /n "%printer%"

TIMEOUT 3

REM Adds printer
rundll32 printui.dll, PrintUIEntry /ga /q /n "%printer%"


