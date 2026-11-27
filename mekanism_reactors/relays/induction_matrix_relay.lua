-- induction_matrix_relay.lua
--
-- Relays induction matrix telemetry to induction_matrix_mon.lua

local settings = {
    transmission_channel = 4,
    transmission_period_s = 1.0,
    matrix_detection_retries = 4,
    matrix_detection_interval_s = 5.0
}

local modem = peripheral.find("modem")
if not modem then
    print("No modem detected... Aborting program")
    return
end

local function getFormedMatrix()
    local m = peripheral.find("inductionPort")
    if m and peripheral.getType(m) == "inductionPort" and m.getLastInput ~= nil then
        return m
    end
    return nil
end

local matrix = getFormedMatrix()
local detection_retries = settings.matrix_detection_retries

while not matrix and detection_retries > 0 do
    print("Formed matrix not found... Trying again (" .. detection_retries .. " left)")
    sleep(settings.matrix_detection_interval_s)
    matrix = getFormedMatrix()
    detection_retries = detection_retries - 1
end

if not matrix then
    print("No formed matrix detected... Aborting program")
    return
end

print("Induction Matrix connected! Transmitting telemetry...")

while true do
    local ok, err = pcall(function()
        local data = {
            energy = matrix.getEnergy(),
            energy_percent = matrix.getEnergyFilledPercentage()
        }
        local packet = {
            type = "MATRIX_TELEMETRY",
            timestamp = os.epoch("utc"),
            payload = data
        }
        modem.transmit(settings.transmission_channel, settings.transmission_channel, packet)
    end)

    if not ok then
        print("Lost connection to formed matrix... Aborting program")
        return
    end

    sleep(settings.transmission_period_s)
end
