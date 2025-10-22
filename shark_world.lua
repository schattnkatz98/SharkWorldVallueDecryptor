-- HSW Class Finder Script
-- This script finds the class PlayerControlGenericFish in Hungry Shark World (HSW)

searchClassName = "PlayerControlGenericFish"
largeOffset = 0xfffffffffffffff0  -- Large offset for pointer adjustment

-- Function to choose between REGION_ANONYMOUS and REGION_OTHER
function chooseRegion()
    local regionChoice = gg.choice({"Anonymous", "Other"}, nil, "Choose Region for search:")
    if regionChoice == 1 then
        gg.setRanges(gg.REGION_ANONYMOUS)
        gg.toast("Anonymous region selected")
    elseif regionChoice == 2 then
        gg.setRanges(gg.REGION_OTHER)
        gg.toast("Other region selected")
    else
        gg.toast("No region selected. Exiting...")
        os.exit()
    end
end

-- Function to search for the class name and refine results
function searchClassNameAndRefine()
    gg.toast("Searching for class: " .. searchClassName)
    gg.searchNumber(':' .. searchClassName, gg.TYPE_BYTE)  -- Search for class name
    gg.sleep(1000)
    local count = gg.getResultsCount()
    if count == 0 then
        gg.toast("No results found for class.")
        os.exit()
    end
    gg.toast("Found " .. count .. " results. Refining...")
    
    local results = gg.getResults(count)
    gg.refineNumber(results[1].value, gg.TYPE_BYTE)  -- Refine based on the first result (P of Player)
    
    -- Save the refined results for pointer search
    refinedResults = gg.getResults(9999)
    gg.addListItems(refinedResults)
end

-- Function to search for pointers and apply offset
function searchPointersAndApplyOffset()
    local results = gg.getResults(9999)
    
    -- Delete old list items before pointer search
    gg.clearList()
    gg.toast("Deleted old list items.")
    
    gg.toast("Searching pointers in C_ALLOC or ANONYMOUS")
    gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_ANONYMOUS)
    gg.loadResults(refinedResults)  -- Load saved refined results
    gg.searchPointer(0)  -- Pointer search
    local pointerCount = gg.getResultsCount()
    if pointerCount == 0 then
        gg.toast("No pointers found.")
        os.exit()
    end
    gg.toast("Found " .. pointerCount .. " pointers. Applying large offset...")

    -- Apply large offset to found pointers
    local pointers = gg.getResults(pointerCount)
    for i, v in ipairs(pointers) do
        v.address = v.address + largeOffset
    end
    gg.addListItems(pointers)  -- Save adjusted pointers
end


function repeatPointerSearchOnAdjusted()
    gg.toast("Searching for pointers on adjusted addresses in ANONYMOUS...")
    
    -- Load the adjusted pointer results
    local adjustedResults = gg.getListItems()
    
    -- Clear old list before new pointer search
    gg.clearList()
    
    -- Perform pointer search again in ANONYMOUS
    gg.setRanges(gg.REGION_ANONYMOUS)
    gg.loadResults(adjustedResults)
    gg.searchPointer(0)
    
    local finalPointerCount = gg.getResultsCount()
    if finalPointerCount == 0 then
        gg.toast("No further pointers found.")
        os.exit()
    end
    gg.toast("Found " .. finalPointerCount .. " final pointers.")
    
    -- Save the final pointer results
    finalPointers = gg.getResults(finalPointerCount)
    gg.addListItems(finalPointers)
    
    gg.toast("Final pointer search completed.")
end

function refineResults()
    local pointers = gg.getListItems()
    gg.clearList()

    gg.loadResults(pointers)
    gg.searchPointer(0)

    local count = gg.getResultsCount()
    if count == 0 then
        gg.toast("No results found for class.")
        os.exit()
    end
    gg.toast("Found " .. count .. " results. Refining...")
    PointerResults = gg.getResults(count)
    gg.addListItems(PointerResults)
    gg.clearResults()
end

