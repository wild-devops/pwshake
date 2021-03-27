## `filters:` **element**

**Optional**

Contains definitions of small functions that will be loaded into the **PWSHAKE** execution context.

These functions will be used into the  **PWSHAKE** processing as attributes interpolators or helpers.

Added functions are actually of the **Powershell** `filter` type, so they have some peculiarities:

* have to take the first argument from  **Powershell** pipeline
* have the only `process` stage (block) in  **Powershell** execution
* have the first argument taken from pipeline is referred as `$_` variable in the `process` stage (block)

Example:
```
PS>cat pwshake.yaml
attributes:
    my_attr: '{{$capsed:my_attr_value}}'
    the_same_as: '{{$("my_attr_value" | f-$capsed)}}'
    sq_braced: '{{$("{{my_attr}}" | sq-braced)}}'
filters:
  f-$capsed: |-
    { "$_".ToUpper() }
  sq-braced: |-
    { "[$_]" }
...
```
```
PS>Invoke-pwshake
PWSHAKE config:
attributes:
    my_attr: MY_ATTR_VALUE
    the_same_as: MY_ATTR_VALUE
    sq_braced: '[MY_ATTR_VALUE]'
...
```

Note that if the filter name starts with `f-$` chars it could be used to interpolate attributes.

In this case the text following of `:` is passed to the filter as the first argument and result of the filter execution is substituted as the attribute value.
