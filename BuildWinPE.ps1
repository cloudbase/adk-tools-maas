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
  [string]$WinPEFolder = "c:\winpe",
  [string]$ADKVersion = "8.0",
  [switch]$ForceADKInstall = $false
)

Function CleanupWinPEFolders
{
    #Cleanup before starting any processing
    if (Test-Path -path $WinPEFolder) {rmdir $WinPEFolder -Recurse -Force}

    New-Item $WinPEFolder -Type Directory
    New-Item $pe_src -Type Directory
    New-Item $pe_drivers -Type Directory
    New-Item $pe_logs -Type Directory
    New-Item $pe_bin -Type Directory
    New-Item $pe_build -Type Directory
    New-Item $pe_mount -Type Directory
    New-Item $pe_tmp -Type Directory
    New-Item $pe_iso -Type Directory
    New-Item $pe_pxe -Type Directory
    New-Item "$pe_pxe\Boot" -Type Directory
}

Function InstallADKTools
{
    if(-not (Test-Path -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$($adk_reg_key[$ADKVersion])"))
    {

        foreach($adk_version in $adk_reg_key.Keys)
        {
            if(Test-Path -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$($adk_reg_key[$adk_version])")
            {
                if($ForceADKInstall)
                {
                    $uninstall_adk = $(Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$($adk_reg_key[$adk_version])" -Name QuietUninstallString).QuietUninstallString
                    Invoke-Expression "& $uninstall_adk"
                }
                else
                {
                    throw "Different Windows Assessment and Deployment Kit version already installed on this system."
                }
            }
        }

        Invoke-WebRequest -UseBasicParsing -uri $($adk_url[$ADKVersion]) -OutFile $pe_src\$adk_file
        $p = Start-Process -FilePath "$pe_src\$adk_file" -ArgumentList "/quiet /norestart /features `"$adk_features`" /log `"$adk_install_log`"" -Wait -PassThru
        if($p.ExitCode)  { throw "The ADK installation failed" }
    }
}




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
$adk_url             = @{}
$adk_url["8.0"]      = "http://download.microsoft.com/download/9/9/F/99F5E440-5EB5-4952-9935-B99662C3DF70/adk/adksetup.exe"
$adk_url["8.1"]      = "http://download.microsoft.com/download/6/A/E/6AEA92B0-A412-4622-983E-5B305D2EBE56/adk/adksetup.exe"
$adk_file            = "adksetup.exe"
$adk_features        = "OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment"
$adk_install_log     = "$pe_logs\adksetup.log"
$adk_base_dir        = @{}
$adk_base_dir["8.0"] = "${ENV:ProgramFiles(x86)}\Windows Kits\8.0\Assessment and Deployment Kit"
$adk_base_dir["8.1"] = "${ENV:ProgramFiles(x86)}\Windows Kits\8.1\Assessment and Deployment Kit"
$adk_reg_key         = @{}
$adk_reg_key["8.0"]  = "{fc46d1b2-9557-4c1f-baac-04af4d2db7e4}"
$adk_reg_key["8.1"]  = "{9277b0c4-2ca8-431b-b4e2-98daf4005ec0}"


# Windows PE Specific Paths
$pe_root             = "$($adk_base_dir[$ADKVersion])\Windows Preinstallation Environment"
$pe_amd64_src        = "$($adk_base_dir[$ADKVersion])\Windows Preinstallation Environment\amd64"
$pe_x32_src          = "$($adk_base_dir[$ADKVersion])\Windows Preinstallation Environment\x86"
$pe_package_src      = "$($adk_base_dir[$ADKVersion])\Windows Preinstallation Environment\amd64\WinPE_OCs"
$pe_deployment_tools = "$($adk_base_dir[$ADKVersion])\Deployment Tools"
$dism_path           = "$pe_deployment_tools\amd64\DISM"
$bcd_path            = "$pe_deployment_tools\amd64\BCDBoot"
$wism_path           = "$pe_deployment_tools\WSIM"
$startnet_cmd        = "$pe_mount\Windows\System32\startnet.cmd"

# Windows PE Packages
$winpe_package_list=@{}
$winpe_package_list["8.0"]=@("WinPE-WMI.cab",
"en-us\WinPE-WMI_en-us.cab",
"WinPE-WMI.cab",
"en-us\WinPE-WMI_en-us.cab",
"WinPE-Scripting.cab",
"WinPE-NetFx4.cab",
"en-us\WinPE-NetFx4_en-us.cab",
"WinPE-PowerShell3.cab",
"en-us\WinPE-PowerShell3_en-us.cab",
"WinPE-StorageWMI.cab",
"en-us\WinPE-StorageWMI_en-us.cab")
$winpe_package_list["8.1"]=@("WinPE-WMI.cab",
"en-us\WinPE-WMI_en-us.cab",
"WinPE-WMI.cab",
"en-us\WinPE-WMI_en-us.cab",
"WinPE-WMI.cab",
"en-us\WinPE-WMI_en-us.cab",
"WinPE-Scripting.cab",
"WinPE-NetFx.cab",
"en-us\WinPE-NetFx_en-us.cab",
"WinPE-PowerShell.cab",
"en-us\WinPE-PowerShell_en-us.cab",
"WinPE-StorageWMI.cab",
"en-us\WinPE-StorageWMI_en-us.cab",
"WinPE-EnhancedStorage.cab",
"en-us\WinPE-EnhancedStorage_en-us.cab")

# Windows PE boot folder structure
$win_boot     = "boot"
$win_source   = "source"
$win_unattend = "unattend"
$win_extra    = "extra"

# Make sure the WinPE image is not mounted from a previous failed run
cmd.exe /c dism.exe /Unmount-Wim /MountDir:$pe_mount /discard

CleanupWinPEFolders

InstallADKTools

$env:Path += $dism_path;$bcd_path;$wsim_path;$::path

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

    # Add required packages to the WinPE image
    foreach ($pe_package in $($winpe_package_list[$ADKVersion]))
    {
        cmd.exe /c "dism.exe /image:$pe_mount /Add-Package /PackagePath:`"$pe_package_src\$pe_package`""
        if ($LastExitCode) { throw "dism failed installing " }
    }

    # If needed, add aditional drivers to the WinPE image
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
    
    # If possible, use large TFTP blocks
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

    # Create the script to launch our custom Windows Setup
    Add-Content $startnet_cmd "`n"
    Add-Content $startnet_cmd "`npowershell -ExecutionPolicy RemoteSigned x:\run_install.ps1`n"
    Add-Content $startnet_cmd "`n exit"
    Copy-Item "$script_dir\run_install.ps1" "$pe_mount\run_install.ps1"

    # Unmount the image once we finish
    cmd.exe /c dism.exe /Unmount-Wim /MountDir:$pe_mount /commit
    if ($LastExitCode) { throw "dism failed" }
}
catch
{
    # Something went wrong. Don't leave the image mounted
    cmd.exe /c dism.exe /Unmount-Wim /MountDir:$pe_mount /discard
    throw
}

# Place the WinPE image in the right location
Copy-Item $pe_build\winpe.wim $pe_pxe\Boot\winpe.wim
