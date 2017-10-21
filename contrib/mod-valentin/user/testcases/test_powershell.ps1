param(
	[parameter( ValueFromRemainingArguments = $true )]
	[string[]]$Args # Leave all argument validation to the script, not to PowerShell
)

Clear-Host
Write-Host

if ( $args.Length -gt 0 ) {
	#
	# GetHDDStatus.ps1,  Version 1.00
	# Get the SMART status for all local harddisks
	#
	# Usage:    powershell  ./GetHDDStatus.ps1
	#
	# Notes:    This script requires elevated privileges.
	#           In Linux, the output does not include disk indexes.
	#
	# Credits:  Windows part based on code by Geoff @ UVM:
	#           www.uvm.edu/~gcd/2013/01/which-disk-is-that-volume-on
	#
	# Written by Rob van der Woude
	# http://www.robvanderwoude.com
	#

	Write-Host "GetHDDStatus.ps1,  Version 1.00"

	Write-Host "Get the SMART status for all local harddisks"

	Write-Host

	Write-Host "Usage:    " -NoNewline
	Write-Host "powershell  ./GetHDDStatus.ps1" -ForegroundColor White

	Write-Host

	Write-Host "Notes:    This script requires elevated privileges."

	Write-Host "          In Linux, the output does not include disk indexes."

	Write-Host

	Write-Host "Credits:  Windows part based on code by Geoff @ UVM:"

	Write-Host "          www.uvm.edu/~gcd/2013/01/which-disk-is-that-volume-on" -ForegroundColor DarkGray

	Write-Host

	Write-Host "Written by Rob van der Woude"

	Write-Host "http://www.robvanderwoude.com"

	Write-Host

	exit 1
}

$rc = 0

if ( $HOME[0] -eq '/' ) {
	# Linux: lshw/smartctl/df commands

	Write-Host "Volume   `tStatus`tCapacity`tModel" -ForegroundColor White
	Write-Host "======   `t======`t========`t=====`n" -ForegroundColor White

	( . lshw -short -class disk ) -match "/dev/" | ForEach-Object {
		$disk = ( $_.trim( ) -split '\s+',  3 )[1]
		$name = ( $_.trim( ) -split 'disk', 2 )[1].trim( )
		if ( $disk -notmatch "(/cd|/dvd|/sr)" ) {
			try {
				$size = 0
				$size = ( ( ( . df -l --output=source,size ) -match $disk ) -split '\s+', 2 )[1] / 1MB
				if ( $size -gt 0 ) {
					$test = ( ( ( . smartctl -H $disk ) -match "SMART [^\n\r]+: ([A-Z]+)" ) -split ":" )[1].trim( )
					Write-Host "$disk`t" -ForegroundColor White -NoNewline
					if ( $test -eq "PASSED" ) {
						$fgc = "Green"
					} else {
						$fgc = "Red"
						$rc = 1
					}
					Write-Host "$test`t" -ForegroundColor $fgc -NoNewline
					Write-Host ( "{0,5:N0} GB`t$name" -f $size ) -ForegroundColor White
				}
			}
			catch {
				# ignore errors from USB sticks etc.
			}
		}
	}
} else {
	# Windows: WMI

	# based on code by Geoff @ UVM
	# https://www.uvm.edu/~gcd/2013/01/which-disk-is-that-volume-on/

	[System.Collections.SortedList]$volumedetails = New-Object System.Collections.SortedList
	[System.Collections.SortedList]$volumestatus  = New-Object System.Collections.SortedList

	$diskdrives = Get-WmiObject -Namespace "root/CIMV2" -Class Win32_DiskDrive
	foreach ( $disk in $diskdrives ) {
		$diskindex  = $disk.Index
		$diskmodel  = $disk.Model
		$disksize   = "{0,5:F0} GB" -f ( $disk.Size / 1GB )
		$diskstatus = $disk.Status
		$part_query = 'ASSOCIATORS OF {Win32_DiskDrive.DeviceID="' + $disk.DeviceID.replace('\','\\') + '"} WHERE AssocClass=Win32_DiskDriveToDiskPartition'
		$partitions = @( Get-WmiObject -Query $part_query | Sort-Object StartingOffset )
		foreach ( $partition in $partitions ) {
			$vol_query = 'ASSOCIATORS OF {Win32_DiskPartition.DeviceID="' + $partition.DeviceID + '"} WHERE AssocClass=Win32_LogicalDiskToPartition'
			$volumes   = @( Get-WmiObject -Query $vol_query )
			foreach ( $volume in $volumes ) {
				if ( -not $volumedetails.Contains( $volume.Name ) ) {
					$volumedetails.Add( $volume.Name, "[Disk $diskindex]`t$disksize`t$diskmodel" )
					$volumestatus.Add( $volume.Name, $diskstatus )
				}
			}
		}
	}

	Write-Host "Volume`tStatus`tDisk    `tCapacity`tModel" -ForegroundColor White
	Write-Host "======`t======`t====    `t========`t=====`n" -ForegroundColor White

	$volumedetails.Keys | ForEach-Object {
		$fgc = "Green"
		$status = ( $volumestatus[$_] )
		if ( $status -ne "OK" ) {
			$fgc = "Red"
			$rc  = 1
		}
		Write-Host ( "$_`t" ) -ForegroundColor White -NoNewline
		Write-Host ( "$status`t" ) -ForegroundColor $fgc -NoNewline
		Write-Host ( $volumedetails[$_] ) -ForegroundColor White
	}
}

Write-Host

exit $rc
