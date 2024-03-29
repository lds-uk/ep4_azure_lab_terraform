# Initialize
$ErrorActionPreference = "Stop"
$WarningPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"


# Initialize subscription
$isAzModulePresent = Get-Module -Name Az.* -ListAvailable
if ([String]::IsNullOrEmpty($isAzModulePresent) -eq $true) {
    Write-Output "Script requires Az modules. Obtain from https://github.com/Azure/azure-powershell."
    return
}
else {
    Write-Output "Importing Az module.."
    Import-Module Az
    Write-Output "finished import"
}
Write-Output "Connecting to Azure1"
 
# Checking if connected to Azure

    Write-Output "Connecting to Azure2"
    try {
        Write-Output "Connecting to Azure."
        Write-Output "Provide your credentials to access your Azure subscription - See Login Pop-up Window"
        Connect-AzAccount
    }
    catch {
        Write-Output "Error: Cannot connect to Azure!"
    }

Write-Output "Connecting to Azure3"

# Collect AzSubscription details to create Service principal
$azAccount = Get-AzSubscription
$tenantId = $azAccount.TenantId
$subscriptionId = $azAccount.Id
$subResourceId = "/subscriptions/" + $azAccount.Id

Write-Output "check file"
Out-File "test.txt"


$appDisplayName = "terraform-sp-"

# Create new SPN
Write-Output "Creating a new SPN"
$spn = New-AzADServicePrincipal -DisplayName $appDisplayName 
Write-Output "SPN creation completed successfully (SPN Name: $($spn.DisplayName))"
$spnPass = $spn.PasswordCredentials.SecretText
$spnAppId = $spn.AppId

# Assigning permissions for SPN
Write-Output "Assigning Role: Contributor at Subscription"
New-AzRoleAssignment -ObjectId $spn.Id -RoleDefinitionName "Contributor" -Scope $subResourceId

# Write values to providers.tf for Terraform
Write-Output "Creating providers.tf configuration file for Terraform AzureRM Provider authentication."
Set-Content "providers.tf" "provider ""azurerm"" {"
Add-Content "providers.tf" "subscription_id = ""$subscriptionId"""
Add-Content "providers.tf" "client_id = ""$spnAppId"""
Add-Content "providers.tf" "client_secret = ""$spnPass"""
Add-Content "providers.tf" "tenant_id = ""$tenantId"""
Add-Content "providers.tf" "features {}"
Add-Content "providers.tf" "}"
Write-Output "** appPassword saved to $appDisplayName.txt **"
$spnPass | Out-File "$appDisplayName.txt"
$spnAppId | Out-File "AppId.txt"
$tenantId | Out-File "tenant_id.txt"