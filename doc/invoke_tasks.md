## `invoke_tasks:` **element**

**Optional**

Aliases: **`invoke_run_lists:`**, **`apply_roles:`**

Contains list of `tasks:` element named items, that **PWSHAKE** engine executes in order of this element contained enumeration. 

Example:
```
invoke_tasks:
- clean
- build
- test
- publish
```
This tells to **PWSHAKE** engine to invoke a `clean:` item from the `tasks:` element first, then a `build:` item, etc.

If the `invoke_tasks:` is omitted in `pwshake.yaml` config and isn't passed as a `-Tasks` parameter of the `pwshake.ps1` bootstrapper script (or `Invoke-pwshake` command), so **PWSHAKE** engine has nothing to do.

The `-Tasks` parameter value of the `pwshake.ps1` bootstrapper script (or `Invoke-pwshake` command) has strong precedence above the `invoke_tasks:` in the `pwshake.yaml` config and totally replaces this element content.

Example:
```
PS>cat ./pwshake.yaml
invoke_tasks:
- clean
- build
...
```
```
PS>Invoke-pwshake
PWSHAKE config:
...
invoke_tasks:
- clean
- build
```
```
PS>Invoke-pwshake -Tasks publish
PWSHAKE config:
...
invoke_tasks:
- publish
```

[See more about `tasks:`](/doc/tasks.md)

[See more about the `-Tasks` parameter of  bootstrapper `pwshake.ps1` script](/doc/bootstrapper.md)