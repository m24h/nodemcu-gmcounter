local moduleName = ...
local M = {}
_G[moduleName] = M

local tool = require("tool")

local oled_i2c = 0  -- GPIO16
local oled_sda = 2  -- GPIO4
local oled_scl = 1  -- GPIO5
local oled_sla = 0x3c 

--- init oled 
--- font_5x7_tf,font_6x10_mf,font_7x13_mf,font_10x20_mf
i2c.setup(oled_i2c, oled_sda, oled_scl, i2c.FAST)
local oled = u8g2.ssd1306_i2c_128x32_univision(oled_i2c, oled_sla)
oled:setPowerSave(0)
oled:setDrawColor(1)
oled:setFlipMode(0)
oled:setFontMode(0)
oled:setBitmapMode(0)
oled:setFontDirection(0)
oled:setFontPosTop()
oled:setFontRefHeightAll()

--- 6*7
local wm_sta = string.char(0x00,0x1E,0x21,0x0C,0x12,0x00,0x0C)
local wm_ap  = string.char(0x0C,0x00,0x12,0x0C,0x21,0x1E,0x00)

--- turn on, default on, no need to use it for init
function M.on()
    oled:setPowerSave(0)
    oled:clearBuffer()
    oled:sendBuffer()
end

--- turn off
function M.off()
    oled:clearBuffer()
    oled:sendBuffer()
    oled:setPowerSave(1)
end

--- show in display with wellcome 
function M.welcome(dzt, rate)
    oled:clearBuffer()
    local s = ""

    -- line 1
    oled:setFont(u8g2.font_10x20_mf)
    s="G-M Counter"
    oled:drawStr((128-oled:getStrWidth(s))/2, 0, s)

    -- line 2
    oled:setFont(u8g2.font_6x10_mf)
    -- dead time
    s="d:" .. dzt .. "\181s"
    oled:drawStr(0, 22, s)
    -- rate
    s="r:" .. rate .. "/\181Sv"
    oled:drawStr(128-oled:getStrWidth(s), 22, s)

    oled:sendBuffer()
end


--- show in display with given contents
--- parameter units : (second, volt, count, 0.01uSv/h, 0.01 counts per minute, 0.01uSv/h)
function M.main(time, batt, cp, cpm, usv, avg)
    oled:clearBuffer()
    local s = ""
    
    -- line 1
    oled:setFont(u8g2.font_5x7_tf)
    -- battery
    oled:drawHLine(1,0,2)
    oled:drawFrame(0,1,4,6)
    if (batt>4000) then
        oled:drawBox(1,2,2,4)
    elseif (batt>3900) then
        oled:drawBox(1,3,2,3)
    elseif (batt>3800) then
        oled:drawBox(1,4,2,2)
    elseif (batt>3700) then
        oled:drawBox(1,5,2,1)
    end
    -- network
    local wifimode=wifi.getmode()
    if wifimode==wifi.STATION then
        oled:drawXBM(5, 0, 6, 7, wm_sta)
    elseif wifimode~=wifi.NULLMODE then
        oled:drawXBM(5, 0, 6, 7, wm_ap)
    end
    -- time
    s = tool.timeStr(time)
    oled:drawStr(wifimode~=wifi.NULLMODE and 12 or 5, 0, s)
    -- pulses
    s = tool.numStrK(cp)
    oled:drawStr(128-oled:getStrWidth(s), 0, s)

    -- line2
    oled:setFont(u8g2.font_7x13_mf)
    -- usv
    s=tool.numStr5d2(usv, " \181Sv/h", " mSv/h")
    oled:drawStr(128-oled:getStrWidth(s), 8, s)
    
    -- line3
    oled:setFont(u8g2.font_6x10_mf)
    -- cpm
    s=tool.numStr5d2(cpm, "/m", "k/m")
    oled:drawStr(0, 22, s)
    -- avg
    s=tool.numStr5d2(avg, " \181Sv/h", " mSv/h")
    oled:drawStr(128-oled:getStrWidth(s), 22, s)

    oled:sendBuffer()
end

return M