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

local function display_reactor_stats(active, inj_rate, plasma_temp, case_temp, prod)
    write("Fusion Reactor Status: ")
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

local function display_aux_stats(tritium, deuterium)
    print("Tritium %: " .. string.format("%.2f%%", tritium*100))
    print("Deuterium %: " .. string.format("%.2f%%", deuterium*100))
end

local function main()
    local modem 
    if pocket then
        modem = peripheral.wrap("back")
    else
        modem = peripheral.wrap("top")
    end
    
    if modem then
        modem.open(3)
    else
        print("No modem found... terminating program")
        return
    end

    local active = false
    local inj_rate = 0.0
    local plasma_temp = 0.0
    local case_temp = 0.0
    local production_rate = 0.0
    local tritium = 0.0
    local deuterium = 0.0

    term.setTextColor(colors.red)
    print("Fusion Reactor Disconnected")
    term.setTextColor(colors.white)
    while true do
        local event, side, channel, replyChannel, packet = os.pullEvent("modem_message")
        if channel == 3 and packet.type == "REACTOR_TELEMETRY" then
            data = packet.payload
            active = data.active
            inj_rate = data.inj_rate
            plasma_temp = data.plasma_temp
            case_temp = data.case_temp
            production_rate = data.production_rate
        elseif channel == 3 and packet.type == "AUX_TELEMETRY" then
            data = packet.payload
            tritium = data.tritium
            deuterium = data.deuterium
        end
        term.clear()
        term.setCursorPos(1,1)
        display_reactor_stats(active, inj_rate, plasma_temp, case_temp, production_rate)
        print("")
        display_aux_stats(tritium, deuterium)
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