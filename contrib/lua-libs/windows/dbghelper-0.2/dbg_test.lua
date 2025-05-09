--dbgtest.lua

require "dbghelper"

-- test source
prg = [=[
	local u1 = 'a'

	function f(x)
		local a, b, str
		a = 1
		b = g(a, 2)
		str = u1
		return b * x
	end
	
	do
		local u2 = 'b'

		function g(x, y)
			local z, str
			z = x * y
			str = u1 .. u2
			return h()
		end

		do
			local u3 = 'c'

			function h()
				local str = u1 .. u2 .. u3
				return 1
			end
		end
	end

	a = f(1)
]=]

function step_cr(cr, evt, count)
	local ok, what, x
	repeat
		ok, what, x = debug.resumeuntil(cr, evt, count)
		info = debug.getinfo(cr, 0, "nlS") or {}
		print(ok, what, x and x or "", info.name, info.currentline, info.linedefined, info.lastlinedefined)
	until not ok
end

print "\n*** Call and Return Hooks"
cr = coroutine.create(loadstring(prg))
step_cr(cr, "cr")

print "\n*** Line Hooks"
cr = coroutine.create(loadstring(prg))
step_cr(cr, "l")

print "\n*** Call, Return and Line hooks"
cr = coroutine.create(loadstring(prg))
step_cr(cr, "crl")

print "\n*** Count Hooks"
cr = coroutine.create(loadstring(prg))
step_cr(cr, nil, 10)

print "\n*** Yield and resume with args, and return values"
function test_args_and_yield_and_return(a,b)
	print("-- Args", a, b)
	local d, e = coroutine.yield(a*2, b*2)
	print("-- yield returned", d, e)
	return 'a', 'b', 11
end

cr = coroutine.create(test_args_and_yield_and_return)

print(debug.resumeuntil(cr, "l", nil, 2, 3))
repeat
	res = { debug.resumeuntil(cr, "l", nil) }
	print(unpack(res))
until not res[1] or res[2] == 'yield'

print(debug.resumeuntil(cr, "l", nil, 4, 5))

repeat
	res = { debug.resumeuntil(cr, "l", nil) }
	print(unpack(res))
until not res[1]

print "\n*** Handling pcalls, 5.1 will skip the pcalled function, 5.2 will step through it"
function this_is_pcalled()
	print "--- pcalled function"
	local step = 1
	step = 2 -- just to do some lines
	print "--- pcall end"
end
function test_yield_through_pcall()
	print "-- beginning"
	local x = 1
	print "-- before pcall"
	pcall(this_is_pcalled)
	print "-- after pcall"
	x = 2 * x
	print "-- end"
end

cr = coroutine.create(test_yield_through_pcall)
step_cr(cr, "l")

print "\n*** An error occurs"
function kablooie()
	local a = 10
	local b = 20
	local c = a * b
	print(c + this_is_not_defined)
end
cr = coroutine.create(kablooie)
step_cr(cr, "l")

print "" -- done

