targetScope = 'subscription'

@description('The environment for which the deployment is being executed')
@allowed([
  'dev'
  'uat'
  'prod'
])
param environment string

param uniqueSuffix string = substring(uniqueString(concat(subscription().id),environment),0,5)

param location string = deployment().location

// Variables
var workloadName = 'la-std-basics'
var resourceSuffix = '${workloadName}-${environment}'
var ResourceGroupName = 'integration-demos-${resourceSuffix}${uniqueSuffix}'

resource RG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: ResourceGroupName
  location: location
}

module LogicAppDeploy 'LogicApp.bicep' = {
  name: 'LogicAppDeploy'
  scope: resourceGroup(RG.name)
  params: {
    uniqueSuffix: uniqueSuffix
    deploymentEnvironment: environment
    location: location
    workloadName: workloadName
  }
}

output LogicAppPlan_name string = LogicAppDeploy.outputs.LogicAppPlan_name
output LogicApp_name string = LogicAppDeploy.outputs.LogicApp_name
output LogicApp_Storage_name string = LogicAppDeploy.outputs.LogicApp_Storage_name
output ResourceGroupName string = ResourceGroupName
