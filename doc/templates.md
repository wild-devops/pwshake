## `templates:` **element**

**Optional**

Alias: **`actions:`**

Contains definitions of `[step:]` elements structure for reusing and syntax shortenings in the whole `pwshake.yaml` config.

This tells to **PWSHAKE** engine how to substitute any structured `yaml` input in step definitions into an executable **Powershell** command.

* ## `templates:` example
    ```
    PS>cat python.yaml
    templates:
      python:
        options: $[[$_.python]]
        inline:
        powershell: |
          if ($_.python -is [string]) {
            "python3 $($_.python)" | Cmd-Shell
          } elseif ($python.inline) {
            python3 -c $python.inline
          } elseif ($python.options) {
            "python3 $($python.options)" | Cmd-Shell
          } else {
            python3 --version
          }
    ```
    The given example can be used with regular `pwshake.yaml` config by including the template file `python.yaml` and using a new `python:` element as a regular step in `tasks:` definition.
    ```
    PS>cat hello.py
    import sys
    print("Hello " + sys.argv[1] + "!", file=sys.stdout, flush=True)

    PS>cat python_pwshake.yaml
    includes:
    - python.yaml

    tasks:
      test_python_template:
      - 'All defaults':
          python:
      - 'Give me a version please':
          python: --version
      - 'Inline python':
          python:
            inline: print('Hello pwshake!');
      - 'Explicit options':
          python:
            options: '{{pwshake_path}}/hello.py again'
      - 'Implicit options':
          python: '{{pwshake_path}}/hello.py twice'

    invoke_tasks:
    - test_python_template
    ```
    Output should look like the following:
    ```
    PS>Invoke-pwshake ./python_pwshake.yaml
    ...
    Invoke task: test_python_template
    Execute step: All defaults
    Python 3.6.8
    Execute step: Give me a version please
    bash: python3 --version
    Python 3.6.8
    Execute step: Inline python
    Hello pwshake!
    Execute step: Explicit options
    bash: python3 /workdir/examples/5.templates/v1.2/hello.py again
    Hello again!
    Execute step: Implicit options
    bash: python3 /workdir/examples/5.templates/v1.2/hello.py twice
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
      # execute cmd.exe shell command on Windows host
      - cmd: 'dir /b'
      # ensure that given directory exists in the current {{work_dir}}
      - directory: .test_results
      # iterates 'items:' elements and pass each of them to the 'action:' as Powershell command or template call
      - each:
          items:
          - Hello
          - PWSHAKE
          action: echo $_
      # writes text to host output
      - echo: 'Hello PWSHAKE!'
      # writes text to the given file by 'path:', 'content:' and optionally 'encoding:' values
      - file:
          path: 'test.json'
          content: '{"I":"m","a":"test"}'
          encoding: Ascii # default is UTF8
      # performs git checkout from the given 'source:' repo to the relational 'target:' directory
      - git:
          source: https://github.com/wild-devops/pwshake.git
          ref: v1.0.0
          directories:
          - examples
          - doc
          target: .old_repo
      # performs conditional executing for lists of provided steps
      - if:
          condition: true
          then:
          - echo: true
          else:
          - echo: false
          - pwsh: throw 'Good bye!'
      # performs unconditional executing for list of provided steps
      - invoke_steps:
        - echo: List
        - cmd: echo of
        - pwsh: echo other
        - shell: echo steps
      # performs unconditional executing for list of provided tasks
      - invoke_tasks:
        - list_of
        - tasks_to_execute
      # run msbuild.exe with given attributes
      - msbuild:
          project: 'MySolution.sln'
          targets:
          - Clean
          - Build
          properties:
          - Configuration=Release
          - SolutionDir=.
          options: /m
      # run Powershell script with name tasks_to_execute.ps1 found in {{work_dir}} or 'scripts_directories:' items related to {{pwshake_path}}
      - script: tasks_to_execute
      - tasks_to_execute # <<< this is shortened form 
      # execute bash shell command on Linux host
      - shell: 'ls .'
      # create symbolic links for each key of provided hashtable with target of its values
      - symlinks:
          link1: target1
          'link 2': target 2
      # transform xml file by given 'path:' and items of hashtables with XPath keys and [string] values to apply
      - xml-file:
          path: test.xml
          # xmlns:
          # - 'q': 'uri:my-config-xml-file'
          inserts:
          - '/xml': '<five six="seven"/>'
          - '/xml/five[1]': '<eight nine="wrong"/>'
          - '//one': 'count="zero"'
          updates:
          - '/xml/two/@three': 'four'
          - '//@nine': 'ten'
          deletes:
          - '/xml/six[@seven="wrong"]':

    ```
    All these steps above are actually substituted templates which are loaded from [this location](/pwshake/templates).

