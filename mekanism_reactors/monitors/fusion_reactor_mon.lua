-- fusion_reactor_mon.lua
--
-- Receives and interprets transmissions from fusion_reactor_relay.lua and aux_fusion_relay.lua,
-- then prints information to the terminal

local settings = {
    transmission_channel = 3,
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

-- Display Functions
local function display_reactor_stats(active, inj_rate, plasma_temp, case_temp, prod)
    write("Fusion Reactor: ")
    if active then
        term.setTextColor(colors.green)
        print("\nACTIVE")
    else
        term.setTextColor(colors.red)
        print("\nOFF")
    end
    term.setTextColor(colors.white)

    print("\nInjection Rate: " .. string.format("%d", inj_rate))
    print("Plasma Temp: " .. f_tostring_units(plasma_temp) .. "\xB0C")
    print("Case Temp: " .. f_tostring_units(case_temp) .. "\xB0C")
    print("Energy Rate: " .. f_tostring_units(J_to_FE(prod)) .. "FE/t")
end

local function display_reactor_timeout(last_transmission_time)
    write("Fusion Reactor: ")
    term.setTextColor(colors.yellow)
    print("\nTIMEOUT")
    term.setTextColor(colors.white)

    print("\nTime since last packet:")
    print(time_tostring(os.epoch("utc") - last_transmission_time))
    print("") -- maintain spacing
    print("")
end

local function display_aux_stats(tritium, deuterium)
    print("Tritium %: " .. string.format("%.2f%%", tritium*100))
    print("Deuterium %: " .. string.format("%.2f%%", deuterium*100))
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
local active = false
local inj_rate = 0.0
local plasma_temp = 0.0
local case_temp = 0.0
local production_rate = 0.0
local tritium = 0.0
local deuterium = 0.0

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
    if channel == settings.transmission_channel and packet.type == "REACTOR_TELEMETRY" then
        last_packet_time = packet.timestamp
        data = packet.payload

        active = data.active
        inj_rate = data.inj_rate
        plasma_temp = data.plasma_temp
        case_temp = data.case_temp
        production_rate = data.production_rate
    elseif channel == settings.transmission_channel and packet.type == "AUX_TELEMETRY" then
        last_aux_packet_time = packet.timestamp
        data = packet.payload

        tritium = data.tritium
        deuterium = data.deuterium
    end

    -- Print to screen
    term.clear()
    term.setCursorPos(1,1)
    local current_time = os.epoch("utc")

    if current_time - last_packet_time <= settings.transmission_timeout_ms then
        display_reactor_stats(active, inj_rate, plasma_temp, case_temp, production_rate)
    else
        display_reactor_timeout(last_packet_time)
    end
    
    print("")

    if current_time - last_aux_packet_time <= settings.transmission_timeout_ms then
        display_aux_stats(tritium, deuterium)
    else
        display_aux_timeout(last_aux_packet_time)
    end
end