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
local detection_retries = 4

while not reactor and detection_retries > 0 do
    print("Formed Fission Reactor not found... Trying again (" .. detection_retries .. " left)")
    sleep(5.0)
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
            modem.transmit(1, 1, packet)
        end)

        if not ok then
            print("Lost connection to formed Fission Reactor... Aborting program")
            return
        end

        sleep(1)
    end
end

local function listen_for_commands()
    while true do
        local event, side, channel, replyChannel, packet = os.pullEvent("modem_message")

        if channel == 1 and packet.type == "SCRAM" then
            pcall(function()
                if reactor.getStatus() then
                    print("REMOTE SCRAM RECEIVED! Shutting down reactor...")
                    reactor.scram()
                end
            end)
        end
    end
end

modem.open(1)
parallel.waitForAny(relay_telemetry, listen_for_commands)
