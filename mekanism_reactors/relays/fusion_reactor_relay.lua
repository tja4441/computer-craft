-- fusion_reactor_relay.lua
--
-- Relays reactor telemetry to fusion_reactor_mon.lua

local settings = {
    transmission_channel = 3,
    transmission_period_s = 1.0,
    reactor_detection_retries = 4,
    reactor_detection_interval_s = 5.0
}

local modem = peripheral.find("modem")

if not modem then
    print("No modem detected... Aborting program")
    return
end

-- Helper function: finds the Logic Adapter AND verifies the multiblock is formed
local function getFormedFusionReactor()
    local r = peripheral.find("fusionReactorLogicAdapter") or peripheral.find("fusionReactor")
    if r and r.isIgnited ~= nil then
        return r
    end
    return nil
end

local reactor = getFormedFusionReactor()
local detection_retries = settings.reactor_detection_retries

while not reactor and detection_retries > 0 do
    print("Formed Fusion Reactor not found... Trying again (" .. detection_retries .. " left)")
    sleep(settings.reactor_detection_interval_s)
    reactor = getFormedFusionReactor()
    detection_retries = detection_retries - 1
end

if not reactor then
    print("No formed Fusion Reactor detected... Aborting program")
    return
end

print("Fusion Reactor connected! Transmitting telemetry...")

while true do
    local ok, err = pcall(function()
        local data = {
            active = reactor.isIgnited(),
            inj_rate = reactor.getInjectionRate(),
            plasma_temp = reactor.getPlasmaTemperature(),
            case_temp = reactor.getCaseTemperature(),
            production_rate = reactor.getProductionRate()
        }
        local packet = {
            type = "REACTOR_TELEMETRY",
            timestamp = os.epoch("utc"),
            payload = data
        }
        modem.transmit(settings.transmission_channel, settings.transmission_channel, packet)
    end)

    if not ok then
        print("Lost connection to formed Fusion Reactor... Aborting program")
        return
    end

    sleep(settings.transmission_period_s)
end
