Set-ExecutionPolicy Bypass -Scope Process -Force
$templateContent = @"
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <style>
      body {
        font-family: Arial, sans-serif;
      }

      hr {
        border: none;
        border-top: 2px solid black;
        margin: 0;
        width: 100%;
      }

      .contact-info li {
        list-style: none;
        margin-bottom: 5px;
      }
      .tab {
        display: inline-block;
        margin-left: 40px;
      }
    </style>
  </head>
  <body>
    <p>
      <strong
        >Hello, could you please provide your contact information below:</strong
      >
    </p>
    <ul class="contact-info">
      <li>
        <u>Your name:<span class="tab"></span></u>
      </li>
      <li>
        <u>Your company:<span class="tab"></span></u>
      </li>
      <li>
        <u>Your phone number:<span class="tab"></span></u>
      </li>
    </ul>
    <hr />
    <p><strong>Please describe your issue below:</strong></p>
    <br />
  </body>
</html>
"@

$templatePath = "C:\Users\Public\Desktop\VIPros Support.oft"
$recipientEmail = "support@vipros.net"

# Create a new Outlook application object
$outlook = New-Object -ComObject Outlook.Application

# Create a new mail item
$mailItem = $outlook.CreateItem(0)

# Set the recipient
$mailItem.To = $recipientEmail

# Set the subject
$mailItem.Subject = "Support Ticket"

# Set the HTML body using the template content
$mailItem.HTMLBody = $templateContent

# Save the template as an OFT file
$mailItem.SaveAs($templatePath, 3)

# Clean up the Outlook application object
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($mailItem) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($outlook) | Out-Null
Remove-Variable outlook, mailItem
