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
  [string]$ImageName = "Windows Server 2012 R2 SERVERSTANDARD",
  [string]$InstallMediaPath = "D:",
  [string]$TargetPath = "\\192.168.100.1\WinPE",
  [string]$AditionalDrivers = $null
)

$ErrorActionPreference = "Stop"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
Import-Module "$scriptPath\WimFileInfo.ps1"

$installWimPath = Join-Path $InstallMediaPath "sources\install.wim"
$images = Get-WimFileImagesInfo $installWimPath
$image = $images | where { $_.ImageName -eq $ImageName}

if (!$image)
{
    throw "Image ""$ImageName"" not found on install media path ""$InstallMediaPath"""
}

$maasImagesMap = @{}
$maasImagesMap.ws2012r2stdcore = "Windows Server 2012 R2 SERVERSTANDARDCORE"
$maasImagesMap.ws2012r2std = "Windows Server 2012 R2 SERVERSTANDARD"
$maasImagesMap.ws2012r2dccore = "Windows Server 2012 R2 SERVERDATACENTERCORE"
$maasImagesMap.ws2012r2dc = "Windows Server 2012 R2 SERVERDATACENTER"
$maasImagesMap.ws2012r2hv = "Hyper-V Server 2012 R2 SERVERHYPERCORE"
$maasImagesMap.ws2012stdcore = "Windows Server 2012 SERVERSTANDARDCORE"
$maasImagesMap.ws2012std = "Windows Server 2012 SERVERSTANDARD"
$maasImagesMap.ws2012dccore = "Windows Server 2012 SERVERDATACENTERCORE"
$maasImagesMap.ws2012dc = "Windows Server 2012 SERVERDATACENTER"
$maasImagesMap.ws2012hv = "Hyper-V Server 2012 SERVERHYPERCORE"
$maasImagesMap.ws2008r2stdcore = "Windows Server 2008 R2 SERVERSTANDARDCORE"
$maasImagesMap.ws2008r2std = "Windows Server 2008 R2 SERVERSTANDARD"
$maasImagesMap.ws2008r2dccore = "Windows Server 2008 R2 SERVERDATACENTERCORE"
$maasImagesMap.ws2008r2dc = "Windows Server 2008 R2 SERVERDATACENTER"
$maasImagesMap.ws2008r2hv = "Hyper-V Server 2008 R2 SERVERHYPERCORE"
$maasImagesMap.ws2008r2entcore = "Windows Server 2008 R2 SERVERENTERPRISECORE"
$maasImagesMap.ws2008r2ent = "Windows Server 2008 R2 SERVERENTERPRISE"
$maasImagesMap.ws2008r2webcore = "Windows Server 2008 R2 SERVERWEBCORE"
$maasImagesMap.ws2008r2web = "Windows Server 2008 R2 SERVERWEB"

$maasImageName = $maasImagesMap.Keys | where {$maasImagesMap[$_] -eq $image.ImageName}
if (!$maasImageName)
{
    throw "Image ""$ImageName"" is not currently supported by MaaS"
}

$imageIndex = $image.ImageIndex

# Our WinPE Folder Structure
$pe_dir      = "c:\winpe"
$pe_programs = "c:\winpe\build\mount\Program Files (x86)"
$pe_src      = "$pe_dir\src"
$pe_drivers  = "$pe_dir\src\drivers"
$pe_bin      = "$pe_dir\bin"
$pe_logs     = "$pe_dir\logs"
$pe_build    = "$pe_dir\build"
$pe_mount    = "$pe_dir\build\mount"
$pe_iso      = "$pe_dir\ISO"
$pe_pxe      = "$pe_dir\PXE"
$pe_tmp      = "$pe_dir\tmp"

# ADK Url and Install Options
$adk_url          = "http://download.microsoft.com/download/9/9/F/99F5E440-5EB5-4952-9935-B99662C3DF70/adk/adksetup.exe"
$adk_file         = "adksetup.exe"
$adk_features     = "OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment"
$adk_install_log  = "$pe_logs\adksetup.log"

# Windows PE Specific Paths
$pe_root             = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment"
$pe_amd64_src        = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64"
$pe_x32_src          = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\x86"
$pe_package_src      = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs"
$pe_deployment_tools = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Deployment Tools"
$dism_path           = "$pe_deployment_tools\amd64\DISM"
$bcd_path            = "$pe_deployment_tools\amd64\BCDBoot"
$wism_path           = "$pe_deployment_tools\WSIM"
$startnet_cmd        = "$pe_mount\Windows\System32\startnet.cmd"

# Windows PE Packages
$winpe_wmi              = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WMI.cab"
$winpe_wmi_enus         = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-WMI_en-us.cab"
$winpe_hta              = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WMI.cab"
$winpe_hta_enus         = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-WMI_en-us.cab"
$winpe_scripting        = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-Scripting.cab"
$winpe_netfx4           = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-NetFx4.cab"
$winpe_netfx4_enus      = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-NetFx4_en-us.cab"
$winpe_powershell3      = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-PowerShell3.cab"
$winpe_powershell3_enus = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-PowerShell3_en-us.cab"
$winpe_storagewmi       = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-StorageWMI.cab"
$winpe_storagewmi_enus  = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-StorageWMI_en-us.cab"


$win_boot     = "boot"
$win_source   = "source"
$win_unattend = "unattend"
$win_extra    = "extra"
$win_folder   = $maasImageName

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

if (!(Test-Path -path "$pe_pxe\Boot")) {New-Item "$pe_pxe\Boot" -Type Directory}

Copy-Item "$pe_root\amd64\Media" "$pe_build\" -Recurse
Copy-Item "$pe_root\amd64\en-us\winpe.wim" $pe_build
Copy-Item "$pe_deployment_tools\amd64\Oscdimg\etfsboot.com" $pe_build
Copy-Item "$pe_deployment_tools\amd64\Oscdimg\oscdimg.exe" $pe_build

cmd.exe /c "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"
if ($LastExitCode) { throw "DandISetEnv failed" }

dism.exe /Mount-Wim /WimFile:$pe_build\winpe.wim /index:$imageIndex /MountDir:$pe_mount
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

    if ($AdditionalDriversPath)
    {
        # Copy the drivers to a local path
        Copy-Item (join-Path $AdditionalDriversPath *) "$pe_drivers\" -Recurse
        cmd.exe /c dism.exe /image:$pe_mount /Add-Driver /driver:$pe_drivers /recurse /forceunsigned
        if ($LastExitCode) { throw "dism failed in adding external drivers" }
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

#Copy the WindowsPE image and boot components to the target path:

$dest =  "$TargetPath\$win_folder"
if (Test-Path -path $dest) { rmdir $dest -Recurse -Force }

New-Item $dest\$win_boot -Type Directory
New-Item $dest\$win_source -Type Directory
New-Item $dest\$win_unattend -Type Directory
Copy-Item $pe_pxe\Boot\* $dest\$win_boot
dir $dest\$win_boot -r | % { if ($_.Name -cne $_.Name.ToLower()) { ren $_.FullName $_.Name.ToLower() } }
Copy-Item $InstallMediaPath\sources\* $dest\$win_source -Recurse
dir $dest\$win_source -r | % { if ($_.Name -cne $_.Name.ToLower()) { ren $_.FullName $_.Name.ToLower() } }

Write-Host "WinPE image generated and copied to $dest"
