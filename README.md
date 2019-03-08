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
    :option("optionkey", optionvalue)
    :perform(function(self, ...)
        -- Do something with ...

        return output1, ..., ouputn
    end)
```

### Operators

- **`task1 .. task2`**: returns a new task that does `task1` then `task2`
- **`task1 & task2`**: returns a new task that does `task2` if `task1` returns truthy value
- **`task1 | task2`**: returns a new task that does `task2` only if `task1` returns falsy value
- **`task1 >> task2`**: returns a new task that pipes `task1` into `task2`
- **`task1 ~ task2`**: returns a new task that, if `task1` has output, pipes it to `task2`
- **`task1 * task2`**: returns a new task that does `task2` for all output of `task1`
- **`task1 ^ (condition)`**: returns a new task that does `task1` if `condition` (expression or function to be evaluated) is true

Here's an commented excerpt of [`fourmi.plan.lua`](https://github.com/giann/fourmi/blob/master/example-fourmi.plan.lua):

```lua
return {
    -- Default plan to execute
    plan "all"
        -- Define its task
        :task(
            -- List files that ends with `.lua`
            ls:opt("mask", "%.lua$")
            * -- For each of them do the following
            (
                -- Minify then gzip
                (minify:opt("out", __"${HOME}/tmp-code") >> gzip)
                    -- Only if gzip file are not already there
                    ^ function(file)
                        return outdated(
                            file,
                            __"${HOME}/tmp-code/" .. file:gsub("%.lua$", ".min.lua.gz")
                        )
                    end
            )
        ),

    -- To call this plan do: `fourmi clean`
    plan "clean"
        :task(
            (
                -- List files that ends with `.lua`
                ls:opt("mask", "%.lua$")
                >>
                -- Transform file.lua to file.min.lua.gz
                map:opt("map" , function(element)
                    local mapped = element:gsub("%.lua$", ".min.lua.gz")
                    return mapped
                end)
            )
            * -- Remove each of them
            rm:opt("dir", __"${HOME}/tmp-code")
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
