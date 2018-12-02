configuration ConfigureSQLNode 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName ComputerManagementDsc, PSDesiredStateConfiguration, xPendingReboot
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("$($DomainName)\$($AdminCreds.UserName)", $AdminCreds.Password)
    $Interface=Get-NetAdapter| Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)

    Node localhost
    {
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }

	    Computer JoinDomain
        { 
            Name = $ENV:COMPUTERNAME
            DomainName = $DomainName
            Credential = $DomainCreds # Credential to join to domain
        }

        Group AddADUserToLocalAdminGroup {
            GroupName='Administrators'
            Ensure= 'Present'
            MembersToInclude= "$DomainName\SQLTeam"
            Credential = $DomainCreds
            PsDscRunAsCredential = $DomainCreds
            DependsOn = "[Computer]JoinDomain"
        }

   }
} 