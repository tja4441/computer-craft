-- aux_fusion_relay.lua
--
-- Relays auxilliary telemetry to fusion_reactor_mon.lua

local settings = {
    transmission_channel = 3,
    transmission_period_s = 1.0,
    tritium_pipe_dir = "left",
    deuterium_pipe_dir = "right"
}

local modem = peripheral.find("modem")
if not modem then
    error("No modem found!")
end

local tritium_pipe = peripheral.wrap(settings.tritium_pipe_dir)
if not tritium_pipe then
    error("No tritium pipe on " .. settings.tritium_pipe_dir .. "!")
end

local deuterium_pipe = peripheral.wrap(settings.deuterium_pipe_dir)
if not deuterium_pipe then
    error("No deuterium pipe on " .. settings.deuterium_pipe_dir .. "!")
end

if tritium_pipe and deuterium_pipe then
    print("All pipes detected... Transmitting data!")
    while true do
        local data = {
            tritium = tritium_pipe.getFilledPercentage(),
            deuterium = deuterium_pipe.getFilledPercentage()
        }
        local packet = {
            type = "AUX_TELEMETRY",
            timestamp = os.epoch("utc"),
            payload = data
        }
        modem.transmit(settings.transmission_channel, settings.transmission_channel, packet)
        sleep(settings.transmission_period_s)
    end
end