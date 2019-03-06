# fourmi
🐜 A small taskrunner written in Lua

```lua
return (
    ls                                                            -- List files
    *                                                             -- For all of them do this
    (filter:opt {                                                 -- Only on *.lua files
            pattern = "%.lua$",
            quiet = true
        }
        ~ (prefix:opt {                                           -- Prefix with path
                prefix = path .. "/",
                quiet = true
            }
            >> minify:opt("out", os.getenv "HOME" .. "/tmp-code") -- Minify
                >> gzip))                                         -- Gzip
)(path)
```

<p align="center">
    <img src="https://github.com/giann/fourmi/raw/master/example/result.png" alt="fourmi">
</p>
