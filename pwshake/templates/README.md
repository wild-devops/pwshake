# Here the kind of **PWSHAKE** DSL
Assumed good enough to start.

Technically the **PWSHAKE** don't need any **DSL** except the basic config structure.

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
* `echo.yaml` - just for fun
* `file.yaml` - simplification of files content manipulations
* `git.yaml` - simplification of git checkout operation
* `invoke_tasks.yaml` - to invoke other tasks from the step inside of the current task
* `msbuild.yaml` - yes, it's our legacy tribute since we still have tons of **MsBuild** projects
* `script.yaml` - in the v1.0.0 this was an awful part of main code

[See more about `templates:` element](../../doc/templates.md) 