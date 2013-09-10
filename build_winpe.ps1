# Copyright 2013 Cloudbase Solutions Srl
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

Param(
  [switch]$UseCrowbar,
  [string]$CrowbarAdminIP = "192.168.124.10",
  [string]$CrowbarFolder = "windows-6.2"
)

# $built_for crowbar must be set to $true if the Windows PE target usage is 
# corwbar or $false otherwise
# $add_additional_drivers enables adding additional drivers. 7-zip is required
# in this case and Drivers.zip file to be placed in ${pe_drivers}
# $add_virtio_drivers enables adding the virtio drivers into the image (see 
# $virtio_driverfile for version information)
  $built_for_crowbar     = $UseCrowbar
  $add_aditional_drivers = $false
  $add_virtio_drivers = $false
  $virtio_driverfile = 'virtio-win-0.1-59.iso'

  # Our WinPE Folder Structure
  $pe_dir              = 'c:\winpe'
  $pe_programs         = 'c:\winpe\build\mount\Program Files (x86)'
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

if ($built_for_crowbar)
{
  # Crowbar server specific info
  $crowbar_server_ip   = $CrowbarAdminIP
  $crowbar_share       = "reminst"
  $crowbar_mountpoint  = "p:"
  # crowbar folder default values are:
  # windows-6.2 for Windows Server 2012
  # hyperv-6.2 for Hyper-V Server 2012
  $crowbar_folder      = $CrowbarFolder
  $crowbar_boot        = "boot"
  $crowbar_source      = "source"
  $crowbar_unattend    = "unattend"
  $crowbar_extra       = "extra"
}
else
{
  $pxe_server_ip       = "192.168.1.1"
  $pxe_server_share    = "reminst"
  $pxe_server_source   = "source"
  $pxe_server_unattend = "unattend"
  $pxe_mount_point     = "p:"
}

#Cleanup before starting any processing
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
  Start-Process -FilePath "$pe_src\$adk_file" -ArgumentList "/quiet /norestart /features `"$adk_features`" /log `"$adk_install_log`"" -wait
}
$env:Path += $dism_path;$bcd_path;$wsim_path;$::path

if($add_aditional_drivers)
{
  $env:Path += "c:\Program Files (x86)\7-Zip"
}

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

if ($add_aditional_drivers)
{
  pushd
  cd $pe_src
  cmd.exe /c "7z.exe x $pe_drivers\Drivers.zip",
  popd
  if($add_virtio_drivers)
  {
    $virtio_driverurl = 'http://alt.fedoraproject.org/pub/alt/virtio-win/latest/images/bin/'
    Invoke-WebRequest -UseBasicParsing -uri $virtio_driverurl/$virtio_driverfile -OutFile $pe_drivers\$virtio_driverfile
    pushd
    cd $pe_drivers
    cmd.exe /c "7z.exe x $pe_drivers\$virtio_driverfile"
    popd
  }

  cmd.exe /c dism.exe /image:$pe_mount /Add-Driver /driver:$pe_drivers /recurse /forceunsigned
}

# bcdcreate.cmd needs to be placed in $pe_bin\bcdcreate.cmd
$script_dir = Split-Path -Parent $MyInvocation.MyCommand.Path
Copy-Item $script_dir\bcdcreate.cmd $pe_bin\bcdcreate.cmd
pushd
cd $pe_pxe\Boot
cmd.exe /c $pe_bin\bcdcreate.cmd
popd

Add-Content $startnet_cmd "`n"
if($built_for_crowbar)
{
  Add-Content $startnet_cmd "`n net use $crowbar_mountpoint \\$crowbar_server_ip\$crowbar_share"
  Add-Content $startnet_cmd "`n $crowbar_mountpoint\$crowbar_folder\$crowbar_source\setup.exe /noreboot /unattend:$crowbar_mountpoint\$crowbar_folder\$crowbar_unattend\unattended.xml"
  Add-Content $startnet_cmd "`n copy $crowbar_mountpoint\$crowbar_folder\$crowbar_extra\set_state.ps1 \"
  Add-Content $startnet_cmd "`n powershell -ExecutionPolicy RemoteSigned \set_state.ps1"
  Add-Content $startnet_cmd "`exit"
}
else
{
  Add-Content $startnet_cmd "`n net use $pxe_mount_point \\$pxe_server_ip\$pxe_server_share"
  Add-Content $startnet_cmd "`n $pxe_mount_point\$pxe_server_source\setup.exe /unattend:$pxe_mount_point\$pxe_server_unattend\unattended.xml"
}
cmd.exe /c dism.exe /Unmount-Wim /MountDir:$pe_mount /commit

Copy-Item $pe_build\winpe.wim $pe_pxe\Boot\winpe.wim

if($built_for_crowbar)
{
  #Copy the WindowsPE image and boot components to the crowbar server:
  New-PSDrive $crowbar_mountpoint[0] -PSProvider FileSystem -Root "\\$crowbar_server_ip\$crowbar_share"
  if (!(Test-Path -path $crowbar_mountpoint\$crowbar_folder\$crowbar_boot)) {New-Item $crowbar_mountpoint\$crowbar_folder\$crowbar_boot -Type Directory}
  if (!(Test-Path -path $crowbar_mountpoint\$crowbar_folder\$crowbar_source)) {New-Item $crowbar_mountpoint\$crowbar_folder\$crowbar_source -Type Directory}
  if (!(Test-Path -path $crowbar_mountpoint\$crowbar_folder\$crowbar_unattend)) {New-Item $crowbar_mountpoint\$crowbar_folder\$crowbar_unattend -Type Directory}
  Copy-Item $pe_pxe\Boot\* $crowbar_mountpoint\$crowbar_folder\$crowbar_boot -Force
  dir $crowbar_mountpoint\$crowbar_folder\$crowbar_boot -r | % { if ($_.Name -cne $_.Name.ToLower()) { ren $_.FullName $_.Name.ToLower() } }
  Copy-Item $install_media\sources\* $crowbar_mountpoint\$crowbar_folder\$crowbar_source -Recurse -Force
  dir $crowbar_mountpoint\$crowbar_folder\$crowbar_source -r | % { if ($_.Name -cne $_.Name.ToLower()) { ren $_.FullName $_.Name.ToLower() } }
  Remove-PSDrive $crowbar_mountpoint[0]
}
