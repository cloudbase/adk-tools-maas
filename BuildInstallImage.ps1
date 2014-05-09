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
  [string]$InstallMediaPath = "D:",
  [string]$WinPEFolder = "C:\winpe",
  [string]$ImageName = "",
  [string]$AdditionalDriversPath = $null
)

$ErrorActionPreference = "Stop"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
Import-Module "$scriptPath\WimFileInfo.ps1"

$pe_src       = "$WinPEFolder\src"
$pe_drivers   = "$WinPEFolder\src\drivers"

$img_location = "$InstallMediaPath\sources"
$img_build    = "$WinPEFolder\image"
$img_mount    = "$img_build\mount"
$img_sources  = "$img_build\sources"

# ADK Url and Install Options
$adk_url          = "http://download.microsoft.com/download/9/9/F/99F5E440-5EB5-4952-9935-B99662C3DF70/adk/adksetup.exe"
$adk_file         = "adksetup.exe"
$adk_features     = "OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment"
$adk_install_log  = "$pe_logs\adksetup.log"
$adk_base_dir     = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit"
$adk_reg_key      = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{fc46d1b2-9557-4c1f-baac-04af4d2db7e4}"

if (!(Test-Path -path $WinPEFolder)) {throw "WinPE was not built yet, please build WinPE first."}
if (!(Test-Path -path $pe_src)) {New-Item $pe_src -Type Directory}
if (!(Test-Path -path $pe_drivers)) {New-Item $pe_drivers -Type Directory}

if (!(Test-Path -path $img_build)) {New-Item $img_build -Type Directory}
if (!(Test-Path -path $img_mount)) {New-Item $img_mount -Type Directory}
if (!(Test-Path -path $img_sources)) {New-Item $img_sources -Type Directory} else {Remove-Item -Recurse -Force $img_sources\*}

if(-not (Test-Path -Path $adk_reg_key))
{
    Invoke-WebRequest -UseBasicParsing -uri $adk_url -OutFile $pe_src\$adk_file

    $p = Start-Process -FilePath "$pe_src\$adk_file" -ArgumentList "/quiet /norestart /features `"$adk_features`" /log `"$adk_install_log`"" -Wait -PassThru
    if($p.ExitCode)  { throw "The ADK installation failed" }
}

$env:Path += $dism_path;$bcd_path;$wsim_path;$::path

Copy-Item $InstallMediaPath\sources\* $img_sources -Recurse -Exclude "*install.wim"

$installWimPath = Join-Path $InstallMediaPath "sources\install.wim"
$images = Get-WimFileImagesInfo $installWimPath

foreach ($image in $images)
{
    if ($ImageName -ne "" -and $image.ImageName -ne $ImageName)
    {
        continue
    }

    $maasImageName = $image.ImageName.replace(' ','-')

    Write-Host "MaaS image name: $maasImageName"

    if (Test-Path -path $img_build\$maasImageName.wim) {Remove-Item -Force $img_build\$maasImageName.wim}

    &dism.exe /export-image /sourceimagefile:$img_location\install.wim /sourcename:$($image.ImageName) /destinationimagefile:$img_build\$maasImageName.wim
    if ($LastExitCode) { throw "dism failed exporting install.wim" }

    try
    {
        if ($AdditionalDriversPath)
        {
            &dism.exe /Mount-Wim /WimFile:$img_build\$maasImageName.wim /name:$($image.ImageName) /MountDir:$img_mount
            if ($LastExitCode) { throw "dism failed mounting install.wim" }
            &dism.exe /image:$img_mount /Add-Driver /driver:$pe_drivers /recurse /ForceUnsigned
            if ($LastExitCode) { throw "dism failed in adding external drivers" }        
            &dism.exe /Unmount-Wim /MountDir:$img_mount /commit
            if ($LastExitCode) { throw "dism failed unmounting install.wim" }
        }

    }
    catch
    {
        # Something went wrong. Don't leave the image mounted
        &dism.exe /Unmount-Wim /MountDir:$img_mount /discard
        throw
    }
}