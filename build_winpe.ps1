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
  [string]$UNC = "\\192.168.100.1\WinPE",
  [string]$DestDir = "windows-6.2",
  [string]$CDrom = "D:",
  [bool]$AddVirtIO = $false,
  [bool]$AditionalDrivers = $false
)

$ErrorActionPreference = "Stop"

# $add_additional_drivers enables adding additional drivers. 7-zip is required
# in this case and Drivers.zip file to be placed in ${pe_drivers}
# $add_virtio_drivers enables adding the virtio drivers into the image (see
# $virtio_driverfile for version information)
$add_aditional_drivers	= $AditionalDrivers
$add_virtio_drivers			= $AddVirtIO
$virtio_driverfile 				= "virtio-win-0.1-59.iso"

# Our WinPE Folder Structure
$pe_dir 			= "c:\winpe"
$pe_programs	= "c:\winpe\build\mount\Program Files (x86)"
$pe_src         	= "$pe_dir\src"
$pe_drivers  	= "$pe_dir\src\drivers"
$pe_bin        	= "$pe_dir\bin"
$pe_logs  		= "$pe_dir\logs"
$pe_build   		= "$pe_dir\build"
$pe_mount  	= "$pe_dir\build\mount"
$pe_iso      		= "$pe_dir\ISO"
$pe_pxe			= "$pe_dir\PXE"
$pe_tmp			= "$pe_dir\tmp"

# ADK Url and Install Options
$adk_url             	= "http://download.microsoft.com/download/9/9/F/99F5E440-5EB5-4952-9935-B99662C3DF70/adk/adksetup.exe"
$adk_file				= "adksetup.exe"
$adk_features 		= "OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment"
$adk_install_log	= "$pe_logs\adksetup.log"

# Windows PE Specific Paths
$pe_root 						= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment"
$pe_amd64_src 			= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64"
$pe_x32_src 				= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\x86"
$pe_package_src 		= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs"
$pe_deployment_tools = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Deployment Tools"
$dism_path    				= "$pe_deployment_tools\amd64\DISM"
$bcd_path     				= "$pe_deployment_tools\amd64\BCDBoot"
$wism_path   				= "$pe_deployment_tools\WSIM"
$startnet_cmd  			= "$pe_mount\Windows\System32\startnet.cmd"

#Location of the install media for the OS:
$install_media       = $CDrom

# Windows PE Packages
$winpe_wmi 						= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WMI.cab"
$winpe_wmi_enus 				= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-WMI_en-us.cab"
$winpe_hta    						= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WMI.cab"
$winpe_hta_enus  				= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-WMI_en-us.cab"
$winpe_scripting  				= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-Scripting.cab"
$winpe_netfx4  					= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-NetFx4.cab"
$winpe_netfx4_enus  			= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-NetFx4_en-us.cab"
$winpe_powershell3 			= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-PowerShell3.cab"
$winpe_powershell3_enus	= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-PowerShell3_en-us.cab"
$winpe_storagewmi 			= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-StorageWMI.cab"
$winpe_storagewmi_enus 	= "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-StorageWMI_en-us.cab"


$samba_mountpoint 	= "p:"
$win_boot  					= "boot"
$win_source  				= "source"
$win_unattend  			= "unattend"
$win_extra  				= "extra"
$win_folder 				= $DestDir

# Make sure the image is not mounted from a previous failed run
cmd.exe /c dism.exe /Unmount-Wim /MountDir:$pe_mount /discard

#Cleanup before starting any processing
if (Test-Path -path $pe_dir) {rmdir $pe_dir -Recurse -Force}

New-Item $pe_dir -Type Directory

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
	$p = Start-Process -FilePath "$pe_src\$adk_file" -ArgumentList "/quiet /norestart /features `"$adk_features`" /log `"$adk_install_log`"" -Wait -PassThru
	if($p.ExitCode)  { throw "The ADK installation failed" }
}

$env:Path += $dism_path;$bcd_path;$wsim_path;$::path

if($add_aditional_drivers)
{
	$env:Path += "${ENV:ProgramFiles(x86)}\7-Zip"
}

if (!(Test-Path -path "$pe_pxe\Boot")) {New-Item "$pe_pxe\Boot" -Type Directory}

Copy-Item "$pe_root\amd64\Media" $pe_build -Recurse
Copy-Item "$pe_root\amd64\en-us\winpe.wim" $pe_build
Copy-Item "$pe_deployment_tools\amd64\Oscdimg\etfsboot.com" $pe_build
Copy-Item "$pe_deployment_tools\amd64\Oscdimg\oscdimg.exe" $pe_build

cmd.exe /c "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"
if ($LastExitCode) { throw "DandISetEnv failed" }

dism.exe /Mount-Wim /WimFile:$pe_build\winpe.wim /index:1 /MountDir:$pe_mount
if ($LastExitCode) { throw "dism failed" }

