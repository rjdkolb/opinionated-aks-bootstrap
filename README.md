# opinionated-aks-bootstrap
> Setting up an AKS cluster with Terraform is not trivial. The project project seeks to fulfill the following goals:
- A minimal configuration that configures an Ingress, certificate management and Helm.
- A scalable and 'reliable' cluster.
- The same project can be used to configure many environments (dev, test, prod etc.)
- The project can be used by others directly and indirectly


## Prerequisites

You will need the following installed:
- helm
- kubectl
- terraform

## Installation

OS X & Linux:

### Create storage account with container 'terraform-state'

If you don't have a Azure blob container installed yet, you can create one as follows:
```sh
cd terraform-state
export TF_VAR_terraform_storage_name=<This must be a unique name>
terraform init
terraform plan
terraform plan -out planfile 
```

### Initialize 

If TF_VAR_terraform_storage_name is not yet specified, set it.
```sh
export TF_VAR_terraform_storage_name=<This must be a unique name>
```

Make sure you are in the root directory of the project and initialize the state file so it is stored on the `storage_account_name` and in container name `container_name`.

```sh
terraform init -backend-config="storage_account_name=$TF_VAR_terraform_storage_name" \
-backend-config="container_name=terraform-state" \
-backend-config="key=dev.terraform.tfstate"
```

### Plan

```sh
terraform plan
```

### Apply the plan
```sh
terraform apply
```

## Release History

* 0.0.1
    * Work in progress. There is still an issue with certificate enrollment.

## Meta

Your Name – [@rjdkolb](https://twitter.com/rjdkolb)

Distributed under the MIT license. See ``LICENSE`` for more information.

[https://github.com/rjdkolb/opinionated-aks-bootstrap](https://github.com/rjdkolb/)

## Contributing

1. Fork it (<https://github.com/rjdkolb/opinionated-aks-bootstrap/fork>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request


