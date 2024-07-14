terraform {
  required_providers {
    # Third-party providers have to be declared in any modules that use them.
    azuredevops = {
      source = "microsoft/azuredevops"
      version = "~> 1.1"
    }
  }
}