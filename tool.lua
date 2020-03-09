local moduleName = ...
local M = {}
_G[moduleName] = M

-- make time string in 12:34:56 format
function M.timeStr(t)
    local a = t/3600
    t = t%3600
    return string.format("%02d:%02d:%02d", a, t/60, t%60)
end

-- make number string using "," as thousands separator
function M.numStrK(n)
    if (n<1000) then
        return tostring(n)
    elseif (n<1000000) then
        return string.format("%d,%03d", n/1000, n%1000)
    elseif (n<1000000000) then
        local a=n/1000000
        n=n%1000000
        return string.format("%d,%03d,%03d", a, n/1000, n%1000)
    else
        local a=n/1000000000
        n=n%1000000000
        local b=n/1000000
        n=n%1000000
        return string.format("%d,%03d,%03d,%03d", a, b, n/1000, n%1000)
    end
end

--- using input n as 2-digits fix-point number, as in 0.01 unit
--- make string keeping 5 significant digits, 
--- with thousands separators
--- changing units (string form) (u1~u2) if needed
function M.numStr5d2(n, u1, u2)
    if (n<100000) then -- 0~999.99 u1
        return string.format("%d.%02d%s", n/100, n%100, u1)
    elseif (n<999995) then -- 1,000.0 ~ 9,999.9(4) u1
        n = (n+5)/10
        return string.format("%s.%01d%s", M.numStrK(n/10), n%10, u1)
    elseif (n<9999950) then  -- 10,000 ~ 99,999(.49) u1
        n = (n+50)/100
        return M.numStrK(n)..u1
    elseif (n<99999500) then  -- 100.00 ~ 999.99(499) u2
        n = (n+500)/1000
        return string.format("%d.%02d%s", n/100, n%100, u2)
    elseif (n<999995000) then  -- 1,000.0 ~ 9,999.9(4999) u2
        n = (n+5000)/10000
        return string.format("%s.%01d%s", M.numStrK(n/10), n%10, u2)
    else -- 10,000 ~ 31bit limit u2
        n = (n+50000)/100000
        return M.numStrK(n)..u2
    end
end

--- for (a*b+c)/d, input signed 32bit, return signed 64bit quotient and signed 32bit remainder as {low32, high32, remainder}
--- following lua remainder rule
function M.muldiv (a, b, c, d)
    --- a*b
    local t0, t1, t2, t3 = bit.rshift(a,16), bit.band(0xffff, a), bit.rshift(b,16), bit.band(0xffff, b)
    t0, t1, t2, t3 = t1*t3, t1*t2, t0*t3, t0*t2
    t0, t1 = bit.band(0xffff, t0), bit.rshift(t0,16)+t1+bit.band(0xffff, t2)
    t0, t3 = t0 + bit.lshift(t1, 16), t3+bit.rshift(t1,16)+bit.rshift(t2,16)
    if (a<0) then t3 = t3-b end
    if (b<0) then t3 = t3-a end

    --- +c
    if (c>0) then
        if (t0<0) then
            t0 = t0+c
            if (t0>=0) then t3=t3+1 end
        else
            t0 = t0+c
        end
    else
        if (t0>=0) then
            t0 = t0+c
            if (t0<0) then t3=t3-1 end
        else
            t0 = t0+c
        end
    end

    --- /d
    local s1, s2 = false, false
    if (d<0) then 
        d = -d
        s1 = true
    end
    if (t3<0) then
        t0 = -t0
        t3 = -t3 - 1
        s2 = true
    end
    
    t2=0
    for t1=1,32 do
        t2 = bit.lshift(t2, 1) + bit.rshift(t3, 31)
        t3 = bit.lshift(t3, 1)
        if (t2>=d or t2<0) then
            t2 = t2 - d
            t3 = t3 + 1
        end
    end    
    for t1=1,32 do
        t2 = bit.lshift(t2, 1) + bit.rshift(t0, 31)
        t0 = bit.lshift(t0, 1)
        if (t2>=d or t2<0) then
            t2 = t2 - d
            t0 = t0 + 1
        end
    end
        
    if (s1) then
        if (s2) then
            t2 = -t2
        else
            t0 = -t0
            t3 = -t3 - 1
            if (t2~=0) then
                t2 = t2 - d
                if (t0==0) then
                    t3 = t3 -1
                end
                t0 = t0 - 1
            end
        end   
    elseif (s2) then
        t0 = -t0
        t3 = -t3 - 1
        if (t2~=0) then
            t2 = d - t2
            if (t0==0) then
                t3 = t3 -1
            end
            t0 = t0 - 1
         end
    end

    return t0, t3, t2
end

--- when key of pin is long pressed (>2000ms), callback longDo(pin)
--- when key of pin is short pressed (>50ms and no long pressed), callback to shotDo(pin)
--- callback happens when long pressed timeout or short pressed key release
--- val is the pin value setting when pressed
function M.key(pin, val, shortDo, longDo)
    local last=-1
    local timer=nil
    gpio.mode(pin, gpio.INT)
    gpio.trig(pin, "both", function(level, when, cnt)
        if timer then
            timer:unregister()
            timer=nil
        end
        if level==val then
            if (last<0) then
                last=when
                if longDo then
                    timer=tmr.create()
                    if timer then
                        timer:alarm(2000, tmr.ALARM_SINGLE, function(t)
                            if t==timer then
                                if last>=0 and gpio.read(pin)==val then
                                    longDo(pin)
                                end
                                last=-1
                                timer=nil
                            end
                        end)
                    end
                end
            end
        else
            if last>=0 then
                local n=bit.band(0x7fffffff, when - last)
                if n>=50000 and shortDo then
                     shortDo(pin)
                end
                last=-1  
            end
        end
    end)
end

return M
