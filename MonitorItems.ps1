####################################################################################
# MonitorItems
# Script to return Monitoring items to processing script
#
####################################################################################

#----------------------------
# BizTalk Server MonitorItems
#----------------------------

# Variable Monitor-Objecten voor BT Server en methodes om deze op te halen

# To Add a monitoring Item: 
# 1. Create one like done below
# 2. Add the item to the corresponding Get***MonitoringItems method
# 3.a When the "Check" type is equal to an existing one, there is no need to create new logic for it. 
#     CheckServer.ps1 will process it based on the name. e.g. 'Config file existence' will always test the existence of the file/path 
# 3.b When the monitoring item is a new kind of check, add corresponding code within the switch of CheckServer.ps1. 
#     NB: Monitoring item Check must correspond between the scripts. e.g. 'Program version' here, must correspond with 'Program version' as switch-statement

$BTMonitoringItem1 = [PSCustomObject]@{
    Check      = 'FilePathExistence'
    CheckParam = [PSCustomObject]@{
        Filename = 'tnsnames.ora'
        Filepath = 'D:\app\Oracle\product\12.2.0\client_1\Network\Admin'
    }   
}

$BTMonitoringItem2 = [PSCustomObject]@{
    Check      = 'Program version'
    CheckParam = [PSCustomObject]@{
        Programname = 'Microsoft BizTalk Server 2015 Feature Update 3'
        Programversion = '3.13.335.2'
    }   
}

$BTMonitoringItem3 = [PSCustomObject]@{
    Check      = 'EnvironmentVariable'
    CheckParam = [PSCustomObject]@{
        Variablename = 'TNS_ADMIN'
        VariableValue = 'D:\app\Oracle\product\12.2.0\client_1\Network\Admin'
    } 
}

Function GetBTServerMonitoringItems
{
    $BTMonitoringItems = "" 
    $BTMonitoringItems = @()
    $BTMonitoringItems += $BTMonitoringItem1
    $BTMonitoringItems += $BTMonitoringItem2
    $BTMonitoringItems += $BTMonitoringItem3

    #Write-Debug $($("Monitoring Items : " + $($BTMonitoringItems | format-Table -AutoSize | out-string)).Trim())
    
    return $BTMonitoringItems
}


#----------------------------
# Generic Dev Server
#----------------------------

# Variable Monitor-Objecten voor Generic Dev Server en methodes om deze op te halen


$GenDevMonitoringItem1 = [PSCustomObject]@{
    Check      = 'Check windows service existence'
    CheckParam = [PSCustomObject]@{
        ServiceName = 'OracleRemExecServiceV2'
        ServiceStatus = 'Running'
    }   
}

Function GetGenDevServerMonitoringItems
{
    $MonitoringItems = "" 
    $MonitoringItems = @()
    $MonitoringItems += $GenDevMonitoringItem1
    #Write-Debug $($("Monitoring Items : " + $($MonitoringItems | format-Table -AutoSize | out-string)).Trim())
    return $MonitoringItems
}



#----------------------------
# Shared methods
#----------------------------

#gets Template PSCustomObject
# Function GetTemplate($templateName, $MonitoringItems)
# {
#         return [PSCustomObject]@{
#         TemplateName = $templateName
#         MonitoringItems = $MonitoringItems
#         }
# }
# 
# Function GetTemplates()
# {
# $Template1 = GetGenDevServerTemplate
# $Template2 = GetBTServerTemplate
# $Templates = "" 
# $Templates = @()
# $Templates += $Template1
# $Templates += $Template2
# return $Templates
# }

