# Provider Variables

## Azure Active Directory

variable "azure_tenant_id" {
    description = "The Azure Entra tenant ID."
    type = string
}

## Azure DevOps

variable "azure_devops_pat" {
  description = "An Azure DevOps personal access token for deploying Azure DevOps resources. Assume the PAT has full access"
  type = string
  sensitive = true
}

variable "azure_devops_org" {
    description = "A URL in the format https://dev.azure.com/org-name"
    type = string
}