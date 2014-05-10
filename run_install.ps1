Start-Sleep -s 10
$regControl = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control"

$bootOpts = $regControl.SystemStartOptions

$kernParams = $bootOpts.split(" ")[2].split(';')

$kernParams


$remoteSmbPath = $kernParams[0].toLower()

$sourcePath = $kernParams[1].toLower()

$preseedUrl = $kernParams[2].replace('\', '/').toLower()


do{Start-Sleep 1; (new-object System.Net.WebClient).DownloadFile($preseedUrl,'x:\unattended.xml')} while ($? -eq $false)

$metadataUrl = $preseedUrl.split('?')[0]

do{Start-Sleep 1; New-SmbMapping -RemotePath $remoteSmbPath -LocalPath p: } while ($? -eq $false)

if ($? -eq $false){
  exit
}

cmd.exe /c p:\$sourcePath\setup.exe /noreboot /unattend:x:\unattended.xml
if ($?)
{
	Invoke-WebRequest -Uri $metadataUrl -OutFile x:\dump.json -Method Post -Body "op=netboot_off"
}

Start-Sleep 5
