--[[
  return a function, which called thus return an object as
    .pin  --- init set, pin number for interrupt
    .ud   --- init set, "down" or "up", interrupt type
    .dzt  --- init set, dead zone time of GM tube, in microsecond
    .cpm  --- set/get, in 0.01 CPM, corrected by dead time
    .cnt  --- set/get, total pulses count, raw, not corrected
    .dur  --- set/get, total counting duration, in second, corrected by dead time
    .dud  --- set/get, additional duration, in microsecond, 0 to 999999 
    :start()  --- start GM working
    :stop()   --- stop GM work, but not clear old setting and data
    :clear()  --- clear all non-setting data as a new start 
--]]
local tool=require("tool")

local function stop (self)
    local pin=self.pin
    if pin then
        gpio.trig(pin, "none")
    end
end

local function start (self)
    stop (self)
    
    local pin=self.pin
    assert(pin, "gmcounter's pin is nil")
        
    gpio.mode(pin, gpio.INT)
    local pls  = 0
    local last = tmr.now()   -- last pulses time, us
    gpio.trig(pin, self.ud, function(level, when, cnt) 
        pls = pls + cnt
        local t = bit.band(0x7fffffff, when - last) - self.dzt * pls
        --- calculate only when time passed at least 500ms after last calculating
        if t>=500000 then
            -- cpm=pls*6000*1M/wd, in this short duration from last calculating
            local a = (t+5)/10  --- avoid overflow, 6,000,000,000 > 2^31
            local b = tool.muldiv(pls, 600000000, a/2, a)

            -- cpm quality, empirical formula
            a = pls + t/200000 + b*5/(self.cpm+1) + self.cpm*5/(b+1)
            --- limit to range: 10% - 30%
            a = a<10 and 10 or a>50 and 50 or a 
            self.cpm = tool.muldiv(b, a, 50, 100) + tool.muldiv(self.cpm, 100-a, 50, 100)

            -- add to durations and count
            a = self.dud + t
            b = a/1000000
            self.dur = self.dur + b 
            self.dud = a - b*1000000
            self.cnt = self.cnt + pls
            pls = 0
            last = when
        end
    end)
end

local function clear (self)
    self.cpm = 0
    self.cnt = 0
    self.dur = 0
    self.dud = 0
end

local function gmcounter ()
    local gm = {}
    gm.pin = nil
    gm.ud  = "down"
    gm.dzt = 0
    gm.cpm = 0
    gm.cnt = 0
    gm.dur = 0
    gm.dud = 0
        
    gm.start = start
    gm.stop  = stop
    gm.check = check
    gm.clear = clear

    return gm
end
        
return gmcounter
