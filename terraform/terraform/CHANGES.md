# Changes to Fix Terraform Plan Error

## Issue Description

The following error was occurring during `terraform plan`:

```
Error: Invalid count argument

  on modules\kubernetes\main.tf line 30, in resource "azurerm_role_assignment" "acr_pull":
  30:   count                            = var.create_role_assignment && var.acr_id != null ? 1 : 0

The "count" value depends on resource attributes that cannot be determined until apply, so Terraform cannot predict how many instances will be created.
```

We tried to fix this by using `for_each` instead of `count`, but encountered a similar error:

```
Error: Invalid for_each argument

The "for_each" value depends on resource attributes that cannot be determined until apply, so Terraform cannot predict how many instances will be created.
```

## Solution

The solution was to move the role assignment to a separate module. This approach works because:

1. It separates the role assignment from the Kubernetes module, allowing Terraform to better manage dependencies.
2. It avoids the issue with computed values in conditional expressions.
3. It provides more explicit control over when the role assignment is created.

### Changes Made

1. Created a new module `role_assignment` with:
   - `main.tf`: Defines the `azurerm_role_assignment` resource
   - `variables.tf`: Defines the input variables
   - `outputs.tf`: Defines the output values

2. Removed the role assignment resource and related variables from the Kubernetes module:
   - Removed the `azurerm_role_assignment` resource from `modules/kubernetes/main.tf`
   - Removed the `acr_id` and `create_role_assignment` variables from `modules/kubernetes/variables.tf`

3. Updated the root module to use the new role_assignment module:
   - Removed the `acr_id` and `create_role_assignment` parameters from the Kubernetes module call
   - Added a new module block for the role_assignment module
   - Added a new variable `create_acr_role_assignment` to control whether to create the role assignment
   - Updated the tfvars files to set the value for the `create_acr_role_assignment` variable

## How to Test

Run the `plan.bat` script to verify that the error is resolved:

```
.\plan.bat
```

This should create a plan without any errors related to the role assignment.