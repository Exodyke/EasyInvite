local function InitDB()
    if not EasyInviteDB then EasyInviteDB = {} end
    if EasyInviteDB.enableWhisper == nil then EasyInviteDB.enableWhisper = true end
    if EasyInviteDB.whisperMessage == nil then 
        EasyInviteDB.whisperMessage = "Инвайчу в гильдию, не забудь в чат гильдии указать свои имя, спек и гс!" 
    end
    if EasyInviteDB.enableWelcome == nil then EasyInviteDB.enableWelcome = true end
    if EasyInviteDB.welcomeMessage == nil then 
        EasyInviteDB.welcomeMessage = "Приветствую %s в нашей гильдии %g! Укажи в чат гильдии свои имя, спек и гс!" 
    end
end

UnitPopupButtons["EASY_GUILD_INVITE"] = { text = "|cff00ff00Пригласить в гильдию|r", dist = 0 }

hooksecurefunc("UnitPopup_ShowMenu", function(dropdownMenu, which, unit, name, userData)
    if which == "CHAT_ROSTER" or which == "PLAYER" or which == "PARTY" or which == "FRIEND" then
        local targetName = name or (unit and UnitName(unit))
        if targetName and targetName ~= UnitName("player") then
            local count = #UnitPopupShown
            UnitPopupShown[count + 1] = 1
            
            local buttonInfo = UnitPopupButtons["EASY_GUILD_INVITE"]
            UIDropDownMenu_AddButton({
                text = buttonInfo.text,
                value = "EASY_GUILD_INVITE",
                notCheckable = 1,
                func = function()
                    local dropdown = UIDROPDOWNMENU_INIT_MENU
                    if dropdown then
                        local n = dropdown.name
                        if not n and dropdown.unit then
                            n = UnitName(dropdown.unit)
                        end
                        if not n then
                            n = targetName
                        end
                        if n and n ~= UnitName("player") then
                            GuildInvite(n)
                            if EasyInviteDB.enableWhisper and EasyInviteDB.whisperMessage ~= "" then
                                local cleanWhisper = string.gsub(EasyInviteDB.whisperMessage, "[\r\n]", " ")
                                SendChatMessage(cleanWhisper, "WHISPER", nil, n)
                            end
                        else
                            UIErrorsFrame:AddMessage("Не удалось определить имя игрока или это ваш ник", 1.0, 0.1, 0.1, 1.0)
                        end
                    end
                end
            }, UIDROPDOWNMENU_MENU_LEVEL)
        end
    end
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "EasyInvite" then
        InitDB()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "CHAT_MSG_SYSTEM" and EasyInviteDB.enableWelcome then
        local playerName = string.match(arg1, "([^%s]+) присоединяется к гильдии%.")
        if playerName then
            local guildName = GetGuildInfo("player") or "нашей гильдии"
            local msg = EasyInviteDB.welcomeMessage
            msg = string.gsub(msg, "%%s", playerName)
            msg = string.gsub(msg, "%%g", guildName)
            msg = string.gsub(msg, "[\r\n]", " ")
            
            local delayFrame = CreateFrame("Frame")
            local elapsed = 0
            delayFrame:SetScript("OnUpdate", function(f, delta)
                elapsed = elapsed + delta
                if elapsed >= 2.0 then
                    SendChatMessage(msg, "GUILD")
                    delayFrame:SetScript("OnUpdate", nil)
                end
            end)
        end
    end
end)

local optionsPanel = CreateFrame("Frame", "EasyInviteOptionsPanel", InterfaceOptionsFramePanelContainer)
optionsPanel.name = "EasyInvite"

local bgButton = CreateFrame("Button", nil, optionsPanel)
bgButton:SetAllPoints(optionsPanel)
bgButton:SetFrameLevel(optionsPanel:GetFrameLevel())
bgButton:SetScript("OnClick", function()
    local editW = _G["EasyInviteOptionsPanelEditWhisper"]
    local editWelcome = _G["EasyInviteOptionsPanelEditWelcome"]
    if editW then editW:ClearFocus() end
    if editWelcome then editWelcome:ClearFocus() end
end)

optionsPanel:SetScript("OnHide", function()
    local editW = _G["EasyInviteOptionsPanelEditWhisper"]
    local editWelcome = _G["EasyInviteOptionsPanelEditWelcome"]
    if editW then editW:ClearFocus() end
    if editWelcome then editWelcome:ClearFocus() end
end)

