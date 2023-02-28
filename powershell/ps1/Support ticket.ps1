# Check if Outlook process is running
$OutlookProcess = Get-Process | Where-Object { $_.Name -eq "OUTLOOK" }

# Get the Outlook application object
if ($OutlookProcess) {
  $Outlook = [Runtime.Interopservices.Marshal]::GetActiveObject("Outlook.Application")
} else {
  $Outlook = New-Object -ComObject Outlook.Application
}

# Create a new email message
$Mail = $Outlook.CreateItem(0)

# Set the recipient of the email
$Mail.To = "support@cloud-it.biz"

# Set the subject of the email
$Mail.Subject = "Support Ticket"

# Set the body of the email
$Mail.BodyFormat = [Microsoft.Office.Interop.Outlook.OlBodyFormat]::olFormatHTML
$Mail.HTMLBody = "<p><font color='green'>***Hello, Could you please type here your contact information ?***</font></p>
    <ul>
        <li><font color='green'>Your name:</font> </li>
        <li><font color='green'>Your company:</font> </li>
        <li><font color='green'>Your phone number:</font> </li>
    </ul>
<hr>
<p><font color='green'>***Could please describe your issue below ?***</font></p> <br>"

# Display the email message
$Mail.Display()

stop-process -Id $PID