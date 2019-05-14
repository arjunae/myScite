<#
 	.SYNOPSIS
        This script outputs a breakdown of the logon process.
		
    .DESCRIPTION
        This script gives an insight to the logon process phases.
        Each phase described have a column for duration in seconds, start and end time
        of the phase, and interim delay which is the time that passed between the
        end of one phase and the start of the one that comes after.
		
	.PARAMETER  <UserName <string[]>
		Specifies the user name on which the script runs. The default is the user who runs the script.
		
	.PARAMETER	<UserDomain <string[]>
		Specifies the domain name of the user on which the script runs. The default is the domain name of the user who runs the script.
		
	.PARAMETER  <CUDesktopLoadTime>
		Specifies the duration of the Shell phase, can be used with ControlUp as passed argument.
		
    .LINK
        For more information refer to:
            http://www.controlup.com

    .EXAMPLE
        C:\PS> Get-LogonDurationAnalysis -UserName Rick
		
		Gets analysis of the logon process for the user 'Rick' in the current domain.
#>

function Get-LogonDurationAnalysis {

param (
    [Parameter(Mandatory=$false)]
    [Alias('User')]
    [String]
    $Username = $env:USERNAME,
    [Parameter(Mandatory=$false)] 
    [Alias('Domain')]
    [String]
    $UserDomain = $env:USERDOMAIN,
    [int]
    $CUDesktopLoadTime
    )
    begin {
    function Get-PhaseEvent {
    
    param (
        [ValidateNotNullOrEmpty()]
        [String]
        $PhaseName,
        [ValidateNotNullOrEmpty()]
        [String]
        $StartProvider,
        [ValidateNotNullOrEmpty()]
        [String]
        $EndProvider,
        [ValidateNotNullOrEmpty()]
        [String]
        $StartXPath,
        [ValidateNotNullOrEmpty()]
        [String]
        $EndXPath,
        [int]
        $CUAddition
        )

        try {
            $StartEvent = Get-WinEvent -MaxEvents 1 -ProviderName $StartProvider -FilterXPath $StartXPath -ErrorAction Stop
            if ($StartProvider -eq 'Microsoft-Windows-Security-Auditing' -and $EndProvider -eq 'Microsoft-Windows-Security-Auditing') {
                $EndEvent = Get-WinEvent -MaxEvents 1 -ProviderName $EndProvider -FilterXPath ("{0}{1}" -f $EndXPath,@"
and *[EventData[Data[@Name='ProcessId'] 
and (Data=`'$($StartEvent.Properties[4].Value)`')]] 
"@) # Responsible to match the process termination event to the exact process
            }
            elseif ($CUAddition) {
                Set-Variable -Name EndEvent -Value ($StartEvent | Select-Object -ExpandProperty TimeCreated).AddSeconds($CUAddition)
            }

            else {
                $EndEvent = Get-WinEvent -MaxEvents 1 -ProviderName $EndProvider -FilterXPath $EndXPath
            }
       }

        catch {
            if ($PhaseName -ne 'Citrix Profile Mgmt') {
                if ($StartProvider -eq 'Microsoft-Windows-Security-Auditing' -or $EndProvider -eq 'Microsoft-Windows-Security-Auditing' ) {
                    "Could not find $PhaseName events (requires audit process tracking)"
                }
                else {
                    "Could not find $PhaseName events"
                }
                Return
            }
        }

        $EventInfo = @{}

        if ($EndEvent) {
            if ((($EndEvent).GetType()).Name -eq 'DateTime') {
                $Duration = New-TimeSpan -Start $StartEvent.TimeCreated -End $EndEvent
                $EventInfo.EndTime = $EndEvent
            }
            else {
                $Duration = New-TimeSpan -Start $StartEvent.TimeCreated -End $EndEvent.TimeCreated
                $EventInfo.EndTime = $EndEvent.TimeCreated 
            }
        }
        $Script:EventProperties = $StartEvent.Properties
        $EventInfo.PhaseName = $PhaseName
        $EventInfo.StartTime = $StartEvent.TimeCreated
        $EventInfo.Duration = $Duration.TotalSeconds

        $PSObject = New-Object -TypeName PSObject -Property $EventInfo

        if ($EventInfo.Duration) {
            $Script:Output += $PSObject
        }
    }

        $Script:Output = @()

        try {
        $LogonEvent = Get-WinEvent -MaxEvents 1 -ProviderName Microsoft-Windows-Security-Auditing -FilterXPath @"
        *[System[(EventID='4624')]] 
        and *[EventData[Data[@Name='TargetUserName'] 
        and (Data=`"$UserName`")]] 
        and *[EventData[Data[@Name='TargetDomainName'] 
        and (Data=`"$UserDomain`")]] 
        and *[EventData[Data[@Name='LogonType'] 
        and (Data=`"2`" or Data=`"10`" or Data=`"11`")]]
        and *[EventData[Data[@Name='ProcessName'] 
        and (Data=`"C:\Windows\System32\winlogon.exe`")]]
"@ -ErrorAction Stop
        }
        catch {
            Throw 'Could not find EventID 4624 (Successfully logged on event) in the Windows Security log.'
        }

        $Logon = New-Object -TypeName PSObject

        Add-Member -InputObject $Logon -MemberType NoteProperty -Name LogonTime -Value $LogonEvent.TimeCreated
        Add-Member -InputObject $Logon -MemberType NoteProperty -Name FormatTime -Value (Get-Date -Date $LogonEvent.TimeCreated -UFormat %r)
        Add-Member -InputObject $Logon -MemberType NoteProperty -Name LogonID -Value ($LogonEvent.Properties[7]).Value
        Add-Member -InputObject $Logon -MemberType NoteProperty -Name WinlogonPID -Value ($LogonEvent.Properties[16]).Value
        Add-Member -InputObject $Logon -MemberType NoteProperty -Name UserSID -Value ($LogonEvent.Properties[4]).Value

        $ISO8601Date = Get-Date -Date $Logon.LogonTime
        $ISO8601Date = $ISO8601Date.ToUniversalTime()
        $ISO8601Date = $ISO8601Date.ToString("s")

        $NPStartXpath = @"
        *[System[(EventID='4688')
        and TimeCreated[@SystemTime > '$ISO8601Date']]]
        and *[EventData[Data[@Name='ProcessId'] 
        and (Data=`'$($Logon.WinlogonPID)`')]] 
        and *[EventData[Data[@Name='NewProcessName'] 
        and (Data='C:\Windows\System32\mpnotify.exe')]] 
"@

        $NPEndXPath = @"
        *[System[(EventID='4689')
        and TimeCreated[@SystemTime > '$ISO8601Date']]]
        and *[EventData[Data[@Name='ProcessName'] 
        and (Data=`"C:\Windows\System32\mpnotify.exe`")]] 
"@

        $ProfStartXpath = @"
        *[System[(EventID='10')
        and TimeCreated[@SystemTime > '$ISO8601Date']]]
        and *[EventData[Data and (Data='$UserName')]]
"@

        $ProfEndXpath = @"
        *[System[(EventID='1')
        and  TimeCreated[@SystemTime>='$ISO8601Date']]]
        and *[System[Security[@UserID='$($Logon.UserSID)']]]
"@

        $UserProfStartXPath = @"
        *[System[(EventID='1')
        and  TimeCreated[@SystemTime>='$ISO8601Date']]]
        and *[System[Security[@UserID='$($Logon.UserSID)']]]
"@

        $UserProfEndXPath = @"
        *[System[(EventID='2')
        and  TimeCreated[@SystemTime>='$ISO8601Date']]]
        and *[System[Security[@UserID='$($Logon.UserSID)']]]
"@

        $GPStartXPath = @"
        *[System[(EventID='4001')
        and  TimeCreated[@SystemTime>='$ISO8601Date']]]
        and *[EventData[Data[@Name='PrincipalSamName'] 
        and (Data=`"$UserDomain\$UserName`")]] 
"@

        $GPEndXPath = @"
        *[System[(EventID='8001')
        and TimeCreated[@SystemTime > '$ISO8601Date']]]
        and *[EventData[Data[@Name='PrincipalSamName'] 
        and (Data=`"$UserDomain\$UserName`")]] 
"@

        $GPScriptStartXPath = @"
        *[System[(EventID='4018')
        and  TimeCreated[@SystemTime>='$ISO8601Date']]]
        and *[EventData[Data[@Name='PrincipalSamName'] 
        and (Data=`"$UserDomain\$UserName`")]] 
        and *[EventData[Data[@Name='ScriptType'] 
        and (Data='1')]]
"@

        $GPScriptEndXPath = @"
        *[System[(EventID='5018')
        and  TimeCreated[@SystemTime>='$ISO8601Date']]]
        and *[EventData[Data[@Name='PrincipalSamName'] 
        and (Data=`"$UserDomain\$UserName`")]] 
        and *[EventData[Data[@Name='ScriptType'] 
        and (Data='1')]]
"@

        $UserinitXPath = @"
        *[System[(EventID='4688')
        and TimeCreated[@SystemTime > '$ISO8601Date']]]
        and *[EventData[Data[@Name='ProcessId'] 
        and (Data=`'$($Logon.WinlogonPID)`')]] 
        and *[EventData[Data[@Name='NewProcessName'] 
        and (Data='C:\Windows\System32\userinit.exe')]] 
"@

        $ShellXPath = @"
        *[System[(EventID='4688')
        and TimeCreated[@SystemTime > '$ISO8601Date']]] 
        and *[EventData[Data[@Name='SubjectLogonId'] 
        and (Data=`'$($Logon.LogonID)`')]] 
        and *[EventData[Data[@Name='NewProcessName'] 
        and (Data=`"C:\Program Files (x86)\Citrix\system32\icast.exe`" or Data=`"C:\Windows\explorer.exe`")]]
"@

        $ExplorerXPath = @"
        *[System[(EventID='4688')
        and TimeCreated[@SystemTime > '$ISO8601Date']]] 
        and *[EventData[Data[@Name='SubjectLogonId'] 
        and (Data=`'$($Logon.LogonID)`')]] 
        and *[EventData[Data[@Name='NewProcessName'] 
        and (Data=`"C:\Windows\explorer.exe`")]]
"@
    }

    process {
        Get-PhaseEvent -PhaseName 'Network Providers' -StartProvider 'Microsoft-Windows-Security-Auditing' -EndProvider 'Microsoft-Windows-Security-Auditing' `
        -StartXPath $NPStartXpath -EndXPath $NPEndXPath

        if (Get-WinEvent -ListProvider 'Citrix Profile management' -ErrorAction SilentlyContinue) {

            Get-PhaseEvent -PhaseName 'Citrix Profile Mgmt' -StartProvider 'Citrix Profile management' -EndProvider 'Microsoft-Windows-User Profiles Service' `
            -StartXPath $ProfStartXpath -EndXPath $ProfEndXpath
        }

        Get-PhaseEvent -PhaseName 'User Profile' -StartProvider 'Microsoft-Windows-User Profiles Service' -EndProvider 'Microsoft-Windows-User Profiles Service' `
        -StartXPath $UserProfStartXPath -EndXPath $UserProfEndXPath

        Get-PhaseEvent -PhaseName 'Group Policy' -StartProvider 'Microsoft-Windows-GroupPolicy' -EndProvider 'Microsoft-Windows-GroupPolicy' `
        -StartXPath $GPStartXPath -EndXPath $GPEndXPath

        Get-PhaseEvent -PhaseName 'GP Scripts' -StartProvider 'Microsoft-Windows-GroupPolicy' -EndProvider 'Microsoft-Windows-GroupPolicy' `
        -StartXPath $GPScriptStartXPath -EndXPath $GPScriptEndXPath

        if ($Script:EventProperties[3].Value -eq $true) {
            if ($Script:Output[-1].PhaseName -eq 'GP Scripts') {
                $Script:Output[-1].PhaseName = 'GP Scripts (sync)'
            }
        }

        else {
            if ($Script:Output[-1].PhaseName -eq 'GP Scripts') {
                $Script:Output[-1].PhaseName = 'GP Scripts (async)'
            }
        }

        Get-PhaseEvent -PhaseName 'Pre-Shell (Userinit)' -StartProvider 'Microsoft-Windows-Security-Auditing' -EndProvider 'Microsoft-Windows-Security-Auditing' `
        -StartXPath $UserinitXPath -EndXPath $ShellXPath

        if ($CUDesktopLoadTime) {
        Get-PhaseEvent -PhaseName 'Shell' -StartProvider 'Microsoft-Windows-Security-Auditing' -StartXPath $ExplorerXPath -CUAddition $CUDesktopLoadTime
        }

        if ($Script:Output[-1].PhaseName -eq 'Shell' -or $Script:Output[-1].PhaseName -eq 'Pre-Shell (Userinit)') {
        $TotalDur = "{0:N1}" -f (New-TimeSpan -Start $Logon.LogonTime -End $Script:Output[-1].EndTime | Select-Object -ExpandProperty TotalSeconds) `
        + " seconds"
        }

        else
        {
        $TotalDur = 'N/A'
        }

        $Script:Output = $Script:Output | Sort-Object StartTime

        for($i=1;$i -le $Script:Output.length-1;$i++) {

            $Deltas = New-TimeSpan -Start $Script:Output[$i-1].EndTime -End $Script:Output[$i].StartTime
            $Script:Output[$i] | Add-Member -MemberType NoteProperty -Name TimeDelta -Value $Deltas -Force
        }

        $Deltas = New-TimeSpan -Start $Logon.LogonTime -End $Script:Output[0].StartTime
        $Script:Output[0] | Add-Member -MemberType NoteProperty -Name TimeDelta -Value $Deltas -Force
    }

    end {
        Write-Host "User name:`t $UserName `
Logon Time:`t $($Logon.FormatTime) `
Logon Duration:`t $TotalDur"

        $Format = @{Expression={$_.PhaseName};Label="Logon Phase"}, `
        @{Expression={'{0:N1}' -f $_.Duration};Label="Duration (s)"}, `
        @{Expression={'{0:hh:mm:ss.f}' -f $_.StartTime};Label="Start Time"}, `
        @{Expression={'{0:hh:mm:ss.f}' -f $_.EndTime};Label="End Time"}, `
        @{Expression={'{0:N1}' -f ($_.TimeDelta | Select-Object -ExpandProperty TotalSeconds)};Label="Interim Delay"}
        $Script:Output | Format-Table $Format -AutoSize

        Write-Host "Only synchronous scripts affect logon duration"
    }
}
# SIG # Begin signature block
# MIIOXAYJKoZIhvcNAQcCoIIOTTCCDkkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUposxNIOpr6j0GzAg7yjSGHjT
# hvSgggtbMIIFSTCCBDGgAwIBAgIQVBVQxNeFI36WQTc7Ab5sWDANBgkqhkiG9w0B
# AQUFADCBtDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8w
# HQYDVQQLExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTswOQYDVQQLEzJUZXJtcyBv
# ZiB1c2UgYXQgaHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL3JwYSAoYykxMDEuMCwG
# A1UEAxMlVmVyaVNpZ24gQ2xhc3MgMyBDb2RlIFNpZ25pbmcgMjAxMCBDQTAeFw0x
# NDA4MTMwMDAwMDBaFw0xNjEwMTEyMzU5NTlaMHsxCzAJBgNVBAYTAklMMQwwCgYD
# VQQIEwNMT0QxDDAKBgNVBAcTA0xPRDEnMCUGA1UEChQeU01BUlQtWCBTT0ZUV0FS
# RSBTT0xVVElPTlMgTFREMScwJQYDVQQDFB5TTUFSVC1YIFNPRlRXQVJFIFNPTFVU
# SU9OUyBMVEQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD2tPA0RFlK
# dnbFCAgWRlZeopz0BwZxnQb5WF3SagckulMBKryQ/Y7ZIJwfflSocQdbNukp+0mq
# mJRAfURaIBCnuFmwD6iNzyHRVybeyrX2XZJZzCWNCsiEaXY/5L10t0Y8Oh6hbakc
# dVQtEXXP+4bw6Ue3V/fzIjNkdndJq5AqESyWgh/stCqKcmjduMXCZtUPvqsVhYCc
# ahLPVM/cmOppDluIaY1d8NquBNSHSS2w9eIQrgKl+tQwPhfRZy+O033SlBy92IP7
# VrKwJ5EedFaF7etByJtWWu6AxmylMtmG/dPI8zjJ1KjiQBTog9l1B0IRnnXs4hNL
# JIEZprIm7GbjAgMBAAGjggGNMIIBiTAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIH
# gDArBgNVHR8EJDAiMCCgHqAchhpodHRwOi8vc2Yuc3ltY2IuY29tL3NmLmNybDBm
# BgNVHSAEXzBdMFsGC2CGSAGG+EUBBxcDMEwwIwYIKwYBBQUHAgEWF2h0dHBzOi8v
# ZC5zeW1jYi5jb20vY3BzMCUGCCsGAQUFBwICMBkWF2h0dHBzOi8vZC5zeW1jYi5j
# b20vcnBhMBMGA1UdJQQMMAoGCCsGAQUFBwMDMFcGCCsGAQUFBwEBBEswSTAfBggr
# BgEFBQcwAYYTaHR0cDovL3NmLnN5bWNkLmNvbTAmBggrBgEFBQcwAoYaaHR0cDov
# L3NmLnN5bWNiLmNvbS9zZi5jcnQwHwYDVR0jBBgwFoAUz5mp6nsm9EvJjo/X8AUm
# 7+PSp50wHQYDVR0OBBYEFAbgZ+D2b2MB+Lxi82txiFtFaVsvMBEGCWCGSAGG+EIB
# AQQEAwIEEDAWBgorBgEEAYI3AgEbBAgwBgEBAAEB/zANBgkqhkiG9w0BAQUFAAOC
# AQEAQYqGaPrQtk53ksYyD/HhqQw0iOpi+GTxmJ7vhZDS7C7mL6rwJwT4MYrEy6sy
# N4YCK2/9+RNTarYoFzhTzIofslKmSQnRLNQ1+4kvdwoIkUBu8t1DgytEUvKR+tFk
# m5x8drjqFTR3if7IaEMaf54FMVB88CH1HIvVJ9h3uOCApdqbScA0i4O/V2buPhyN
# 4FgFcfiidi+qZunBNeLdnp3zJzl1RM6YQg9U9+LVzU2RYPb4pfLR/A5wcBLdU/0e
# P1fWQGgNvqqWDlaBBPbEkgp9LOrnX31isb5ku7F4S5rHHA0BO6umJk9qijWmNZO+
# RXD6iTcFfSpRV1xvok1Ph7ZzYzCCBgowggTyoAMCAQICEFIA5aolVvwahu2WydRL
# M8cwDQYJKoZIhvcNAQEFBQAwgcoxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJp
# U2lnbiwgSW5jLjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE6MDgG
# A1UECxMxKGMpIDIwMDYgVmVyaVNpZ24sIEluYy4gLSBGb3IgYXV0aG9yaXplZCB1
# c2Ugb25seTFFMEMGA1UEAxM8VmVyaVNpZ24gQ2xhc3MgMyBQdWJsaWMgUHJpbWFy
# eSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eSAtIEc1MB4XDTEwMDIwODAwMDAwMFoX
# DTIwMDIwNzIzNTk1OVowgbQxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2ln
# biwgSW5jLjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE7MDkGA1UE
# CxMyVGVybXMgb2YgdXNlIGF0IGh0dHBzOi8vd3d3LnZlcmlzaWduLmNvbS9ycGEg
# KGMpMTAxLjAsBgNVBAMTJVZlcmlTaWduIENsYXNzIDMgQ29kZSBTaWduaW5nIDIw
# MTAgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD1I0tepdeKuzLp
# 1Ff37+THJn6tGZj+qJ19lPY2axDXdYEwfwRof8srdR7NHQiM32mUpzejnHuA4Jnh
# 7jdNX847FO6G1ND1JzW8JQs4p4xjnRejCKWrsPvNamKCTNUh2hvZ8eOEO4oqT4Vb
# kAFPyad2EH8nA3y+rn59wd35BbwbSJxp58CkPDxBAD7fluXF5JRx1lUBxwAmSkA8
# taEmqQynbYCOkCV7z78/HOsvlvrlh3fGtVayejtUMFMb32I0/x7R9FqTKIXlTBdO
# flv9pJOZf9/N76R17+8V9kfn+Bly2C40Gqa0p0x+vbtPDD1X8TDWpjaO1oB21xku
# pc1+NC2JAgMBAAGjggH+MIIB+jASBgNVHRMBAf8ECDAGAQH/AgEAMHAGA1UdIARp
# MGcwZQYLYIZIAYb4RQEHFwMwVjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cudmVy
# aXNpZ24uY29tL2NwczAqBggrBgEFBQcCAjAeGhxodHRwczovL3d3dy52ZXJpc2ln
# bi5jb20vcnBhMA4GA1UdDwEB/wQEAwIBBjBtBggrBgEFBQcBDARhMF+hXaBbMFkw
# VzBVFglpbWFnZS9naWYwITAfMAcGBSsOAwIaBBSP5dMahqyNjmvDz4Bq1EgYLHsZ
# LjAlFiNodHRwOi8vbG9nby52ZXJpc2lnbi5jb20vdnNsb2dvLmdpZjA0BgNVHR8E
# LTArMCmgJ6AlhiNodHRwOi8vY3JsLnZlcmlzaWduLmNvbS9wY2EzLWc1LmNybDA0
# BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLnZlcmlzaWdu
# LmNvbTAdBgNVHSUEFjAUBggrBgEFBQcDAgYIKwYBBQUHAwMwKAYDVR0RBCEwH6Qd
# MBsxGTAXBgNVBAMTEFZlcmlTaWduTVBLSS0yLTgwHQYDVR0OBBYEFM+Zqep7JvRL
# yY6P1/AFJu/j0qedMB8GA1UdIwQYMBaAFH/TZafC3ey78DAJ80M5+gKvMzEzMA0G
# CSqGSIb3DQEBBQUAA4IBAQBWIuY0pMRhy0i5Aa1WqGQP2YyRxLvMDOWteqAif99H
# OEotbNF/cRp87HCpsfBP5A8MU/oVXv50mEkkhYEmHJEUR7BMY4y7oTTUxkXoDYUm
# cwPQqYxkbdxxkuZFBWAVWVE5/FgUa/7UpO15awgMQXLnNyIGCb4j6T9Emh7pYZ3M
# sZBc/D3SjaxCPWU21LQ9QCiPmxDPIybMSyDLkB9djEw0yjzY5TfWb6UgvTTrJtmu
# DefFmvehtCGRM2+G6Fi7JXx0Dlj+dRtjP84xfJuPG5aexVN2hFucrZH6rO2Tul3I
# IVPCglNjrxINUIcRGz1UUpaKLJw9khoImgUux5OlSJHTMYICazCCAmcCAQEwgckw
# gbQxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEfMB0GA1UE
# CxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE7MDkGA1UECxMyVGVybXMgb2YgdXNl
# IGF0IGh0dHBzOi8vd3d3LnZlcmlzaWduLmNvbS9ycGEgKGMpMTAxLjAsBgNVBAMT
# JVZlcmlTaWduIENsYXNzIDMgQ29kZSBTaWduaW5nIDIwMTAgQ0ECEFQVUMTXhSN+
# lkE3OwG+bFgwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAw
# GQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisG
# AQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFM8r7sHdFDnC1zh9Tv6FPwFGCN2OMA0G
# CSqGSIb3DQEBAQUABIIBAG93oC3owTJ6SU8qnsCw9lZIMlQfVzu1IQJdrpxQXI5C
# uiocm46OHSQYWeI4aFcqlnDowlsK0j5zUZ6X3RyE7y6iouooinj6MTwLpOaryVHn
# Psbg0ZW3s2utfV8OD40xugcZWcfnJPdWF0qCsEav0EOWDagp6YvGsETQE3sE+H7G
# Ada0yGcj4sTc4j6r0LI3y+t/3OlsuSo2Pu4xVMZFHonUVrS8AgXL6ugdmfQtJRai
# BxAGT8XO6cZTqPaUR0+EMcwiGXpMN8H2p6bjNZdget5rm2liWq/rDGcVui/GHDtD
# ExS2Z8cTyX10N6k8MK5TxcT03rS0uUn3XaV+X7TFgSY=
# SIG # End signature block
