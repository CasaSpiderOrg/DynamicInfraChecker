####################################################################################
# ComputerGroups
# Script to return Templates to processing script
#
####################################################################################

$MyDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
. "$MyDir\MonitorItems.ps1"

Function GetBTServerTemplate()
{       
        $BTTempMonitoringItems = GetBTServerMonitoringItems
        return GetTemplate "BizTalkServer" $BTTempMonitoringItems
}

Function GetGenDevServerTemplate()
{
        $GenDevTempMonitoringItems = GetGenDevServerMonitoringItems
        return GetTemplate "GenericDevelopmentServer" $GenDevTempMonitoringItems
}


#----------------------------
# Shared methods
#----------------------------

#gets Template PSCustomObject
Function GetTemplate($templateName, $MonitoringItems)
{
        return [PSCustomObject]@{
        TemplateName = $templateName
        MonitoringItems = $MonitoringItems
        }
}