local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Настройки EasyInvite")

local author = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
author:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
author:SetText("Автор: |cffC41F3BExodyke|r")

optionsPanel.refresh = function()
    InitDB()
    _G[optionsPanel:GetName() .. "CheckWhisper"]:SetChecked(EasyInviteDB.enableWhisper)
    _G[optionsPanel:GetName() .. "EditWhisper"]:SetText(EasyInviteDB.whisperMessage)
    _G[optionsPanel:GetName() .. "EditWhisper"]:SetCursorPosition(0)
    _G[optionsPanel:GetName() .. "CheckWelcome"]:SetChecked(EasyInviteDB.enableWelcome)
    _G[optionsPanel:GetName() .. "EditWelcome"]:SetText(EasyInviteDB.welcomeMessage)
    _G[optionsPanel:GetName() .. "EditWelcome"]:SetCursorPosition(0)
end

optionsPanel:SetScript("OnShow", function()
    optionsPanel.refresh()
end)

local function CreateCheckbox(name, text, parent, x, y)
    local cb = CreateFrame("CheckButton", parent:GetName() .. name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    _G[cb:GetName() .. "Text"]:SetText(text)
    return cb
end

local function CreateMultiLineEditBox(name, parent, x, y, width, height)
    local container = CreateFrame("Frame", parent:GetName() .. name .. "Container", parent)
    container:SetSize(width, height)
    container:SetPoint("TOPLEFT", x, y)
    container:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    container:SetBackdropColor(0, 0, 0, 0.5)
    container:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local eb = CreateFrame("EditBox", parent:GetName() .. name, container)
    eb:SetPoint("TOPLEFT", container, 8, -6)
    eb:SetPoint("BOTTOMRIGHT", container, -8, 6)
    eb:SetFontObject("GameFontHighlight")
    eb:SetMaxLetters(250)
    eb:SetAutoFocus(false)
    eb:SetMultiLine(true)
    
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    eb:SetScript("OnKeyDown", function(self, key)
        if key == "ENTER" then
            self:ClearFocus()
        end
    end)
    
    return eb
end

local checkWhisper = CreateCheckbox("CheckWhisper", "Отправлять шепот при приглашении", optionsPanel, 16, -70)
checkWhisper:SetScript("OnClick", function(self) EasyInviteDB.enableWhisper = self:GetChecked() and true or false end)

local labelWhisper = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
labelWhisper:SetPoint("TOPLEFT", 16, -105)
labelWhisper:SetText("Текст сообщения в ПМ:")

local editWhisper = CreateMultiLineEditBox("EditWhisper", optionsPanel, 20, -125, 380, 42)
editWhisper:SetScript("OnTextChanged", function(self) EasyInviteDB.whisperMessage = self:GetText() end)

local checkWelcome = CreateCheckbox("CheckWelcome", "Приветствовать новых игроков в чате гильдии", optionsPanel, 16, -195)
checkWelcome:SetScript("OnClick", function(self) EasyInviteDB.enableWelcome = self:GetChecked() and true or false end)

local labelWelcome = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
labelWelcome:SetPoint("TOPLEFT", 16, -230)
labelWelcome:SetText("Текст приветствия в гильд-чат:")

local editWelcome = CreateMultiLineEditBox("EditWelcome", optionsPanel, 20, -250, 380, 42)
editWelcome:SetScript("OnTextChanged", function(self) EasyInviteDB.welcomeMessage = self:GetText() end)

local hintTitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
hintTitle:SetPoint("TOPLEFT", 16, -325)
hintTitle:SetText("|cff00ff00Доступные теги подстановки:|r")

local hintTags = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
hintTags:SetPoint("TOPLEFT", 16, -345)
hintTags:SetJustifyH("LEFT")
hintTags:SetText("%s — Ник вступившего игрока\n%g — Название вашей гильдии")

InterfaceOptions_AddCategory(optionsPanel)

SLASH_EASYINVITE1 = "/easyinvite"
SlashCmdList["EASYINVITE"] = function()
    InterfaceOptionsFrame_OpenToCategory(optionsPanel)
end

print("|cff00ff00EasyInvite успешно загружен!|r Настройки: /easyinvite или Меню -> Интерфейс -> Модификации.")


-- ПОСМОТРЕЛ? ДОВОЛЕН?