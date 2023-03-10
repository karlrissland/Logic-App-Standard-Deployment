# ########################################################################
# Goal is to automate configuration for the azure subscription and Github
#
# Functionality
# Azure
# - Create App Registration
# - Add RBAC for App Registration
# - Add Federated credentials (Rep, environments)
# GitHub
# - Create GitHub Secrets and assign values from Azure Config
# - Create GitHub Environments and assign values
# - Create GitHub variables within Environments and assign values
#
# NOTE: GitHub PATs cannot be created programatically, it will need to be 
# created and then manually added as your repo secret.  It is expected that
# variable management will be added to the gh CLI in the future, or a 
# permissions setting will be added for the default PAT assiged to the
# runner... which will remote the need to create a PAT
#
###########################################################################

# NOTE: Script assumes Gitub and Azure CLI are installed and you are logged in

# Parameters

#parameters to be updated to match local environment
$OrgOwner = Read-Host "Please enter your github org name or owner name: "
$RepoName = Read-Host "Please enter the name of your github repository: "
$AppRegistrationName = "GitHubActions-FederationCred"
$AzureRegion = "eastus"

#Need PSSodium for secret encryption
Install-MOdule -Name PSSodium


# Changing the following variables will require changes to other scripts
# specifically, the deploymentscript.ps1 file and the github workflow.yml files
$DevEnvironmentName = "development"
$TestEnvironmentName = "test"
$ProdEnvironmentName = "production"
$DevWorkloadEnvironment = "dev"
$TestWorkloadEnvironment = "uat"
$ProdWorkloadEnvironment = "prod"

###################
# Configure Azure #
###################
Write-Output "Configuring Azure"

#Link to creating an AD App Registration
# https://learn.microsoft.com/en-us/cli/azure/ad/app?view=azure-cli-latest#az-ad-app-create
$AzureClientId = (az ad app create --display-name $AppRegistrationName | ConvertFrom-Json).appId  #Need to add contributor access to the subscription
$AzureAccountInfoObj = az account show | ConvertFrom-Json
$AzureSubscriptionId = $AzureAccountInfoObj.id
$AzureTenantId = $AzureAccountInfoObj.homeTenantId
Write-Output $AzureAccountInfoObj
Write-Output "ClientId: $AzureClientId"
WRite-Output "SubscriptionId: $AzureSubscriptionId"
Write-Output "TenantId: $AzureTenantId"
Write-Output " - Created App Registration"

Write-Output " - Starting Add Role Assignment"
az role assignment create --assignee $AzureClientId --role contributor --scope /subscriptions/$AzureSubscriptionId
Write-Output " - Added Role Assingment to App Registration"

#Link to adding federated credentials to an ad app
# https://learn.microsoft.com/en-us/cli/azure/ad/app/federated-credential?view=azure-cli-latest#az-ad-app-federated-credential-create

$fedCred = "{'audiences': [ 'api://AzureADTokenExchange'],'description': 'Allow access to the development environment',"
$fedCred = $fedCred + "'issuer': 'https://token.actions.githubusercontent.com','name':'GitHubActionFederation-Environment-Development',"
$fedCred = $fedCred + "'subject': 'repo:" +$OrgOwner+ "/" + $RepoName + ":environment:" + $DevEnvironmentName + "'}"
az ad app federated-credential create --id $AzureClientId --parameters $fedCred
Write-Output " - Added Federated Credential for $DevEnvironmentName"

$fedCred = "{'audiences': [ 'api://AzureADTokenExchange'],'description':'Allow access to the Test environment',"
$fedCred = $fedCred + "'issuer':'https://token.actions.githubusercontent.com','name':'GitHubActionFederation-Environment-Test',"
$fedCred = $fedCred + "'subject':'repo:" +$OrgOwner+ "/" + $RepoName + ":environment:" + $TestEnvironmentName + "'}"
az ad app federated-credential create --id $AzureClientId --parameters $fedCred
Write-Output " - Added Federated Credential for $TestEnvironmentName"

