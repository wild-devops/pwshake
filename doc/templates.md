## `templates:` **element**

**Optional**

Aliase: **`actions:`**

Contains definitions of `[step:]` elements structure for reusing and syntax shortenings in the whole `pwshake.yaml` config.

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
      - 'Run python':
          python: --version
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
    Execute step: python_1
    Python 3.6.8
    Execute step: Run python
    bash: python --version
    Python 3.6.8
    Execute step: python_2
    Hello pwshake!
    Execute step: python_3
    bash: python /workdir/examples/5.templates/v1.2/hello.py again

    Hello again!
    Execute step: python_4
    bash: python /workdir/examples/5.templates/v1.2/hello.py twice
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
      - cmd: 'dir /b'
      - directory: .test_results
      - each:
          items:
            - Hello
            - PWSHAKE
          action: echo $_
      - echo: 'Hello PWSHAKE!'
      - file:
          path: 'test.json'
          content: '{"I":"m","a":"test"}'
          encoding: Ascii # default is UTF8
      - git:
          source: https://github.com/wild-devops/pwshake.git
          ref: v1.0.0
          directories:
            - examples
            - doc
          target: .old_repo
      - if:
          condition: true
          then:
            - echo: true
          else:
            - echo: false
            - pwsh: throw 'Good bye!'
      - invoke_steps:
          - echo: List
          - cmd: echo of
          - pwsh: echo other
          - shell: echo steps
      - invoke_tasks:
          - list_of
          - tasks_to_execute
      - msbuild:
          project: 'MySolution.sln'
          targets:
            - Clean
            - Build
          properties:
            - Configuration=Release
            - SolutionDir=.
          options: /m
      - script: tasks_to_execute
      - shell: 'ls .'
    ```
    All these steps above are actually substituted templates which are loaded from [this location](/pwshake/templates).

