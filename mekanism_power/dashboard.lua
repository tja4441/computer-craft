local parentTerm = term.current()
local w, h = parentTerm.getSize()
local halfWidth = math.floor(w / 2)
local halfHeight = math.floor(h / 2)

-- Draw crosshair divider lines
parentTerm.clear()
for y = 1, h do
    parentTerm.setCursorPos(halfWidth, y)
    parentTerm.write("|")
end
for x = 1, w do
    parentTerm.setCursorPos(x, halfHeight)
    parentTerm.write("-")
end
parentTerm.setCursorPos(halfWidth, halfHeight)
parentTerm.write("+")

-- 1. Create four corner subwindows around the dividers
local topLeft     = window.create(parentTerm, 1, 1, halfWidth - 1, halfHeight - 1)
local topRight    = window.create(parentTerm, halfWidth + 1, 1, w - halfWidth, halfHeight - 1)
local bottomLeft  = window.create(parentTerm, 1, halfHeight + 1, halfWidth - 1, h - halfHeight)
local bottomRight = window.create(parentTerm, halfWidth + 1, halfHeight + 1, w - halfWidth, h - halfHeight)

-- 2. Helper to create a task entry pairing a coroutine with its window
local function createTask(win, scriptPath, ...)
    local args = {...}
    return {
        win = win,
        filter = nil,
        co = coroutine.create(function()
            shell.run(scriptPath, table.unpack(args))
        end)
    }
end

local tasks = {
    createTask(topLeft,     "fission_reactor_mon.lua"),
    createTask(topRight,    "fusion_reactor_mon.lua"),
    createTask(bottomLeft,  "turbine_mon.lua"),
    createTask(bottomRight, "induction_matrix_mon.lua")
}

-- 3. Custom scheduler loop
local eventData = {}
while #tasks > 0 do
    for i = #tasks, 1, -1 do
        local task = tasks[i]
        local eventName = eventData[1]
        
        -- Resume on initial start (eventName == nil), matching filter, or terminate
        if task.filter == nil or task.filter == eventName or eventName == "terminate" then
            term.redirect(task.win)
            
            local ok, param = coroutine.resume(task.co, table.unpack(eventData))
            
            if not ok then
                term.redirect(parentTerm)
                error(param, 0)
            elseif coroutine.status(task.co) == "dead" then
                table.remove(tasks, i)
            else
                task.filter = param
            end
        end
    end
    
    -- Wait for the next event if any scripts are still running
    if #tasks > 0 then
        eventData = { os.pullEventRaw() }
    end
end

-- Clean up when all scripts finish
term.redirect(parentTerm)
term.setCursorPos(1, h)
print("\nAll scripts finished!")
