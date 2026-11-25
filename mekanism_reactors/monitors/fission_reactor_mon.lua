local function J_to_FE(J)
    return 0.4*J
end

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

local function display_aux_stats(fissile_fuel, nuclear_waste, spent_waste)
    print("Fissile Fuel %: " .. string.format("%.2f%%", fissile_fuel*100))
    print("Nuclear Waste %: " .. string.format("%.2f%%", nuclear_waste*100))
    print("Spent Waste %: " .. string.format("%.2f%%", spent_waste*100))
end

local function main()
    local modem 
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

    if pocket then
        modem = peripheral.wrap("back")
    else
        modem = peripheral.wrap("top")
    end

    if modem then
        modem.open(1)
    else
        print("No modem found... terminating program")
        return
    end

    term.setTextColor(colors.red)
    print("Fission Reactor Disconnected")
    term.setTextColor(colors.white)
    while true do
        local event, side, channel, replyChannel, packet = os.pullEvent("modem_message")
        if channel == 1 and packet.type == "SCRAM" then
            auto_scrammed = true
            scram_reason = packet.payload
        elseif channel == 1 and packet.type == "REACTOR_TELEMETRY" then
            data = packet.payload
            if data.active then
                auto_scrammed = false
            end
            active = data.active
            temp = data.temp
            burn_rate = data.burn_rate
            heating_rate = data.heating_rate
            coolant = data.coolant
        elseif channel == 1 and packet.type == "AUX_TELEMETRY" then
            data = packet.payload
            fissile_fuel = data.fissile_fuel
            nuclear_waste = data.nuclear_waste
            spent_waste = data.spent_waste
        end
        term.clear()
        term.setCursorPos(1, 1)
        display_reactor_stats(active, temp, damage, burn_rate, heating_rate, coolant, auto_scrammed, scram_reason)
        print("")
        display_aux_stats(fissile_fuel, nuclear_waste, spent_waste)
    end
end

local function wait_for_quit()
    local heldKeys = {}

    while true do
        local event, key = os.pullEvent()

        if event == "key" then
            heldKeys[key] = true

            if (heldKeys[keys.leftCtrl] or heldKeys[keys.rightCtrl]) and heldKeys[keys.q] then
                break
            end
        elseif event == "key_up" then
            heldKeys[key] = nil
        end
    end
end

parallel.waitForAny(main, wait_for_quit)