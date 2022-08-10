## Author(s)
- Mike Madeja (https://github.com/mikemadeja/terraform-provider-azapi-examples)

# Introduction 
This is a self sustaining example of how to utlize the azapi terraform provider to utilize Azure resources that do not exist in the current azurerm provider. It will build the following objects.
- **azapi_resource - Microsoft.Insights/webtests@2018-05-01-preview** (https://docs.microsoft.com/en-us/rest/api/application-insights/web-tests/create-or-update?tabs=HTTP)
- azurerm_resource_group
- azurerm_application_insights
- azurerm_monitor_action_group
- azurerm_monitor_metric_alert

This example will tie in azapi with the regular azurerm components.
Webtests are built and exist within an Application Insights instance via a hidden-link tag. We then create a monitor metric alert to alert when a site is down and then send it to an action group. 

The current azurerm provider as of 7/12/2022 only allows the old method of XML when building webtests and can't do SSL monitoring, this is where azapi comes in. (https://registry.terraform.io/providers/hashicorp/azurerm/3.0.0/docs/resources/application_insights_web_test)

# Getting Started
To build this example, you must have access to an Azure subscription
- cd in terraform-provider-azapi-examples\webtests
- az login
- terraform init
- terraform plan
- terraform apply -auto-approve 

Once deployed, go to the application insights that was deployed, then click Availability, you will see the webtests that were built.

To destroy this in your environment if you built it before.
- cd in terraform-provider-azapi-examples\webtests
- az login
- terraform destroy -auto-approve
