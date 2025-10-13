
EasyPoisons = {}
local mainFrame = nil
local poisonFrames = {}
local quantities = {}

-- Poison database with materials needed
local POISONS = {
    {
        name = "Dissolvent Poison II",
        itemID = 54010,
        icon = "Interface\\Icons\\spell_nature_slowpoison",
        materials = {
            {itemID = 8924, name = "Dust of Deterioration", amount = 3},
            {itemID = 2931, name = "Maiden's Anguish", amount = 4},
            {itemID = 8925, name = "Crystal Vial", amount = 1, stackSize = 5}
        }
    },
    {
        name = "Crippling Poison II",
        itemID = 3776,
        icon = "Interface\\Icons\\inv_potion_19",
        materials = {
            {itemID = 8923, name = "Essence of Agony", amount = 3},
            {itemID = 8925, name = "Crystal Vial", amount = 1, stackSize = 5}
        }
    },
    {
        name = "Instant Poison IV",
        itemID = 8928,
        icon = "Interface\\Icons\\ability_poisons",
        materials = {
            {itemID = 8924, name = "Dust of Deterioration", amount = 4},
            {itemID = 8925, name = "Crystal Vial", amount = 1, stackSize = 5}
        }
    },
    {
        name = "Corrosive Poison II",
        itemID = 47409,
        icon = "Interface\\Icons\\inv_corrosive_01",
        materials = {
            {itemID = 8924, name = "Dust of Deterioration", amount = 3},
            {itemID = 5173, name = "Deathweed", amount = 3},
            {itemID = 8925, name = "Crystal Vial", amount = 1, stackSize = 5}
        }
    },
    {
        name = "Deadly Poison V",
        itemID = 20844,
        icon = "Interface\\Icons\\ability_rogue_dualweild",
        materials = {
            {itemID = 5173, name = "Deathweed", amount = 7},
            {itemID = 8925, name = "Crystal Vial", amount = 1, stackSize = 5}
        }
    },
    {
        name = "Mind-numbing Poison III",
        itemID = 9186,
        icon = "Interface\\Icons\\spell_nature_nullifydisease",
        materials = {
            {itemID = 8924, name = "Dust of Deterioration", amount = 2},
            {itemID = 8923, name = "Essence of Agony", amount = 2},
            {itemID = 8925, name = "Crystal Vial", amount = 1, stackSize = 5}
        }
    }
}

-- Initialize saved variables
function EasyPoisons:Initialize()
    if not EasyPoisonsDB then
        EasyPoisonsDB = {}
    end

    -- Initialize quantities
    for i = 1, table.getn(POISONS) do
        quantities[i] = 0
    end
end

-- Get item price from vendor
function EasyPoisons:GetItemPrice(itemID)
    local numItems = GetMerchantNumItems()
    for i = 1, numItems do
        local link = GetMerchantItemLink(i)
        if link then
            local _, _, itemString = string.find(link, "item:(%d+)")
            if itemString and tonumber(itemString) == itemID then
                local name, texture, price, quantity, numAvailable, isUsable = GetMerchantItemInfo(i)
                return price or 0
            end
        end
    end
    return 0
end

-- Calculate total cost
function EasyPoisons:CalculateTotalCost()
    local totalCost = 0
    local materialTotals = {}

    -- First, calculate total materials needed across all poisons
    for i = 1, table.getn(POISONS) do
        local poison = POISONS[i]
        local qty = quantities[i] or 0

        if qty > 0 then
            for j = 1, table.getn(poison.materials) do
                local mat = poison.materials[j]
                local neededAmount = mat.amount * qty

                -- Add to material totals
                if not materialTotals[mat.itemID] then
                    materialTotals[mat.itemID] = {
                        total = 0,
                        stackSize = mat.stackSize or 1
                    }
                end
                materialTotals[mat.itemID].total = materialTotals[mat.itemID].total + neededAmount
            end
        end
    end

    -- Now calculate cost based on total materials needed
    for itemID, data in materialTotals do
        local stacksToBuy = math.ceil(data.total / data.stackSize)
        local price = EasyPoisons:GetItemPrice(itemID)
        -- Price is per stack, so multiply by number of stacks
        totalCost = totalCost + (price * stacksToBuy)
    end

    return totalCost
end

-- Format money with colored text
function EasyPoisons:FormatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor(math.mod(copper, 10000) / 100)
    copper = math.mod(copper, 100)

    local text = ""

    if gold > 0 then
        text = text .. "|cFFFFD700" .. gold .. "g|r "
    end

    if silver > 0 or gold > 0 then
        text = text .. "|cFFC0C0C0" .. silver .. "s|r "
    end

    text = text .. "|cFFB87333" .. copper .. "c|r"

    return text
