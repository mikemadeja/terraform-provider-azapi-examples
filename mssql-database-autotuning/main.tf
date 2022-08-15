# Author(s)
# Mike Madeja (https://github.com/mikemadeja/terraform-provider-azapi-examples)

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.15.0"
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
  location            = "central us"
  autotuning = {
    ForceLastGoodPlan = {
      autoExecuteValue = "Enabled"
    }
    CreateIndex = {
      autoExecuteValue = "Enabled"
    }
    DropIndex = {
      autoExecuteValue = "Disabled"
    }
  }
}

resource "random_string" "example" {
  length  = 16
  special = false
}

resource "random_uuid" "random_uuid" {}
data "azurerm_subscription" "current" {}

resource "azapi_update_resource" "mssql_database_autotuning" {
  for_each    = local.autotuning
  type        = "Microsoft.Sql/servers/databases/advisors@2014-04-01"
  resource_id = "${azurerm_mssql_database.example.id}/advisors/${each.key}"
  body = jsonencode({
    properties : {
      autoExecuteValue : each.value.autoExecuteValue
    }
  })
  depends_on = [
    azurerm_mssql_database.example
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
  name           = "dbautotuning_${random_string.example.result}"
  server_id      = azurerm_mssql_server.example.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "BasePrice"
  max_size_gb    = 2
  read_scale     = false
  sku_name       = "S0"
  zone_redundant = false

  lifecycle {
    ignore_changes = [
      license_type
    ]
  }
}

resource "azurerm_resource_group" "example" {
  name     = "rg_${random_string.example.result}"
  location = local.location
}
