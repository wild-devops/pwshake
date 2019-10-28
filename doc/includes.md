## `includes:` **element**

**Optional**

Contains list of file paths relational to the main `pwshake.yaml` that will be merged into the main config before **PWSHAKE** engine starts execution. It's useful for splitting long configurations to several meaningful parts.

Files named `attributes.[json|yaml]` will be merged directly into the `attributes:` element of the main `pwshake.yaml` config.

Example:
```
PS>cat attributes.json
{
    "my_attr": "some_value"
}
```
```
PS>cat pwshake.yaml
includes:
    - attributes.json
```
```
PS>Invoke-pwshake
PWSHAKE config:
attributes:
    my_attr: some_value
...
```

Files listed in the `includes:` element are merged in order of the sequence and can override the main `pwshake.yaml` config values.

Example:
```
PS>cat module.yaml
tasks:
 some_task: task1
```
```
PS>cat pwshake.yaml
includes:
  - module.yaml
tasks:
 some_task: empty
```
```
PS>Invoke-pwshake
PWSHAKE config:
...
tasks:
 some_task: task1
...
```

Lists defined in included files are merged by addition its items to the previous merged list excluding existed items.

Example:
```
PS>cat module1.yaml
scripts_directories:
 - dir1
```
```
PS>cat module2.yaml
scripts_directories:
 - dir1
 - dir2
 - dir3
```
```
PS>cat module3.yaml
scripts_directories:
 - dir3
 - dir4
 - dir5
```
```
PS>cat pwshake.yaml
includes:
  - module1.yaml
  - module2.yaml
  - module3.yaml
```
```
PS>Invoke-pwshake
PWSHAKE config:
...
scripts_directories:
 - dir1
 - dir2
 - dir3
 - dir4
 - dir5
...
```
Every included file can contain its own list of `includes:`, so nested inclusion is allowed.

Each item in `includes:` will be looked for in folders relative to the `yaml` file that contains current `includes:` element.