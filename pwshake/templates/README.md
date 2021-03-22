# Here is the kind of **PWSHAKE** DSL
Assumed good enough to start.

Technically the **PWSHAKE** doesn't need any **DSL** except the basic config structure.

[See more about `pwshake.yaml` configuration file structure](../../doc/config.md)

But as all programmers we are lazy enough to not type `Write-Output` when there is an ability to type `echo` despite the **echo** is the standard **Powershell** alias or **bash** command.

Obviously that this `yaml` config code is more readable and easy to type:
```
steps:
- echo: I'm lazy and smart
```

Rather than these:
```
steps:
- pwsh: Write-Output -InputObject 'I know powershell commands full syntax'
- shell: 'I know kung-fu' | echo
```

So, below are a few shortenings that can be useful in the `pwshake.yaml` configuration file instead of frequently used commands, steps or even some complex scenarios.

## **Built-in** `templates:` **element items**

* `cmd.yaml` - with `shell:` alias inside, redirects the input shell command text to built-in function that cares about exit codes, **stderr** output, exception handling, etc
* `directory.yaml` - to ensure that given directory exists
* `each.yaml` - simple iterator
* `echo.yaml` - just for fun
* `file.yaml` - simplification of files content manipulations
* `git.yaml` - simplification of git checkout operation, from the v1.4 implemented as real **DSL** via other templates composition
* `if.yaml` - for conditional templates composition
* `invoke_steps.yaml` - for groupping templates composition
* `invoke_tasks.yaml` - to invoke other tasks from the step inside of the current task
* `msbuild.yaml` - yes, it's our legacy tribute since we still have to use tons of **MsBuild** projects
* `script.yaml` - calling **Powershell** scripts, in the v1.0.0 this was an awful part of main code

[See more about `templates:` element](../../doc/templates.md) 

## **Moreover**
Built-in `templates:` element items are loaded into the **PWSHAKE** execution contex on early stage of the `yaml` config file processing.

After this the regular `templates:` element items defined in the current `yaml` config file are merged into the same context.

So, as the result of this merging there is an ability to override any built-in template based on your own decision.

Example:
```
PS> cat ./my_colored_echo.yaml
templates:
  echo:
    text: '...' # this is default
    color: DarkGreen # this is default
    powershell: |
      Write-Host (Coalesce $step.echo, $step.text) -ForegroundColor $step.color

tasks:
  print_me_in_green:
  - echo: I'm not green
  - echo:
  print_me_in_cyan:
  - echo:
      text:  I'm not cyan
      color: Cyan

invoke_tasks:
- print_me_in_green
- print_me_in_cyan
```
Output:
```
Invoke task: print_me_in_green
Execute step: echo_1
I'm not green
Execute step: echo_2
...
Invoke task: print_me_in_cyan
Execute step: echo_3
I'm not cyan
```
By those three dots you can see that your new inline template works correctly, but unfortunately **PWSHAKE** engine (at least in the current version) captures all commands outputs to save them into the log file and redirects the captured strings to user console via the dumb non-colored `$Host.UI.WriteLine()` (sorry).

Anyway, there are good news:
## The **PWSHAKE**'s **DSL** is really in your own hands!
