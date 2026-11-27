-- turbine_mon.lua
--
-- Receives and interprets transmissions from turbine_relay.lua,
-- then prints information to the terminal

local settings = {
    transmission_channel = 2,
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

local function mf_tostring_units(float)
    if math.abs(float) > 1000000000000 then -- 1 Gx
        return string.format("%.2f G", float/1000000000000)
    elseif math.abs(float) > 1000000000 then -- 1 Mx
        return string.format("%.2f M", float/1000000000)
    elseif math.abs(float) > 1000000 then -- 1 kx
        return string.format("%.2f k", float/1000000)
    elseif math.abs(float) > 1000 then --- 1 x
        return string.format("%.2f ", float/1000)
    else
        return string.format("%.2f m", float)
    end
end

-- Display Functions
local function display_turbine_stats(steam, steam_rate, energy, energy_rate)
    print("Turbine: ")

    print("\nSteam: " .. string.format("%.2f%%", steam*100))
    print("Steam Rate: " .. mf_tostring_units(steam_rate) .. "B/t")
    print("\nEnergy: " .. string.format("%.2f%%", energy*100))
    print("Energy Rate: " .. f_tostring_units(J_to_FE(energy_rate)) .. "FE/t")
end

local function display_turbine_timeout(last_transmission_time)
    write("Turbine: ")
    term.setTextColor(colors.yellow)
    print("\nTIMEOUT")
    term.setTextColor(colors.white)

    print("\nTime since last packet:")
    print(time_tostring(os.epoch("utc") - last_transmission_time))
end

-- Main Program Loop
local steam = 0.0
local steam_rate = 0.0
local energy = 0.0
local energy_rate = 0.0

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
    if channel == settings.transmission_channel and packet.type == "TURBINE_TELEMETRY" then
        last_packet_time = packet.timestamp
        local data = packet.payload

        steam = data.steam
        steam_rate = data.steam_rate
        energy = data.energy
        energy_percent = data.energy_percent
    end
    term.clear()
    term.setCursorPos(1,1)

    if os.epoch("utc") - last_packet_time <= settings.transmission_timeout_ms then
        display_turbine_stats(data.steam, data.steam_rate, data.energy, data.energy_rate)
    else
        display_turbine_timeout(last_packet_time)
    end
end
