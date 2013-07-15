set BASEDIR=%1
  bcdedit.exe -createstore BCD
  set BCDEDIT=bcdedit.exe -store BCD
  %BCDEDIT% -create {ramdiskoptions} -d "Ramdisk options"
  %BCDEDIT% -set {ramdiskoptions} ramdisksdidevice boot
  %BCDEDIT% -set {ramdiskoptions} ramdisksdipath \Boot\boot.sdi
  for /f "tokens=3" %%a in ('%BCDEDIT% -create -d "Windows PE" -application osloader') do set GUID=%%a
  %BCDEDIT% -set %GUID% systemroot \Windows
  %BCDEDIT% -set %GUID% detecthal Yes
  %BCDEDIT% -set %GUID% winpe Yes
  %BCDEDIT% -set %GUID% osdevice ramdisk=[boot]\Boot\winpe.wim,{ramdiskoptions}
  %BCDEDIT% -set %GUID% device ramdisk=[boot]\Boot\winpe.wim,{ramdiskoptions}
  %BCDEDIT% -create {bootmgr} -d "Windows Boot Manager"
  %BCDEDIT% -set {bootmgr} timeout 30
  %BCDEDIT% -set {bootmgr} displayorder %GUID%