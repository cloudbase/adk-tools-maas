Function FormatPreseedUrl($str) {
    $str = $str.replace('\', '/').toLower()
    $chars = $str.toCharArray()
    $result = ''
    $lower = $TRUE
    foreach($char in $chars) {
        if ($char -eq '^') {
            $lower = $FALSE
        } else {
            if (!$lower) {
                $obj = New-Object String($char)
                $result += $obj.toUpper()
                $lower = $TRUE
            } else {
                $result += $char
            }
        }
    }
    return $result
}

Start-Sleep -s 2
$regControl = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control"

$bootOpts = $regControl.SystemStartOptions

$kernParams = $bootOpts.split(" ")[2].split(';')

$kernParams


$remoteSmbPath = $kernParams[0].toLower()

$sourcePath = $kernParams[1].toLower()

$preseedUrl = $kernParams[2].replace('\', '/').toLower()
$preseedUrl = FormatPreseedUrl $kernParams[2]


do{Start-Sleep 1; (new-object System.Net.WebClient).DownloadFile($preseedUrl,'x:\unattended.xml')} while ($? -eq $false)

$metadataUrl = $preseedUrl.split('?')[0]

do{Start-Sleep 1; New-SmbMapping -RemotePath $remoteSmbPath -LocalPath p: } while ($? -eq $false)

#if ($? -eq $false){
#  exit
#}

Set-Content "X:\clean_disk.txt" @"
select disk 0
clean
create partition primary id=7
active
rescan
select disk 0
detail disk
select partition 1
detail partition
"@

bootsect /nt60 ALL /force /mbr

diskpart /s X:\clean_disk.txt

cmd.exe /c P:\$sourcePath\setup.exe /noreboot /unattend:x:\unattended.xml
if ($?)
{
	Invoke-WebRequest -Uri $metadataUrl -OutFile x:\dump.json -Method Post -Body "op=netboot_off"
}

Start-Sleep 5
