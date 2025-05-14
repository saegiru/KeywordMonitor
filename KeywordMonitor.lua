local addonName = "KeywordMonitor"
local frame, scroll, db

-- create main frame
frame = CreateFrame("Frame", addonName.."Frame", UIParent)
frame:SetSize(300, 200)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetBackdrop({
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true, tileSize = 32, edgeSize = 32,
  insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

-- title text
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", frame, "TOP", 0, -8)
title:SetText("Keyword Monitor")

-- scrolling message area
scroll = CreateFrame("ScrollingMessageFrame", addonName.."Scroll", frame)
scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28)
scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
scroll:SetFontObject("ChatFontNormal")
scroll:SetFading(false)
scroll:SetMaxLines(200)
scroll:EnableMouseWheel(true)
scroll:SetScript("OnMouseWheel", function(self, delta)
  if delta > 0 then self:ScrollUp() else self:ScrollDown() end
end)

-- handle events
frame:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" then
    local name = ...
    if name == addonName then
      -- init saved‑vars
      if not KeywordMonitorDB then KeywordMonitorDB = {} end
      db = KeywordMonitorDB
      -- register all chat events
      for _, e in ipairs({
        "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_WHISPER",
        "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
        "CHAT_MSG_CHANNEL"
      }) do
        frame:RegisterEvent(e)
      end
      -- slash command
      SLASH_KWMON1 = "/kwmon"
      SlashCmdList["KWMON"] = function(msg) HandleSlash(msg) end
    end

  else
    -- chat message events
    local text, sender = ...
    if db and #db > 0 then
      local lower = text:lower()
      for i, kw in ipairs(db) do
        if lower:find(kw:lower(), 1, true) then
          local stamp = date("%H:%M")
          scroll:AddMessage(string.format("[%s] %s: %s", stamp, sender, text))
          PlaySoundFile("Sound\\Interface\\RaidWarning.ogg")
          frame:Show()
          break
        end
      end
    end
  end
end)

frame:RegisterEvent("ADDON_LOADED")

-- slash‑command handler
function HandleSlash(msg)
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
  cmd = cmd:lower()
  if cmd == "add" and rest ~= "" then
    tinsert(db, rest)
    print("|cffffff00[KW] Added keyword:|r "..rest)
  elseif cmd == "remove" and rest ~= "" then
    for i, v in ipairs(db) do
      if v:lower() == rest:lower() then
        tremove(db, i)
        print("|cffffff00[KW] Removed keyword:|r "..rest)
        return
      end
    end
    print("|cffff0000[KW] Keyword not found:|r "..rest)
  elseif cmd == "list" then
    if #db == 0 then
      print("|cffffff00[KW] No keywords set.|r")
    else
      print("|cffffff00[KW] Current keywords:|r")
      for _, v in ipairs(db) do print("  • "..v) end
    end
  elseif cmd == "show" then
    frame:Show()
  elseif cmd == "hide" then
    frame:Hide()
  else
    print("|cffffff00[KW] Usage:|r")
    print("  /kwmon add <word>")
    print("  /kwmon remove <word>")
    print("  /kwmon list")
    print("  /kwmon show | /kwmon hide")
  end
end
