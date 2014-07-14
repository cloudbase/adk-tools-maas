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
  [string]$TargetPath = "\\192.168.100.1\WinPE",
  [string]$WinPEFolder = "C:\winpe",
  [string]$ImageName = "",
  [switch]$Overwrite = $true
)

$ErrorActionPreference = "Stop"

$pe_pxe      = "$WinPEFolder\PXE"
$win_boot     = "boot"
$win_source   = "source"
$win_unattend = "unattend"

$img_build    = "$WinPEFolder\image"
$img_sources  = "$img_build\sources"

$maasImagesMap = @{}
$maasImagesMap.ws2012r2stdcore = "Windows Server 2012 R2 SERVERSTANDARDCORE"
$maasImagesMap.ws2012r2std     = "Windows Server 2012 R2 SERVERSTANDARD"
$maasImagesMap.ws2012r2dccore  = "Windows Server 2012 R2 SERVERDATACENTERCORE"
$maasImagesMap.ws2012r2dc      = "Windows Server 2012 R2 SERVERDATACENTER"
$maasImagesMap.ws2012r2hv      = "Hyper-V Server 2012 R2 SERVERHYPERCORE"
$maasImagesMap.win81ent        = "Windows 8.1 Enterprise"
$maasImagesMap.ws2012stdcore   = "Windows Server 2012 SERVERSTANDARDCORE"
$maasImagesMap.ws2012std       = "Windows Server 2012 SERVERSTANDARD"
$maasImagesMap.ws2012dccore    = "Windows Server 2012 SERVERDATACENTERCORE"
$maasImagesMap.ws2012dc        = "Windows Server 2012 SERVERDATACENTER"
$maasImagesMap.ws2012hv        = "Hyper-V Server 2012 SERVERHYPERCORE"
$maasImagesMap.ws2008r2stdcore = "Windows Server 2008 R2 SERVERSTANDARDCORE"
$maasImagesMap.ws2008r2std     = "Windows Server 2008 R2 SERVERSTANDARD"
$maasImagesMap.ws2008r2dccore  = "Windows Server 2008 R2 SERVERDATACENTERCORE"
$maasImagesMap.ws2008r2dc      = "Windows Server 2008 R2 SERVERDATACENTER"
$maasImagesMap.ws2008r2hv      = "Hyper-V Server 2008 R2 SERVERHYPERCORE"
$maasImagesMap.ws2008r2entcore = "Windows Server 2008 R2 SERVERENTERPRISECORE"
$maasImagesMap.ws2008r2ent     = "Windows Server 2008 R2 SERVERENTERPRISE"
$maasImagesMap.ws2008r2webcore = "Windows Server 2008 R2 SERVERWEBCORE"
$maasImagesMap.ws2008r2web     = "Windows Server 2008 R2 SERVERWEB"


$images = Get-ChildItem $img_build -Filter *.wim

foreach($image in $images)
{
    $CurrentImageName = $image.Name.SubString(0,$image.Name.length-4).Replace('-',' ')
    $CurrentImageName = $CurrentImageName -replace '(Hyper-V)*(-+)' , '$1 '
    
	if ($ImageName -ne "" -and $CurrentImageName -ne $ImageName)
    {
        continue
    }

    $maasImageName = $maasImagesMap.Keys | where {$maasImagesMap[$_] -eq $CurrentImageName}

    if($maasImageName)
    {
        $win_folder   = $maasImageName

        #Copy the image and boot components to the target path:
        $dest =  "$TargetPath\$win_folder"
        if (-not $Overwrite -and $(Test-Path -Path $dest\$win_source\install.wim))
        {
            continue
 
        } 
        if (Test-Path -path $dest) { rmdir $dest -Recurse -Force }

        New-Item $dest\$win_boot -Type Directory
        New-Item $dest\$win_source -Type Directory
        New-Item $dest\$win_unattend -Type Directory
        Copy-Item $pe_pxe\Boot\* $dest\$win_boot
        dir $dest\$win_boot -r | % { if ($_.Name -cne $_.Name.ToLower()) { ren $_.FullName $_.Name.ToLower() } }
        Copy-Item $img_sources\* $dest\$win_source -Recurse
        Copy-Item $img_build\$($image.Name) $dest\$win_source\install.wim
        dir $dest\$win_source -r | % { if ($_.Name -cne $_.Name.ToLower()) { ren $_.FullName $_.Name.ToLower() } }
    }

}
