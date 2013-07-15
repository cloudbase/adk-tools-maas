  $pe_dir              = 'c:\winpe'
  $pe_programs         = 'c:\winpe\build\mount\Program Files (x86)'

  # Our WinPE Folder Structure
  $pe_src              = "$pe_dir\src"
  $pe_drivers          = "$pe_dir\src\drivers"
  $pe_bin              = "$pe_dir\bin"
  $pe_logs             = "$pe_dir\logs"
  $pe_build            = "$pe_dir\build"
  $pe_mount            = "$pe_dir\build\mount"
  $pe_iso              = "$pe_dir\ISO"
  $pe_pxe              = "$pe_dir\PXE"
  $pe_tmp              = "$pe_dir\tmp"

  # ADK Url and Install Options
  $adk_url             = 'http://download.microsoft.com/download/9/9/F/99F5E440-5EB5-4952-9935-B99662C3DF70/adk/adksetup.exe'
  $adk_file            = 'adksetup.exe'
  $adk_features        = 'OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment'
  $adk_install_log     = "$pe_logs\adksetup.log"

  # Windows PE Specific Paths
  $pe_root             = 'C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment'
  $pe_amd64_src        = 'C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64'
  $pe_x32_src          = 'C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\x86'
  $pe_package_src      = 'C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs'
  $pe_deployment_tools = 'C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Deployment Tools'
  $dism_path           = "$pe_deployment_tools\amd64\DISM"
  $bcd_path            = "$pe_deployment_tools\amd64\BCDBoot"
  $wism_path           = "$pe_deployment_tools\WSIM"
  $startnet_cmd        = "$pe_mount\Windows\System32\startnet.cmd"

  # Crowbar server specific info
  $crowbar_server      = "admin"
  $crowbar_share       = "reminst"
  $crowbar_mountpoint  = "p:"
  $crowbar_folder      = "windows-6.2"
  $crowbar_source      = "source"
  $crowbar_unattend    = "unattend"
  $crowbar_boot        = "boot"

  #Location of the install media for the OS:
  $install_media       = "D:"

  # Windows PE Packages
  $winpe_wmi              = "C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WMI.cab"
  $winpe_wmi_enus         = "C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-WMI_en-us.cab"
  $winpe_hta              = "C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WMI.cab"
  $winpe_hta_enus         = "C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-WMI_en-us.cab"
  $winpe_scripting        = "C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-Scripting.cab"
  $winpe_netfx4           = "C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-NetFx4.cab"
  $winpe_netfx4_enus      = "C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-NetFx4_en-us.cab"
  $winpe_powershell3      = "C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-PowerShell3.cab"
  $winpe_powershell3_enus = "C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-PowerShell3_en-us.cab"
  $winpe_storagewmi       = "C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-StorageWMI.cab"
  $winpe_storagewmi_enus  = "C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-StorageWMI_en-us.cab"

rmdir $pe_dir -Recurse

if (!(Test-Path -path $pe_dir)) {New-Item $pe_dir -Type Directory}
if (!(Test-Path -path $pe_src)) {New-Item $pe_src -Type Directory}
if (!(Test-Path -path $pe_drivers)) {New-Item $pe_drivers -Type Directory}
if (!(Test-Path -path $pe_logs)) {New-Item $pe_logs -Type Directory}
if (!(Test-Path -path $pe_bin)) {New-Item $pe_bin -Type Directory}
if (!(Test-Path -path $pe_build)) {New-Item $pe_build -Type Directory}
if (!(Test-Path -path $pe_mount)) {New-Item $pe_mount -Type Directory}
if (!(Test-Path -path $pe_tmp)) {New-Item $pe_tmp -Type Directory}
if (!(Test-Path -path $pe_iso)) {New-Item $pe_iso -Type Directory}
if (!(Test-Path -path $pe_pxe)) {New-Item $pe_pxe -Type Directory}

$adk_reg_key = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{fc46d1b2-9557-4c1f-baac-04af4d2db7e4}"
if(-not (Test-Path -Path $adk_reg_key))
{
  Invoke-WebRequest -UseBasicParsing -uri $adk_url -OutFile $pe_src\$adk_file
  "$pe_src\adksetup.exe /quiet /norestart /features $adk_features /log $adk_install_log"
}
$env:Path += $dism_path;$bcd_path;$wsim_path;$::path
#$env:Path += "c:\Program Files (x86)\7-Zip"

if (!(Test-Path -path "$pe_pxe\Boot")) {New-Item "$pe_pxe\Boot" -Type Directory}

if (!(Test-Path -path "$pe_build\Media")) {New-Item "$pe_build\Media" -Type Directory}
Copy-Item "$pe_root\amd64\Media" "$pe_build" -Recurse