end

-- Update cost display
function EasyPoisons:UpdateCostDisplay()
    if not mainFrame or not mainFrame.costText then return end

    local cost = EasyPoisons:CalculateTotalCost()
    mainFrame.costText:SetText(EasyPoisons:FormatMoney(cost))
end

-- Create input box
function EasyPoisons:CreateInputBox(parent, width)
    local input = CreateFrame("EditBox", nil, parent)
    input:SetWidth(width)
    input:SetHeight(16)
    input:SetAutoFocus(false)
    input:SetNumeric(true)
    input:SetMaxLetters(3)

    input:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 6,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    input:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    input:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local font = input:CreateFontString(nil, "OVERLAY")
    font:SetFontObject(GameFontNormalSmall)
    input:SetFontObject(GameFontNormalSmall)
    input:SetTextColor(1, 1, 1, 1)
    input:SetTextInsets(4, 4, 0, 0)
    input:SetJustifyH("CENTER")

    input:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)

    input:SetScript("OnEnterPressed", function()
        this:ClearFocus()
    end)

    return input
end

-- Create poison row
function EasyPoisons:CreatePoisonRow(parent, index)
    local poison = POISONS[index]
    local frame = CreateFrame("Frame", "EasyPoisonRow"..index, parent)
    frame:SetWidth(280)
    frame:SetHeight(22)

    -- Background
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = nil,
        tile = true, tileSize = 16,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    })
    frame:SetBackdropColor(0.15, 0.15, 0.15, 0.6)

    -- Enable mouse for hover effect
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function()
        frame:SetBackdropColor(0.25, 0.35, 0.45, 0.8)
    end)
    frame:SetScript("OnLeave", function()
        frame:SetBackdropColor(0.15, 0.15, 0.15, 0.6)
    end)

    -- Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(18)
    icon:SetHeight(18)
    icon:SetPoint("LEFT", frame, "LEFT", 3, 0)
    icon:SetTexture(poison.icon)

    -- Name
    local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    nameText:SetWidth(180)
    nameText:SetJustifyH("LEFT")
    nameText:SetText(poison.name)
    nameText:SetTextColor(0.9, 0.9, 0.9, 1)

    -- Minus button
    local minusButton = CreateFrame("Button", nil, frame)
    minusButton:SetWidth(14)
    minusButton:SetHeight(14)
    minusButton:SetPoint("RIGHT", frame, "RIGHT", -75, 0)
    minusButton:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 4,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    minusButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8)
    minusButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    local minusText = minusButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    minusText:SetPoint("CENTER", minusButton, "CENTER", 0, 0)
    minusText:SetText("-")
    minusText:SetTextColor(1, 1, 1, 1)

    minusButton:SetScript("OnEnter", function()
        minusButton:SetBackdropColor(0.8, 0.3, 0.3, 1)
    end)
    minusButton:SetScript("OnLeave", function()
        minusButton:SetBackdropColor(0.6, 0.2, 0.2, 0.8)
    end)
    minusButton:SetScript("OnClick", function()
        if quantities[index] > 0 then
            quantities[index] = quantities[index] - 1
            frame.input:SetText(tostring(quantities[index]))
            EasyPoisons:UpdateCostDisplay()
        end
    end)

    -- Input box
    local input = EasyPoisons:CreateInputBox(frame, 40)
    input:SetPoint("RIGHT", frame, "RIGHT", -32, 0)
    input:SetText("0")
    frame.input = input

    input:SetScript("OnTextChanged", function()
        local value = tonumber(this:GetText()) or 0
        if value < 0 then
            value = 0
            this:SetText("0")
        end
        quantities[index] = value
        EasyPoisons:UpdateCostDisplay()
    end)

    -- Plus button
    local plusButton = CreateFrame("Button", nil, frame)
    plusButton:SetWidth(14)
    plusButton:SetHeight(14)
    plusButton:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
    plusButton:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 4,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    plusButton:SetBackdropColor(0.2, 0.6, 0.2, 0.8)
    plusButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    local plusText = plusButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    plusText:SetPoint("CENTER", plusButton, "CENTER", 0, 0)
    plusText:SetText("+")
    plusText:SetTextColor(1, 1, 1, 1)

    plusButton:SetScript("OnEnter", function()
        plusButton:SetBackdropColor(0.3, 0.8, 0.3, 1)
    end)
    plusButton:SetScript("OnLeave", function()
        plusButton:SetBackdropColor(0.2, 0.6, 0.2, 0.8)
    end)
    plusButton:SetScript("OnClick", function()
        quantities[index] = quantities[index] + 1
        frame.input:SetText(tostring(quantities[index]))
        EasyPoisons:UpdateCostDisplay()
    end)

    frame:Hide()
    return frame
