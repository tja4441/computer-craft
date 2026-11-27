-- fission_reactor_relay.lua
--
-- Relays reactor telemetry to fission_reactor_mon.lua
-- Also listens for SCRAM commands to remotely shut down the reactor

local settings = {
    transmission_channel = 1,
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
local function getFormedFissionReactor()
    local r = peripheral.find("fissionReactorLogicAdapter") or peripheral.find("fissionReactor")
    if r and r.getStatus ~= nil then
        return r
    end
    return nil
end

local reactor = getFormedFissionReactor()
local detection_retries = settings.reactor_detection_retries

while not reactor and detection_retries > 0 do
    print("Formed Fission Reactor not found... Trying again (" .. detection_retries .. " left)")
    sleep(settings.reactor_detection_interval_s)
    reactor = getFormedFissionReactor()
    detection_retries = detection_retries - 1
end

if not reactor then
    print("No formed Fission Reactor detected... Aborting program")
    return
end

print("Fission Reactor connected! Transmitting telemetry & listening for SCRAM...")

local function relay_telemetry()
    while true do
        local ok, err = pcall(function()
            local data = {
                active = reactor.getStatus(),
                temp = reactor.getTemperature(),
                damage = reactor.getDamagePercent(),
                burn_rate = reactor.getActualBurnRate(),
                heating_rate = reactor.getHeatingRate(),
                coolant = reactor.getCoolantFilledPercentage()
            }
            local packet = {
                type = "REACTOR_TELEMETRY",
                timestamp = os.epoch("utc"),
                payload = data
            }
            modem.transmit(settings.transmission_channel, settings.transmission_channel, packet)
        end)

        if not ok then
            print("Lost connection to formed Fission Reactor... Aborting program")
            return
        end

        sleep(settings.transmission_period_s)
    end
end

local function listen_for_commands()
    while true do
        local event, side, channel, replyChannel, packet = os.pullEvent("modem_message")

        if channel == settings.transmission_channel and packet.type == "SCRAM" then
            pcall(function()
                if reactor.getStatus() then
                    print("REMOTE SCRAM RECEIVED! Shutting down reactor...")
                    reactor.scram()
                end
            end)
        end
    end
end

modem.open(settings.transmission_channel)
parallel.waitForAny(relay_telemetry, listen_for_commands)
