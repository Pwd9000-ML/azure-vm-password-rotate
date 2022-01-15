# Rotate AZURE virtual machines local administrator Passwords using AZURE key vault secrets

## Inputs

| Inputs | Required | Description | Default |
|--------- | -------- | ----------- | ------- |
| key-vault-name | True | Name of the Azure key vault pre-populated with secret name keys representing server names hosted in Azure. | N/A |

## AZURE VMs password rotate action

```
- name: Rotate VMs administrator passwords
    uses: Pwd9000-ML/azure-vm-password-rotate@v1-beta
    with:
    key-vault-name: ${{ env.KEY_VAULT_NAME }}
```

## Example Usage

[Link to example workflow file](https://github.com/Pwd9000-ML/azure-vm-password-rotate/blob/master/exampleWorkflows/rotate-vm-passwords.yml)

## Rotate VM Passwords every monday at 09:00 UTC

```
name: Update Azure VM passwords
on: 
  workflow_dispatch:
  schedule:
    - cron:  '0 9 * * 1' # Runs at 9AM every Monday

jobs:
  publish:
    runs-on: windows-latest
    env:
      KEY_VAULT_NAME: 'your-key-vault'

    steps:
    - name: Check out repository
      uses: actions/checkout@v2

    - name: Log into Azure using github secret AZURE_CREDENTIALS
      uses: Azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
        enable-AzPSSession: true

    - name: Rotate VMs administrator passwords
      uses: Pwd9000-ML/azure-vm-password-rotate@v1
      with:
        key-vault-name: ${{ env.KEY_VAULT_NAME }}
```

**Notes:**

- As per the example above, you also need a GitHub Secret `AZURE_CREDENTIALS` to log into Azure using Action: `Azure/login@v1`
- The credential used must also have access to the key vault.
- You can use the [AzurePreReqs](https://github.com/Pwd9000-ML/azure-vm-password-rotate/tree/master/azurePreReqs) script to create a key vault, generate a GitHub Secret to use as `AZURE_CREDENTIALS` and sets relevant access on the key vault.
- Key Vault must be pre-populated with `Secret Keys`, where each `key` represents a server name e.g:

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/azure-vm-password-rotate/master/assets/kvsecrets.png)

## Versions of runner that can be used

At the moment only windows runners are supported. Support for all runner types will be released soon.

| Environment | YAML Label |
| --------------------|---------------------|
| Windows Server 2019 | `windows-latest` or `windows-2019` |
| Windows Server 2016 | `windows-2016` |

## License

The associated scripts and documentation in this project are released under the [MIT License](LICENSE).
