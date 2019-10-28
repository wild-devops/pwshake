## `templates:` **element**
Contains definitions of `step:` elements structure for reusing and syntax shortenings in the whole `pwshake.yaml` config.

This tells to **PWSHAKE** engine how to substitute any structured `yaml` input in step definitions into an executable **Powershell** command.

* ## `templates:` example
    ```
    PS>cat python.yaml
    templates:
      python:
        file:
        inline:
        powershell: |
          if ($step.python) {
            "python $($step.python)" | Cmd-Shell
          } elseif ($step.file) {
            "python $($step.file)" | Cmd-Shell
          } elseif ($step.inline) {
            python -c $step.inline
          } else {
            python --version
          }
    ```
    The given example can be used with regular `pwshake.yaml` config by including the template file `python.yaml` and using a new `python:` element as a regular step in tasks definition.
    ```
    PS>cat hello.py
    import sys
    print("Hello " + sys.argv[1] + "!", file=sys.stdout, flush=True)

    PS>cat python_pwshake.yaml
    includes:
    - python.yaml

    tasks:
      test_python_template:
      - python:
      - python: --version
      - python:
          inline: print('Hello pwshake!');
      - python:
          file: |
            {{pwshake_path}}/hello.py again
      - python: '{{pwshake_path}}/hello.py twice'

    invoke_tasks:
    - test_python_template
    ```
    Output should look like the following:
    ```
    PS>Invoke-pwshake ./python_pwshake.yaml
    ...
    Invoke task: test_python_template
    Execute step: step_25540982
    Python 3.6.8
    Execute step: step_8493528
    bash: python --version
    Python 3.6.8
    Execute step: step_46664441
    Hello pwshake!
    Execute step: step_6213368
    bash: python /workdir/examples/templates/hello.py again

    Hello again!
    Execute step: step_32712664
    bash: python /workdir/examples/templates/hello.py twice
    Hello twice!
    ```

* ## Implicit built-in `templates:`
    
    Some built-in `[step:]` template definitions are already included into the **PWSHAKE** module and loaded during the **PWSHAKE** engine initialization.

    So, they can be used in regular `pwshake.yaml` config without including either as external files or `templates:` element items.

    Examples:
    ```
    PS>cat some_pwshake.yaml
    ...
    tasks:
      - cmd:
      - shell:
      - msbuild:
      - script:
      - invoke_tasks:
    ```
    All these steps above are actually substituted templates which are loaded from [this location](/pwshake/templates).

