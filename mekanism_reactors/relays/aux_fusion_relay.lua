local modem = peripheral.find("modem")
if not modem then
    error("No modem found!")
end

local tritium_pipe = peripheral.wrap("left")
if not tritium_pipe then
    error("No tritium pipe on left!")
end

local deuterium_pipe = peripheral.wrap("right")
if not deuterium_pipe then
    error("No deuterium pipe on right!")
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
            payload = data
        }
        modem.transmit(3, 3, packet)
        sleep(1)
    end
end