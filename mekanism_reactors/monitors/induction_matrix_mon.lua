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

local delta = createDifferentiator(0.0)
local delta_percent = createDifferentiator(0.0)

local function display_matrix_stats(energy, energy_percent)
    print("Induction Matrix Status: ")

    print("\nEnergy: " .. f_tostring_units(J_to_FE(energy)) .. "FE")
    print("Energy %: " .. string.format("%.2f%%", energy_percent*100))

    local net_change = delta(energy)
    local net_change_percent = delta_percent(energy_percent)

    print("\nNet Change: " .. f_tostring_units(J_to_FE(net_change)) .. "FE/s")
    print("Net Change %: " .. string.format("%.2f%%", net_change_percent*100))
end

local function main()
    local modem 
    if pocket then
        modem = peripheral.wrap("back")
    else
        modem = peripheral.wrap("top")
    end
    
    if modem then
        modem.open(4)
    else
        print("No modem found... terminating program")
        return
    end

    term.setTextColor(colors.red)
    print("Induction Matrix Disconnected")
    term.setTextColor(colors.white)
    while true do
        local event, side, channel, replyChannel, packet = os.pullEvent("modem_message")
        if channel == 4 and packet.type == "MATRIX_TELEMETRY" then
            local data = packet.payload
            term.clear()
            term.setCursorPos(1,1)
            display_matrix_stats(data.energy, data.energy_percent)
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