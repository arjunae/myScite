# current versions of Windows come with disabled (unsigned) powershell script execution.
# To explicitly use an unsigned powershell script, sign your scripts or try: 
# PowerShell.exe -ExecutionPolicy UnRestricted -File test_powershell.ps1

# PowerShell cmdlet to interrogate the Network Adapter
# src: http://www.computerperformance.co.uk/powershell/powershell_ipconfig.htm

$strComputer = "."
$colItems = Get-WmiObject -class "Win32_NetworkAdapterConfiguration" `
-computername $strComputer | Where {$_.IPEnabled -Match "True"}
foreach ($objItem in $colItems) {
   Clear-Host
   Write-Host "MAC Address: " $objItem.MACAddress
   Write-Host "IPAddress: " $objItem.IPAddress
   Write-Host "IPEnabled: " $objItem.IPEnabled
   Write-Host "DNS Servers: " $objItem.DNSServerSearchOrder
   Write-Host ""
}