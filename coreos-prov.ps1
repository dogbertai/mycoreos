
function New-InstallVM {
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
    #Set-VMDvdDrive -VMName ${VMName} -Path ${InstallMedia}
}
function Install-OSToHD {
    try {
        Start-VM -Name ${VMName}
        VMConnect.exe localhost ${VMName}
        #curl -LO http://windforce.internal.dogbertai.net:8080/mycoreos.ign
        #sudo coreos-installer install /dev/sda --ignition-file mycoreos.ign
        Read-Host -Prompt 'Press ENTER to continue...'
    }
    finally {
        Stop-VM -Name ${VMName}
    }
}
${VMName} = 'CoreOS'
${Switch} = 'External Switch'
${InstallMedia} = "C:\Users\dogbe\Downloads\fedora-coreos-31.20200505.3.0-live.x86_64.iso"
venv\Scripts\python.exe generatefcc.py ${VMName}
docker run --rm -v ${PWD}:/work quay.io/coreos/fcct:release --pretty --strict -o /work/mycoreos.ign /work/mycoreos.fcc
venv\Scripts\python.exe generatebootstrap.py
docker run --rm -v ${PWD}:/work quay.io/coreos/fcct:release --pretty --strict -o /work/bootstrap.ign /work/bootstrap.fcc
${EmbedMedia} = "${PWD}\fedora-coreos-embed.iso"
Copy-Item -Path ${InstallMedia} -Destination ${EmbedMedia} -Force
docker run --rm -v ${PWD}:/work quay.io/coreos/coreos-installer:release iso embed --config /work/bootstrap.ign --force /work/fedora-coreos-embed.iso
New-InstallVM -VMName ${VMName} -Switch ${Switch} -InstallMedia ${EmbedMedia}
Install-OSToHD -VMName ${VMName}
Set-VMDvdDrive -VMName ${VMName} -Path $null
${DiskDrive} = Get-VMHardDiskDrive -VMName ${VMName}
Set-VMFirmware -VMName ${VMName} -FirstBootDevice ${DiskDrive}
