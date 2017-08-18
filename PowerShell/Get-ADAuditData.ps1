function New-ZipFile {
    # http://stackoverflow.com/questions/1153126/how-to-create-a-zip-archive-with-powershell#13302548
    param (
        [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$true)]
        $Path,
        [Parameter(Mandatory=$True, Position=1, ValueFromPipeline=$true)]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        $Source
    )
    Add-Type -Assembly System.IO.Compression.FileSystem
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    [System.IO.Compression.ZipFile]::CreateFromDirectory($sourcedir,$zipfilename, $compressionLevel, $false)
}

function ConvertFrom-UAC {
    param (
        [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$true)]
        $Value
    )
    $uacOptions = @{
        512     = 'Enabled'
        514     = 'Disabled'
        528     = 'Enabled - Locked Out'
        530     = 'Disabled - Locked Out'
        544     = 'Enabled - Password Not Required'
        546     = 'Disabled - Password Not Required'
        560     = 'Enabled - Password Not Required - Locked Out'
        640     = 'Enabled - Encrypted Text Password Allowed'
        2048    = 'Enabled - Interdomain Trust Account'
        2050    = 'Disabled - Interdomain Trust Account'
        2080    = 'Enabled - Interdomain Trust Account - Password Not Required'
        2082    = 'Disabled - Interdomain Trust Account - Password Not Required'
        4096    = 'Enabled - Workstation Trust Account'
        4098    = 'Disabled - Workstation Trust Account'
        4128    = 'Enabled - Workstation Trust Account - Password Not Required'
        4130    = 'Disabled - Workstation Trust Account - Password Not Required'
        8192    = 'Enabled - Server Trust Account'
        8194    = 'Disabled - Server Trust Account'
        66048   = 'Enabled - Password Does Not Expire'
        66050   = 'Disabled - Password Does Not Expire'
        66056   = 'Enabled - Password Does Not Expire - HomeDir Required'
        66064   = 'Enabled - Password Does Not Expire - Locked Out'
        66066   = 'Disabled - Password Does Not Expire - Locked Out'
        66080   = 'Enabled - Password Does Not Expire - Password Not Required'
        66082   = 'Disabled - Password Does Not Expire - Password Not Required'
        66176   = 'Enabled - Password Does Not Expire - Encrypted Text Password Allowed'
        69632   = 'Enabled - Workstation Trust Account - Dont Expire Password'
        131584  = 'Enabled - Majority Node Set (MNS) Account'
        131586  = 'Disabled - Majority Node Set (MNS) Account'
        131600  = 'Enabled - Majority Node Set (MNS) Account - Locked Out'
        197120   = 'Enabled - Majority Note Set (MNS) Account - Password Does Not Expire'
        262656   = 'Enabled - Smartcard Required'
        262658   = 'Disabled - Smartcard Required'
        262690   = 'Disabled - Smartcard Required - Password Not Required'
        328194   = 'Disabled - Smartcard Required - Password Not Required - Password Does Not Expire'
        524800   = 'Enabled - Trusted For Delegation'
        528384   = 'Enabled - Workstation Trust Account - Trusted for Delegation'
        528386   = 'Disabled - Workstation Trust Account - Trusted for Delegation'
        528416   = 'Enabled - Workstation Trust Account - Trusted for Delegation - Password Not Required'
        528418   = 'Disabled - Workstation Trust Account - Trusted for Delegation - Password Not Required'
        532480   = 'Server Trust Account - Trusted For Delegation (Domain Controller)'
        532482   = 'Disabled - Server Trust Account - Trusted For Delegation (Domain Controller)'
        590336   = 'Enabled - Password Does Not Expire - Trusted For Delegation'
        590338   = 'Disabled - Password Does Not Expire - Trusted For Delegation'
        1049088  = 'Enabled - Not Delegated'
        1049090  = 'Disabled - Not Delegated'
        1114624  = 'Enabled - Password Does Not Expire - Not Delegated'
        1114656  = 'Enabled - Password Not Required - Password Does Not Expire - Not Delegated'
        2097664  = 'Enabled - Use DES Key Only'
        2163200  = 'Enabled - Password Does Not Expire - Use DES Key Only'
        2687488  = 'Enabled - Password Does Not Expire - Trusted For Delegation - Use DES Key Only'
        3211776  = 'Enabled - Password Does Not Expire - Not Delegated - Use DES Key Only'
        4194816  = 'Enabled - PreAuthorization Not Required'
        4260352  = 'Enabled - Password Does Not Expire - PreAuthorization Not Required'
        4260354  = 'Disabled - Password Does Not Expire - PreAuthorization Not Required'
        16781312 = 'Enabled - Workstation Trust Account - Trusted to Authenticate For Delegation'
        16843264 = 'Enabled - Password Does Not Expire - Trusted to Authenticate For Delegation'
        83890176 = 'Enabled - Server Trust Account - Trusted For Delegation - (Read-Only Domain Controller (RODC))'
    }

    if ($uacOptions.ContainsKey($Value)) {
        $newValue = $uacOptions[$Value]
    }
    else {
        $newValue = 'Unknown User Account Type'
    }
    return $newValue
}

