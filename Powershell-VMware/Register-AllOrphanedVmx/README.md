##Description :



This module contains 1 cmdlet : **Register-AllOrphanedVmx**.  
It requires PowerShell version 3
 (or later) and PowerCLI 5.5 (or later).



##Register-AllOrphanedVmx :



###Parameters :



**VIServer :** To specify the vCenter Server to connect PowerCLI to.
The default is Localhost.  
If not specified, it defaults to localhost .



**ResourcePool :** To specify in which cluster or resource pool the VMs should be registered into.  



###Examples :



-------------------------- EXAMPLE 1 --------------------------

PS C:\>Register-AllOrphanedVmx -ResourcePool ( Get-Cluster DevCluster )











