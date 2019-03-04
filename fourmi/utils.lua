local function map(t, mapFn)
    local mapped = {}

    for k, v in pairs(t) do
        mapped[k] = mapFn(k, v)
    end

    return mapped
end

return {
	table = {
		map = map
	}
}