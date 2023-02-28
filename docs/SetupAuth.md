The github workflow testAzureConnectivity.yml will test authentication against a windows and ubuntu agent.

Follow documentation found here; https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure

Make sure you assign the service principle access to your subscription and resources.  You can reference documentation found here; https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#assign-the-application-to-a-role

NOTE: this example assums you will be using one subscription and different resource groups for your environments.  If needed, a few small changes will enable this demo to work with multiple subscriptions, i.e. a subscription for dev/test and another for production.