<#
.DESCRIPTION
   This script will perform Storage vMotion for virtual machines hosted in a particular VMware farm
   based on the input file specified in "moveInput.csv"
   Format of the input file is :    Farm Name,SourceDatastore,TargetDatastore
   Script will go through each VMs in the specified source datastore and will move all of its datastore
   to a new one based on the datastore free space.
   This is useful when cleaning old datastore, performing a LUN migration / decomission and reclaiming storage.
   Pre-requisite : 
   1. PowerCLI need to be installed
   2. Establish connection manually in PowerCLI using Connect-VIServer
.AUTHOR
    Mohd Zain Hassan (mohd-zain.hassan@dxc.com)
#>



$inputFile = Import-Csv c:\script\moveInput.csv -Header Farm,SourceDstore,DestDstore
$LogFile = "MoveVM_" + (Get-Date -UFormat "%d-%b-%Y-%H-%M") + "_log.csv" 
$resultArray =@()

foreach ($item in $inputFile)
{
write-host 'Connecting to Farm : ' $item.Farm
write-host 'Working on DataStore : ' $item.SourceDstore
    
    $myDataStore = Get-DataStore -Name $item.SourceDstore
    $vms = VMware.VimAutomation.Core\get-vm -Datastore $myDataStore
     

    foreach ($vm in $vms) { 
        write-host 'Working on VM : ' $vm
        $tempObj = new-object PSObject
        $tempObj | add-member -MemberType NoteProperty -Name "Farm" -Value $item.Farm
        $tempObj | add-member -MemberType NoteProperty -Name "OldDstore" -Value $item.SourceDstore
        $currTime = get-date -Format g  
        $tempObj | add-member -MemberType NoteProperty -Name "Timestamp" -Value $currTime
        $tempObj | Add-Member -MemberType NoteProperty -Name "VM" -Value $vm.Name
        $selectedDS = Get-Datastore | Where-Object {$_.Name -eq $item.DestDstore}
       
        # List vmdk files for the selected VM
        $vm | Get-HardDisk
        Write-Host 'Moving ' $vm ' from ' $item.SourceDstore ' to ' $selectedDS

        while ((Get-Task | Where-Object {$_.Name -eq "RelocateVM_Task"} | Where-Object {$_.State -eq "Running"}).count -ge 10) {sleep 30}
            $task = VMware.VimAutomation.Core\Move-VM -VM $vm -Datastore $selectedDS -RunAsync
        
        $tempObj | Add-Member -MemberType NoteProperty -Name "NewDstore" -Value $selectedDS
        $tempObj | Add-Member -MemberType NoteProperty -Name "VMotionTask" -Value $task.id
        $tempObj | Add-Member -MemberType NoteProperty -Name "VMotionState" -Value $task.State

    $resultArray += $tempObj   
    }
    
}
 Write-Host 'Completed all vMotion' 

$resultArray | Export-csv $LogFile -NoTypeInformation -Append -Force