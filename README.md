Generate PXE boot environment for Microsoft Windows and Hyper-V Servers.
========================================================================

**This collection of scripts take source DVD or a mounted ISO image and generates the required WinPE files for PXE boot.**

The order in which the scripts must be executed and their corresponding optional parameters are:

**1. BuildWinPE.ps1**

- *WinPEFolder* _ -> specifies the location for building the WinPE image files (defaults to C:\winpe)
- *AdditionalDriversPath* -> specifies a location for adding additional drivers to the WinPE image (defaults to null)
- *UseLargeTFTPBlockSize* -> specifies that TFTP should use large blocks while transferring the image (defaults to TRUE)
- *ADKVersion* -> specifies the required Windows Assessment and Deployment Kit version (default version is 8.1)
- *ForceADKInstall* -> specifies wether the script should remove any other installed version of Windows Assessment and Deployment Kit

**2. BuildInstallImage.ps1**

- *WinPEFolder* -> specifies the location for building the install image files (defaults to C:\winpe)
- *AdditionalDriversPath* -> specifies a location for adding additional drivers to the WinPE image (defaults to null)
- *InstallMediaPath* -> specifies the location of the source DVD or mounted ISO image (defaults to D:\)
- *ImageName* -> Specifies the name of the image to be generated. If ommited, all images available on the install media will be processed (defaults to NULL)

**3. CopyImageToMaaS.ps1**

- *WinPEFolder* -> specifies the location of the source WinPE and install image files (defaults to C:\winpe)
- *TargetPath* -> specifies the destination network share for transferring the files (defaults to \\192.168.100.1\WinPE)
- *ImageName* -> Specifies the name of the image to be transferred. If ommited, all images available on the source WinPE folder will be processed (defaults to NULL)
- *Overwrite* -> boolean value specifying if an existing image should be overwriten or not (defaults to TRUE)
