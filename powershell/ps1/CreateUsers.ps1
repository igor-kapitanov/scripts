function CreateUsers
{
    Write-Host "***** Create admin users *****" -ForegroundColor Green
	#Create firsr admin user
	$user1 = "name"
	$fname1 = "name"
    $password1 = ConvertTo-SecureString "password" -AsPlainText -Force
    New-LocalUser $user1 -Password $password1 -FullName $fname1 -Description "first admin user"
    Set-LocalUser $user1 -AccountNeverExpires -PasswordNeverExpires $true -UserMayChangePassword $false
    Add-LocalGroupMember -Group "Administrators" -Member $user1 -ErrorAction stop
	
    #Create second admin user
	$user2 = "name"
	$fname2 = "name"
    $password2 = ConvertTo-SecureString "password" -AsPlainText -Force
    New-LocalUser $user2 -Password $password2 -FullName $fname2 -Description "second admin user"
    Set-LocalUser $user2 -AccountNeverExpires -PasswordNeverExpires $true -UserMayChangePassword $false
    Add-LocalGroupMember -Group "Administrators" -Member $user2 -ErrorAction stop
}
