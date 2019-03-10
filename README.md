<p align="center">
    <img src="https://github.com/giann/fourmi/raw/master/assets/logo.png" alt="fourmi" height="304">
</p>


# fourmi
🐜 A small taskrunner that harnesses the power of Lua's metamethods to easily express flow of tasks.

**Note:** Fourmi is in active development.

## Installation

Requirements:
- Lua 5.3
- luarocks >= 3.0 (_Note: `hererocks -rlatest` will install 2.4, you need to specify it with `-r3.0`_)

```bash
luarocks install --server=http://luarocks.org/dev fourmi
```

## Usage

Write a [fourmi.plan.lua](#plan) file in your project directory and then:

```bash
# If `plan` is not provided, will run plan named `all`
fourmi [--file <file>] [-h] <plan> [<arguments>] ...
```

## Task

Task are relatively small jobs that you can combine using operators.

```lua
local mytask = task "mytask"
    :description "A short description of what it does"
    :property("propertykey", propertyvalue)
    :perform(function(self, ...)
        -- Do something with ...

        return output1, ..., ouputn
    end)
```

### Operators

- **`task1 .. task2`**: returns a new task that does `task1` then `task2`
- **`task1 & task2`**: returns a new task that does `task2` has output, pipes it to `task2`
- **`task1 | task2`**: returns a new task that does `task2` only if `task1` returns falsy value
- **`task1 >> task2`**: returns a new task that pipes `task1` into `task2`
- **`task1 * task2`**: returns a new task that does `task2` for all output of `task1`
- **`task1 ^ (condition)`**: returns a new task that does `task1` if `condition` (expression or function to be evaluated) is true

Here's an commented excerpt of [`fourmi.plan.lua`](https://github.com/giann/fourmi/blob/master/example-fourmi.plan.lua):

```lua
return {
    -- Default plan
    plan "all"
        -- Small description of what the plan does
        :description "Minify and gzip lua files"
        -- Define its task
        :task(
            -- List files in `./fourmi` ending with `.lua`
            ls("./fourmi", "%.lua$")
                -- For each of them: if the gzipped file does not exist or is older than the original,
                -- minify then gzip then move to `~/tmp-code`
                * (outdated "~/tmp-code/#{original}.gz"
                    & minify >> gzip >> mv "~/tmp-code")
        ),

    -- Clean plan
    plan "clean"
        :description "Cleanup"
        :task(
            -- Remove all files from `~/tmp-code`
            empty "~/tmp-code"
        )
}
```

<p align="center">
    <img src="https://github.com/giann/fourmi/raw/master/assets/result.png" alt="fourmi">
</p>


If you don't want to use operators, you can use their aliases:
- **`..`**: after
- **`&`**: success
- **`|`**: failure
- **`>>`**: into
- **`~`**: ouput
- **`*`**: each
- **`^`**: meet
