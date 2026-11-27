-- induction_matrix_mon.lua 
--
-- Receives and interprets transmissions from induction_matrix_relay.lua,
-- then prints information to the terminal

local settings = {
    transmission_channel = 4,
    transmission_timeout_ms = 10000
}

-- Helper Functions
local function J_to_FE(J)
    return 0.4*J
end

local function f_tostring_units(float)
    if math.abs(float) > 1000000000000 then -- 1 Tx
        return string.format("%.2f T", float/1000000000000)
    elseif math.abs(float) > 1000000000 then -- 1 Gx
        return string.format("%.2f G", float/1000000000)
    elseif math.abs(float) > 1000000 then -- 1 Mx
        return string.format("%.2f M", float/1000000)
    elseif math.abs(float) > 1000 then --- 1 kx
        return string.format("%.2f k", float/1000)
    else
        return string.format("%.2f ", float)
    end
end

function createDifferentiator(initialValue)
    local prev = initialValue

    return function(current)
        if prev == nil then
            prev = current
            return 0 
        end

        local diff = current - prev
        prev = current -- Update state for the next timestep
        return diff
    end
end

-- Display Functions
local function display_matrix_stats(energy, energy_percent)
    print("Induction Matrix: ")
    
    print("\nEnergy: " .. f_tostring_units(J_to_FE(energy)) .. "FE")
    print("Energy %: " .. string.format("%.2f%%", energy_percent*100))
    
    local net_change = delta(energy)
    local net_change_percent = delta_percent(energy_percent)
    
    print("\nNet Change: " .. f_tostring_units(J_to_FE(net_change)) .. "FE/s")
    print("Net Change %: " .. string.format("%.2f%%", net_change_percent*100))
end

local function display_matrix_timeout(last_transmission_time)
    write("Induction Matrix: ")
    term.setTextColor(colors.yellow)
    print("\nTIMEOUT")
    term.setTextColor(colors.white)

    print("\nTime since last packet:")
    print(time_tostring(os.epoch("utc") - last_transmission_time))
end

-- Main Program Loop
local delta = createDifferentiator(0.0)
local delta_percent = createDifferentiator(0.0)

local energy = 0.0
local energy_percent = 0.0

local last_packet_time = 0

local modem = peripheral.find("modem")
if modem then
    modem.open(settings.transmission_channel)
else
    print("No modem found... terminating program")
    return
end

while true do
    local event, side, channel, replyChannel, packet = os.pullEvent("modem_message")
    if channel == settings.transmission_channel and packet.type == "MATRIX_TELEMETRY" then
        last_packet_time = packet.timestamp
        local data = packet.payload

        energy = data.energy
        energy_percent = data.energy_percent
    end
    term.clear()
    term.setCursorPos(1,1)
    
    if os.epoch("utc") - last_packet_time <= settings.transmission_timeout_ms then
        display_matrix_stats(energy, energy_percent)
    else
        display_matrix_timeout(last_packet_time)
    end
end