# Author(s)
# Mike Madeja (https://github.com/mikemadeja/terraform-provider-azapi-examples)

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.00.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "=0.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "=3.3.1"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  location = "central us"
  sqldbs = {
    db01 = {
      max_size_gb = 2
    }
    db02 = {
      max_size_gb = 1
    }
  }
}

resource "random_string" "example" {
  length  = 16
  special = false
}

resource "random_uuid" "random_uuid" {}
data "azurerm_subscription" "current" {}

resource "azapi_update_resource" "mssql_database_autotuning_create_index" {
  type        = "Microsoft.Sql/servers/advisors@2014-04-01"
  resource_id = "${azurerm_mssql_server.example.id}/advisors/CreateIndex"
  body = jsonencode({
    properties : {
      autoExecuteValue : "Enabled"
    }
  })
  depends_on = [
    azurerm_mssql_server.example, azurerm_mssql_database.example
  ]
}

# The API must have a limitation, I can't do a for_each loop so each Advisor piece has to be called out.
resource "azapi_update_resource" "mssql_database_autotuning_force_last_good_plan" {
  type        = "Microsoft.Sql/servers/advisors@2014-04-01"
  resource_id = "${azurerm_mssql_server.example.id}/advisors/ForceLastGoodPlan"
  body = jsonencode({
    properties : {
      autoExecuteValue : "Enabled"
    }
  })
  depends_on = [
    azurerm_mssql_server.example, azurerm_mssql_database.example,
    azapi_update_resource.mssql_database_autotuning_create_index
  ]
}

resource "azapi_update_resource" "mssql_database_autotuning_drop_index" {
  type        = "Microsoft.Sql/servers/advisors@2014-04-01"
  resource_id = "${azurerm_mssql_server.example.id}/advisors/DropIndex"
  body = jsonencode({
    properties : {
      autoExecuteValue : "Disabled"
    }
  })
  depends_on = [
    azurerm_mssql_server.example, azurerm_mssql_database.example,
    azapi_update_resource.mssql_database_autotuning_force_last_good_plan
  ]
}

resource "azurerm_mssql_server" "example" {
  name                          = lower("sqlserver-${random_string.example.result}")
  resource_group_name           = resource.azurerm_resource_group.example.name
  location                      = resource.azurerm_resource_group.example.location
  version                       = "12.0"
  administrator_login           = "azapiprovider"
  administrator_login_password  = "pw_${random_string.example.result}"
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
}

resource "azurerm_mssql_database" "example" {
  for_each       = local.sqldbs
  name           = "dbautotuning_${each.key}"
  server_id      = azurerm_mssql_server.example.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "BasePrice"
  max_size_gb    = each.value.max_size_gb
  read_scale     = false
  sku_name       = "S0"
  zone_redundant = false
}

resource "azurerm_resource_group" "example" {
  name     = "rg_${random_string.example.result}"
  location = local.location
}