$fedCred = "{'audiences': ['api://AzureADTokenExchange'],'description':'Allow access to the Production environment',"
$fedCred = $fedCred + "'issuer':'https://token.actions.githubusercontent.com','name':'GitHubActionFederation-Environment-Production',"
$fedCred = $fedCred + "'subject':'repo:" +$OrgOwner+ "/" + $RepoName + ":environment:" + $ProdEnvironmentName + "'}"
az ad app federated-credential create --id $AzureClientId --parameters $fedCred
Write-Output " - Added Federated Credential for $ProdEnvironmentName"

$fedCred = "{'audiences': ['api://AzureADTokenExchange'],'description':'Allow access to the repository',"
$fedCred = $fedCred + "'issuer':'https://token.actions.githubusercontent.com','name':'GitHubActionFederation-Environment-Repo',"
$fedCred = $fedCred + "'subject':'repo:" +$OrgOwner+ "/" + $RepoName + "::ref:refs/heads/main'}"
az ad app federated-credential create --id $AzureClientId --parameters $fedCred
Write-Output " - Added Federated Credential for repo"
Write-Output "Azure Configured"
Write-Output ""

####################
# Configure GitHub #
####################
Write-Output "Configuring GitHub repo $RepoName "

#Gets info about the repo which has the repoid
$RepoID = (gh api repos/$OrgOwner/$RepoName | ConvertFrom-Json).id
Write-Output " - RepoID: $RepoID"

#Sets the repo secret

#Need to get the GitHub Public Key and Id
$RepoPubKeyObj = gh api /repos/$OrgOwner/$RepoName/actions/secrets/public-key | convertFrom-Json
$GitHubKeyId = $RepoPubKeyObj.Key_id
$GitHubKey = $RepoPubKeyObj.Key

#Need to encrypt values

$EncryptedValue = ConvertTo-SodiumEncryptedString -Text $AzureClientId -PublicKey $GitHubKey
gh api --method PUT /repos/karlrissland/test/actions/secrets/AZURE_CLIENT_ID -f encrypted_value="$EncryptedValue" -f key_id="$GitHubKeyId"

$EncryptedValue = ConvertTo-SodiumEncryptedString -Text $AzureSubscriptionId -PublicKey $GitHubKey
gh api --method PUT /repos/karlrissland/test/actions/secrets/AZURE_SUBSCRIPTION_ID -f encrypted_value="$EncryptedValue" -f key_id="$GitHubKeyId"

$EncryptedValue = ConvertTo-SodiumEncryptedString -Text $AzureTenantId -PublicKey $GitHubKey
gh api --method PUT /repos/karlrissland/test/actions/secrets/AZURE_TENANT_ID  -f encrypted_value="$EncryptedValue" -f key_id="$GitHubKeyId"

$EncryptedValue = ConvertTo-SodiumEncryptedString -Text "<ManuallyUpdateWithPAT>" -PublicKey $GitHubKey
gh api --method PUT /repos/karlrissland/test/actions/secrets/GH_PAT -f encrypted_value="$EncryptedValue" -f key_id="$GitHubKeyId"

#gh secret set AZURE_CLIENT_ID --body "$AzureClientId" --repos $RepoName --org $OrgOwner --app actions  
#gh secret set AZURE_SUBSCRIPTION_ID --body "$AzureSubscriptionId" --repos $RepoName --org $OrgOwner --app actions  
#gh secret set AZURE_TENANT_ID --body "$AzureTenantId" --repos $RepoName --org $OrgOwner --app actions  
#gh secret set GH_PAT --body "<ManuallyUpdateWithPAT>" --repos $RepoName --org $OrgOwner --app actions  #Use the GitHub GUI to create the PAT and then update the secret            
Write-Output " - Configured Action Secrets"


#Creates the Repo Variable: https://docs.github.com/en/rest/actions/variables?apiVersion=2022-11-28#create-an-organization-variable
gh api --method POST /repos/$OrgOwner/$RepoName/actions/variables -f name='GH_REPO_ID' -f value="$RepoID" 
Write-Output " - Configured Action Variables"