end

-- Create main window
function EasyPoisons:CreateMainFrame()
    if mainFrame then return end

    mainFrame = CreateFrame("Frame", "EasyPoisonsFrame", UIParent)
    mainFrame:SetWidth(300)
    mainFrame:SetHeight(260)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    mainFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    mainFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    mainFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    mainFrame:SetFrameStrata("HIGH")
    mainFrame:Hide()

    -- Get addon metadata
    local addonVersion = GetAddOnMetadata("EasyPoisons", "Version") or "1.0"
    local addonAuthor = GetAddOnMetadata("EasyPoisons", "Author") or "Unknown"

    -- Title
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -8)
    title:SetText("|cFF00FF00EasyPoisons|r |cFFAAAAAA v" .. addonVersion .. "|r")
    title:SetTextColor(1, 1, 1, 1)

    -- Author
    local author = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    author:SetPoint("TOP", title, "BOTTOM", 0, -2)
    author:SetText("|cFF888888by " .. addonAuthor .. "|r")
    author:SetTextColor(0.7, 0.7, 0.7, 1)

    -- Close button
    local closeButton = CreateFrame("Button", nil, mainFrame)
    closeButton:SetWidth(12)
    closeButton:SetHeight(12)
    closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -6, -6)
    closeButton:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 4,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    closeButton:SetBackdropColor(0.8, 0.2, 0.2, 0.8)
    closeButton:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    local closeText = closeButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    closeText:SetPoint("CENTER", closeButton, "CENTER", 0, 0)
    closeText:SetText("×")
    closeText:SetTextColor(1, 1, 1, 1)

    closeButton:SetScript("OnEnter", function()
        closeButton:SetBackdropColor(1, 0.3, 0.3, 1)
    end)
    closeButton:SetScript("OnLeave", function()
        closeButton:SetBackdropColor(0.8, 0.2, 0.2, 0.8)
    end)
    closeButton:SetScript("OnClick", function()
        mainFrame:Hide()
    end)

    -- Content area
    local content = CreateFrame("Frame", nil, mainFrame)
    content:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -40)
    content:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -10, -40)
    content:SetHeight(160)
    mainFrame.content = content

    -- Create poison rows
    local yOffset = 0
    for i = 1, table.getn(POISONS) do
        if not poisonFrames[i] then
            poisonFrames[i] = EasyPoisons:CreatePoisonRow(content, i)
        end
        local frame = poisonFrames[i]
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        frame:Show()
        yOffset = yOffset - 24
    end

    -- Reset button
    local resetButton = CreateFrame("Button", nil, mainFrame)
    resetButton:SetWidth(80)
    resetButton:SetHeight(20)
    resetButton:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 30, 35)
    resetButton:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 4,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    resetButton:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    resetButton:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    local resetText = resetButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetText:SetPoint("CENTER", resetButton, "CENTER", 0, 0)
    resetText:SetText("Reset")
    resetText:SetTextColor(0.9, 0.9, 0.9, 1)

    resetButton:SetScript("OnEnter", function()
        resetButton:SetBackdropColor(0.3, 0.3, 0.3, 1)
    end)
    resetButton:SetScript("OnLeave", function()
        resetButton:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    end)
    resetButton:SetScript("OnClick", function()
        EasyPoisons:ResetQuantities()
    end)

    -- Buy button
    local buyButton = CreateFrame("Button", nil, mainFrame)
    buyButton:SetWidth(80)
    buyButton:SetHeight(20)
    buyButton:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -30, 35)
    buyButton:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 4,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    buyButton:SetBackdropColor(0.2, 0.7, 0.2, 0.9)
    buyButton:SetBackdropBorderColor(0.2, 0.8, 0.2, 1)

    local buyText = buyButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buyText:SetPoint("CENTER", buyButton, "CENTER", 0, 0)
    buyText:SetText("Buy")
    buyText:SetTextColor(1, 1, 1, 1)

    buyButton:SetScript("OnEnter", function()
        buyButton:SetBackdropColor(0.3, 0.9, 0.3, 1)
        buyButton:SetBackdropBorderColor(0.3, 1, 0.3, 1)
    end)
    buyButton:SetScript("OnLeave", function()
        buyButton:SetBackdropColor(0.2, 0.7, 0.2, 0.9)
        buyButton:SetBackdropBorderColor(0.2, 0.8, 0.2, 1)
    end)
    buyButton:SetScript("OnClick", function()
        EasyPoisons:BuyMaterials()
    end)

    -- Cost display
    local costLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    costLabel:SetPoint("BOTTOM", mainFrame, "BOTTOM", -40, 8)
    costLabel:SetText("Total Cost:")
    costLabel:SetTextColor(0.7, 0.7, 0.7, 1)

    local costText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    costText:SetPoint("LEFT", costLabel, "RIGHT", 5, 0)
    costText:SetText(EasyPoisons:FormatMoney(0))
    costText:SetTextColor(1, 0.85, 0, 1)
    mainFrame.costText = costText