Copy-Item "$pe_root\amd64\en-us\winpe.wim" "$pe_build\winpe.wim"

Copy-Item "$pe_deployment_tools\amd64\Oscdimg\etfsboot.com" "$pe_build\etfsboot.com"

Copy-Item "$pe_deployment_tools\amd64\Oscdimg\oscdimg.exe" "$pe_build\oscdimg.exe"

cmd.exe /c "C:\Program Files (x86)\Windows Kits\8.0\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"

dism.exe /Mount-Wim /WimFile:$pe_build\winpe.wim /index:1 /MountDir:$pe_mount

Copy-Item "$pe_mount\Windows\Boot\PXE\pxeboot.com" "$pe_pxe\Boot\pxeboot.com"

Copy-Item "$pe_mount\Windows\Boot\PXE\pxeboot.n12" "$pe_pxe\Boot\pxeboot.0"

Copy-Item "$pe_mount\Windows\Boot\PXE\bootmgr.exe" "$pe_pxe\Boot\bootmgr.exe"

Copy-Item "$pe_mount\Windows\Boot\PXE\abortpxe.com"  "$pe_pxe\Boot\abortpxe.com"

Copy-Item "$pe_root\amd64\Media\Boot\boot.sdi" "$pe_pxe\Boot\boot.sdi"

cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_wmi`""

cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_wmi_enus`""

cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_hta`""

cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_hta_enus`""

cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_scripting`""

cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_netfx4`""

cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_netfx4_enus`""

cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_powershell3`""

cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_powershell3_enus`""

cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_storagewmi`""

cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_storagewmi_enus`""

# 7zip needs to be installed and also the Drivers.zip file to be placed in ${pe_drivers}

#pushd
#cd $pe_src
#cmd.exe /c "7z.exe x $pe_drivers\Drivers.zip",
#popd

#$driverfile = 'virtio-win-0.1-59.iso'
#$driverurl = 'http://alt.fedoraproject.org/pub/alt/virtio-win/latest/images/bin/'

#Invoke-WebRequest -UseBasicParsing -uri $driverurl/$driverfile -OutFile $pe_drivers\$driverfile

#pushd
#cd $pe_drivers
#cmd.exe /c "`"c:\Program Files\7-Zip\7z.exe`" x $pe_drivers\$driverfile"
#popd

#cmd.exe /c dism.exe /image:$pe_mount /Add-Driver /driver:$pe_drivers /recurse /forceunsigned

# bcdcreate.cmd needs to be placed in $pe_bin\bcdcreate.cmd
Copy-Item .\bcdcreate.cmd $pe_bin\bcdcreate.cmd
pushd
cd $pe_pxe\Boot
cmd.exe /c $pe_bin\bcdcreate.cmd
popd

Add-Content $startnet_cmd "`n"
Add-Content $startnet_cmd "`n net use $crowbar_mountpoint \\$crowbar_server\$crowbar_share"
Add-Content $startnet_cmd "`n $crowbar_mountpoint\$crowbar_folder\$crowbar_source\setup.exe /unattend:$crowbar_mountpoint\$crowbar_folder\$crowbar_unattend\unattended.xml"

cmd.exe /c dism.exe /Unmount-Wim /MountDir:$pe_mount /commit

Copy-Item $pe_build\winpe.wim $pe_pxe\Boot\winpe.wim

#Copy the whole part to the crowbar server:
net use $crowbar_mountpoint \\$crowbar_server\$crowbar_share
if (!(Test-Path -path $crowbar_mountpoint\$crowbar_folder\$crowbar_boot)) {New-Item $crowbar_mountpoint\$crowbar_folder\$crowbar_boot -Type Directory}
if (!(Test-Path -path $crowbar_mountpoint\$crowbar_folder\$crowbar_source)) {New-Item $crowbar_mountpoint\$crowbar_folder\$crowbar_source -Type Directory}
if (!(Test-Path -path $crowbar_mountpoint\$crowbar_folder\$crowbar_unattend)) {New-Item $crowbar_mountpoint\$crowbar_folder\$crowbar_unattend -Type Directory}
Copy-Item $pe_pxe\Boot\* $crowbar_mountpoint\$crowbar_folder\$crowbar_boot
dir $crowbar_mountpoint\$crowbar_folder\$crowbar_boot -r | % { if ($_.Name -cne $_.Name.ToLower()) { ren $_.FullName $_.Name.ToLower() } }
Copy-Item $install_media\sources\* $crowbar_mountpoint\$crowbar_folder\$crowbar_source -Recurse
dir $crowbar_mountpoint\$crowbar_folder\$crowbar_source -r | % { if ($_.Name -cne $_.Name.ToLower()) { ren $_.FullName $_.Name.ToLower() } }
net use $crowbar_mountpoint /delete