## `attributes_overrides:` **element**

Contains list of named items which determine order and content of **metadata** that will be merged into the `attributes:` element before **PWSHAKE** engine starts execution of the `invoke_tasks:` element content.

Example:
```
attributes_overrides:
- local
- test
- stage
- prod
```
The above settings tells to **PWSHAKE** engine to look for files named `local.yaml`,  `test.yaml`,  `stage.yaml`,  `prod.yaml` in the directoty `./attributes_overrides` relative to the `pwshake.yaml` config location (which is also the `pwshake_path:` attribute value).

If such file exists **PWSHAKE** engine merge each of them content with the `attribites:` element value in order as listed.

In results the `attribites:` element values will be overriden according to requirements of particular environment, role, host, instance, etc.

## `override_to:` **attributes item**
The `attribites:` element can contain a special named item `override_to:` which defines when to stop iterating the list of `attributes_overrides:` items to perform overriding.

It can be passed outside of the `pwshake.yaml` config as a part of the `-MetaData` parameter.

Example, given files:
```
PS>cat ./attributes_overrides/local.yaml
env_name: lds
```
```
PS>cat ./attributes_overrides/test.yaml
env_name: fi1438
```
```
PS>cat ./attributes_overrides/prod.yaml
env_name: lwfw-3er54c0
```
```
PS>cat ./pwshake.yaml
attributes:
  env_name: undefined
attributes_overrides:
- local
- test
- prod
...
```

Below are several **PWSHAKE** engine runs with the given configuration:

Iterating never stopped, since the `override_to:` is not set, so the resultig `env_name:` value comes from the last override (`prod.yaml`):
```
PS>Invoke-pwshake
PWSHAKE config:
attributes:
  env_name: lwfw-3er54c0
...
```
Iterating stopped after the first override (`local.yaml`):
```
PS>Invoke-pwshake -MetaData 'override_to=local'
PWSHAKE config:
attributes:
  env_name: lds
...
```
Iterating stopped after the second override (`test.yaml`):
```
PS>Invoke-pwshake -MetaData 'override_to=test'
PWSHAKE config:
attributes:
  env_name: fi1438
...
```
Iterating stopped after the third override (`prod.yaml`) that is equivalent of the first example since the `-prod` is the last item in the `attributes_overrides:` list:
```
PS>Invoke-pwshake -MetaData 'override_to=prod'
PWSHAKE config:
attributes:
  env_name: lwfw-3er54c0
...
```

[See more about the `-MetaData` parameter of  bootstrapper `pwshake.ps1` script](/doc/bootstrapper.md)