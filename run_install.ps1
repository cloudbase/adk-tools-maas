Start-Sleep -s 10
$regControl = Get-ItemProperty -Path "HKLM:\System\ControlSet001\Control"

$bootOpts = $regControl.SystemStartOptions

$kernParams = $bootOpts.split(" ")[2].split(';')

$kernParams


$remoteSmbPath = $kernParams[0].toLower()

$sourcePath = $kernParams[1].toLower()

$preseedUrl = $kernParams[2].replace('\', '/').toLower()



Invoke-WebRequest -Uri $preseedUrl -OutFile x:\unattended.xml

$metadataUrl = $preseedUrl.split('?')[0]

New-SmbMapping -RemotePath $remoteSmbPath -LocalPath p:

if ($? -eq $false){
  exit
}

cmd.exe /c p:\$sourcePath\setup.exe /noreboot /unattend:x:\unattended.xml

Invoke-WebRequest -Uri $metadataUrl -OutFile x:\dump.json -Method Post -Body "op=netboot_off"

Start-Sleep 5
