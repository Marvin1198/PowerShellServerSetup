Clear-Host 

Write-Host "---------------------------------------------------------------------------------"
Write-Host "-------------------------Server Setup Script Start Here-------------------------"

Function CommandStatus ($Status) { 
    if ($Status -eq $true) {
        Write-Host "Success!" -ForegroundColor Green 
    } 
    else {
        Write-Host "Failed" -ForegroundColor Red 
    } 
}

Set-ExecutionPolicy  -ExecutionPolicy Unrestricted -Force -Confirm:$false | Out-Null 

$MachineName = (Read-Host -Prompt "Enter the name of the machine" | Out-String).Trim() 
Write-Host "Previous Computer Name is "$env:computername
Rename-Computer -NewName $MachineName 
CommandStatus($?) 
Write-Host "After Execution of Command Computer Name is "$env:computername
  
Write-Host "---------------------------------------------------------------------"
Write-Host "Now Installing the Drivers into the VM"
#Searching Network Drivers (Replace below path with your Driver's path)
Get-ChildItem 'C:\Share\A2-115 - Dell Optiplex 7000\7000' -Recurse –filter “*.inf” | 
ForEach-Object{ 

 Pnputil.exe /add-driver $_.FullName /install 

} 
Write-Host "---------------------------------------------------------------------"
Write-Host "----------------Setting up the IP Address of the VM------------------"
Write-Host "---------------------------------------------------------------------"
Write-Host "Select the index number of the adapter you want to apply an IP address" 
Get-NetAdapter | Select ifIndex,interfacedescription,macaddress,Status,linkspeed | Format-Table 


Write-Host "If you do not want to assign a static IP, leave it blank" 
$adapterIndex = (Read-Host -Prompt "Adapter index") 
Do { 

    if ($adapterIndex.length -ge 1) { 

    $IPAddress = (Read-Host -Prompt "Enter a static IP address? ") 

    $PrefixLength = (Read-Host -Prompt "Enter the prefix length (CIDR)? ") 

    $DefaultGateway = (Read-Host -Prompt "Enter the default gateway address? ") 

    $DNSAddress = (Read-Host -Prompt "Enter the DNS address? ") 

    } 

    if ($adapterIndex.Length -ge 1) { 

    Write-Host "Setup IP information..." 

    New-NetIPAddress -InterfaceIndex $adapterIndex -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $DefaultGateway | Out-Null 

    CommandStatus($?) 

    Write-Host "Set DNS Address" 

    Set-DnsClientServerAddress -InterfaceIndex $adapterIndex -ServerAddresses $DNSAddress 

    CommandStatus($?) 

    }else { 

    Write-Host "Set IP address to DHCP" 

    $IPType = "IPV4" 

    $adapter = Get-NetAdapter | ? {$_.status -eq "up"} 

    $interface = $adapter | Get-netipinterface -AddressFamily $IPType 

    $interface | Set-NetIPInterface -Dhcp Enabled 

    $interface | Set-DnsClientServerAddress -ResetServerAddresses 

    $adapterIndex = $adapter.ifIndex 

    CommandStatus($?) 

    } 

    Write-Host "Checking for Internet Connection against Google.ca" 

    Start-Sleep -Seconds 5 

    Test-Connection google.ca -ErrorAction SilentlyContinue | Out-Null 

    CommandStatus($?) 

    $internetworks = $? 

    if($internetworks -eq $false) { 

    Write-Host "There is something wrong with the IP address you set. Let's try again..." -ForegroundColor Yellow 

    } 
    else
    {
    Write-Host "Test Connection with the IP address you set is working. Congrats!!!!"
    }

} Until ($internetworks -eq $true) 

Write-Host "---------------------------------------------------------------------"
Write-Host "--------------Setting up the Set Timezone of the VM------------------" -ForegroundColor Yellow 
Write-Host "---------------------------------------------------------------------"
  
$date = Get-Date -Format r
Write-Host "Before the Update Date Time and TimeZone is $date" -ForegroundColor Yellow 
Set-TimeZone -Name "Eastern Standard Time" 
CommandStatus($?) 
w32tm /resync 
$date = Get-Date -Format r
Write-Host "After the Update Date Time and TimeZone is $date" -ForegroundColor Yellow 


  
Write-Host "---------------------------------------------------------------------"
Write-Host "--------------Turn IE ESC off for Admins of the VM------------------" -ForegroundColor Yellow 
Write-Host "---------------------------------------------------------------------"
#Write-Host "Turn IE ESC off for Admins" -ForegroundColor Yellow 

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0 

CommandStatus($?) 
Write-Host "---------------------------------------------------------------------"

  
Write-Host "---------------------------------------------------------------------"
Write-Host "--------------Enable Remote Desktop of the VM------------------" -ForegroundColor Yellow 
Write-Host "---------------------------------------------------------------------"
#Write-Host "Enable Remote Desktop" -ForegroundColor Yellow 

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 
CommandStatus($?) 
Write-Host "---------------------------------------------------------------------"
  


#Write-Host "Set firewall to private" 
Write-Host "---------------------------------------------------------------------"
Write-Host "--------------Set firewall to private--------------------------------" -ForegroundColor Yellow 
Write-Host "---------------------------------------------------------------------"
Set-NetConnectionProfile -InterfaceIndex $adapterIndex -NetworkCategory Private 
CommandStatus($?) 

  
Write-Host "-----------------------------------------------------------------------"
Write-Host "--------------Create a New User Account--------------------------------" -ForegroundColor Yellow 
Write-Host "-----------------------------------------------------------------------"
$NewUserName = (Read-Host -Prompt "Enter a new username for another administrator account") 

$Password = (Read-Host -Prompt "Enter a password") 

$FullUsername = (Read-Host -Prompt "Enter a full name of the user") 

New-LocalUser $NewUserName -Password (ConvertTo-SecureString $Password -AsPlainText -Force) -FullName $FullUsername 

Add-LocalGroupMember -Group "Administrators" -Member $NewUserName 

Write-Host "---------------------------------------------------------------------------------"
Write-Host "-------------------------Server Setup Script Ends Here-------------------------"
Write-Host "---------------------------------------------------------------------------------"
