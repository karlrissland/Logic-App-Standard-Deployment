# Logic Apps Standard Deployment Examples

Demonstrates how to automate the deployment of Logic Apps Standard into Azure.  Will cover common scenarios that need to be takend into consideration when deploying with GitHub actions

- Parameterizing a workflow
- Deploying across dev/test/production
- Working with Schemas and Maps
- Working with Azure Managed Connections
- Setting up Custom Property Tracking

## Azure Architecture
The following diagram describes the general architecture of Azure services depicted in this solution.

![Azure Architecture](docs/img/architecture-azure.drawio.svg)

## Repository Structure
The following diagram describes the structure of the repository.  Highlighting key files.

## Deployment
The solution has GitHub workflows setup to deploy the infrastructure, application, or both.  There is also a PowerShell script available to deploy the infrastructure.

![CI/CD Architecture](docs/img/architecture-cicd.drawio.svg)

- Build: package the Logic App Standard
- Deploy to Azure logicapp-dev
- Deploy to Azure logicapp-prd

Each of the Deployment stage will:

- Create the resource group if it doesn't exist
- Provision and create Azure resources using an Azure Resource Manager Template
- Deploy the Logic App Standard package to the Workflow Service (sites in the architecture diagram)

## References

- https://docs.microsoft.com/en-us/azure/logic-apps/single-tenant-overview-compare
- https://docs.microsoft.com/en-us/azure/logic-apps/create-single-tenant-workflows-visual-studio-code
- https://docs.microsoft.com/en-us/azure/developer/github/deploy-to-azure
- https://docs.microsoft.com/en-us/azure/logic-apps/set-up-devops-deployment-single-tenant-azure-logic-apps?tabs=github
- https://docs.microsoft.com/en-us/azure/templates/
