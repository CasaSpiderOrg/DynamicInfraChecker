########################################################################
# Mail
########################################################################

$_EmailHeader = @"
<Title>BizTalk Server Installation Check Report</Title>
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
<H1>BizTalk Server Installation Check Report</H1>
"@

$_SMTPClient = "mail"
$_Receivers = "remy.de.pundert@brabantwater.nl"
$_Sender = "remy.de.pundert@brabantwater.nl"
$_emailRecipient = "nijhp1"
$_emailSmtpServer = "mail"
$_subjectText = "BizTalk Server Installation Check Report"

Function GetHeader()
{
return $_EmailHeader
}

Function SendMail($body)
{
    $SMTPClient = New-Object System.Net.Mail.SmtpClient($_SMTPClient)

        $emailMessage = New-Object System.Net.Mail.MailMessage
        $emailMessage.From = $_Receivers
        $emailMessage.To.Add($_Receivers) 
        $emailMessage.Subject = $_subjectText
        $emailMessage.IsBodyHtml = $true
        $emailMessage.Body = $body 

        Write-Host $emailMessage

    $SMTPClient.Send($emailMessage)
}