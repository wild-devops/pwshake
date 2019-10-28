## `tasks:` **element**

Aliases: **`run_lists:`**, **`roles:`**

Contains named items that used by **PWSHAKE** engine as definitions of complex, composed and interdependent tasks.

The first level of items are task **names**, that can be used in other items and\or elements to reference a particular task for **reuse**, **compose** and **invoke**

Example:
```
tasks:
  clean:
  build:
  test:
  publish:
```
Above is the collection of 4 empty tasks, which all do nothing rather than exist.

## `tasks:` **item content**

Every named element of the `tasks:` can contain some definitions to provide more meaningful behaviour:

* ### `name:` **element**

  Contains meaningful name that passed to log output.

  Example:
  ```
  tasks:
    do_something:
      name: I really do nothing
  ...
  ```

* ### `when:` **element** (aliases: `only:`, `except:`, `skip_on:`)

  Contains an expression in **powershell** syntax that determine if the task should be either invoked or bypassed.

  Example:
  ```
  tasks:
    do_something:
      name: I'm bypassed because of $false in 'when:'
      when: $false
  ...
  ```

  Example (aliased):
  ```
  tasks:
    do_something:
      name: I'm bypassed because of $false in 'only:'
      only: $false
    do_nothing:
      name: I'm bypassed because of $env:PATH is never empty
      except: $env:PATH
    always_ignored:
      name: I'm bypassed because of weird life
      skip_on: $true
  ...
  ```

* ### `steps:` **element**

  Alias: **`scripts:`**

  Contains list of named items which are assumed as powershell script files without `.ps1` extension located in one of subdirectories determined by the `scripts_directories:` element.

  Example:
  ```
  tasks:
    do_something:
      scripts:
      - do_clean
      - do_build
      - do_format_disk_c
  ...
  ```
  This is the single task named `do_something` which contains a list of scripts to execute in order, so **PWSHAKE** engine will look for files `./do_clean.ps1`, `./do_build.ps1`, `./do_format_disk_c.ps1` and will execute them all in a sequence.

  Also this syntax can be shortened since the `steps:` element is a default for task named item:
  ```
  tasks:
    do_something:
    - do_clean
    - do_build
    - do_format_disk_c
  ...
  ```

* ### `steps:` **items types**
  By default the `steps:` element items are just names of powershell files without `.ps1` extension.

  But they can be of some more special **types**:
  
  * `- powershell:` (alias `pwsh:`) - inline powershell code

    Multiline syntax is the native powershell code.

    Example:
    ```
    tasks:
      clean:
      - powershell: rm ./results -r -force
      - pwsh: |
          Write-Host "this is example of" ` 
          + " multiline code"
    ```
  * `- cmd:` (alias `shell:`) - inline command shell code, either **cmd.exe** on **Windows** or **/bin/bash** on **Linux**
    
    Multiline syntax just combines the single long command string.

    Example:
    ```
    tasks:
      test:
      - cmd: nunit-console.exe .\bin\Debug\MyTests.dll
      - shell: |
          this.exe -is -example -of ^
          -multiline -code -with -long ^
          -list -of -fake -parameters
    ```

  * `- msbuild:` - element to run **MSBuild** with particular settings

    Example:
    ```
    tasks:
      build:
      - msbuild: .\MySolution.sln
      - msbuild:
          project: .\MyProject.csproj
          targets: TransformConfigs
          properties: Configuration=Debug
    ```
    The above are 2 calls to **MSBuild**: the first is in shortened form and just uses default target (`Build`) and default options, the second uses given parameters `targets:` and `properties:` passed from `pwshake.yaml` config.

  * `- [step]:` - an implicit element to fulfill the particular step settings in explicit way

    Example:
    ```
    tasks:
      build:
      - step1:
          name: Clean work directory
          powershell: rm ./work -recurse -force
      - name: This is step 2
        cmd: echo 'step2'
      - step3:
          name: Do msbuild task
          msbuild:
            project: .\MyProject.csproj
            targets: TransformConfigs
            properties: Configuration=Debug
    ```
    [See more about `[step]:` element](/doc/step.md)

* ### `depends_on:` **element**

  Contains list of named items which are assumed as other defined tasks in this `pwshake.yaml` config.

  Example:
  ```
  tasks:
    clean:
    - do_clean
    build:
      depends_on:
      - clean
      steps:
      - do_build
    test:
    - do_test
    publish:
      depends_on:
      - build
      - test
      steps:
      - do_publish
  ```
  This is a list of 4 named tasks, 2 of which are dependent of other 2, and **PWSHAKE** engine invokes them according to these dependencies and order.

  So, the execution order of the above tasks should be:
  ```
  PS>Invoke-pwshake -runLists publish
  ...
  Arranged tasks:
  - name: clean
    when: $true
    steps:
    - do_clean
    depends_on: []
  - name: build
    when: $true
    steps:
    - do_build
    depends_on: []
  - name: test
    when: $true
    steps:
    - do_test
    depends_on: []
  - name: publish
    when: $true
    steps:
    - do_publish
    depends_on: []
  ...
  ```
  It gives to **PWSHAKE** engine an ability to invoke ordered chains of tasks and\or to run composed tasks for reusing complex scenarios:

  ```
  tasks:
    complex_task:
    - do_one_thing
    - do_other_thing
    - do_long_named_thing
    build:
      depends_on:
      - complex_task
      steps:
      - do_build
    test:
      depends_on:
      - complex_task
      steps:
      - do_test
    publish:
      depends_on:
      - complex_task
      - build
      - test
      steps:
      - do_publish
    ```

    In this case the `complex_task` will be invoked before each other task invocation.
