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

function Get-ProgID {            
  #.Synopsis      
  #  Gets all of the ProgIDs registered on a system      
  #.Description      
  #  Gets all ProgIDs registered on the system. The ProgIDs returned can be used with New-Object -comObject  
  # http://blogs.msdn.com/b/powershell/archive/2009/03/20/get-progid.aspx  
  #.Example      
  #  Get-ProgID      
  #.Example      
  #  Get-ProgID | Where-Object { $_.ProgID -like "*Image*" }       
  param()      
  $paths = @("REGISTRY::HKEY_CLASSES_ROOT\CLSID")      
  if ($env:Processor_Architecture -eq "amd64") {      
    $paths+="REGISTRY::HKEY_CLASSES_ROOT\Wow6432Node\CLSID"      
  }       
  Get-ChildItem $paths -include VersionIndependentPROGID -recurse |      
  Select-Object @{      
    Name='ProgID'      
    Expression={$_.GetValue("")}          
  }, @{      
    Name='32Bit'      
    Expression={      
      if ($env:Processor_Architecture -eq "amd64") {      
        $_.PSPath.Contains("Wow6432Node")        
      } else {      
        $true      
      }            
    }      
  }      
}

#Get-ProgID