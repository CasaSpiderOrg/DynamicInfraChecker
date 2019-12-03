
#########################################################################################
## Functionname      : Get-EnvironmentVariable
#########################################################################################

<# 
 .Synopsis
  Get Environmentvariable setting on specified Computername
 .Description
  Get Environmentvariable setting on specified Computername
 .Parameter CompterName
  (Remote) Computer Name
 .Parameter Name
  EnvironmentVariable Name
 .Example
  PS> Get-EnvironmentVariable -ComputerName win092 -
#>

function Get-EnvironmentVariable {
    [cmdletbinding()] 
    param( 
        [string[]]$ComputerName =$env:ComputerName, 
        [string]$Name 
    ) 
    
    foreach($Computer in $ComputerName) { 
        Write-Verbose "Working on $Computer" 
        if(!(Test-Connection -ComputerName $Computer -Count 1 -quiet)) { 
            Write-Verbose "$Computer is not online" 
            Continue 
        } 
        
        try { 
            $EnvObj = @(Get-WMIObject -Class Win32_Environment -ComputerName $Computer -EA Stop) 
            if(!$EnvObj) { 
                Write-Verbose "$Computer returned empty list of environment variables" 
                Continue 
            } 
            Write-Verbose "Successfully queried $Computer" 
            
            if($Name) { 
                Write-Verbose "Looking for environment variable with the name $name" 
                $Env = $EnvObj | Where-Object {$_.Name -eq $Name} 
                if(!$Env) { 
                    Write-Verbose "$Computer has no environment variable with name $Name" 
                    Continue 
                } 
                $Env             
            } else { 
                Write-Verbose "No environment variable specified. Listing all" 
                $EnvObj 
            } 
            
        } catch { 
            Write-Verbose "Error occurred while querying $Computer. $_" 
            Continue 
        } 
    
    }
} # Get-EnvironmentVariable

#########################################################################################
## Main Program
#########################################################################################

#$DebugPreference = "Continue"
$DebugPreference = "SilentlyContinue"

$resulttable = New-Object System.Data.DataTable
$resulttable.Columns.Add("ComputerName","string") | out-null
$resulttable.Columns.Add("Check","string") | out-null
$resulttable.Columns.Add("SollSituation","string") | out-null
$resulttable.Columns.Add("IstSituation","string") | out-null
$resulttable.Columns.Add("Conclusion","string") | out-null
$resulttable.Columns.Add("CheckResult","string") | out-null

$MonitoringItems = "" 
$MonitoringItems = @()

$MonitoringItem1 = [PSCustomObject]@{
    Check      = 'Config file existence'
    CheckParam = [PSCustomObject]@{
        Filename = 'tnsnames.ora'
        Filepath = 'D:\app\Oracle\product\12.2.0\client_1\Network\Admin'
    }   
}

$MonitoringItem2 = [PSCustomObject]@{
    Check      = 'Program version'
    CheckParam = [PSCustomObject]@{
        Programname = 'Microsoft BizTalk Server 2015 Feature Update 3'
        Programversion = '3.13.335.2'
    }   
}

$MonitoringItem3 = [PSCustomObject]@{
    Check      = 'EnvironmentVariable'
    CheckParam = [PSCustomObject]@{
        Variablename = 'TNS_ADMIN'
        VariableValue = 'D:\app\Oracle\product\12.2.0\client_1\Network\Admin'

    } 
}

$MonitoringItems += $MonitoringItem1
$MonitoringItems += $MonitoringItem2
$MonitoringItems += $MonitoringItem3

Write-Debug $($("Monitoring Items : " + $($MonitoringItems | format-Table -AutoSize | out-string)).Trim())

$Template1 = [PSCustomObject]@{
        TemplateName = "BizTalkServer"
        MonitoringItems = $MonitoringItems
}


$MonitoringItems = "" 
$MonitoringItems = @()

$MonitoringItem1 = [PSCustomObject]@{
    Check      = 'Check windows service existence'
    CheckParam = [PSCustomObject]@{
        ServiceName = 'OracleRemExecServiceV2'
        ServiceStatus = 'Running'
    }   
}

$MonitoringItems += $MonitoringItem1

Write-Debug $($("Monitoring Items : " + $($MonitoringItems | format-Table -AutoSize | out-string)).Trim())

$Template2 = [PSCustomObject]@{
    TemplateName = "GenericDevelopmentServer"
    MonitoringItems = $MonitoringItems
}


$Templates = "" 
$Templates = @()

$Templates += $Template1
$Templates += $Template2

$ComputerGroups = "" 
$ComputerGroups = @()

