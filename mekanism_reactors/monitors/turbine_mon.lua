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

local function display_turbine_stats(steam, steam_rate, energy, energy_rate)
    print("Turbine Status: ")

    print("\nSteam: " .. string.format("%.2f%%", steam*100))
    print("Steam Rate: " .. mf_tostring_units(steam_rate) .. "B/t")
    print("\nEnergy: " .. string.format("%.2f%%", energy*100))
    print("Energy Rate: " .. f_tostring_units(J_to_FE(energy_rate)) .. "FE/t")
end

local function main()
    local modem 
    if pocket then
        modem = peripheral.wrap("back")
    else
        modem = peripheral.wrap("top")
    end
    
    if modem then
        modem.open(2)
    else
        print("No modem found... terminating program")
        return
    end

    term.setTextColor(colors.red)
    print("Turbine Disconnected")
    term.setTextColor(colors.white)
    while true do
        local event, side, channel, replyChannel, packet = os.pullEvent("modem_message")
        if channel == 2 and packet.type == "TURBINE_TELEMETRY" then
            local data = packet.payload
            term.clear()
            term.setCursorPos(1,1)
            display_turbine_stats(data.steam, data.steam_rate, data.energy, data.energy_rate)
        end
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