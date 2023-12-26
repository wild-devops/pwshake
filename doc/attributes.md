## `attributes:` **element**

**Optional**

Contains definition of data that passed into executable scripts as a single parameter.

This is the single source of true for **PWSHAKE** engine about all inputs used by the `pwshake.yaml` config processing.

This parameter should be of type **Powershell** `[hashtable]` that allows to **merge**, **interpolate** and **override** contained values during **PWSHAKE** execution.

* ## `attributes:` example
    ```
    attributes:
      some_attribute: 
        nested_attribute1: this is 1
        nested_attribute2: that is 2
      composed_attribute:
      - 1
      - 2
      - 3
    ```
    The given example is transformed in the following **Powershell** `[hashtable]` and passed by **PWSHAKE** engine to every executable script defined in the `tasks:` element.
    ```
    @{
      attributes=@{
        some_attribute=@{
          nested_attribute1="this is 1";
          nested_attribute2="that is 2";
        };
        composed_attribute=@(1,2,3);
      }
    }
    ```
* ## `attributes:` **merging**

  The `pwshake.ps1` bootstrapper script can accept additional `-MetaData` (or `-Attributes` alias) parameter that merges given parameter value into the `attributes:` element:
  ```
  PS>./pwshake.ps1 -MetaData "env_name=shake42"
  ```
  Output (the `pwshake_path` value is merged by **PWSHAKE** engine):
  ```
  PWSHAKE config:
  attributes:
    env_name: "shake42"
    pwshake_path: /absolute/path/to/your/working/directory/MyRepo
  ...
  ```
  [See more about the `-MetaData` parameter of  bootstrapper `pwshake.ps1` script](/doc/bootstrapper.md)

* ## `attributes:` **interpolation**
  
  Values of several attributes can be reused and/or composed by simple **interpolation** syntax: `{{key-to-be-interpolated}}`, for example:
  ```
  PS> cat ./pwshake.yaml
  attributes:
    win_fqdn: "{{env_name}}-windows.{{override_to}}"
  ...
  ```
  ```
  PS>./pwshake.ps1 -Metadata @{env_name="shake42";override_to="test"}
  PWSHAKE config:
  attributes:
    env_name: shake42
    override_to: test
    pwshake_path: /absolute/path/to/your/working/directory/MyRepo
    win_fqdn: shake42-windows.test
  ...
  ```
  If `attributes:` has deep hierarchical structure it can be interpolated with dot syntax `{{key.to.be.interpolated}}`, for example:
  ```
  PS> cat ./pwshake.yaml
  attributes:
    a:
      b:
        c: d
    e: "{{a.b.c}}"
  ...
  ```
  ```
  PS>Invoke-pwshake
  PWSHAKE config:
  attributes:
    a:
      b:
        c: d
    e: d
  ...
  ```
  If keys given by **interpolation** syntax are not present either in `attributes:` element or in `-MetaData` parameter value they are evaluated with empty string, for example:
  ```
  PS> cat ./pwshake.yaml
  attributes:
    win_fqdn: "{{env_name}}-windows.shake.{{override_to}}"
  ...
  ```
  ```
  PS>./pwshake.ps1
  PWSHAKE config:
  attributes:
    pwshake_path: /absolute/path/to/your/working/directory/MyRepo
    win_fqdn: -windows.shake.
  ...
  ```
  ## Evaluation of environment variables

  **PWSHAKE** supports simple evaluation of environment variables in **interpolation** syntax similar to **Powershell** syntax `{{$env:COMPUTERNAME}}`, for example:
  ```
  PS>$env:SOME_VAL="fi42321"
  ```
  ```
  PS>./pwshake.ps1 -Metadata 'env_name={{$env:SOME_VAL}}-windows'
  PWSHAKE config:
  attributes:
    pwshake_path: /absolute/path/to/your/working/directory/MyRepo
    env_name: fi42321-windows
  ...
  ```

  ## Evaluation of **Powershell** expressions

  If it's required to evaluate dynamic value of attribute, there is an ability to do this with general **Powershell** string interpolation syntax `"$(...)"`.
  
  Examples:
  ```
  PS>./pwshake.ps1 -Metadata 'env_name={{$([System.Environment]::MachineName)}}'
  ...
  ```
  
  ```
  PS>./pwshake.ps1 -Metadata 'env_id={{$("env-$([System.Guid]::NewGuid())")}}'
  ...
  ```
  All examples above are valid only for early stage of **PWSHAKE** engine processing (merging `-MetaData` and interpolate the `attributes:` element state that will not be changed in the further processing).

  If You need to use dynamic evaluation in the later `tasks:` (`- step:`) processing stage, You can use a quite similar `templates:` evaluation syntax `$[[$some_really_dynamic_value]]`, for example:
  ```
  PS> cat ./dynamic_eval.yaml
  tasks:
    dynamic_eval_test:
    - echo: '{{$($some_really_dynamic_value)}}'
    - skip_on: $some_really_dynamic_value
      echo: "$some_really_dynamic_value is empty"
    - pwsh: |
        $script:some_really_dynamic_value = (Get-Date -Format o)
      #  ^^^^^^ used 'script' scope since the 'pwsh:' step invoked in it's own scope
    - echo: $[[$some_really_dynamic_value]]
    - skip_on: $some_really_dynamic_value
      pwsh: throw $some_really_dynamic_value
  invoke_tasks:
  - dynamic_eval_test
  ```

  ```
  PS> pwshake ./dynamic_eval.yaml -Verbosity Normal
  Invoke task: dynamic_eval_test
  Execute step: echo_1

  Execute step: echo_2
  $some_really_dynamic_value is empty
  Execute step: pwsh_3
  Execute step: echo_4
  2008-10-31T13:56:50.6495398+00:00
  Execute step: pwsh_5
    Bypassed because of: [-not ($some_really_dynamic_value)] = False
  ```
  
* ## `attributes:` **overriding**
  [See more about `attributes_overrides:`](/doc/attributes_overrides.md) element