$ComputerGroup1 = [PSCustomObject]@{
    GroupName   = 'BizTalkServers'
    ComputerList = @('win236o1','win236o2','win236t')   
}

$ComputerGroup2 = [PSCustomObject]@{
    GroupName   = 'GenericDevelopmentServers'
    ComputerList = @('win155o')   
}

$ComputerGroups += $ComputerGroup1
$ComputerGroups += $ComputerGroup2


$ComputerGroupAssignedTemplates = ""
$ComputerGroupAssignedTemplates = @()

$ComputerGroupAssignedTemplate = [PSCustomObject]@{
    ComputerGroup = $($ComputerGroups | where-object groupname -eq 'BizTalkServers')
    Template = $($Templates | where-object TemplateName -eq 'BizTalkServer')
}

$ComputerGroupAssignedTemplates += $ComputerGroupAssignedTemplate

$ComputerGroupAssignedTemplate = [PSCustomObject]@{
    ComputerGroup = $($ComputerGroups | where-object groupname -eq 'GenericDevelopmentServers')
    Template = $($Templates | where-object TemplateName -eq 'GenericDevelopmentServer')
}

$ComputerGroupAssignedTemplates += $ComputerGroupAssignedTemplate

$ComputerGroupAssignedTemplates | ForEach-Object {
    $ComputerGrp = $_.ComputerGroup
    $Templ = $_.Template
    $ComputerList = $ComputerGrp.ComputerList
    write-debug "Processing ComputerList: $($ComputerList | out-string)"
    $MonitoringItems = $Templ.MonitoringItems
    $ComputerList | ForEach-Object {
        $ComputerName = $_
        write-debug "Processing Computer: $ComputerName"
        $MonitoringItems | ForEach-Object {
            $checkresult=$false
            $resultrow = $resulttable.NewRow()
            $check = $_.Check
            write-debug "Processing check : $check"
            $checkparam = $_.CheckParam
            Write-Debug $("Check : " + $($check | Out-String)).Trim()
            Write-Debug $("Check Param : " + $($checkparam | format-Table -AutoSize | Out-String)).Trim()
            switch ($check) {
                'Config file existence' {
                    $filename = $checkparam.Filename
                    $filepath = $checkparam.Filepath
                    $uncpathSoll = '\\' + $ComputerName + '\' + (($filepath -split ":")[0]).ToLower() + "`$" + ($filepath -split ":")[1] + '\' + $filename
                    $checkresult = Test-Path -Path $uncpathSoll
                    if ($checkresult) {
                        $uncpathIst = $uncpathSoll
                    } else {
                        $uncpathIst = ""
                    }

                    $resultrow.ComputerName = $ComputerName
                    $resultrow.Check = $check
                    $resultrow.SollSituation =  $uncpathSoll
                    $resultrow.istSituation = $uncpathIst
                    $resultrow.Conclusion = $(if ($checkresult) {"Config File $uncpathSoll exists"} else { "Config File $uncpathSoll doesn't exist"})
                    $resultrow.CheckResult = $checkresult
                    $resulttable.Rows.Add($resultrow)   
                }
                'Check windows service existence' {
                    $Servicename = $checkparam.Servicename
                    $ServiceStatusSoll= $checkparam.Servicestatus
                    $Serviceinfo = Get-Service -ComputerName $ComputerName -name $Servicename
                    $ServiceStatusIst = $Serviceinfo.Status
                    
                    if ($ServiceStatusIst) {
                        $ServiceExists=$true
                        $checkresult = $ServiceStatusIst -eq $ServiceStatusSoll
                    } else {
                        $ServiceExists=$false
                    }

                    $resultrow.ComputerName = $ComputerName
                    $resultrow.Check = $check
                    $resultrow.SollSituation =  $ServiceStatusSoll
                    $resultrow.istSituation = $ServiceStatusIst
                    $resultrow.Conclusion = $(
                        if ($ServiceExists -and $checkresult) {
                            "Service : $Servicename exists and has $ServiceStatusIst status"
                        } else { 
                            if ($ServiceExists -and !$checkresult) {
                                "Service : $Servicename exists, but has no $ServiceStatusSoll status"
                            } else {
                                "Service : $Servicename doesn't exist"
                            }
                        })                    
                    $resultrow.CheckResult = $checkresult
                    $resulttable.Rows.Add($resultrow)               
                }           
                'Program version' {
                    $programname = $checkparam.Programname
                    $programversionSoll = $checkparam.Programversion
                    $programinfo=''
                    $programinfo=Invoke-command -computer $ComputerName {Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*} | Where-object ParentDisplayName -eq $programname
                    $programversionIst = '' 
                    $programversionIst = $programinfo.version
                    
                    if ($programversionIst) {
                        $ProgramExists=$true
                        $checkresult = $programversionIst -eq $programversionSoll
                    } else {
                        $ProgramExists=$false
                    }

                    $resultrow.ComputerName = $ComputerName
                    $resultrow.Check = $check
                    $resultrow.SollSituation =  $programversionSoll
                    $resultrow.istSituation = $programversionIst
                    $resultrow.Conclusion = $(
                        if ($ProgramExists -and $checkresult) {
                            "Program : $programname exists and has correct version : $programversionIst"
                        } else { 
                            if ($ProgramExists -and !$checkresult) {
                                "Program : $programname exists, but with other version : $programversionIst"
                            } else {
                                "Program : $programname doesn't exist"
                            }
                        })                    
                    $resultrow.CheckResult = $checkresult
                    $resulttable.Rows.Add($resultrow)               
                }
                'EnvironmentVariable' {
                    $variablename = $checkparam.Variablename
                    $variablevalueSoll = $checkparam.Variablevalue
                    $variablevalueIst=(Get-EnvironmentVariable -ComputerName $ComputerName -Name $variablename).VariableValue
                    if ($variablevalueIst) {
                        $VariableExists=$true
                        $checkresult = $variablevalueIst -eq $variablevalueSoll
                    } else {
                        $VariableExists=$false
                    }
                    
                    $resultrow.ComputerName = $ComputerName
                    $resultrow.Check = $check
                    $resultrow.SollSituation =  $variablevalueSoll
                    $resultrow.istSituation = $variablevalueIst
                    $resultrow.Conclusion = $(
                        if ($VariableExists -and $checkresult) {
                            "Environment Variable : $variablename exists and has correct value : $variablevalueIst"
                        } else { 
                            if ($VariableExists -and !$checkresult) {
                                "Environment Variable : $variablename exists, but with other value : $variablevalueIst"
                            } else {
                                "Environment Variable $variablename doesn't exist"
                            }
                        })
                    $resultrow.CheckResult = $checkresult
                    $resulttable.Rows.Add($resultrow)                                             
                }
            }
        } 
    }
}    

