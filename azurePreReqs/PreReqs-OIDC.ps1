### Create-SP-OIDC.ps1 ###
# Log into Azure
Az login

# Show current subscription (use 'Az account set' to change subscription)
Az account show

# variables
$subscriptionId = $(az account show --query id -o tsv)
$resourceGroup = "<RGName>"
$keyVaultName = "<KVName>"
$location = "UKSouth"

$appName = "<SPNAppName>"
$githubOrgName = "<GHOrgName>"
$githubRepoName = "<GHRepoName>"
$githubBranch = "<GHBranchName>"

#Create Resource Group and Key Vault
az group create --name $resourceGroup -l $location
az keyvault create --name $keyVaultName --resource-group $resourceGroup --location $location --enable-rbac-authorization

# Create AAD App and Principal
$appId = $(az ad app create --display-name $appName --query appId -o tsv)
az ad sp create --id $appId

# Create federated GitHub credentials (Entity type 'Branch')
$githubBranchConfig = [PSCustomObject]@{
    name        = "GH-[$githubOrgName-$githubRepoName]-Branch-[$githubBranch]"
    issuer      = "https://token.actions.githubusercontent.com"
    subject     = "repo:" + "$githubOrgName/$githubRepoName" + ":ref:refs/heads/$githubBranch"
    description = "Federated credential linked to GitHub [$githubBranch] branch @: [$githubOrgName/$githubRepoName]"
    audiences   = @("api://AzureADTokenExchange")
}
$githubBranchConfigJson = $githubBranchConfig | ConvertTo-Json
$githubBranchConfigJson | az ad app federated-credential create --id $appId --parameters "@-"

# Create federated GitHub credentials (Entity type 'Pull Request')
$githubPRConfig = [PSCustomObject]@{
    name        = "GH-[$githubOrgName-$githubRepoName]-PR"
    issuer      = "https://token.actions.githubusercontent.com"
    subject     = "repo:" + "$githubOrgName/$githubRepoName" + ":pull_request"
    description = "Federated credential linked to GitHub Pull Requests @: [$githubOrgName/$githubRepoName]"
    audiences   = @("api://AzureADTokenExchange")
}
$githubPRConfigJson = $githubPRConfig | ConvertTo-Json
$githubPRConfigJson | az ad app federated-credential create --id $appId --parameters "@-"

### Additional federated GitHub credential entity types are 'Tag' and 'Environment' (see: https://docs.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azcli#github-actions-example) ###

# Assign RBAC permissions to Service Principal (Change as necessary)
$appId | foreach-object {

    # Permission 1 (Example)
    az role assignment create `
        --role "Virtual Machine Contributor" `
        --assignee $_ `
        --subscription $subscriptionId

    # Permission 2 (Example)
    az role assignment create `
        --role "Key Vault Secrets Officer" `
        --assignee "$_" `
        --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.KeyVault/vaults/$keyVaultName"
}

# Authorize the operation to create a few secrets - Signed in User (Key Vault Secrets Officer)
az ad signed-in-user show --query id -o tsv | foreach-object {
    az role assignment create `
        --role "Key Vault Secrets Officer" `
        --assignee "$_" `
        --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.KeyVault/vaults/$keyVaultName"
}