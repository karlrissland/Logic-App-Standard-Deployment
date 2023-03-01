
# Set Azure Region
$LOCATION = "eastus"

# Set starting Bicep
$BICEP_FILE = ".\main.bicep"

#choose to mark this as a dev environment vs uat or prod
$resourceSuffix = "dev" # valid options are (dev, uat, prod)

$deploymentName = "powershelldeployment"

Write-Output "starting up"

Write-Output "deploying infrastructure...."

$deployoutput = az deployment sub create -l $LOCATION -n $deploymentName -f $BICEP_FILE -p environment=$resourceSuffix 

Write-Output "deployment complete."

Write-Output $deployoutput
