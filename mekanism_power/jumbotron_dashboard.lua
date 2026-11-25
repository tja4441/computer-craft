local monitors = { peripheral.find("monitor") }
local num_monitors = 4
local scriptToRun = "dashboard.lua"
local detection_retries = 4

while #monitors < num_monitors and detection_retries > 0 do
    print(#monitors .. " monitors found... Trying again (" .. detection_retries .. " left)")
    sleep(5.0)
    monitors = { peripheral.find("monitor") }
    detection_retries = detection_retries - 1
end

if #monitors < num_monitors then
    print(#monitors .. " monitors found... Aborting program")
    return
end

print("All " .. num_monitors .. " monitors detected! Starting programs...")

local tasks = {}
for _, mon in ipairs(monitors) do
    local name = peripheral.getName(mon)
    table.insert(tasks, function()
        shell.run("monitor", name, scriptToRun)
    end)
end

parallel.waitForAll(table.unpack(tasks))