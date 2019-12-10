
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

#$DebugPreference = "Continue"
$DebugPreference = "SilentlyContinue"

$resulttable = New-Object System.Data.DataTable
$resulttable.Columns.Add("ComputerName","string") | out-null
$resulttable.Columns.Add("Check","string") | out-null
$resulttable.Columns.Add("SollSituation","string") | out-null
$resulttable.Columns.Add("IstSituation","string") | out-null
$resulttable.Columns.Add("Conclusion","string") | out-null
$resulttable.Columns.Add("CheckResult","string") | out-null

Function GetResultRow($ComputerName, $check, $SollSituation, $istSituation, $Conclusion, $CheckResult)
{
    $resultrow = $resulttable.NewRow()
    $resultrow.ComputerName = $ComputerName
    $resultrow.Check = $check
    $resultrow.SollSituation =  $SollSituation
    $resultrow.istSituation = $istSituation
    $resultrow.Conclusion = $Conclusion
    $resultrow.CheckResult = $CheckResult
    $resulttable.Rows.Add($resultrow)     
}

#########################################################################################
## Main Program
#########################################################################################

### Load External Scripts

$MyDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)

. "$MyDir\Mail.ps1"
. "$MyDir\ComputerGroups.ps1"
. "$MyDir\ResultMessages.ps1"

##

# Get ComputerGroups, which includes MonitorTemplates, which includes MonitorItems
$ComputerGroupTemplates = GetComputerGroupAssignedTemplates

#ForEach MonitorTemplate
$ComputerGroupTemplates | ForEach-Object {
    $ComputerGrp = $_.ComputerGroup
    $Templ = $_.Template
    $ComputerList = $ComputerGrp.ComputerList

    write-debug "Processing ComputerList: $($ComputerList | out-string)"

    $MonitoringItems = $Templ.MonitoringItems
    
    #ForEach Computer within the Template
    $ComputerList | ForEach-Object {
        $ComputerName = $_

        write-debug "Processing Computer: $ComputerName"

        #ForEach MonitoringItem
        $MonitoringItems | ForEach-Object {
            
            $checkresult=$false
            $check = $_.Check

            write-debug "Processing check : $check"

            $checkparam = $_.CheckParam

            Write-Debug $("Check : " + $($check | Out-String)).Trim()
            Write-Debug $("Check Param : " + $($checkparam | format-Table -AutoSize | Out-String)).Trim()
            
            switch ($check) {

 ##### EXISTENCE FILEPATH FILES

                'FilePathExistence' {
                    $filename = $checkparam.Filename
                    $filepath = $checkparam.Filepath
                    $uncpathSoll = '\\' + $ComputerName + '\' + (($filepath -split ":")[0]).ToLower() + "`$" + ($filepath -split ":")[1] + '\' + $filename
                    $checkresult = Test-Path -Path $uncpathSoll
                          if ($checkresult) {$uncpathIst = $uncpathSoll} else {$uncpathIst = ""}
                    $Conclusion = $(if ($checkresult) {ExistsCorrect "Config File" $uncpathSoll "tested with"} else { ExistsNot "Config File" $uncpathSoll})
                    AddResultRow $ComputerName $check $uncpathSoll $uncpathIst $Conclusion $checkresult
   
                }

 ##### EXISTENCE WINDOWSService

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

                        $Conclusion = $(
                        if ($ServiceExists -and $checkresult) { ExistsCorrect "Service" $Servicename $ServiceStatusIst
                        } 
                        else { 
                        if ($ServiceExists -and !$checkresult) { ExistsBut "Service" $Servicename $ServiceStatusSoll
                            } 
                            else { ExistsNot "Service" $Servicename
                            }
                        })

                    AddResultRow $ComputerName $check $ServiceStatusSoll $ServiceStatusIst $Conclusion $checkresult              
                 
                }

  ##### PROGRAM VERSION
                           
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
                     $resultrow.Conclusion = $(
                        if ($ProgramExists -and $checkresult) {
                                ExistsCorrect "Program" $programname $programversionIst
                        } else { 
                            if ($ProgramExists -and !$checkresult) {
                                ExistsNot "Program" $programname $programversionIst
                            } else {
                                ExistsNot "Program" $programname
                            }
                        })   

                    AddResultRow $ComputerName $check $programversionSoll $programversionIst $Conclusion $checkresult

                }

  ##### ENVIRONMENT VARIABLE

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
                    
                    $Conclusion = $(
                        if ($VariableExists -and $checkresult) {
                                ExistsCorrect "Environment Variable" $variablename $variablevalueIst
                        } else { 
                            if ($VariableExists -and !$checkresult) {
                                ExistsBut "Environment Variable" $variablename $variablevalueIst
                            } else {
                                ExistsNot "Environment Variable" $variablename
                            }
                        })

                    AddResultRow $ComputerName $check $variablevalueSoll $variablevalueIst $Conclusion $checkresult                                             
                }
            }
        } 
    }
}    

$resulttable

[xml]$html = $resulttable |
Select-object ComputerName,Check,SollSituation,IstSituation,Conclusion,CheckResult |
ConvertTo-Html -Fragment

1..($html.table.tr.count-1) | ForEach-Object {

    #enumerate each TD
    $td = $html.table.tr[$_]

    #create a new class attribute
    $class = $html.CreateAttribute("class")
     
    #set the class value based on the item value
    Switch ($td.childnodes.item(5).'#text') {
    "True" { $class.value = "CheckOK"}
    "False" { $class.value = "CheckNOK"}
    Default { $class.value = "CheckUnknown"}
    }
    #append the class
    $td.childnodes.item(5).attributes.append($class) | Out-Null
    }


$head = GetHeader
ConvertTo-HTML -Head $head -Body $html.InnerXml -PostContent "<h6>Created $(Get-Date)</h6>"ù | Out-File -filepath BizTalk_Server_Installation_Check_Report.htm -Encoding ascii
$body = ConvertTo-HTML -Head $head -Body $html.InnerXml -PostContent "<h6>Created $(Get-Date)</h6>" 

# Send Mail
SendMail $body