function filterFrequentAddresses()
    local allResults = gg.getListItems()  -- Lade alle gespeicherten Ergebnisse
    class = {}  -- Zählt, wie oft jede Adresse vorkommt


    for i = 1, #allResults do
        -- Erzeuge eine **neue Tabelle** für jedes Element in `h`
        class[i] = {
            address = allResults[i].value,
            flags = 32
        }
    end
    gg.clearList()

end



function menu()
    while true do
        -- Display the multi-choice menu
        local mc = gg.multiChoice({'BaseSpeed', 'tornadoeat', 'UnlSpeed', 'exit'}, nil, 'made by skulduggery98 :)')

        -- If no selection is made (user cancels), hide the GG menu and wait for the user to reopen it
        if mc == nil then
            gg.toast("No selection made, hiding menu.")
            gg.setVisible(false)
            while not gg.isVisible() do
                gg.sleep(100)  -- Wait until the user reopens GG
            end
            gg.setVisible(false)  -- Hide the UI again once it's opened
        else
            -- Handle each choice properly by checking the table entries
            if mc[1] then
                local SharkSpeed = gg.prompt(
                    {"Enter the value for SharkSpeed:"},  -- Prompt message
                    {30},  -- Default value (optional)
                    {"number"}  -- Input type (number, text, etc.)
                )
                -- Call the function with user input
                if SharkSpeed ~= nil then
                    PatchBaseSpeed(SharkSpeed)
                end
            end

            if mc[2] then
                local BiteRadius = gg.prompt(
                    {"Bite Radius"},  -- Prompt message
                    {10},  -- Default value (optional)
                    {"number"}  -- Input type (number, text, etc.)
                )
                PatchBiteRadius(BiteRadius)

            end

            if mc[3] then
                PatchSpeedBar()
            end

            if mc[4] then
                gg.toast("Exiting script...")
                os.exit()
            end
        end
    end
end


function PatchBaseSpeed(SharkSpeed)
    local off = {
        ['SharkSpeed'] = 0xD8
    }

    speed = {}
    for i, v in ipairs(class) do
        speed[i] = {
            address = v.address + off['SharkSpeed'],
            flags = gg.TYPE_FLOAT,
            value = SharkSpeed[1],
            name = 'SharkBaseSpeed'
        }
  
    end
    gg.addListItems(speed)
    gg.setValues(speed)
end

function PatchBiteRadius(BiteRadius)
    local off = {
        ['BiteRadiusFraction'] = 0xDC, 
        ['BiteRadius'] = 0x150
    }

    BiteRadiusFraction = {}
    SharkBiteRadius = {}

    for i, v in ipairs(class) do
        BiteRadiusFraction[i] = {
            address = v.address + off['BiteRadiusFraction'],
            flags = gg.TYPE_FLOAT,
            value = BiteRadius[1],
            name = 'BiteRadiusFraction'
        }
    end

    for i, v in ipairs(class) do
        SharkBiteRadius[i] = {
            address = v.address + off['BiteRadius'],
            flags = gg.TYPE_FLOAT,
            value = BiteRadius[1],
            name = 'SharkBiteRadius'
        }
    end
    gg.addListItems(BiteRadiusFraction)
    gg.addListItems(SharkBiteRadius)
    gg.setValues(BiteRadiusFraction)
    gg.setValues(SharkBiteRadius)
end

function PatchSpeedBar()
    local off = {
        ['SpeedBar'] = 0x138
    }
    SpeedBar = {}

    for i, v in ipairs(class) do
        SpeedBar[i] = {
            address = v.address + off['SpeedBar'],
            flags = gg.TYPE_FLOAT,
            value = 0,000123,
            name = 'SpeedBar'
        }
    end
    gg.addListItems(SpeedBar)
    gg.setValues(SpeedBar)
end



-- Main script execution
function main()
    gg.clearResults()
    gg.clearList()
    chooseRegion()
    searchClassNameAndRefine()  -- Search and refine class results
    searchPointersAndApplyOffset()  -- Search pointers and apply offset
    repeatPointerSearchOnAdjusted()
    refineResults()
    filterFrequentAddresses()
    menu()
    gg.toast("Class search and pointer search completed!")
end
main()
