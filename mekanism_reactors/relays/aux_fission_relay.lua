local modem = peripheral.find("modem")
if not modem then
    error("No modem found!")
end

local fissile_fuel_pipe = peripheral.wrap("top")
if not fissile_fuel_pipe then
    error("No fissile fuel pipe on top!")
end

local nuclear_waste_pipe = peripheral.wrap("right")
if not nuclear_waste_pipe then
    error("No nuclear waste pipe on right!")
end

local spent_waste_pipe = peripheral.wrap("left")
if not spent_waste_pipe then
    error("No spent nuclear waste pipe on left!")
end

local nuclear_waste_threshold = 0.10
local spent_waste_threshold = 0.05

local function watch_nuclear_waste()
    print("Watching for nuclear waste backup above " .. nuclear_waste_threshold*100 .. "% of capacity...")
    while true do
        if nuclear_waste_pipe.getFilledPercentage() > nuclear_waste_threshold then
            print("Nuclear waste percentage higher than " .. nuclear_waste_threshold*100 .. "%. Sending SCRAM on port 1...")
            local packet = {
                type = "SCRAM",
                payload = "Nuclear waste buildup"
            }
            modem.transmit(1, 1, packet)
            repeat
                sleep(1.0)
            until nuclear_waste_pipe.getFilledPercentage() < nuclear_waste_threshold*0.8
            print("Watching nuclear waste again...")
        end
    end
end

local function watch_spent_waste()
    print("Watching for spent waste backup above " .. spent_waste_threshold*100 .. "% of capacity...")
    while true do
        if spent_waste_pipe.getFilledPercentage() > spent_waste_threshold then
            print("Spent waste percentage higher than " .. spent_waste_threshold*100 .. "%. Sending SCRAM on port 1...")
            local packet = {
                type = "SCRAM",
                payload = "Spent waste buildup"
            }
            modem.transmit(1, 1, packet)
            repeat
                sleep(1.0)
            until spent_waste_pipe.getFilledPercentage() < spent_waste_threshold*0.8
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
            modem.transmit(1, 1, packet)
            sleep(1)
        end
    end
end

parallel.waitForAny(relay_data, watch_nuclear_waste, watch_spent_waste)