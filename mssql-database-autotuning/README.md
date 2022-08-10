## Author(s)
- Mike Madeja (https://github.com/mikemadeja/terraform-provider-azapi-examples)

# Introduction 
This is a self sustaining example of how to utlize the azapi terraform provider to utilize Azure resources that do not exist in the current azurerm provider. It will update and build the following objects.
- **Microsoft.Sql/servers/databases/advisors@2022-02-01-preview** (https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/2022-02-01-preview/servers/databases/advisors)
- azurerm_resource_group
- azurerm_mssql_server
- azurerm_mssql_database

Autotuning for Databases is not yet featured in the Terrafrom azurerm provider.
This example will tie in azapi with the regular Terraform azurerm components.

# Getting Started
To build this example, you must have access to an Azure subscription
- cd in terraform-provider-azapi-examples\mssql-database-autotuning
- az login
- terraform init
- terraform plan
- terraform apply -auto-approve 

Once deployed, go to the Autotuning within the SQL database and you will see the updated values

To destroy this in your environment if you built it before.
- cd in terraform-provider-azapi-examples\mssql-database-autotuning
- az login
- terraform destroy -auto-approve
