-- fission_reactor_mon.lua
--
-- Receives and interprets transmissions from fission_reactor_relay.lua and aux_fission_relay.lua,
-- then prints information to the terminal

local settings = {
    transmission_channel = 1,
    transmission_timeout_ms = 10000
}

-- Helper Functions
local function K_to_C(K)
    return K - 273.15
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

local function time_tostring(ms)
    local sec = math.floor(ms/1000)
    if sec < 60 then
        return sec .. "s"
    elseif sec < 3600 then
        local m = math.floor(sec / 60)
        local s = sec % 60
        return string.format("%dm %ds", m, s)
    elseif sec < 86400 then
        local h = math.floor(sec / 3600)
        local m = math.floor((sec % 3600) / 60)
        local s = sec % 60
        return string.format("%dh %dm %ds", h, m, s)
    else
        local d = math.floor(sec / 86400)
        local h = math.floor((sec % 86400) / 3600)
        local m = math.floor((sec % 3600) / 60)
        return string.format("%dd %dh %dm", d, h, m)
    end
end

-- Display Functions
local function display_reactor_stats(active, temp, damage, burn_rate, heating_rate, coolant, auto_scrammed, scram_reason)
    write("Fission Reactor: ")
    if active then
        term.setTextColor(colors.green)
        print("\nACTIVE")
    elseif auto_scrammed == true then
        term.setTextColor(colors.red)
        print("AUTO-SCRAMMED:")
        print(scram_reason)
    else
        term.setTextColor(colors.red)
        print("\nOFF")
    end
    term.setTextColor(colors.white)

    print("Temperature: " .. f_tostring_units(K_to_C(temp)) .. "\xB0C")
    print("Damage: " .. string.format("%.2f%%", damage*100))
    print("Burn Rate: " .. mf_tostring_units(burn_rate) .. "B/t")
    print("Heating Rate: " .. mf_tostring_units(heating_rate) .. "B/t")
    print("Coolant: " .. string.format("%.2f%%", coolant*100))
end

local function display_reactor_timeout(last_transmission_time)
    write("Fission Reactor: ")
    term.setTextColor(colors.yellow)
    print("\nTIMEOUT")
    term.setTextColor(colors.white)

    print("Time since last packet:")
    print(time_tostring(os.epoch("utc") - last_transmission_time))
    print("") -- maintain spacing
    print("")
    print("")
end

local function display_aux_stats(fissile_fuel, nuclear_waste, spent_waste)
    print("Fissile Fuel %: " .. string.format("%.2f%%", fissile_fuel*100))
    print("Nuclear Waste %: " .. string.format("%.2f%%", nuclear_waste*100))
    print("Spent Waste %: " .. string.format("%.2f%%", spent_waste*100))
end

local function display_aux_timeout(last_transmission_time)
    write("Aux. Telemetry: ")
    term.setTextColor(colors.yellow)
    print("\nTIMEOUT")
    term.setTextColor(colors.white)

    print("Time since last packet:")
    print(time_tostring(os.epoch("utc") - last_transmission_time))
end

-- Main Program Loop
local auto_scrammed = false
local scram_reason = ""

local active = false
local temp = 0.0
local damage = 0.0
local burn_rate = 0.0
local heating_rate = 0.0
local coolant = 0.0
local fissile_fuel = 0.0
local nuclear_waste = 0.0
local spent_waste = 0.0

local last_packet_time = 0
local last_aux_packet_time = 0

local modem = peripheral.find("modem")
if modem then
    modem.open(settings.transmission_channel)
else
    print("No modem found... terminating program")
    return
end

while true do
    -- Check for incoming packet
    local event, side, channel, replyChannel, packet = os.pullEvent("modem_message")
    if channel == settings.transmission_channel and packet.type == "SCRAM" then
        auto_scrammed = true
        scram_reason = packet.payload
    elseif channel == settings.transmission_channel and packet.type == "REACTOR_TELEMETRY" then
        last_packet_time = packet.timestamp
        data = packet.payload
        
        if data.active then
            auto_scrammed = false
        end
        
        active = data.active
        temp = data.temp
        burn_rate = data.burn_rate
        heating_rate = data.heating_rate
        coolant = data.coolant
    elseif channel == settings.transmission_channel and packet.type == "AUX_TELEMETRY" then
        last_aux_packet_time = packet.timestamp
        data = packet.payload
        
        fissile_fuel = data.fissile_fuel
        nuclear_waste = data.nuclear_waste
        spent_waste = data.spent_waste
    end
    
    -- Print to screen
    term.clear()
    term.setCursorPos(1, 1)
    local current_time = os.epoch("utc")

    if current_time - last_packet_time <= settings.transmission_timeout_ms then
        display_reactor_stats(active, temp, damage, burn_rate, heating_rate, coolant, auto_scrammed, scram_reason)
    else
        display_reactor_timeout(last_packet_time)
    end

    if current_time - last_aux_packet_time <= settings.transmission_timeout_ms then
        print("")
        display_aux_stats(fissile_fuel, nuclear_waste, spent_waste)
    else
        -- no empty line, need extra room
        display_aux_timeout(last_aux_packet_time)
    end
end