end

-- Reset all quantities
function EasyPoisons:ResetQuantities()
    for i = 1, table.getn(POISONS) do
        quantities[i] = 0
        if poisonFrames[i] and poisonFrames[i].input then
            poisonFrames[i].input:SetText("0")
        end
    end
    EasyPoisons:UpdateCostDisplay()
end

-- Buy materials
function EasyPoisons:BuyMaterials()
    local totalCost = EasyPoisons:CalculateTotalCost()
    local playerMoney = GetMoney()

    if totalCost > playerMoney then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000EasyPoisons: Not enough money!|r")
        return
    end

    local materialTotals = {}

    -- Build material totals across all poisons
    for i = 1, table.getn(POISONS) do
        local poison = POISONS[i]
        local qty = quantities[i] or 0

        if qty > 0 then
            for j = 1, table.getn(poison.materials) do
                local mat = poison.materials[j]
                local neededAmount = mat.amount * qty

                -- Add to material totals
                if not materialTotals[mat.itemID] then
                    materialTotals[mat.itemID] = {
                        name = mat.name,
                        total = 0,
                        stackSize = mat.stackSize or 1
                    }
                end
                materialTotals[mat.itemID].total = materialTotals[mat.itemID].total + neededAmount
            end
        end
    end

    -- Build purchase list with optimized stack counts
    local purchaseList = {}
    for itemID, data in materialTotals do
        local stacksToBuy = math.ceil(data.total / data.stackSize)
        table.insert(purchaseList, {
            itemID = itemID,
            name = data.name,
            stacks = stacksToBuy,
            stackSize = data.stackSize
        })
    end

    -- Purchase items
    local numItems = GetMerchantNumItems()
    for i = 1, table.getn(purchaseList) do
        local item = purchaseList[i]

        -- Find item in vendor list
        for j = 1, numItems do
            local link = GetMerchantItemLink(j)
            if link then
                local _, _, itemString = string.find(link, "item:(%d+)")
                if itemString and tonumber(itemString) == item.itemID then
                    -- Buy the item
                    local maxStack = GetMerchantItemMaxStack(j)
                    BuyMerchantItem(j, item.stacks)
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00EasyPoisons: Purchased " .. (item.stacks * item.stackSize) .. "x " .. item.name .. "|r")
                    break
                end
            end
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00EasyPoisons: Purchase complete!|r")
end

-- Check if vendor sells poison materials
function EasyPoisons:IsVendorPoisonVendor()
    local numItems = GetMerchantNumItems()
    if numItems == 0 then return false end

    -- Check if vendor sells any poison materials
    for i = 1, numItems do
        local link = GetMerchantItemLink(i)
        if link then
            local _, _, itemString = string.find(link, "item:(%d+)")
            local vendorItemID = tonumber(itemString)

            -- Check against all materials in our poison database
            for j = 1, table.getn(POISONS) do
                local poison = POISONS[j]
                for k = 1, table.getn(poison.materials) do
                    if poison.materials[k].itemID == vendorItemID then
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- Event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")

eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "EasyPoisons" then
        EasyPoisons:Initialize()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00EasyPoisons loaded! Type /easypoisons to toggle window.|r")
    elseif event == "MERCHANT_SHOW" then
        if EasyPoisons:IsVendorPoisonVendor() then
            if not mainFrame then
                EasyPoisons:CreateMainFrame()
            end
            mainFrame:Show()
            EasyPoisons:UpdateCostDisplay()
        end
    elseif event == "MERCHANT_CLOSED" then
        if mainFrame and mainFrame:IsVisible() then
            mainFrame:Hide()
        end
    end
end)

-- Slash command
SLASH_EASYPOISONS1 = "/easypoisons"
SLASH_EASYPOISONS2 = "/ep"
SlashCmdList["EASYPOISONS"] = function(msg)
    if not mainFrame then
        EasyPoisons:CreateMainFrame()
    end

    if mainFrame:IsVisible() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        EasyPoisons:UpdateCostDisplay()
    end
end
