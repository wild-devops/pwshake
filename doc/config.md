## Main elements of **PWSHAKE** configuration file

* ### **`attributes:` element**
    Required

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
    Contains definition of data that passed into executable scripts as a single parameter.

    This parameter should be of type **Powershell** `[hashtable]` that allows to **merge**, **interpolate** and **override** contained values during **PWSHAKE** execution.

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
    [See more about `attributes:`](/doc/attributes.md)

* ### **`includes:` element**
    Optional
    ```
    includes:
      - attributes.json
      - pwshake-ci\start-stage.yaml
      - pwshake-ci\stop-stage.yaml
    ```
    Contains list of file paths relational to the main `pwshake.yaml` that will be merged into the main config before **PWSHAKE** engine starts execution. It's useful for splitting long configurations to several meaningful parts.

    [See more about `includes:`](/doc/includes.md)
    

* ### **`tasks:` element**

  Aliases: **`tasks:`**, **`roles:`**

  Required

  ```
  tasks:
    clean:
      steps:
      - powershell: rm ./results -r -force
    build:
    - run_build_script
    test:
    - powershell: dotnet test
    publish:
    - cmd: |
      python.exe ./tools/some_script.py --with long ^
      --list of --options that --doesnt feet ^
      --to single_line
  ```
  Contains definition of composed and interdependent tasks that will be performed by **PWSHAKE** engine by executing `steps:` defined as `tasks:` items.

  [See more about `tasks:`](/doc/tasks.md)

* ### **`invoke_tasks:` element**

  Aliases: **`invoke_tasks:`**, **`apply_roles:`**

  Required

  ```
  invoke_tasks:
  - clean
  - build
  - test
  - publish
  ```
  Tells to **PWSHAKE** engine about consist and order of execution items defined in the `tasks:` element.

  [See more about `invoke_tasks:`](/doc/invoke_tasks.md)

* ### **`scripts_directories:` element**
    Optional

    ```
    scripts_directories:
    - .
    - test
    - tools
    ```
    Tells to **PWSHAKE** engine where to find scripts defined as items of the `tasks:` element.

    [See more about `scripts_directories:`](/doc/scripts_directories.md)

* ### **`attributes_overrides:` element**
    Optional

    ```
    attributes_overrides:
    - local
    - test
    - stage
    - prod
    ```
    Tells to **PWSHAKE** engine about list of `metadata` files and order of overriding `attributes:` in the main `pwshake.yaml` config file before the actual execution.
    
    [See more about `attributes_overrides:`](/doc/attributes_overrides.md)