function ConvertFrom-UACComputed {
    param(
        [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$true)]
        $Value
    )
    $uacComputed = @{
        0          = 'Refer to userAccountControl Field'
        16         = 'Locked Out'
        8388608    = 'Password Expired'
        8388624    = 'Locked Out - Password Expired'
        67108864   = 'Partial Secrets Account'
        2147483648 = 'Use AES Keys'
    }

    if ($uacComputed.ContainsKey($Value)) {
        $newValue = $uacComputed[$Value]
    }
    else {
        $newValue = 'Unknown User Account Type'
    }
    return $newValue
}


function Get-ADAuditData {
    <#
    .SYNOPSIS
    Queries current AD Domain for data useful for IT Audit Purposes.

    .DESCRIPTION
    This function will extract key information from Active Directory that can be used to analyze The
    management of an AD Domain. It queries information regarding Users, Groups, OUs, Computers,
    Group Policy Objects, Group Policy Inheritance, Fine Grained Password Policies, Confidential Attributes,
    and Trusted Domains.

    This does not constitute all of the information that can be reviewed for Active Directory and does not
    help determine the actual health of an AD Domain. It is intended for an IT Audit to establish how
    well an IT Department is managing specific object types and policies.

    .PARAMETER Path
    Specifies the path to output the resultant data. Default is the current working directory.

    .EXAMPLE
    PS> Get-ADAuditData -Verbose

    This example will export AD information to a directory in the current working directory. Verbose output
    enabled to visually monitor the script's progress.

    .EXAMPLE
    PS> Get-ADAuditData -Path 'C:\Users\username\Desktop' -Verbose

    This example will export AD information to the desktop of the user 'username'. Verbose output enabled
    to visually monitor the script's progress.

    .NOTES
    Author: Alex Entringer
    Date: 04/01/2017

    The Version 4.0 requirement can be dropped to Version 3.0 if the New-ZipFile function is removed.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$true)]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        $Path = $(Get-Location)
    )
    #Requires -Version 4.0
    #Requires -Modules ActiveDirectory
    Import-Module -Name ActiveDirectory

    $domain = (Get-ADDomain -Current LocalComputer).DistinguishedName

    Write-Verbose -Message 'Creating Output Directory'
    if (Test-Path -Path "$Path\$domain") {
        Remove-Item "$Path\$domain" -Recurse -Force
    }
    New-Item -Path "$Path\$domain" -ItemType Directory | Out-Null
    Write-Verbose -Message 'Output Directory Created'

    Write-Verbose -Message "Starting Execution at $(Get-Date -Format G)"
    Write-Output "Starting Execution at $(Get-Date -Format G)`n`n" | Out-File "$Path\$domain\consoleOutput.txt"

    Write-Verbose -Message 'Exporting Active Directory Users'
    Get-ADUser -Filter * -Properties 'accountExpirationDate','adminCount','assistant','canonicalName','cn','comment','company','controlAccessRights','department',
        'departmentNumber','description','displayName','distinguishedName','division','employeeID','employeeNumber','employeeType','generationQualifier','givenName',
        'info','lastLogonTimestamp','lockoutTime','mail','managedObjects','manager','memberOf','middleName','msDS-AllowedToDelegateTo','msDS-PSOApplied',
        'msDS-ResultantPSO','msDS-SourceObjectDN','msDS-User-Account-Control-Computed','msDS-UserPasswordExpiryTimeComputed','name','o','objectSid','ou',
        'PasswordLastSet','PasswordExpired','personalTitle','primaryGroupID','sAMAccountName','secretary','seeAlso','servicePrincipalName','sIDHistory',
        'sn','title','uid','uidNumber','userAccountControl','userWorkstations','whenChanged','whenCreated' |
        Select-Object 'accountExpirationDate','adminCount','assistant','canonicalName','cn','comment','company',
            @{Name='controlAccessRights';Expression={$_.controlAccessRights -join ';'}},'department',@{Name='departmentNumber';Expression={$_.departmentNumber -join ';'}},
            'description','displayName','distinguishedName','division','employeeID','employeeNumber','employeeType','generationQualifier','givenName','info','lockoutTime','mail',
            @{Name='managedObjects';Expression={$_.managedObjects -join ';'}},'manager',
            @{Name='memberOf';Expression={(($_.memberof -split (",") | Select-String -AllMatches "CN=") -join ", ") -replace "CN=" -replace "" }},
            'middleName',@{Name='msDS-AllowedToDelegateTo';Expression={$_.'msDS-AllowedToDelegateTo' -join ';'}},
            @{Name='msDS-PSOApplied';Expression={$_.'msDS-PSOApplied' -join ';'}},
            'msDS-ResultantPSO','msDS-SourceObjectDN',
            @{Name='msDS-User-Account-Control-Computed';Expression={(ConvertFrom-UACComputed($_.'msDS-User-Account-Control-Computed'))}},
            @{Name='msDS-UserPasswordExpiryTimeComputed';Expression={([datetime]::FromFileTime($_.'msDS-UserPasswordExpiryTimeComputed')).ToString("M/d/yyyy h:mm:ss tt")}},
            @{Name='lastLogonTimestamp';Expression={([datetime]::FromFileTime($_.lastLogonTimestamp)).ToString("M/d/yyyy h:mm:ss tt")}},
            'name',@{Name='o';Expression={$_.o -join ';'}},'objectSid',@{Name='ou';Expression={$_.ou -join ';'}},'PasswordLastSet','PasswordExpired','personalTitle',
            'primaryGroupID','sAMAccountName',@{Name='secretary';Expression={$_.secretary -join ';'}},@{Name='seeAlso';Expression={$_.seeAlso -join ';'}},
            @{Name='servicePrincipalName';Expression={$_.servicePrincipalName -join ';'}},@{Name='sIDHistory';Expression={$_.sIDHistory -join ';'}},'sn','title',
            @{Name='uid';Expression={$_.uid -join ';'}},'uidNumber',@{Name='userAccountControl';Expression={(ConvertFrom-UAC($_.userAccountControl))}},
            'userWorkstations','whenChanged','whenCreated' |
        Export-Csv -Path "$Path\$domain\$domain-Users.csv" -NoTypeInformation -Delimiter '|' -Append
    Write-Verbose -Message 'Active Directory Users Exported'

    Write-Verbose -Message 'Exporting Active Directory Groups'
    Get-ADGroup -Filter * -Properties 'distinguishedName','sAMAccountName','CN','displayName','name','description','groupType','ManagedBy', 'memberOf','objectSID','msDS-PSOApplied','whenCreated','whenChanged' |
        Select-Object 'distinguishedName','sAMAccountName','CN','displayName','name','description','ManagedBy',
            @{Name="memberOf";Expression={(($_.memberof -split (",") | Select-String -AllMatches "CN=") -join ", ") -replace "CN=" -replace "" }},
            'msDS-PSOApplied','whenCreated','whenChanged' |
        Export-Csv -Path "$Path\$domain\$domain-Groups.csv" -NoTypeInformation -Delimiter '|' -Append
    Write-Verbose -Message 'Active Directory Groups Exported'

    Write-Verbose -Message 'Exporting Active Directory Organizational Units'
    Get-ADOrganizationalUnit -Filter * -Properties 'distinguishedName','name','CanonicalName','DisplayName','description','whenCreated','whenChanged','ManagedBy' |
        Export-Csv -Path "$Path\$domain\$domain-OUs.csv" -NoTypeInformation -Delimiter '|' -Append
    Write-Verbose -Message 'Active Directory OUs Exported'

    #Write-Verbose -Message 'Exporting Active Directory Computers'
    #Get-ADComputer -Properties * | Export-Csv -Path "$Path\$domain\$domain-Computers.csv" -NoTypeInformation -Delimiter '|' -Append
    #Write-Verbose -Message 'Active Directory Computers Exported'

    Write-Verbose -Message 'Exporting Active Directory Group Policy Objects'
    New-Item -Path "$Path\$domain\GroupPolicy" -ItemType Directory | Out-Null
    New-Item -Path "$Path\$domain\GroupPolicy\Reports" -ItemType Directory | Out-Null
    Get-GPO -All @credObject @domainObj | ForEach-Object {
        $GPOName = $_.DisplayName
        Get-GPOReport $_.id -ReportType HTML -Path "$Path\$domain\GroupPolicy\Reports\$GPOName.html"
        Get-GPOReport $_.id -ReportType XML -Path "$Path\$domain\GroupPolicy\Reports\$GPOName.xml"
    }
    Write-Verbose -Message 'Active Directory Group Policy Objects Exported'

    Write-Verbose -Message 'Exporting Active Directory Group Policy Inheritance'
    New-Item -Path "$Path\$domain\GroupPolicy\Inheritance" -ItemType Directory | Out-Null
    Get-GPInheritance -Target $domain | Out-File -FilePath "$Path\$domain\GroupPolicy\Inheritance\$domain.txt"
    Get-ADOrganizationalUnit | ForEach-Object {
        Get-GPInheritance -Target $_.DistinguishedName | Out-File -FilePath "$Path\$domain\GroupPolicy\Inheritance\$_.DistinguishedName.txt"
    }
    Write-Verbose -Message 'Active Directory Group Policy Inheritance Exported'

    Write-Verbose -Message 'Exporting Active Directory Organizational Unit Access Control Lists'
    New-Item -Path "$Path\$domain\OU" -ItemType Directory | Out-Null
    New-Item -Path "$Path\$domain\OU\ACLs" -ItemType Directory | Out-Null
    # Special Thanks to Ashley McGlone for the heavy lifting here
    # https://blogs.technet.microsoft.com/ashleymcglone/2013/03/25/active-directory-ou-permissions-report-free-powershell-script-download/
    # https://gallery.technet.microsoft.com/Active-Directory-OU-1d09f989

    # Build a lookup hash table that holds all of the string names of the
    # ObjectType GUIDs referenced in the security descriptors.
    # See the Active Directory Technical Specifications:
    #  3.1.1.2.3 Attributes
    #    http://msdn.microsoft.com/en-us/library/cc223202.aspx
    #  3.1.1.2.3.3 Property Set
    #    http://msdn.microsoft.com/en-us/library/cc223204.aspx
    #  5.1.3.2.1 Control Access Rights
    #    http://msdn.microsoft.com/en-us/library/cc223512.aspx
    #  Working with GUID arrays
    #    http://blogs.msdn.com/b/adpowershell/archive/2009/09/22/how-to-find-extended-rights-that-apply-to-a-schema-class-object.aspx
    # Hide the errors for a couple duplicate hash table keys.
    $schemaIDGUID = @{}
    ### NEED TO RECONCILE THE CONFLICTS ###
    $EAP = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    Get-ADObject -SearchBase (Get-ADRootDSE).schemaNamingContext -LDAPFilter '(schemaIDGUID=*)' -Properties name, schemaIDGUID |
        ForEach-Object {$schemaIDGUID.add([System.GUID]$_.schemaIDGUID,$_.name)}
    Get-ADObject -SearchBase "CN=Extended-Rights,$((Get-ADRootDSE).configurationNamingContext)" -LDAPFilter '(objectClass=controlAccessRight)' -Properties name, rightsGUID |
        ForEach-Object {$schemaIDGUID.add([System.GUID]$_.rightsGUID,$_.name)}
    $ErrorActionPreference = $EAP

    $OUs  = @(Get-ADDomain | Select-Object -ExpandProperty DistinguishedName)
    $OUs += Get-ADOrganizationalUnit -Filter * | Select-Object -ExpandProperty DistinguishedName
    $OUs += Get-ADObject -SearchBase (Get-ADDomain).DistinguishedName -SearchScope OneLevel -LDAPFilter '(objectClass=container)' | Select-Object -ExpandProperty DistinguishedName

    ForEach ($OU in $OUs) {
        Get-Acl -Path "AD:\$OU" | Select-Object -ExpandProperty Access |
            Select-Object @{name='organizationalUnit';expression={$OU}}, `
                   @{name='objectTypeName';expression={if ($_.objectType.ToString() -eq '00000000-0000-0000-0000-000000000000') {'All'} Else {$schemaIDGUID.Item($_.objectType)}}}, `
                   @{name='inheritedObjectTypeName';expression={$schemaIDGUID.Item($_.inheritedObjectType)}}, `
                   * | Export-Csv -Path "$Path\$domain\OU\ACLs\$OU" -NoTypeInformation -Delimiter '|' -Append
    }
    Write-Verbose -Message 'Active Directory Organizational Unit Access Control Lists Exported'

    Write-Verbose -Message 'Exporting Active Directory Confidentiality Bit Details'
    Get-ADObject -SearchBase "CN=Schema,CN=Configuration,$domain" -LDAPFilter '(searchFlags:1.2.840.113556.1.4.803:=128)' |
        Export-Csv -Path "$Path\$domain\$domain-confidentialBit.csv" -NoTypeInformation -Delimiter '|' -Append
    Write-Verbose -Message 'Active Directory Confidential Bit Details Exported'

    Write-Verbose -Message 'Exporting Active Directory Fine Grained Password Policies'
    Get-ADFineGrainedPasswordPolicy -Filter * | Select-Object -ExcludeProperty AppliesTo *,
        @{Name="memberOf";Expression={(($_.memberof -split (",") | Select-String -AllMatches "CN=") -join ", ") -replace "CN=" -replace "" }} |
        Export-Csv -Path "$Path\$domain\$domain-fgppDetails.csv" -NoTypeInformation -Delimiter '|' -Append
    Write-Verbose -Message 'Active Directory Fine Grained Password Policies Exported'

    Write-Verbose -Message 'Exporting Active Directory Domain Trusts'
    Get-ADTrust -Filter * | Export-Csv -Path "$Path\$domain\$domain-trustedDomains.csv" -NoTypeInformation -Delimiter '|' -Append
    Write-Verbose -Message 'Active Directory Domain Trusts Exported'


    Write-Verbose -Message "Finished Execution at $(Get-Date -Format G)"
    Write-Output "Finished Execution at $(Get-Date -Format G)" | Out-File "$Path\$domain\consoleOutput.txt" -Append

    Write-Verbose -Message 'Compressing Output Data to Zip File'
    New-ZipFile -Path "$Path\$domain.zip" -Source "$Path\$domain"
    Write-Verbose -Message 'Output Data Compressed to Zip File'
}
