![GitHub workflows (all tests)](https://github.com/wild-devops/pwshake/workflows/all%20tests/badge.svg)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/wild-devops/pwshake)
![PowerShell Gallery](https://img.shields.io/powershellgallery/v/pwshake)
![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/pwshake)

# PWSHAKE
Yet another maker based on modern **Powershell** (aka `pwsh` in `Linux` world) and `yaml` configurations.

# What's this?
Technically it's a movable **Powershell** module that helps to perform various operations for build, make, deploy, etc.

As well it's a simple script executor based on **Powershell**.

All executed scripts and\or inline **Powershell** commands are composed, instrumented with input data and structured by the `yaml` configuration.

# What's this NOT?
This is definitely not a piece of computer state\configuration management (aka **DSC**, **CM**, etc), despite it has basic concepts inspired by **Chef** (attributes, overrides, run lists\roles) and **Ansible** (`yaml` config).

# Why is this needed?
This is a try to implement [Protected variations principle](https://en.wikipedia.org/wiki/GRASP_(object-oriented_design)#Protected_variations) in the CI/CD world.

Since every CI-server (**GitLab**, **TeamCity**, **Circle**, **Travis**, etc) has its own definition for jobs, build configurations, dependencies, resources and artifacts, it makes sense to have some independent way doing the same in your own repository and using CI-servers only as entry points (starters) to your project's delivery pipeline.

# How do we use it in the real world?
We have to instantiate and provision lots of Windows hosts in the **AWS** cloud.

There are many roles that these hosts are performed (static\dynamic web sites, api hosts, windows services hosts, databases, etc).

Average time to live for most of them is during from 30 minutes (for auto-testing) to 1 week (for weekly production release, that recreates all prod instances from scratch).

So, we do not need to manage a big **snowflake** infrastructure and to care about managed **state** of it (say hello to **Chef** and **DSC**). Rather we need to organize a simple and robust way to make the full initial configuration of our hosts (quite complex in some cases) and to perform it only once per each host instantiation.

# Where is your own DSL?

All respectable makers or config managers have their own **DSL**, all those `knife`-s, `cookbook`-s, `recipe`-s and other `cucumber`-s.

The **PWSHAKE** is not an exception, but its **DSL** is based on simple concept of `templates:` and implemented via basic functionality of **PWSHAKE** engine: to read `yaml` configs, to compose `[hashtable]`-s from them and to execute `powershell:` commands.

[See about our **DSL**](/pwshake/templates)


# How to prepare **PWSHAKE** usage on Windows or Linux

* Create a new working directory

```
mkdir MyDir
cd MyDir
```

* Download a bootstrapper script `pwshake.ps1` from the root of this repo

```
curl -O https://raw.githubusercontent.com/wild-devops/pwshake/master/pwshake.ps1
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

* Start the bootstrapper `pwshake.ps1` script passing the file name as first argument:

```
PS>./pwshake.ps1 ./my_pwshake.yaml
```
This installs all required components from the `PSGallery` and invokes scripts according to the configuration file (`my_pwshake.yaml` in the current directory)

[See more about bootstrapper `pwshake.ps1` script](/doc/bootstrapper.md)


The result looks like the followed output including information about:
*  `PWSHAKE config:` - loaded config file content (may be rearranged due to overriding, interpolation, and merging metadata)
*  `Arranged tasks:` - tasks to be executed in actual order
*  `Invoke task:` - invoked tasks name
*  `Execute step:` - invoked steps caption
*  Everything else - invoked scripts output

```
PWSHAKE config:
tasks:
  hello:
  - powershell: Write-Host "Hello PWSHAKE!"
includes: []
templates: {}
attributes_overrides: []
scripts_directories:
- .
resources: []
invoke_tasks: hello
attributes:
  pwshake_module_path: /path/to/pwshake/module/source
  pwshake_path: /absolute/path/to/your/working/directory
  pwshake_version: 1.4.0
  work_dir: /absolute/path/to/process/working/directory
  pwshake_log_path: /absolute/path/to/your/working/directory/my_pwshake.log
  some_attribute: this is an attribute value

Arranged tasks:
- when: $true
  steps:
    powershell: Write-Host "Hello PWSHAKE!"
  depends_on: []
  work_dir: ""
  name: hello

Invoke task: hello
Execute step: step_66875131
Hello PWSHAKE!
```
## Test **PWSHAKE** by itself

Clone this repo, change current directory to the repo root folder.

Start the bootstrapper `./pwshake.ps1` script without any arguments passed:
```
PS>./pwshake.ps1
```
And it runs various tests and examples included in this repo.

**Prerequisites:**
Since some examples use third party cli tools, make sure that you have installed:
* python >v3.6
* git >v2.16
* dotnetcore-sdk >v2.2
* msbuild (for Windows only)

## See more about:
* [bootstrapper `pwshake.ps1` script](/doc/bootstrapper.md)
* [`pwshake.yaml` configuration file structure](/doc/config.md)
  * [`attributes:` element](/doc/attributes.md)
  * [`attributes_overrides:` element](/doc/attributes_overrides.md)
  * [`includes:` element](/doc/includes.md)
  * [`invoke_tasks:` element](/doc/invoke_tasks.md)
  * [`tasks:` element](/doc/tasks.md)
  * [`templates:` element](/doc/templates.md)
  * [implicit `[step]:` element](/doc/step.md)
  * [`scripts_directories:` element](/doc/scripts_directories.md)
  * [`resources:` element](/doc/resources.md)

## Happy **PWSHAKE**-ing!
