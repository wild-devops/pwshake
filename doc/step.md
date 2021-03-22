## - `[step]:` **element**

**Optional**

Contains definition of the full explicitly described structure that **PWSHAKE** engine uses to find, distinct, execute and log during the `pwshake.yaml` config processing.

The internal representation of a single **step** looks like a following **Powershell** `[hashtable]`:
```
@{
  name = $null;
  when = "`$true";
  work_dir = $null;
  on_error = "throw";
  powershell = $null;
}
```

So, the following part of the `pwshake.yaml` config file:
```
- step1:
    name: step name
    script: script_name
...
```
will be transformed into the following structure:
```
@{
  name = "step name";
  when = "`$true";
  work_dir = $null;
  on_error = "throw";
  powershell = $null;
  script = "script_name";
}
```
Pay attention that the `step1` identifier itself does not bring any actual value to the executed structure and can be omitted via `yaml` syntax as shown below:
```
- name: step name
  script: script_name
...
```
In this case the `-` sign means that subsequent items in `yaml` hierarchy are keys of the same **Powershell** `[hashtable]`.

* ## - `[step]:` element implicit shortenings
  Since the actual payload in the executed structure have only the two elements:
  * `name:`
  * first non empty of `[script: | powershell: | cmd:]`

  There are allowed some implicit shortenings in the `[step]:` element `yaml` syntax.

  Example:
  ```
  - step1
  ```
  This is the same as:
  ```
  - name: step1
    script: step1
  ```
  Or even the same as:
  ```
  - some_really_useless_step_identifier:
      name: step1
      script: step1
  ```
  On other hand:
  ```
  - my_beauty_named_step:
      script: your_ugly_named_script
  ```
  Above is the same as:
  ```
  - name: my_beauty_named_step
    script: your_ugly_named_script
  ```
  This ability is useful for composing readable configs with many tasks of the similar type.

  Example:
  ```
  - 'Get dependencies':
      cmd: npm i
  - 'Run tests':
      cmd: npm run coverage
  - 'Deploy package':
      cmd: npm publish
  ```

* ### - `powershell:` element implicit shortenings
  Since the `powershell:` element contains inline code that can be too long and\or complex to use it as the meaningful name, so the `name:` property for these shortenings is generated from the step type and incremented number to distinct each other inline step in the **PWSHAKE** execution log.

  Example:
  ```
  - pwsh: rm ./ -recurse -force
  ```
  This is the same as:
  ```
  - name: pwsh_1
    powershell: rm ./ -recurse -force
  ```

* ### - `msbuild:` element implicit shortenings
  All things described above are eligible for the `msbuild:` element.


  Since the actual payload of this element is the **MSBuild** project file name, so the shortening syntax use this value as a `project:` element value.

  Example:
  ```
  - Build:
      msbuild: some_project_file_name
  ```
  This is actually the same as:
  ```
  - name: Build
    msbuild:
      project: some_project_file_name
  ```

* ### - `[when|only|except|skip_on]:` element implicit shortenings
  Since the `[when|only|except|skip_on]:` elements contain inline code that evaluated by **PWSHAKE** engine to make a decision whether or not to execute a particular **step** they can be omitted in general because of the default value is always set to `$true` (`-not ($true) ` for negation aliases `except:`, `skip_on:`).

  Example:
  ```
  - powershell: rm ./ -recurse -force
  ```
  This is the same as:
  ```
  - name: step_1
    powershell: rm ./ -recurse -force
    when: $true
  ```

  The only case when `[when|only|except|skip_on]:` elements should be populated is the requirement to evaluate some condition for the **step** execution.
  
  Example:
  ```
  - powershell: rm ./ -recurse -force
    skip_on: $env:SOME_VALUE -eq '42'
  ```
  This is the same as:
  ```
  - name: powershell_2
    powershell: rm ./ -recurse -force
    when: -not ($env:SOME_VALUE -eq '42')
  ```

* ### - `invoke_tasks:` element explicit content
  
  Since the `invoke_tasks:` element contains a list of items from the `tasks:` element it has not shortening syntax and should be populated as a regular `yaml` list of strings.
  
  Example:
  ```
  do_it_all:
  - invoke_tasks:
    - clean
    - build
    - test
    - deploy
  ```
  This is useful for implementation of conditional scenarios inside tasks execution.
    
  Example:
  ```
  tasks:
    clean:
    build:
    test:
    deploy:
    'Do all stuff if solution file is present':
      scripts:
      - powershell: $script:skip_it_all = -not (Test-Path MySolution.sln)
      - skip_on: $skip_it_all
        invoke_tasks:
        - clean
        - build
        - test
        - deploy
  ```
