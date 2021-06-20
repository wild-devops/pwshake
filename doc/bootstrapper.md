## `pwshake.ps1` **bootstrapper**

The `pwshake.ps1` bootstrapper script contains commands to load all required parts to install the **PWSHAKE** engine from the source of [PSGallery](https://www.powershellgallery.com/packages/pwshake).

It imports **PWSHAKE** engine as a **Powershell** module (named `pwshake`, surprisingly) that exports a single function `Invoke-pwshake` and its alias `pwshake` as well.

Then it calls `Invoke-pwshake` command with all parameters passed to the bootstrapper.

## `pwshake.ps1` and `Invoke-pwshake` **parameters**
All parameters are optional since they all have conventional default values:

* ### **`-ConfigPath`**

  Aliases: **`-Path`, `-File`, `-ConfigFile`**

  Default is: `[string]"$PSScriptRoot\pwshake.yaml"` - i.e. `pwshake.yaml` from the same directory as the bootstrapper.
  
  Tells to **PWSHAKE** engine where to find a `yaml` config file that contains all data for execution.

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
  Aliases: **`-RunLists`**, **`-Roles`**

  Default is: `@()` - an empty array, i.e. nothing to override in `yaml` config's `invoke_tasks:` element.

  Tells to **PWSHAKE** engine which of `tasks:` element items from the given `yaml` config must be executed.
  
  Actually if it's not an empty array, it strongly overrides the content of the `yaml` config's `invoke_tasks:` element.

  Example (invokes the only `publish` task):
  ```
  PS>./pwshake.ps1 -Tasks publish
  ```
  Or (invokes in sequence `clean`, `build` and `test` tasks):
  ```
  PS>Invoke-pwshake -Roles @("clean", "build", "test")
  ```
  Or (the same as previous, but with natural **Powershell** syntax):
  ```
  PS>pwshake -RunLists clean, build, test
  ```

* ### **`-MetaData`**
  Alias: **`-Attributes`**

  Default is: `$null` - i.e. nothing to merge into the `yaml` config's `attributes:` element.

  Gives **PWSHAKE** engine an ability to populate the `yaml` config's `attributes:` element with an external data (**metadata** as a term) passed from the outside world (CI server, cloud provider agent, canny developer, etc).

  The `-MetaData` parameter can accept:
  * raw `json` string:
    ```
    PS>./pwshake.ps1 -MetaData '{"env_name":"shake42","override_to":"test"}'
    ```
  * multiline string:
    ```
    PS>./pwshake.ps1 -MetaData "env_name=shake42$([Environment]::NewLine)override_to=test"
    ```
  * Powershell `[hashtable]` literal:
    ```
    PS>./pwshake.ps1 -MetaData @{env_name="shake42";override_to="test"}
    ```
  * path to the `metadata` file which contains simple key value pairs in each row:
    ```
    PS>cat ./metadata
    env_name=shake42
    override_to=test

    PS>./pwshake.ps1 -MetaData ./metadata
    ...
    ```
  * path to the `metadata.json` file which contains `json` object literal:
    ```
    PS>cat ./metadata.json
    {
      "env_name": "shake42",
      "override_to": "test"
    }

    PS>Invoke-pwshake -MetaData ./metadata.json
    ...
    ```
  * path to the `metadata.yaml` file which contains `yaml` representation of the `attributes:` element content without  `attributes:` element itself:
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

* ### **`-Verbosity`**

  Alias: **`-LogLevel`**

  Default is: `Verbose` - for backward compatibility.

  Available values:
  * `Quiet` - logs nothing, except **Powershell** host process exceptions, the olny way to check if run was successful - inspect if process (`powershell.exe` or `pwsh`) exit code was not 0;
  * `Error` - logs only script exceptions and third party cli tools failures (exit code is not 0);
  * `Warning` - reserved for future;
  * `Minimal` - logs only raw scripts and cli tools output passed to **stdout**, **stderr** and any **Powershell** streams;
  * `Information` - additionally logs task and step captions before each task\step invocation;
  * `Verbose` - additionally logs `Invoke-pwshake` call arguments and **PWSHAKE** config file content after all initialization stages performed by the **PWSHAKE** engine (merging metadata, attributes interpolation, etc)
  * `Debug` - logs tons of tracing information about each action performed during the **PWSHAKE** config file processing;
  * `Silent = Quiet` - alias;
  * `Normal = Information` - alias;
  * `Default = Verbose` - alias for backward compatibility.

* ### **`-DryRun`**

  Aliases: **`-WhatIf`**, **`-Noop`**

  Default is: `$false` - i.e. normal execution.

  If it's passed as flag (`[switch]` in **Powershell** terms) the **PWSHAKE** engine does not execute any actual `steps:` listed in `pwshake.yaml` config, rather it only:
  * **includes** config data from files listed in `includes:`
  * **merges** `attributes:` with `-MetaData` input parameter value
  * **overrides** `attributes:` with data listed in `attributes_overrides:`
  * **interpolates** `attributes:` with substitutions like `{{blah-blah}}`
  * **arranges** `tasks:` according to their dependencies and order in `pwshake.yaml` config  
  * **invokes** `invoke_tasks:` items without actual `steps:` execution

  This option is useful for developing complex `pwshake.yaml` configs with many interdependent `tasks:`, several `includes:` items and/or long chains of `{{}}` substitutions and `attributes_overrides:`
  ```
  PS>./pwshake.ps1 ./my_complex_pwshake.yaml -DryRun
  ```
