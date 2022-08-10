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
      version = "=0.3.0"
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
  email_receiver = {
    "doesnotexist" = {
      email_address           = "doesnotexist@domain.com"
      use_common_alert_schema = true
    }
  }

  default_locations = [
    {
      "Id" : "us-ca-sjc-azr"
    },
    {
      "Id" : "us-tx-sn1-azr"
    }
  ]

  webtests = {
    "_yahoo.com - SSL" = {
      enabled                           = true
      frequency                         = 900
      timeout                           = 120
      kind                              = "standard"
      retry_enabled                     = false
      locations                         = local.default_locations
      request_url                       = "https://yahoo.com"
      http_verb                         = "GET"
      parse_dependent_requests          = false
      follow_redirects                  = true
      expected_http_status_code         = 200
      ssl_check                         = true
      ssl_cert_remaining_lifetime_check = 30
    }
    "_microsoft.com - Ping" = {
      enabled                           = true
      frequency                         = 600
      timeout                           = 110
      kind                              = "standard"
      retry_enabled                     = false
      locations                         = local.default_locations
      request_url                       = "https://microsoft.com/"
      http_verb                         = "GET"
      parse_dependent_requests          = false
      follow_redirects                  = false
      expected_http_status_code         = 200
      ssl_check                         = false
      ssl_cert_remaining_lifetime_check = null
    }
  }
}

resource "random_uuid" "random_uuid" {}
data "azurerm_subscription" "current" {}

resource "azapi_resource" "example_webtests" {
  for_each  = local.webtests
  #To define body, please use Microsoft's documentation for ARM templates, located here. https://docs.microsoft.com/en-us/azure/templates/
  #In this example, we are using the Microsoft.Insights/webtests@2018-05-01-preview API: https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/2018-05-01-preview/webtests?tabs=json
  #You can see which properties are required versus optional in the documentation. 
  type      = "Microsoft.Insights/webtests@2018-05-01-preview"
  name      = each.key
  parent_id = resource.azurerm_resource_group.example.id
  location  = local.location
  tags = {
    "hidden-link:/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${resource.azurerm_resource_group.example.name}/providers/microsoft.insights/components/${resource.azurerm_application_insights.example.name}" : "Resource"
  }
 
  body = jsonencode({
    properties = {
      SyntheticMonitorId : each.key
      Name : each.key
      Enabled : each.value.enabled
      Frequency : each.value.frequency
      Timeout : each.value.timeout
      Kind : each.value.kind
      RetryEnabled : each.value.retry_enabled
      Locations : each.value.locations,
      Request : {
        RequestUrl : each.value.request_url
        HttpVerb : each.value.http_verb
        ParseDependentRequests : each.value.parse_dependent_requests
        FollowRedirects : each.value.follow_redirects
      },
      ValidationRules : {
        ExpectedHttpStatusCode : each.value.expected_http_status_code
        SSLCheck : each.value.ssl_check
        SSLCertRemainingLifetimeCheck : each.value.ssl_cert_remaining_lifetime_check
      }
    }
  })
  depends_on = [
    resource.azurerm_application_insights.example
  ]
}

resource "azurerm_resource_group" "example" {
  name     = "rg_${resource.random_uuid.random_uuid.result}"
  location = local.location
}

resource "azurerm_application_insights" "example" {
  name                = "ai_${resource.random_uuid.random_uuid.result}"
  location            = local.location
  resource_group_name = resource.azurerm_resource_group.example.name
  application_type    = "java"
}

resource "azurerm_monitor_action_group" "example" {
  name                = "mag_${resource.random_uuid.random_uuid.result}"
  short_name          = substr("mag_${resource.random_uuid.random_uuid.result}", 0, 10)
  resource_group_name = resource.azurerm_resource_group.example.name
  enabled             = true

  dynamic "email_receiver" {
    for_each = local.email_receiver
    content {
      name                    = email_receiver.key
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }
}

resource "azurerm_monitor_metric_alert" "example" {
  for_each            = local.webtests
  name                = "mma_${each.key}"
  resource_group_name = resource.azurerm_resource_group.example.name
  scopes              = [resource.azurerm_application_insights.example.id, "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${resource.azurerm_resource_group.example.name}/providers/Microsoft.Insights/webTests/${each.key}"]
  enabled             = true

  application_insights_web_test_location_availability_criteria {
    web_test_id           = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${resource.azurerm_resource_group.example.name}/providers/Microsoft.Insights/webTests/${each.key}"
    component_id          = resource.azurerm_application_insights.example.id
    failed_location_count = 2
  }
  action {
    action_group_id = resource.azurerm_monitor_action_group.example.id
  }
  depends_on = [
    resource.azurerm_application_insights.example,
    resource.azapi_resource.example_webtests
  ]
}
