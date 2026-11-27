-- aux_fission_relay.lua
-- 
-- Relays auxilliary telemetry to fission_reactor_mon.lua
-- Also watches nuclear and spent nuclear waste levels and SCRAMs the reactor if necessary

local settings = {
    transmission_channel = 1,
    transmission_period_s = 1.0,
    fissile_fuel_pipe_dir = "top",
    nuclear_waste_pipe_dir = "right",
    spent_waste_pipe_dir = "left",
    nuclear_waste_threshold_percent = 0.10,
    spent_waste_threshold_percent = 0.05,
    waste_recovery_hysteresis_percent = 0.8
}

local modem = peripheral.find("modem")
if not modem then
    error("No modem found!")
end

local fissile_fuel_pipe = peripheral.wrap(settings.fissile_fuel_pipe_dir)
if not fissile_fuel_pipe then
    error("No fissile fuel pipe on " .. settings.fissile_fuel_pipe_dir .. "!")
end

local nuclear_waste_pipe = peripheral.wrap(settings.nuclear_waste_pipe_dir)
if not nuclear_waste_pipe then
    error("No nuclear waste pipe on " .. settings.nuclear_waste_pipe_dir .. "!")
end

local spent_waste_pipe = peripheral.wrap(settings.spent_waste_pipe_dir)
if not spent_waste_pipe then
    error("No spent nuclear waste pipe on " .. settings.spent_waste_pipe_dir .. "!")
end

local function watch_nuclear_waste()
    print("Watching for nuclear waste backup above " .. settings.nuclear_waste_threshold_percent*100 .. "% of capacity...")
    while true do
        if nuclear_waste_pipe.getFilledPercentage() > settings.nuclear_waste_threshold_percent then
            print("Nuclear waste percentage higher than " .. settings.nuclear_waste_threshold_percent*100 .. "%. Sending SCRAM on port " .. settings.transmission_channel)
            local packet = {
                type = "SCRAM",
                payload = "Nuclear waste buildup"
            }
            modem.transmit(settings.transmission_channel, settings.transmission_channel, packet)
            repeat
                sleep(1.0)
            until nuclear_waste_pipe.getFilledPercentage() < settings.nuclear_waste_threshold_percent*settings.waste_recovery_hysteresis_percent
            print("Watching nuclear waste again...")
        end
    end
end

local function watch_spent_waste()
    print("Watching for spent waste backup above " .. settings.spent_waste_threshold_percent*100 .. "% of capacity...")
    while true do
        if spent_waste_pipe.getFilledPercentage() > settings.spent_waste_threshold_percent then
            print("Spent waste percentage higher than " .. settings.spent_waste_threshold_percent*100 .. "%. Sending SCRAM on port " .. settings.transmission_channel)
            local packet = {
                type = "SCRAM",
                payload = "Spent waste buildup"
            }
            modem.transmit(settings.transmission_channel, settings.transmission_channel, packet)
            repeat
                sleep(1.0)
            until spent_waste_pipe.getFilledPercentage() < settings.spent_waste_threshold_percent*settings.waste_recovery_hysteresis_percent
            print("Watching spent waste again...")
        end
    end
end

local function relay_data()
    if fissile_fuel_pipe and nuclear_waste_pipe and spent_waste_pipe then
        print("All pipes detected... Transmitting data!")
        while true do
            local data = {
                fissile_fuel = fissile_fuel_pipe.getFilledPercentage(),
                nuclear_waste = nuclear_waste_pipe.getFilledPercentage(),
                spent_waste = spent_waste_pipe.getFilledPercentage()
            }
            local packet = {
                type = "AUX_TELEMETRY",
                timestamp = os.epoch("utc"),
                payload = data
            }
            modem.transmit(settings.transmission_channel, settings.transmission_channel, packet)
            sleep(settings.transmission_period_s)
        end
    end
end

parallel.waitForAny(relay_data, watch_nuclear_waste, watch_spent_waste)