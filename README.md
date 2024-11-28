# Terraform Project: Automate the provision of cloud infrastructure using terraform.

## **Overview**
The objective of the project is automate the deployment of cloud resource using Infrastructure as Code tool ( Terraform)

### ****key Features****
* Deploy (Virtual Machines,Application Gateway, Load Balancer)
* Configure (Azure Security Center, Azure key vault)

## Prerequisite 
1. Install Terraform

   Download Terraform: 
   
  * Install Terraform from the official Terraform website.
  * Verify Installation: After installation,    run the following command to verify the installation:
  
      **terraform --version**

##
2. Install Cloud Provider CLI

   Most cloud providers have their own command-line interfaces (CLI) that Terraform interacts with for authentication and configuration.

   **For Azure:**

* Install the Azure CLI: Install Azure CLI.
* Login :

    **az login**

##
 
3. Authentication and Permissions
* **Azure:** Service Principal, Managed Identity, or User Credentials with contributor or owner permissions.

## 
 Practical Guide to Infrastructure Provisioning

 * Create a directory where your project will reside
   
      
      
      
       mkdir ./fino-project
 * Define the cloud provider API with current version

        azurerm = {source = "hashicorp/azurerm"version = "4.11.0"}

  
  
  * Initialiaze the directory to install Terraform plugins

          terraform init
   
  * Create your terraform file structure
     
     
     
    **main.tf  variable.tf  output.tf terraform.
    tfvars** 
  
 * Navigate into the main.tf and write your terraform code          and apply the below command to execute the codes:

     

       terraform apply 