try
{
	Copy-Item "$pe_mount\Windows\Boot\PXE\pxeboot.com" "$pe_pxe\Boot\pxeboot.com"
	Copy-Item "$pe_mount\Windows\Boot\PXE\pxeboot.n12" "$pe_pxe\Boot\pxeboot.0"
	Copy-Item "$pe_mount\Windows\Boot\PXE\bootmgr.exe" "$pe_pxe\Boot\bootmgr.exe"
	Copy-Item "$pe_mount\Windows\Boot\PXE\abortpxe.com"  "$pe_pxe\Boot\abortpxe.com"
	Copy-Item "$pe_root\amd64\Media\Boot\boot.sdi" "$pe_pxe\Boot\boot.sdi"

	cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_wmi`""
	if ($LastExitCode) { throw "dism failed" }

	cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_wmi_enus`""
	if ($LastExitCode) { throw "dism failed" }

	cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_hta`""
	if ($LastExitCode) { throw "dism failed" }

	cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_hta_enus`""
	if ($LastExitCode) { throw "dism failed" }

	cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_scripting`""
	if ($LastExitCode) { throw "dism failed" }

	cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_netfx4`""
	if ($LastExitCode) { throw "dism failed" }

	cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_netfx4_enus`""
	if ($LastExitCode) { throw "dism failed" }

	cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_powershell3`""
	if ($LastExitCode) { throw "dism failed" }

	cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_powershell3_enus`""
	if ($LastExitCode) { throw "dism failed" }

	cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_storagewmi`""
	if ($LastExitCode) { throw "dism failed" }

	cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$winpe_storagewmi_enus`""
	if ($LastExitCode) { throw "dism failed" }

	if ($add_aditional_drivers)
	{
		pushd
		cd $pe_src
		cmd.exe /c "7z.exe x $pe_drivers\Drivers.zip",
		if ($LastExitCode) { throw "7z failed" }
		popd

		if($add_virtio_drivers)
		{
			$virtio_driverurl = "http://alt.fedoraproject.org/pub/alt/virtio-win/latest/images/bin/"
			Invoke-WebRequest -UseBasicParsing -uri $virtio_driverurl/$virtio_driverfile -OutFile $pe_drivers\$virtio_driverfile
			pushd
			cd $pe_drivers
			cmd.exe /c "7z.exe x $pe_drivers\$virtio_driverfile"
			if ($LastExitCode) { throw "7z failed" }
			popd
		}

		cmd.exe /c dism.exe /image:$pe_mount /Add-Driver /driver:$pe_drivers /recurse /forceunsigned
		if ($LastExitCode) { throw "dism failed" }	
	}

	# bcdcreate.cmd needs to be placed in $pe_bin\bcdcreate.cmd
	$script_dir = Split-Path -Parent $MyInvocation.MyCommand.Path
	Copy-Item $script_dir\bcdcreate.cmd $pe_bin\bcdcreate.cmd
	pushd
	cd $pe_pxe\Boot
	cmd.exe /c $pe_bin\bcdcreate.cmd
	if ($LastExitCode) { throw "bcdcreate failed" }
	popd

	Add-Content $startnet_cmd "`n"
	Add-Content $startnet_cmd "`npowershell -ExecutionPolicy RemoteSigned x:\run_install.ps1`n"
	Add-Content $startnet_cmd "`n exit"
	Copy-Item "$script_dir\run_install.ps1" "$pe_mount\run_install.ps1"

	cmd.exe /c dism.exe /Unmount-Wim /MountDir:$pe_mount /commit
	if ($LastExitCode) { throw "dism failed" }
}
catch
{
	# Something went wrong. Don't leave the image mounted
	cmd.exe /c dism.exe /Unmount-Wim /MountDir:$pe_mount /discard
	throw
}

Copy-Item $pe_build\winpe.wim $pe_pxe\Boot\winpe.wim

#Copy the WindowsPE image and boot components to the samba server:
New-PSDrive $samba_mountpoint[0] -PSProvider FileSystem -Root $UNC

try
{
	if (!(Test-Path -path $samba_mountpoint\$win_folder\$win_boot)) {New-Item $samba_mountpoint\$win_folder\$win_boot -Type Directory}
	if (!(Test-Path -path $samba_mountpoint\$win_folder\$win_source)) {New-Item $samba_mountpoint\$win_folder\$win_source -Type Directory}
	if (!(Test-Path -path $samba_mountpoint\$win_folder\$win_unattend)) {New-Item $samba_mountpoint\$win_folder\$win_unattend -Type Directory}
	Copy-Item $pe_pxe\Boot\* $samba_mountpoint\$win_folder\$win_boot -Force
	dir $samba_mountpoint\$win_folder\$win_boot -r | % { if ($_.Name -cne $_.Name.ToLower()) { ren $_.FullName $_.Name.ToLower() } }
	Copy-Item $install_media\sources\* $samba_mountpoint\$win_folder\$win_source -Recurse -Force
	dir $samba_mountpoint\$win_folder\$win_source -r | % { if ($_.Name -cne $_.Name.ToLower()) { ren $_.FullName $_.Name.ToLower() } }
}
finally
{
	Remove-PSDrive $samba_mountpoint[0]
}	
