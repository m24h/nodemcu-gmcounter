pinButton = 4  --- GPIO2
pinGM     = 5  --- GPIO14
pinPower  = 0  --- GPIO16

valBatt = 0
valDur  = 0
valCnt  = 0
valCpm  = 0
valUsv  = 0
valAcc  = 0  -- currently not used in fact, but leave for future
valAvg  = 0

------- check power button is pressed, to enable or disable power LDO
gpio.mode(pinButton, gpio.INPUT)
gpio.mode(pinPower, gpio.OUTPUT)
if gpio.read(pinButton)==1 then
    gpio.write(pinPower, 1)
else
    gpio.write(pinPower, 0)
    return  -- exit
end

------- force use ADC --------
if adc.force_init_mode(adc.INIT_ADC) then
  node.restart()
  return -- exit
end

-------- init tool -----
local tool = require("tool")

-------- init display --------
local disp = require("disp")

------- start --------
print ("power: on")
disp.welcome(cfg.dzt, cfg.rate)

------- main Loop timer -------
mainTimer = tmr.create()

-------- init wifi -------
if (cfg.ssid and cfg.ssid~="" and cfg.wpwd) then
    wifi.setmode(wifi.STATION, false)
    local t={auto=true; save=false}
    t.ssid=cfg.ssid
    t.pwd=cfg.wpwd
    t.got_ip_cb = function (ip) 
        print ("wifi:", ip.IP, ip.netmask, ip.gateway) 
    end
    wifi.sta.config(t)
end

--- start GM counter
gm = require("gmcounter")()
gm.pin  = pinGM       --- GPIO14
gm.ud   = "down"      --- use down edge trigger
gm.dzt  = cfg.dzt     --- GM tube dead zone time in us
gm:start()

---- main working functions -----

local function powerOff()
    mainTimer:unregister()
    gm:stop()
    disp.off()
    print ("power: off")
    gpio.write(pinPower, 0)
end

local function reCount()
    disp.welcome(cfg.dzt, cfg.rate)
    gm:stop()
    gm:clear()
    valDur  = 0
    valCnt  = 0
    valCpm  = 0
    valUsv  = 0
    valAcc  = 0
    valAvg  = 0
    gm:start()
end

local function readBatt()
    return (adc.read(0)*4774+500)/1000   -- need ourside 1/4.774 voltage dividing
end


--- main timer loop ----
mainTimer:alarm(1000, tmr.ALARM_AUTO, function()
    valBatt=readBatt()
    local a=cfg.rate
    local b=(valCnt~=gm.cnt)
    valCpm=gm.cpm
    valCnt=gm.cnt
    valDur=gm.dur
    valUsv=tool.muldiv(valCpm, 60, a/2, a)
    valAcc=tool.muldiv(valCnt, 100, a/2, a)
    local c=a*valDur
    valAvg=c>0 and tool.muldiv(valCnt, 360000, c/2, c) or 0
    disp.main(valDur, valBatt, valCnt, valCpm, valUsv, valAvg)
    if b then 
        print("data:", valDur, valBatt, valCnt, valCpm, valUsv, valAvg)
    end
end)

-------- init button key process ------
tool.key(pinButton, 1, reCount, powerOff)

