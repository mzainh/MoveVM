# MoveVM
This script will perform Storage vMotion for virtual machines hosted in a particular VMware farm  based on the input file specified in "moveInput.csv"
Format of the input file is :    Farm Name,SourceDatastore,TargetDatastore
Script will go through each VMs in the specified source datastore and will move all of its datastore
to a new one based on the datastore free space.

This is useful when cleaning old datastore, performing a LUN migration / decomission and reclaiming storage.
   Pre-requisite : 
   1. PowerCLI need to be installed
   2. Establish connection manually in PowerCLI using Connect-VIServer
