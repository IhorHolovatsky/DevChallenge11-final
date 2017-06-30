# Import-Module .\NServiceBus.PowerShell.dll

# Install-NServiceBusPerformanceCounters -Confirm:$false

# These variables should be set via the Octopus web portal:
#
$OrderProcessorServiceAccountName = 'LORDEROT\Ihor'
$OrderProcessorServiceAccountPassword = '04291997FE'

$ErrorActionPreference = "Stop"

try
{


$acl = Get-Acl C:\WindowsService

$Right = [System.Security.AccessControl.FileSystemRights]"FullControl"
$InheritanceFlag = ([System.Security.AccessControl.InheritanceFlags]::ContainerInherit, [System.Security.AccessControl.InheritanceFlags]::ObjectInherit)
$PropagationFlag = [System.Security.AccessControl.PropagationFlags]::InheritOnly  
$objType =[System.Security.AccessControl.AccessControlType]::Allow
$objUser = New-Object System.Security.Principal.NTAccount($OrderProcessorServiceAccountName) 

$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($objUser, $Right, $InheritanceFlag, $PropagationFlag, $objType) 

$acl.SetAccessRule($accessRule)
$acl | Set-Acl C:\WindowsService


$servicename = "TestService3"
$configfile = "NServiceBus.Test.dll.config"
$numOfInstances = 1
$serviceDisplayName = "Test Service 3"

# Uninstall all instances of the service
$services = get-service | ? {$_.Name -like "$servicename*"}
Write-Host "Installed services:"
$services | format-table

foreach($service in $services)
{
	Write-Host "Uninstalling service $($service.Name)..."
	stop-service $service.name -Force -Passthru

	$parsedName = $service.name.split("$") 
	if($parsedName.length -eq 1)
	{
		start-process "Nservicebus.Host.exe" "/uninstall /servicename:`"$servicename`" " -PassThru -Wait | Write-Host
	}
	else
	{
		$instanceName =  $parsedName[1]  
		start-process "Nservicebus.Host.exe" "/uninstall /servicename:`"$($service.Name)`" /instancename:`"$instanceName`"" -PassThru -Wait | Write-Host
	}
}

<#
# update appdynamics configuration
#$configfile = "C:\ProgramData\AppDynamics\DotNetAgent\Config\config.xml"

# update the config file
$config = [xml](get-content $configfile)

# ensure the windows-services element 
$windowsServices = $config.'appdynamics-agent'.'app-agents'.'windows-services'
if(!$windowsServices)
{
	$windowsServices = $config.CreateElement('windows-services')
	$config.'appdynamics-agent'.'app-agents'.AppendChild($windowsServices)
}

# remove all the windows service nodes
$config.'appdynamics-agent'.'app-agents'.'windows-services'.'windows-service' | ? {$_.name -like "$servicename*"} | % {$windowsServices.RemoveChild($_)}

# add service nodes
for($i=1; $i -le $numOfInstances; $i++)
{
	$instanceName = "instance" + $i
	$windowsServiceName = $servicename + "`$" + $instanceName
	
	$windowsService = $config.CreateElement('windows-service')
	$windowsServices.AppendChild($windowsService)
	$windowsService.SetAttribute('name', $windowsServiceName)

	$tier = $config.CreateElement('tier')
	$windowsService.AppendChild($tier)
	$tier.SetAttribute('name', 'Service Tier')
}

# save the config file
$config.Save((Resolve-Path $configfile))

# restart appdynamics
Restart-service AppDynamics.Agent.Coordinator_service -force 
#>

# install all instances of the service
for($i=1; $i -le $numOfInstances; $i++)
{
	$instanceName = "instance" + $i
	Write-Host "Installing service $servicename instance $instanceName..."
	start-process "Nservicebus.Host.exe" "/install /servicename:`"$servicename`" /instance:`"$instanceName`" /displayname:`"$serviceDisplayName`" /username:`"$OrderProcessorServiceAccountName`" /password:`"$OrderProcessorServiceAccountPassword`"" -PassThru -Wait | Write-Host
		
	#set-service ($servicename + "`$" + $instanceName) -startupType Disabled
	start-service ($servicename + "`$" + $instanceName) 
	$trueName = ($servicename + "`$" + $instanceName) 
	sc.exe failure $trueName reset= 86400 actions= restart/60000/restart/60000/restart/60000
}

Write-Host "Deployment successful."
exit 0
} catch {
write-host "Caught an exception:" -ForegroundColor Red
write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
exit 1
}