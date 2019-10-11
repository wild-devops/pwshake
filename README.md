# PWSHAKE
Yet another maker based on modern **Powershell** (aka `pwsh` in `Linux` world) and `yaml` configurations.

# What's this?
Technically it's a movable **Powershell** module that helps to perform various operations for build, make, deploy, etc.

As well as it's a simple script executor based on **Powershell**.

## How to prepare **PWSHAKE** usage on Windows or Linux

* Create a new working directory

```
mkdir MyDir
cd MyDir
```

* Clone this repo

```
git clone https://github.com/wild-devops/pwshake.git .
```
  
* Create a new file with name `my_pwshake.yaml`

```
touch my_pwshake.yaml
```
* Populate the `my_pwshake.yaml` with required configuration

```
# Attributes are used as common parameters source for executable scripts
attributes:
  some_attribute: this is an attribute value

# List of directories relative to this file location where executable scripts are looking for (can be omitted)
scripts_directories:
  - .

# Declaration of tasks that compose and determine order of executing for scripts
tasks:
  hello:
  - powershell: Write-Host "Hello PWSHAKE!"

# Tasks to current execute
invoke_tasks:
- hello

```

* Start the bootstrapper `pwshake.ps1` script passing the file name as first arguments:

```
PS>./pwshake.ps1 ./my_pwshake.yaml
```
This installs all required components from the `PSGallery` and invokes scripts according to the configuration file (`my_pwshake.yaml` in the current directory)

[See more about bootstrapper `pwshake.ps1` script](../doc/bootstrapper.md)


The result looks like the followed output including information about:
*  `PWSHAKE config:` - loaded config file content (may be rearranged)
*  `Arranged tasks:` - run lists to be executed in order
*  `Invoke task:` - invoked run list names
*  `Execute <step|powershell|cmd|msbuild>:` - invoked script info
*  Everything else - invoked scripts outputs

```
PWSHAKE config:
tasks:
  hello:
  - powershell: Write-Host "Hello PWSHAKE!"
includes: []
attributes_overrides: []
scripts_directories: .
invoke_tasks: hello
attributes:
  pwshake_module_path: /path/to/pwshake/module/source
  pwshake_path: /absolute/path/to/your/working/directory
  pwshake_version: <current.pwshake.version>
  work_dir: /absolute/path/to/process/working/directory
  hello: Hello PWSHAKE!
  pwshake_log_path: /absolute/path/to/your/working/directory/hello_pwshake.log

Arranged tasks:
- when: $true
  steps:
    powershell: Write-Host "Hello PWSHAKE!"
  depends_on: []
  work_dir: ""
  name: hello

Invoke task: hello
Execute step: step_66875131
powershell: {Write-Host "Hello PWSHAKE!"}
Hello PWSHAKE!
```
## Test **PWSHAKE** by itself

Start the bootstrapper `pwshake.ps1` script without any arguments passed:
```
PS>./pwshake.ps1
```
And it runs various tests included in this repo.

## See more about:
* [bootstrapper `pwshake.ps1` script](../doc/bootstrapper.md)
* [`pwshake.yaml` configuration file structure](../doc/config.md)
  * [`attributes:` element](../doc/attributes.md)
  * [`attributes_overrides:` element](../doc/attributes_overrides.md)
  * [`includes:` element](../doc/includes.md)
  * [`invoke_tasks:` element](../doc/invoke_tasks.md)
  * [`tasks:` element](../doc/tasks.md)
    * [implicit `[step]:` element](../doc/step.md)
  * [`scripts_directories:` element](../doc/scripts_directories.md)

## Happy **PWSHAKE**-ing!
