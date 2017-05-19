SET MT_PROGRAM_DIR=C:\games\Minetest
IF EXIST "C:\Games\ENLIVEN" SET MT_PROGRAM_DIR=C:\Games\ENLIVEN
copy /y *.lua "%MT_PROGRAM_DIR%\games\ENLIVEN\mods\metatools\"
copy /y *.md "%MT_PROGRAM_DIR%\games\ENLIVEN\mods\metatools\"
copy /y textures\*.png "%MT_PROGRAM_DIR%\games\ENLIVEN\mods\metatools\textures\"
if NOT ["%errorlevel%"]==["0"] pause