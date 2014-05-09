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
  [switch]$UseLargeTFTPBlockSize = $true,
  [string]$AdditionalDriversPath = $null,
  [string]$WinPEFolder = "c:\winpe"
)

$ErrorActionPreference = "Stop"

# Our WinPE Folder Structure
$pe_programs = "$WinPEFolder\build\mount\Program Files (x86)"
$pe_src      = "$WinPEFolder\src"
$pe_drivers  = "$WinPEFolder\src\drivers"
$pe_bin      = "$WinPEFolder\bin"
$pe_logs     = "$WinPEFolder\logs"
$pe_build    = "$WinPEFolder\build"
$pe_mount    = "$WinPEFolder\build\mount"
$pe_iso      = "$WinPEFolder\ISO"
$pe_pxe      = "$WinPEFolder\PXE"
$pe_tmp      = "$WinPEFolder\tmp"

# ADK Url and Install Options
$adk_url          = "http://download.microsoft.com/download/9/9/F/99F5E440-5EB5-4952-9935-B99662C3DF70/adk/adksetup.exe"
$adk_file         = "adksetup.exe"
$adk_features     = "OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment"
$adk_install_log  = "$pe_logs\adksetup.log"
$adk_base_dir     = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit"
$adk_reg_key = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{fc46d1b2-9557-4c1f-baac-04af4d2db7e4}"

# Windows PE Specific Paths
$pe_root             = "$adk_base_dir\Windows Preinstallation Environment"
$pe_amd64_src        = "$adk_base_dir\Windows Preinstallation Environment\amd64"
$pe_x32_src          = "$adk_base_dir\Windows Preinstallation Environment\x86"
$pe_package_src      = "$adk_base_dir\Windows Preinstallation Environment\amd64\WinPE_OCs"
$pe_deployment_tools = "$adk_base_dir\Deployment Tools"
$dism_path           = "$pe_deployment_tools\amd64\DISM"
$bcd_path            = "$pe_deployment_tools\amd64\BCDBoot"
$wism_path           = "$pe_deployment_tools\WSIM"
$startnet_cmd        = "$pe_mount\Windows\System32\startnet.cmd"

# Windows PE Packages
$winpe_wmi              = "$pe_package_src\WinPE-WMI.cab"
$winpe_wmi_enus         = "$pe_package_src\en-us\WinPE-WMI_en-us.cab"
$winpe_hta              = "$pe_package_src\WinPE-WMI.cab"
$winpe_hta_enus         = "$pe_package_src\en-us\WinPE-WMI_en-us.cab"
$winpe_scripting        = "$pe_package_src\WinPE-Scripting.cab"
$winpe_netfx4           = "$pe_package_src\WinPE-NetFx4.cab"
$winpe_netfx4_enus      = "$pe_package_src\en-us\WinPE-NetFx4_en-us.cab"
$winpe_powershell3      = "$pe_package_src\WinPE-PowerShell3.cab"
$winpe_powershell3_enus = "$pe_package_src\en-us\WinPE-PowerShell3_en-us.cab"
$winpe_storagewmi       = "$pe_package_src\WinPE-StorageWMI.cab"
$winpe_storagewmi_enus  = "$pe_package_src\en-us\WinPE-StorageWMI_en-us.cab"


$win_boot     = "boot"
$win_source   = "source"
$win_unattend = "unattend"
$win_extra    = "extra"

# Make sure the WinPE image is not mounted from a previous failed run
cmd.exe /c dism.exe /Unmount-Wim /MountDir:$pe_mount /discard

#Cleanup before starting any processing
if (Test-Path -path $WinPEFolder) {rmdir $WinPEFolder -Recurse -Force}

New-Item $WinPEFolder -Type Directory

if (!(Test-Path -path $pe_src)) {New-Item $pe_src -Type Directory}
if (!(Test-Path -path $pe_drivers)) {New-Item $pe_drivers -Type Directory}
if (!(Test-Path -path $pe_logs)) {New-Item $pe_logs -Type Directory}
if (!(Test-Path -path $pe_bin)) {New-Item $pe_bin -Type Directory}
if (!(Test-Path -path $pe_build)) {New-Item $pe_build -Type Directory}
if (!(Test-Path -path $pe_mount)) {New-Item $pe_mount -Type Directory}
if (!(Test-Path -path $pe_tmp)) {New-Item $pe_tmp -Type Directory}
if (!(Test-Path -path $pe_iso)) {New-Item $pe_iso -Type Directory}
if (!(Test-Path -path $pe_pxe)) {New-Item $pe_pxe -Type Directory}

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

cmd.exe /c "$pe_deployment_tools\DandISetEnv.bat"
if ($LastExitCode) { throw "DandISetEnv failed" }

&dism.exe /Mount-Wim /WimFile:$pe_build\winpe.wim /index:1 /MountDir:$pe_mount
if ($LastExitCode) { throw "dism failed" }

try
{
    Copy-Item "$pe_mount\Windows\Boot\PXE\pxeboot.com" "$pe_pxe\Boot\pxeboot.com"
    Copy-Item "$pe_mount\Windows\Boot\PXE\pxeboot.n12" "$pe_pxe\Boot\pxeboot.0"
    Copy-Item "$pe_mount\Windows\Boot\PXE\bootmgr.exe" "$pe_pxe\Boot\bootmgr.exe"
    Copy-Item "$pe_mount\Windows\Boot\PXE\abortpxe.com" "$pe_pxe\Boot\abortpxe.com"
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
        dism.exe /image:$pe_mount /Add-Driver /driver:$pe_drivers /recurse /ForceUnsigned
        if ($LastExitCode) { throw "dism failed in adding external drivers" }
    }

    # bcdcreate.cmd needs to be placed in $pe_bin\bcdcreate.cmd
    $script_dir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Copy-Item $script_dir\bcdcreate.cmd $pe_bin\bcdcreate.cmd
    pushd
    
    if($UseLargeTFTPBlockSize)
    {
        $TFTPBlockSize = 8192
    }
    else
    {
        $TFTPBlockSize = 1400
    }

    try
    {
        cd $pe_pxe\Boot
        cmd.exe /c $pe_bin\bcdcreate.cmd $TFTPBlockSize
        if ($LastExitCode) { throw "bcdcreate failed" }
    }
    finally
    {
        popd
    }

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
