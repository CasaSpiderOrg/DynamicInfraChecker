
######################
# How to Add New Checks
######################

To Add Monitor Items and logic follow these steps:

1. Define what needs to be checked
2. Add a New Object inside MonitorItems.ps1 with following signature and add the item to the corresponding get-method:

$MonitoringItemName = [PSCustomObject]@{Check= 'EXAMPLECHECK' CheckParam = [PSCustomObject]@{
Checkvalue1= 'tnsnames.ora' CheckValue2 = 'D:\app\Oracle\product\12.2.0\client_1\Network\Admin'
    }   
}

If logic for 'EXAMPLECHECK' doesn't exists within the processing switch inside CheckServer.ps1, it needs to be added with corresponding switch-value 'EXAMPLECHECK' and the processing logic. 
If logic for 'EXAMPLECHECK' already exists within CheckServer.ps1 and there is allready written down any logic to get the result. The new item will be processed likewise.
e.g. All MonitoringItems within MonitoringItems.ps1 that read the same Check variable (here 'EXAMPLECHECK'), will run the same logic within the script.

switch($Check)
		'EXAMPLECHECK' {
			logic to calculate result based on MonitorItem CheckParams  (here CheckValue1 and CheckValue2)
		}
		'EXAMPLECHECK2' {
			logic to calculate result based on MonitorItem CheckParams
		}