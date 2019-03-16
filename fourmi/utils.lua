local function flatten(t, flat, seen)
    flat = flat or {}
    seen = seen or {}

    seen[t] = true

    for _, v in ipairs(t) do
        if type(v) == "table" and not seen[v] then
            flatten(v, flat, seen)
        else
            table.insert(flat, v)
        end
    end

    return flat
end

---
-- Recursive string interpolation helper
--   - `${VARIABLE}` -> `os.getenv "VARIABLE"`
--   - `#{variable}` -> `variable` in `context` or caller locals or `_G`
--   - `~` -> `os.getenv "HOME"`
--   - `@{variable}` -> `_G.__fourmi.vars[variable]`
-- @tparam string str String to interpolate
-- @tparam[opt] table context Table in which to search variables to interpolates
-- @treturn string
local function __(str, context)
    -- No context provided, build one from caller locals
    if not context and str:match "#{([A-Za-z_]+[A-Za-z_0-9]*)}" then
        context = {}
        local l = 1
        local key, value

        repeat
            key, value = debug.getlocal(2, l)
            l = l + 1

            if key ~= nil then
                context[key] = value
            end
        until not key
    end

    -- Interpolate ${}
    local env
    repeat
        env = str:match "%${([A-Za-z_]+[A-Za-z_0-9]*)}"

        str = env
            and str:gsub("%${" .. env .. "}", os.getenv(env) or "")
            or str
    until not env

    -- Interpolate #{}
    local var
    repeat
        var = str:match "#{([A-Za-z_]+[A-Za-z_0-9]*)}"

        if var then
            local value = context[var]
            if value == nil then
                value = _G[var]
            end
            if value == nil then
                value = ""
            end

            if type(value) == "table" then
                local tmp = {}
                for _, v in ipairs(flatten(value)) do
                    table.insert(
                        tmp,
                        type(v) == "string"
                            and __(v)
                            or v
                    )
                end
                value = table.concat(tmp, " ")
            elseif type(value) == "string" then
                value = __(value)
            end

            str = str:gsub("#{" .. var .. "}", tostring(value))
        end
    until not var

    -- Interpolate ~
    str = str:gsub("~", os.getenv "HOME")

    -- Interpolate @{}
    var = nil
    repeat
        var = str:match "@{([A-Za-z_]+[A-Za-z_0-9]*)}"

        if var then
            local value = _G.__fourmi.vars[var]
            if value == nil then
                value = ""
            end

            if type(value) == "table" then
                local tmp = {}
                for _, v in ipairs(flatten(value)) do
                    table.insert(
                        tmp,
                        type(v) == "string"
                            and __(v)
                            or v
                    )
                end
                value = table.concat(tmp, " ")
            elseif type(value) == "string" then
                value = __(value)
            end

            str = var
                and str:gsub("@{" .. var .. "}", tostring(value))
                or str
        end
    until not var

    return str
end

return {
    flatten = flatten,
    __      = __
}
