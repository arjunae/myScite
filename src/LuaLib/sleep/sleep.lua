#!/usr/bin/lua
require("msleep")
p = print
sf = string.format

local start = os.time()
p(sf("Started at %d", start))
sleep(1)
local mid = os.time()
p(sf("After sleep(1), time is %d", mid))
msleep(2000)
local endd = os.time()
p(sf("After msleep(2000), time is %d", endd))
print()
p(sf("First  interval = %d seconds.", mid - start))
p(sf("Second interval = %d seconds.", endd - mid))
p(sf("Whole  interval = %d seconds.", endd - start))
