## - `[step]:` **element**

Contains definition of the full explicitly described structure that **PWSHAKE** engine uses to find, distict, execute and log during the `pwshake.yaml` config processing.

The internal representation of a single **step** looks like a following **Powershell** `[hashtable]`:
```
@{
  name = $null;
  script = $null;
  powershell = $null;
  cmd = $null;
  msbuild = @{
    project = $null;
    targets = $null;
    properties = $null;
  };
  when = "`$true";
  invoke_tasks = $null;
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

So, the full allowed form of the `- [step]:` element could be the following:
```
- name: step name
  script: script_name
  powershell: "some inline powershell code"
  cmd: "other inline cmd.exe commands"
  msbuild:
    project: some_project_file_name
    targets: "List,Of,Targets"
    properties: "MyProperty=Assigned"
  when: $true
...
```
But **PWSHAKE** engine take pecedence over the given structure items and executes only the first non empty item, in this case `script:` item with '`script_name`' value, all others (`powershell:`, `cmd:`, `msbuild:`) are ignored.

* ### - `[step]:` element implicit shortenings
  Since the actual payload in the executed structure have only the two elements:
  * `name:`
  * first non empty of `[script: | powershell: | cmd: | msbuild:]`

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
  - some_really_useless_string_identifier:
      name: step1
      script: step1
  ```
  On other hand:
  ```
  - my_beauty_named_step:
      script: your_ugly_named_script
  ```
  This is the same as:
  ```
  - name: my_beauty_named_step
    script: your_ugly_named_script
  ```
  This ability is useful for composing readable configs with many tasks of the similar type.

  Example:
  ```
  - name: Get dependencies
    cmd: npm i
  - name: Run tests
    cmd: npm run coverage
  - name: Deploy package
    cmd: npm publish
  ```
  
* ### - `[msbuild]:` element implicit shortenings
  All things described above are eligible for the `msbuild:` element.


  Since the actual payload of this element is the **MSBuild** project file name, so the shortening syntax use this value as a `project:` element value.

  Example:
  ```
  - name: Build
    msbuild: some_project_file_name
  ```
  This is actually the same as:
  ```
  - name: Build
    msbuild:
      project: some_project_file_name
  ```

* ### - `[powershell|cmd]:` element implicit shortenings
  Since the `[powershell|cmd]:` elements contain inline code that can be too long and\or complex to use it as the meaningful name, so the `name:` property for these shortenings is generated from the `.GetHashCode()` method of the supplied inline string to distinct each other inline step  in the **PWSHAKE** engine log.

  Example:
  ```
  - powershell: rm ./ -recurse -force
  ```
  This is the same as:
  ```
  - name: pwshake_2122574676
    powershell: rm ./ -recurse -force
  ```

* ### - `[when|only|except|skip_on]:` element implicit shortenings
  Since the `[when|only|except|skip_on]:` elements contain inline code that evaluated by **PWSHAKE** engine to make a decision whether or not to execute a particular **step** they can be omitted in general because of the default value is always set to `$true` (`-not ($true) ` for negation aliases `except:`, `skip_on:`).

  Example:
  ```
  - powershell: rm ./ -recurse -force
  ```
  This is the same as:
  ```
  - name: pwshake_2122574676
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
  - name: pwshake_2122574676
    powershell: rm ./ -recurse -force
    when: -not ($env:SOME_VALUE -eq '42')
  ```

* ### - `[invoke_tasks]:` element explicit content
  
  Since the `[invoke_tasks]:` element contains a list of items from the `tasks:` element it has not shortening syntax and should be populated as a regular `yaml` list of strings.
  
  Example:
  ```
  do_it_all:
  - invoke_tasks:
    - clean
    - build
    - test
    - deploy
  ```
  This is useful for implementation of conditional scenarios inside run lists execution.
    
  Example:
  ```
  - step:
      name: Do all stuff if solution file is present
      scripts:
      - powershell: $skip_it_all = -not (Test-Path MySolution.sln)
      - skip: $skip_it_all
        invoke_tasks:
        - clean
        - build
        - test
        - deploy
  ```
