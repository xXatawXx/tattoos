---------------------------
    -- Functions --
---------------------------
Utils = {
    MySQLAsyncExecute  = function(query) -- MySQL Query Function
        local IsBusy = true
        local result = nil
        MySQL.Async.fetchAll(query, {}, function(data)
            result = data
            IsBusy = false
        end)
        while IsBusy do
            Citizen.Wait(0)
        end
        return result
    end,
    round  = function(num, numDecimalPlaces) -- Round function
        local mult = 10^(numDecimalPlaces or 0)
        return math.floor(num * mult + 0.5) / mult
    end,
    format_thousand  = function(v) -- Comma Value function
        local s = string.format("%d", math.floor(v))
        local pos = string.len(s) % 3
        if pos == 0 then 
            pos = 2
        end
        return string.sub(s, 1, pos) .. string.gsub(string.sub(s, pos + 1), "(...)", ".%1")
    end,
    tablelength   = function(t) -- Table Length function
        local count = 0
        for _ in pairs(t) do 
            count = count + 1
        end
        return count
    end,
    random_elem = function(tb)
        local keys = {}
        for k in pairs(tb) do table.insert(keys, k) end
        return tb[keys[math.random(#keys)]]
    end,
}
