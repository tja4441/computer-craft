-- turbine_relay.lua
--
-- Relays turbine telemetry to turbine_mon.lua

local settings = {
    transmission_channel = 2,
    transmission_period_s = 1.0,
    turbine_detection_retries = 4,
    turbine_detection_interval_s = 5.0
}

local modem = peripheral.find("modem")
if not modem then
    print("No modem detected... Aborting program")
    return
end

local function getFormedTurbine()
    local t = peripheral.find("turbineValve")
    if t and t.getFlowRate ~= nil then
        return t
    end
    return nil
end

local turbine = getFormedTurbine()
local detection_retries = settings.turbine_detection_retries

while not turbine and detection_retries > 0 do
    print("Formed turbine not found... Trying again (" .. detection_retries .. " left)")
    sleep(settings.turbine_detection_interval_s)
    turbine = getFormedTurbine()
    detection_retries = detection_retries - 1
end

if not turbine then
    print("No formed turbine detected... Aborting program")
    return
end

print("Turbine connected! Transmitting telemetry...")

while true do
    local ok, err = pcall(function()
        local data = {
            steam = turbine.getSteamFilledPercentage(),
            steam_rate = turbine.getFlowRate(),
            energy = turbine.getEnergyFilledPercentage(),
            energy_rate = turbine.getProductionRate()
        }
        local packet = {
            type = "TURBINE_TELEMETRY",
            timestamp = os.epoch("utc"),
            payload = data
        }
        modem.transmit(settings.transmission_channel, settings.transmission_channel, packet)
    end)

    if not ok then
        print("Lost connection to formed turbine... Aborting program")
        return
    end

    sleep(settings.transmission_period_s)
end
