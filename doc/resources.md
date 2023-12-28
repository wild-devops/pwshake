## **`resources:` element**

**Optional**

Alias: **`repositories:`**

Contains list of executable steps that all invoked before the current `yaml` config processing starts by the **PWSHAKE** engine.

The results of these invocations can be used in the current `yaml` config file processing.

Example:
```
PS>cat ./examples/7.resources/v1.3/resources_pwshake.yaml
resources:
- git:
    repo: https://github.com/wild-devops/pwshake.git
    ref: v1.0.0
    directories:
    - examples
    - doc
    target: .old_repo

includes:
- .old_repo/examples/hello_pwshake.yaml
```
In the example above the initial step described in the `resources:` element invokes built-in `git:` step template that performs the following:
* initiates an empty git repo in the `target:` directory relational to the `{{pwshake_path}}` (the current `yaml` config file location)
* checks out the particular `ref:` (tag v1.0.0 in this case) from the given `repo:`
* if there are `directories:` list elements - makes sparse checkout only for the listed directories.

Further the regular `includes:` element can use  the result of resources loading, in this case reusage by including any file that exists in the `.old_repo` directory.

Since the `.old_repo/examples/hello_pwshake.yaml` contains some meaningful content it is merged with the current `yaml` config and **PWSHAKE** engine invokes tasks defined in the included file.

This particular example is quite artificial, but it demonstrates the concept of outer resources loading and using.

The main scenario when it can be useful - to have some shared repo with reusable scripts (configs, inline step templates) and use it in various `yaml` configs placed to other repos.
