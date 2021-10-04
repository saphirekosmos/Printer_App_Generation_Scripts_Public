
set printer=\\PRINTSERVER\DEPT-ROOM101

REM Removes printer if it exists.
rundll32 printui.dll, PrintUIEntry /gd /q /n "%printer%"
