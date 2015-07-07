REM This is a windows terminal console (batch) script using jpegtran to optimize your images
REM it's just removing meta-data and changing the codification to progressive.
REM for more options please visit http://jpegclub.org/jpegtran/

REM Questions? write at @RNLD85

@echo none 
for /f "delims=" %%a in ('dir "*.jpg" /b /s /a-d') do (
	echo processing "%%a"
	"C:\Users\Ronald\Desktop\Temp\ImgTools\jpegtran\jpegtran.exe" -optimize -progressive -copy none "%%a" "%%a.tmp"
	move /Y "%%a.tmp" "%%a" >nul
)
pause