$resulttable

$ReportTitle = "BizTalk Server Installation Check Report"

$head = @"
<Title>$ReportTitle</Title>
<style>
body { background-color:#FFFFFF;
font-family:Tahoma;
font-size:12pt; }
td, th { border:1px solid black;
border-collapse:collapse; }
th { color:white;
background-color:black; }
table, tr, td, th { padding: 2px; margin: 0px }
table { width:95%;margin-left:5px; margin-bottom:20px;}
.CheckNOK {color: Red }
.CheckOK {color: Green }
.CheckUnknown {color: Yellow }
</style>
<br>
<H1>$ReportTitle</H1>
"@

[xml]$html = $resulttable |
Select-object ComputerName,Check,SollSituation,IstSituation,Conclusion,CheckResult |
ConvertTo-Html -Fragment

1..($html.table.tr.count-1) | ForEach-Object {
    #enumerate each TD
    $td = $html.table.tr[$_]
    #create a new class attribute
    $class = $html.CreateAttribute("class")
     
    #set the class value based on the item value
    Switch ($td.childnodes.item(4).'#text') {
    "True" { $class.value = "CheckOK"}
    "False" { $class.value = "CheckNOK"}
    Default { $class.value = "CheckUnknown"}
    }
    #append the class
    $td.childnodes.item(3).attributes.append($class) | Out-Null
    }

ConvertTo-HTML -Head $head -Body $html.InnerXml -PostContent “<h6>Created $(Get-Date)</h6>” | Out-File -filepath BizTalk_Server_Installation_Check_Report.htm -Encoding asci

$emailRecipient = "nijhp1"
 
$emailSmtpServer = "mail"
$emailMessage = New-Object System.Net.Mail.MailMessage
$From='enges1'
$emailMessage.From = $From + '@brabantwater.nl'
$SMTPClient = New-Object System.Net.Mail.SmtpClient( $emailSmtpServer)   

$emailMessageManagentInfo=$emailMessage

$subjectText = "BizTalk Server Installation Check Report"
$emailMessageManagentInfo.Subject = $subjectText
$emailMessageManagentInfo.IsBodyHtml = $true
$emailMessageManagentInfo.Body = $Body 

$To1=$emailRecipient
$emailMessageManagentInfo.To.Add( ($To1 + '@brabantwater.nl') )
        
$SMTPClient.Send( $emailMessageManagentInfo )
