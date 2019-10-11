## `scripts_directories:` **element**

Contains list of directories relative to the `pwshake.yaml` config file location (which is also the `pwshake_path:` attribute value) where **PWSHAKE** engine looks for `scripts:` defined as items of the `tasks:` element.

Example:
```
scripts_directories:
- .
- test
- tools
```
This element can be totally omitted, in that case all `scripts:` will be looked for in the `pwshake_path:` directory.

[See more about `tasks:`](/doc/tasks.md)
