##
# Parašyti skriptą, kuris parodytų ESXi serveryje veikiančias VM ir jų konfigūraciją, 
# jas išjungtų, padarytų kopijas (klonuotų į kitą saugyklą) ir paleistų klonuotas VM. 
# Analizuojant ESXi log failus parodyti, kad buvo užfiksuoti VM‘ų išjungimas ir paleidimas.
##

Import-module VMware.VimAutomation.Core
Import-module VMware.VimAutomation.Vds
Import-module VMware.VimAutomation.Cloud
Import-module VMware.VimAutomation.PCloud
Import-module VMware.VimAutomation.Cis.Core
Import-module VMware.VimAutomation.Storage
Import-module VMware.VimAutomation.HorizonView
Import-module VMware.VimAutomation.HA
Import-module VMware.VimAutomation.vROps
Import-module VMware.VumAutomation
Import-module VMware.DeployAutomation
Import-module VMware.ImageBuilder
Import-module VMware.VimAutomation.License

$ESXIhost = "10.10.42.124"
Connect-VIServer -Server $ESXIhost -User root -Password <password>

Write-EventLog -LogName "Application" -Source "VMWareScript" -EventID 12001 -EntryType Information -Message "VM_Status_checks.ps1 script started."
$ds = Get-Datastore datastore1  
New-PSDrive -Name MyDS -PSProvider ViMdatastore -Root '\' -location $ds  
$VMs = Get-VM  #| Where {$_.PowerState -eq "PoweredOff"} 
foreach ($VM in $VMs) {
	# Print VM Information
	$VM.Summary.Config
	# Shutdown VM
	Stop-VM -VM $VM -Kill -Confirm:$false
    $objState = Get-VM $VM.Name | Select-Object PowerState
    Write-EventLog -LogName "Application" -Source "VMWareScript" -EventID 12002 -EntryType Information -Message "$VM status is PoweredOff."
    
    # Copy VM
    
    ##Copy-DatastoreItem C:\Temp\test.txt -Destination MyDS:\Folder2\  
    Copy-DatastoreItem MyDS:\$VM\* -Destination C:\StorageVZM\$VM\ -Force:$true -Confirm:$false
	
	
	#$ConfigSettings = @{
#		"ipaddress" = "10.134.14.75";
#		"netmask" = "255.255.255.0";
#		"gateway" = "10.134.14.253";
#		"dns" = "10.134.14.9";
#	}
#	$childForkVm = New-InstantCloneVM -ParentVM $$VM -Name $VMclone -ConfigParams $ConfigSettings

	$respool=Get-VMhost -Name "ESXi host name"
	$datastore=Get-datastore -Name 'datastore name'
	New-VM -Name $VM+"_Clone" -VM $VM -ResourcePool $respool -Datastore $datastore -DiskStorageFormat Thin  ## http://vmwaremine.com/2013/05/28/powercli-clone-vm/#sthash.1tEOzpYK.iCrcnoU3.dpbs
	# Start Cloned VM
	$VM+"_Clone" | Start-VM
	# Start original VM
	#If ($objState -match "ff") {Get-VM $VM.Name | Start-VM}
    Write-EventLog -LogName "Application" -Source "VMWareScript" -EventID 12003 -EntryType Information -Message "$VM was started."
}
Write-EventLog -LogName "Application" -Source "VMWareScript" -EventID 12004 -EntryType Information -Message "VM_Status_checks.ps1 script finished it work."
