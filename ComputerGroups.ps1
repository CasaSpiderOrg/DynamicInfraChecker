####################################################################################
# ComputerGroups
# Script to return ComputerGroups items to processing script
#
####################################################################################

$MyDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
. "$MyDir\Templates.ps1"


$BTComputerGroup1 = [PSCustomObject]@{
    GroupName   = 'BizTalkServers'
    ComputerList = @('win236o1','win236o2','win236t')   
}

$GenDevComputerGroup2 = [PSCustomObject]@{
    GroupName   = 'GenericDevelopmentServers'
    ComputerList = @('win155o')   
}

Function GetGenDevComputerGroup()
{
  #get GenDev template from Templates.ps1
  $BTTemplate = GetGenDevServerTemplate
  return GetComputerGroup $GenDevComputerGroup2 $BTTemplate
}

Function GetBTComputerGroup()
{
  #get BT template from Templates.ps1
  $GenDevTemplate = GetBTServerTemplate
  return GetComputerGroup $BTComputerGroup1 $GenDevTemplate
}

Function GetComputerGroup($Group, $Template)
{
    Return [PSCustomObject]@{
    ComputerGroup = $($Group)
    Template = $($Template)
    }
}

Function GetComputerGroupAssignedTemplates()
{
    $ComputerGroupAssignedTemplates = ""
    $ComputerGroupAssignedTemplates = @()
    $ComputerGroupAssignedTemplates+= GetBTComputerGroup
    $ComputerGroupAssignedTemplates+= GetGenDevComputerGroup
    return $ComputerGroupAssignedTemplates
}