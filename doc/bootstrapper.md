## `pwshake.ps1` **bootstrapper**

The `pwshake.ps1` bootstrapper script contains commands to load all required parts to install the **PWSHAKE** engine from the source of `PSGallery`

It imports **PWSHAKE** engine as a **Powershell** module (named `pwshake`, surprisingly) that exports a single function `Invoke-pwshake` and its alias `pwshake` as well

Then it calls `Invoke-pwshake` command with all parameters passed to bootstrapper

## `pwshake.ps1` and `Invoke-pwshake` **parameters**
All parameters are optional since they all have a conventional default values

* ### **`-ConfigPath`**

  Alias: **`-Path`**

  Default is: `[string]"$PSScriptRoot\pwshake.yaml"` - i.e. `pwshake.yaml` from the same directory as the bootstrapper
  
  Tells to **PWSHAKE** engine where to find a `yaml` config file that contains all data for execution

  Example:
  ```
  PS>./pwshake.ps1 ./my/custom_pwshake.yaml
  ```
  Or:
  ```
  PS>Invoke-pwshake -ConfigPath ./my/custom_pwshake.yaml
  ```
  Or:
  ```
  PS>pwshake -Path /home/user/dev/myrepo/custom_pwshake.yaml
  ```
  
* ### **`-Tasks`**
  Aliases: **`-RunLists`**, **`-Roles`**.

  Default is: `@()` - an empty array, i.e. nothing to override in `yaml` config's `invoke_tasks:` element

  Tells to **PWSHAKE** engine which `tasks:` from a given `yaml` config must be executed
  
  Actually, strongly overrides the content of the `yaml` config's `invoke_tasks:` element

  Example (invokes only the `publish` run list):
  ```
  PS>./pwshake.ps1 -Tasks publish
  ```
  Or (invokes in sequence `clean`, `build` and `test` run lists):
  ```
  PS>Invoke-pwshake -Roles @("clean", "build", "test")
  ```
  Or (the same as previous, but with natural **Powershell** syntax):
  ```
  PS>pwshake -RunLists clean, build, test
  ```

* ### **`-MetaData`**
  Default is: `$null` - i.e. nothing to merge into the `yaml` config's `attributes:` element

  Gives **PWSHAKE** engine an ability to populate the `yaml` config's `attributes:` element with external data (**metadata** as a term) passed from the outside world (CI server, cloud provider agent, canny developer, etc)

  The `-MetaData` parameter can accept:
  * raw json string
    ```
    PS>./pwshake.ps1 -MetaData '{"env_name":"shake42","override_to":"test"}'
    ```
  * multiline string
    ```
    PS>./pwshake.ps1 -MetaData "env_name=shake42`noverride_to=test"
    ```
  * Powershell `[hashtable]` literal
    ```
    PS>./pwshake.ps1 -MetaData @{env_name="shake42";override_to="test"}
    ```
  * path to the `metadata` file which contains simple key value pairs in each row
    ```
    PS>cat ./metadata
    env_name=shake42
    override_to=test

    PS>./pwshake.ps1 -MetaData ./metadata
    ...
    ```
  * path to the `metadata.json` file which contains `json` object literal
    ```
    PS>cat ./metadata.json
    {
      "env_name": "shake42",
      "override_to": "test"
    }

    PS>Invoke-pwshake -MetaData ./metadata.json
    ...
    ```
  * path to the `metadata.yaml` file which contains `yaml` representation of the `attributes:` element content
    ```
    PS>cat ./metadata.yaml
    env_name: shake42
    override_to: test

    PS>pwshake -MetaData ./metadata.yaml
    ...
    ```
    All listed above options produce the same **PWSHAKE** engine output:
    ```
    PWSHAKE config:
    attributes:
      env_name: "shake42"
      override_to: "test"
      pwshake_path: /absolute/path/to/your/working/directory/MyRepo
    ...
    ```

* ### **`-DryRun`**

  Aliases: **`-WhatIf`**, **`-Noop`**

  Default is: `$false` - i.e. normal execution

  If it passed as flag (`[switch]` in **Powershell** terms) the **PWSHAKE** engine does not execute any actual `steps:` listed in `pwshake.yaml` config, rather it only:
  * **includes** config data from files listed in `includes:`
  * **merges** `attributes:` with `metadata`
  * **overrides** `attributes:` with data listed in `attributes_overrides:`
  * **interpolates** `attributes:` with substitutions like `{{blah-blah}}`
  * **arranges** `tasks:` according to their dependencies and order in `pwshake.yaml` config  
  * **invokes** `invoke_tasks:` without actual `steps:` execution

  This option is useful for developing complex `pwshake.yaml` configs with many interdependent `tasks:` and/or long chains of `{{}}` substitutions and `attributes_overrides:`
  ```
  PS>./pwshake.ps1 ./my_complex_pwshake.yaml -DryRun
  ```