#Creates the Environments: https://docs.github.com/en/rest/deployments/environments?apiVersion=2022-11-28#create-or-update-an-environment
gh api --method PUT /repos/$OrgOwner/$RepoName/environments/$DevEnvironmentName
gh api --method PUT /repos/$OrgOwner/$RepoName/environments/$TestEnvironmentName
gh api --method PUT /repos/$OrgOwner/$RepoName/environments/$ProdEnvironmentName
Write-Output " - Created Environments"

#Sets the development environment variables
gh api --method POST  /repositories/$RepoID/environments/$DevEnvironmentName/variables -f name='AZURE_REGION' -f value="$AzureRegion"
gh api --method POST  /repositories/$RepoID/environments/$DevEnvironmentName/variables -f name='LOGICAPPPLAN_NAME' -f value="tbd"    #Populated when infrastructure deployed
gh api --method POST  /repositories/$RepoID/environments/$DevEnvironmentName/variables -f name='LOGICAPP_NAME' -f value="tbd"            #Populated when infrastructure deployed
gh api --method POST  /repositories/$RepoID/environments/$DevEnvironmentName/variables -f name='RESOURCEGROUPNAME' -f value="tbd"    #Populated when infrastructure deployed
gh api --method POST  /repositories/$RepoID/environments/$DevEnvironmentName/variables -f name='WORKLOAD_ENVIRONMENT' -f value="$DevWorkloadEnvironment"
Write-Output " - Created variables for $DevEnvironmentName"

#Sets the Test environment variables
gh api --method POST  /repositories/$RepoID/environments/$TestEnvironmentName/variables -f name='AZURE_REGION' -f value="$AzureRegion"
gh api --method POST  /repositories/$RepoID/environments/$TestEnvironmentName/variables -f name='LOGICAPPPLAN_NAME' -f value="tbd"   #Populated when infrastructure deployed
gh api --method POST  /repositories/$RepoID/environments/$TestEnvironmentName/variables -f name='LOGICAPP_NAME' -f value="tbd"            #Populated when infrastructure deployed
gh api --method POST  /repositories/$RepoID/environments/$TestEnvironmentName/variables -f name='RESOURCEGROUPNAME' -f value="tbd"   #Populated when infrastructure deployed
gh api --method POST  /repositories/$RepoID/environments/$TestEnvironmentName/variables -f name='WORKLOAD_ENVIRONMENT' -f value="$TestWorkloadEnvironment"
Write-Output " - Created variables for $TestEnvironmentName"

#Sets the Production environment variables
gh api --method POST  /repositories/$RepoID/environments/$ProdEnvironmentName/variables -f name='AZURE_REGION' -f value="$AzureRegion"
gh api --method POST  /repositories/$RepoID/environments/$ProdEnvironmentName/variables -f name='LOGICAPPPLAN_NAME' -f value="tbd"   #Populated when infrastructure deployed
gh api --method POST  /repositories/$RepoID/environments/$ProdEnvironmentName/variables -f name='LOGICAPP_NAME' -f value="tbd"           #Populated when infrastructure deployed
gh api --method POST  /repositories/$RepoID/environments/$ProdEnvironmentName/variables -f name='RESOURCEGROUPNAME' -f value="tbd"   #Populated when infrastructure deployed
gh api --method POST  /repositories/$RepoID/environments/$ProdEnvironmentName/variables -f name='WORKLOAD_ENVIRONMENT' -f value="$ProdWorkloadEnvironment"
Write-Output " - Created variables for $ProdEnvironmentName"

Write-Output "GitHub Configured"

Write-Output "NOTE: RBAC not yet working for App Reg, manually grant it contributor on the subscription"
Write-Output "NOTE: The GH_PAT Secret contents are invalid as it is imposible to create a PAT programatically."
Write-Output "      Please follow the instructrions to create the PAT with the correct privilages and update "
Write-Output "      the GH_PAT Secret"