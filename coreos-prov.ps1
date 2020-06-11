
param (
    ${VMName} = 'CoreOS',
    ${Switch} = 'External Switch',
    ${InstallMedia} = "C:\Users\dogbe\Downloads\fedora-coreos-31.20200517.3.0-live.x86_64.iso"
)
function New-EmbedMedia {
    param (
        ${VMName},
        ${InstallMedia}
    )
    New-Item -Path "${PWD}" -Name "out" -ItemType "directory"
    venv\Scripts\python.exe generatefcc.py ${VMName} --outfile out\mycoreos.fcc
    docker run --rm -v "${PWD}/out:/work" quay.io/coreos/fcct:release --pretty --strict -o /work/mycoreos.ign /work/mycoreos.fcc
    venv\Scripts\python.exe generatebootstrap.py --config out\mycoreos.ign --outfile out\bootstrap.fcc
    docker run --rm -v "${PWD}/out:/work" quay.io/coreos/fcct:release --pretty --strict -o /work/bootstrap.ign /work/bootstrap.fcc
    ${EmbedMedia} = "${PWD}\out\fedora-coreos-embed.iso"
    Copy-Item -Path ${InstallMedia} -Destination ${EmbedMedia} -Force
    docker run --rm -v "${PWD}/out:/work" quay.io/coreos/coreos-installer:release iso embed --config /work/bootstrap.ign --force /work/fedora-coreos-embed.iso
    return ${EmbedMedia}
}
function New-NodeVM {
    param (
        ${VMName},
        ${Switch},
        ${InstallMedia}
    )
    New-VM -Name ${VMName} -SwitchName ${Switch} -MemoryStartupBytes 8192MB -NewVHDPath "C:\Users\Public\Documents\Hyper-V\Virtual Hard Disks\${VMName}.vhdx" -NewVHDSizeBytes 127GB -Generation 2
    Set-VMProcessor ${VMName} -Count 2
    Add-VMScsiController -VMName ${VMName}
    Add-VMDvdDrive -VMName ${VMName} -ControllerNumber 1 -ControllerLocation 0 -Path ${InstallMedia}
    ${DVDDrive} = Get-VMDvdDrive -VMName ${VMName}
    Set-VMFirmware -VMName ${VMName} -FirstBootDevice ${DVDDrive} -EnableSecureBoot Off
}
function Install-OSToHD {
    Start-VM -Name ${VMName}
    Start-Sleep 5
    ${VM} = Get-VM -Name ${VMName}
    while (${VM}.State -eq 'Running') {
        Start-Sleep 5
    }
}
${EmbedMedia} = New-EmbedMedia -VMName ${VMName} -InstallMedia ${InstallMedia}
New-NodeVM -VMName ${VMName} -Switch ${Switch} -InstallMedia ${EmbedMedia}
Start-Sleep 5
Install-OSToHD -VMName ${VMName}
Set-VMDvdDrive -VMName ${VMName} -Path $null
${DiskDrive} = Get-VMHardDiskDrive -VMName ${VMName}
Set-VMFirmware -VMName ${VMName} -FirstBootDevice ${DiskDrive}
