# stop on error
$ErrorActionPreference = "Stop"

# curl -useb https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/developer/createhyperv.ps1 | iex;

function New-LinuxVM {
	#requires -Modules Hyper-V
	[CmdletBinding(SupportsShouldProcess=$true)]
	param
	(
		[Parameter(Mandatory=$true, Position=1)][String]$VMName,
		[Parameter()][String]$VHDXName = '',
		[Parameter()][String]$VMStoragePath = '',
		[Parameter()][String]$VHDStoragePath = '',
		[Parameter()][String]$InstallISOPath = '',
		[Parameter()][Switch]$Cluster,
		[Parameter()][String]$VMSwitchName = '',
		[Parameter()][Uint32]$StartupMemory = 2048MB,
		[Parameter()][Uint32]$MinimumMemory = 256MB,
		[Parameter()][Uint32]$MaximumMemory = 2GB,
		[Parameter()][Uint64]$VHDXSizeBytes = 30GB
	)

	if([String]::IsNullOrEmpty($VHDXName))
	{
		$VHDXName = '{0}.vhdx' -f $VMName
	}
	if($VHDXName -notmatch '\.vhdx$')
	{
		$VHDXName += '.vhdx'
	}
	if([String]::IsNullOrEmpty($VMStoragePath))
	{
		$VMStoragePath = (Get-VMHost).VirtualMachinePath
	}
	if(-not (Test-Path -Path $VMStoragePath))
	{
		Write-Error -Message ('VM path {0} does not exist.' -f $VMStoragePath)
		return
	}
	if([String]::IsNullOrEmpty($VHDStoragePath))
	{
		$VHDStoragePath = (Get-VMHost).VirtualHardDiskPath
	}
	if(-not (Test-Path -Path $VHDStoragePath))
	{
		Write-Error -Message ('Storage path {0} does not exist.' -f $VHDStoragePath)
		return
	}
	$VHDStoragePath = Join-Path -Path $VHDStoragePath -ChildPath $VHDXName
	if([String]::IsNullOrEmpty($InstallISOPath) -or -not (Test-Path -Path $InstallISOPath -PathType Leaf))
	{
		Write-Error -Message ('ISO {0} does not exist' -f $InstallISOPath)
		return
	}
	if([String]::IsNullOrEmpty($VMSwitchName))
	{
		$VMSwitchName = (Get-VMSwitch | ? SwitchType -eq 'External')[0].Name
	}
	if([String]::IsNullOrEmpty($VMSwitchName))
	{
		Write-Error -Message ('No virtual switch specified')
		return
	}

	$VM = New-VM -Name $VMName -MemoryStartupBytes $StartupMemory -SwitchName $VMSwitchName -Path $VMStoragePath -Generation 2 -NoVHD
	Set-VMMemory -VM $VM -DynamicMemoryEnabled $true -MinimumBytes $MinimumMemory -MaximumBytes $MaximumMemory
	Set-VMProcessor -VM $VM -Count 2
	Start-VM -VM $VM
	Stop-VM -VM $VM -Force
	New-VHD -Path $VHDStoragePath -SizeBytes $VHDXSizeBytes -Fixed -BlockSizeBytes 1MB
	$VMVHD = Add-VMHardDiskDrive -VM $VM -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 0 -Path $VHDStoragePath -Passthru
	$VMDVDDrive = Add-VMDvdDrive -VM $VM -ControllerNumber 0 -ControllerLocation 1 -Passthru
	$VMNetAdapter = Get-VMNetworkAdapter -VM $VM
	Set-VMNetworkAdapter -VMNetworkAdapter $VMNetAdapter -StaticMacAddress ($VMNetAdapter.MacAddress)
	Set-VMFirmware -VM $VM -BootOrder $VMDVDDrive, $VMVHD, $VMNetAdapter -EnableSecureBoot On -SecureBootTemplate 'MicrosoftUEFICertificateAuthority'
	Set-VMDvdDrive -VMDvdDrive $VMDVDDrive -Path $InstallISOPath
	if($Cluster)
	{
		Add-ClusterVirtualMachineRole -VMName $VMName
	}
}

[string] $myVmName = ""
do {
	[string] $myVmName = Read-Host -Prompt "Enter name for new VM"
} while ([string]::IsNullOrEmpty($myVmName))

# New-LinuxVM -InstallISOPath C:\hyperv\CentOS-7-x86_64-Minimal-1708.iso -VMSwitchName "Default Switch"

New-LinuxVM  -VMName $myVmName -InstallISOPath C:\hyperv\rhel-server-7.1-x86_64-dvd.iso -VMSwitchName "Default Switch"


# New-LinuxVM -InstallISOPath C:\hyperv\SLE-12-SP3-Server-DVD-x86_64-GM-DVD1.iso -VMSwitchName "Default Switch"
