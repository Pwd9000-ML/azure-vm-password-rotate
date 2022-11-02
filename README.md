# Rotate AZURE virtual machines local administrator Passwords using AZURE key vault

[![Dependabot](https://badgen.net/badge/Dependabot/enabled/green?icon=dependabot)](https://dependabot.com/)

## Video tutorial

[![image.png](http://img.youtube.com/vi/TJZSFdHlSTs/0.jpg)](http://www.youtube.com/watch?v=TJZSFdHlSTs "Rotate AZURE virtual machines local administrator Passwords using AZURE key vault")

## Overview

This Action will connect to a provided AZURE key vault as input and will loop through each secret key (server name). For each server, automatically generate a random unique password (default 24char), set that password against the VM and save the password value against the relevant secret key in the key vault. This will allow you to automate, maintain and manage all your server passwords from a centrally managed key vault in AZURE by only giving relevant access when required by anyone via key vault permissions.

- The Azure key vault must be pre-populated with `Secret Keys`, where each `key` represents a server name:

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/azure-vm-password-rotate/master/assets/kvsecrets.png)

See this [tutorial](https://dev.to/pwd9000/automate-password-rotation-with-github-and-azure-412a) on setting up the Azure key vault and GitHub Secret Credential (if needed).

## Inputs

| Inputs | Required | Description | Default |
|--------|----------|-------------|---------|
| key-vault-name | True | Name of the Azure key vault pre-populated with secret name keys representing server names hosted in Azure. | N/A |
| password-length | False | The amount of characters in the password. | 24 |

## INSTALLATION

Copy and paste the following snippet into your .yml file.

```yml
- name: Rotate VMs administrator passwords
    uses: Pwd9000-ML/azure-vm-password-rotate@v1.1.0
    with:
      key-vault-name: ${{ env.KEY_VAULT_NAME }}
      password-length: 24 ##Optional configuration
```

## Example Usage

Here is a link to an example [workflow file](https://github.com/Pwd9000-ML/azure-vm-password-rotate/blob/master/exampleWorkflows/rotate-vm-passwords.yml) using legacy authentication (Client and Secret).

## Example - Rotate VM Passwords every monday at 09:00 UTC (Legacy)

```yml
name: Update Azure VM passwords
on: 
  workflow_dispatch:
  schedule:
    - cron:  '0 9 * * 1' ##Runs at 9AM UTC every Monday##

jobs:
  publish:
    runs-on: windows-latest
    env:
      KEY_VAULT_NAME: 'your-key-vault-name'

    steps:
    - name: Check out repository
      uses: actions/checkout@v3.0.2

    - name: Log into Azure using github secret AZURE_CREDENTIALS
      uses: Azure/login@v1.4.5
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
        enable-AzPSSession: true

    - name: Rotate VMs administrator passwords
      uses: Pwd9000-ML/azure-vm-password-rotate@v1.1.0
      with:
        key-vault-name: ${{ env.KEY_VAULT_NAME }}
```

Here is a link to an example [workflow file (OIDC)](https://github.com/Pwd9000-ML/azure-vm-password-rotate/blob/master/exampleWorkflows/rotate-vm-passwords-OIDC.yml) using Open ID Connect(OIDC).

## Example - Rotate VM Passwords every monday at 09:00 UTC (OIDC)

```yml
name: Update Azure VM passwords
on: 
  workflow_dispatch:
  schedule:
    - cron:  '0 9 * * 1' ##Runs at 9AM UTC every Monday##

permissions:
  id-token: write
  contents: read

jobs:
  rotatePwd:
    runs-on: windows-latest
    env:
      KEY_VAULT_NAME: 'your-key-vault-name'

    steps:
    - name: Check out repository
      uses: actions/checkout@v3.0.2

    - name: 'Az CLI login using OIDC'
      uses: azure/login@v1
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
        enable-AzPSSession: true

    - name: Rotate VMs administrator passwords
      uses: Pwd9000-ML/azure-vm-password-rotate@v1.1.0
      with:
        key-vault-name: ${{ env.KEY_VAULT_NAME }}
```

## Notes

- As per the example above, you also need a GitHub Secret `AZURE_CREDENTIALS` to log into Azure using Action: `Azure/login@v1`

- You can use the [AzurePreReqs (legacy)](https://github.com/Pwd9000-ML/azure-vm-password-rotate/tree/master/azurePreReqs) script to create a key vault, generate a GitHub Secret to use as `AZURE_CREDENTIALS` and sets relevant RBAC access on the key vault, `Key Vault Officer`, as well as `Virtual Machine Contributor` over virtual machines in the Azure subscription.

- You can use the [AzurePreReqs (IODC)](https://github.com/Pwd9000-ML/azure-vm-password-rotate/tree/master/azurePreReqs) script to create a key vault, generate a federated GitHub principal (passwordless) to authenticate to Azure using only teh following GitHub secrets: `secrets.AZURE_CLIENT_ID`, `secrets.AZURE_TENANT_ID`, `secrets.AZURE_SUBSCRIPTION_ID` and sets relevant RBAC access on the key vault, `Key Vault Officer`, as well as `Virtual Machine Contributor` over virtual machines in the Azure subscription.

- Passwords will only be rotated for `secrets/names` of servers populated in the key vault as `secret` keys. Only virtual machines that are in a `running` state will have their passwords rotated:

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/azure-vm-password-rotate/master/assets/runneroutput.png)

- Servers will be skipped if they are not running:

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/azure-vm-password-rotate/master/assets/norun.png)

- If a server does not exist or the GitHub Secret `AZURE_CREDENTIALS` does not have access over the Virtual Machine a warning is issued of 'VM NOT found':

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/azure-vm-password-rotate/master/assets/nofind.png)

- DO NOT populate the key vault with servers that act as Domain Controllers.

## Versions of runner that can be used

As of release v1.1.0; Support for linux and windows runner types now available.

| Environment | YAML Label |
| --------------------|---------------------|
| Windows Server 2022 | `windows-2022` |
| Windows Server 2019 | `windows-latest` or `windows-2019` |
| Windows Server 2016 (deprecated )| `windows-2016` |
| Ubuntu 20.04 | `ubuntu-latest` or `ubuntu-20.04` |
| Ubuntu 18.04 | `ubuntu-18.04` |

## License

The associated scripts and documentation in this project are released under the [MIT License](LICENSE).
