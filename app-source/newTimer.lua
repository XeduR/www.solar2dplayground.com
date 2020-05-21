-------------------------------------------------------------------------------
--
-- Corona Labs
--
-- timer.lua
--
-- Code is MIT licensed; see https://www.coronalabs.com/links/code/license
--
-------------------------------------------------------------------------------

-- NOTE: timer is assigned to the global var "timer" on startup.
-- This file should follow standard Lua module conventions
local timer = {
	_runlist = {},
	_pausedTimers = {},
	allowIterationsWithinFrame = false,
}

function timer.performWithDelay( delay, listener, varA, varB )
	-- varA and varB are optional "iterations" and "tag" parameters.
	local iterations = "number" == type(varA) and varA or nil
	local tag = "string" == type(varA) and varA or "string" == type(varB) and varB or ""

	local entry
	local t = type(listener)
	if "function" == t or ( "table" == t and "function" == type( listener.timer ) ) then
		-- faster to access a local timer var than a global one
		local timer = timer

		local fireTime = system.getTimer() + delay

		entry = { _listener = listener, _time = fireTime }

		if nil ~= iterations and type(iterations) == "number" then
			-- pre-subtract out one iteration, so for an initial value of...
			--   ...1, it's a no-op b/c we always fire at least once
			--   ...0, it become -1 which we will interpret as forever
			iterations = iterations - 1
			if iterations ~= 0 then
				entry._delay = delay
				entry._iterations = iterations
			end
		end

		entry._count = 1
		entry._tag = tag
		entry._inFrameIterations = timer.allowIterationsWithinFrame

		timer._insert( timer, entry, fireTime )

	end

	return entry
end

-- returns (time left until fire), (number of iterations left)
function timer.cancel( whatToCancel )
	local t = type( whatToCancel )
	if "string" ~= t and "table" ~= t then
		error("timer.cancel(): invalid timerId or tag (table or string expected, got "..t..")", 2)
	end

	-- Since pausing timers removes them from runlist, it means that both runlist
	-- and pausedTimers must be checked when cancelling timers using a tag.
	local list = {}
	if "table" == whatToCancel then
		list[1] = whatToCancel
	else
		local runlist = timer._runlist
		for i = 1, #runlist do
			list[#list+1] = runlist[i]
		end
		local pausedTimers = timer._pausedTimers
		for i = 1, #pausedTimers do
			list[#list+1] = pausedTimers[i]
		end
	end
	local isTag = ("string" == t)

	for i = #list, 1, -1 do
		local v = list[i]
		-- If a tag was specified, then cancel all timers that share the tag,
		-- otherwise cancel only the specific timer that was specified.
		if (isTag and whatToCancel == v._tag) or whatToCancel == v then
			-- flag for removal from runlist
			v._cancelled = true
			-- prevent from being resumed
			v._expired = true
			
			if not isTag then
				-- Information is only returned when a specific timer is cancelled.
				local fireTime = v._time
				local baseTime = v._pauseTime
				if ( not baseTime ) then
					baseTime = system.getTimer()
				end
		
				return ( fireTime - baseTime ), ( v._iterations or 0 ) + 1
			end
		end
	end
end

function timer.pause( whatToPause, _pauseAll )
	local t = type( whatToPause )
	if "string" ~= t and "table" ~= t then
		error("timer.pause(): invalid timerId or tag (table or string expected, got "..t..")", 2)
	end
	
	local runlist = timer._runlist
	local pausedTimers = timer._pausedTimers
	local isTag = ("string" == t)
	
	-- If user is pausing timers using a tag or pauseAll(), then there won't be warning texts and nothing is returned to user.
	if not _pauseAll and ( not isTag and whatToPause._expired ) then
		print( "WARNING: timer.pause( timerId ) cannot pause a timerId that is already expired." )
		return 0
	elseif not _pauseAll and ( not isTag and whatToPause._pauseTime ) then
		print( "WARNING: timer.pause( timerId ) ignored because timerId is already paused." )
		return 0
	else
		for i = #runlist, 1, -1 do
			local v = runlist[i]
			if (isTag and whatToPause == v._tag and not v._expired and not v._pauseTime) or whatToPause == v then
				pausedTimers[#pausedTimers+1] = v
				local pauseTime = system.getTimer()
				v._pauseTime = pauseTime
				timer._remove( v )
				if not isTag then
					return ( v._time - pauseTime )
				end
			end
		end
	end
end

function timer.resume( whatToResume, _resumeAll )
	local t, msg = type( whatToResume )
	if "string" ~= t and "table" ~= t then
		error("timer.resume(): invalid timerId or tag (table or string expected, got "..t..")", 2)
	end
	
	local pausedTimers = timer._pausedTimers
	local isTag = ("string" == t)

	-- If user is resuming timers using a tag or resumeAll(), then there won't be warning texts and nothing is returned to user.
	if not _resumeAll and ( not isTag and whatToResume._expired ) then
		print( "WARNING: timer.resume( timerId ) cannot resume a timerId that is already expired." )
		return 0
	elseif not _resumeAll and ( not isTag and not whatToResume._pauseTime ) then
		print( "WARNING: timer.resume( timerId ) ignored because timerId was not paused." )
		return 0
	else
		for i = #pausedTimers, 1, -1 do
			local v = pausedTimers[i]
			if (isTag and whatToResume == v._tag and not v._expired and v._pauseTime) or whatToResume == v then	
				local timeLeft = v._time - v._pauseTime
				local fireTime = system.getTimer() + timeLeft
				v._time = fireTime
				v._pauseTime = nil
				table.remove( pausedTimers, i )				
				if ( v._removed ) then
					timer._insert( timer, v, fireTime )
				end
				if not isTag then
					return timeLeft
				end
			end
		end
	end
end

function timer.pauseAll()
	local runlist = timer._runlist
	for i = #runlist, 1, -1 do
		timer.pause( runlist[i], true )
	end
end

function timer.resumeAll()
	local pausedTimers = timer._pausedTimers
	for i = #pausedTimers, 1, -1 do
		timer.resume( pausedTimers[i], true )
	end
end

function timer.cancelAll()
	local runlist = timer._runlist
	for i = #runlist, 1, -1 do
		timer.cancel( runlist[i] )
	end
	local pausedTimers = timer._pausedTimers
	for i = #pausedTimers, 1, -1 do
		timer.cancel( pausedTimers[i] )
	end
end

function timer._updateNextTime()
	local runlist = timer._runlist

	if #runlist > 0 then
		if timer._nextTime == nil then
			Runtime:addEventListener( "enterFrame", timer )
		end
		timer._nextTime = runlist[#runlist]._time
	else
		timer._nextTime = nil
		Runtime:removeEventListener( "enterFrame", timer )
	end
end

function timer._insert( timer, entry, fireTime )
	local runlist = timer._runlist

	-- sort in decreasing fireTime
	local index = #runlist + 1
	for i,v in ipairs( runlist ) do
		if v._time < fireTime then
			index = i
			break
		end
	end
	table.insert( runlist, index, entry )
	entry._removed = nil

	--print( "inserting entry firing at: "..fireTime.." at index: "..index )

	-- last element is the always the next to fire
	-- cache its fire time
	timer._updateNextTime()
end

function timer._remove( entry )
	local runlist = timer._runlist

	-- If no entry is provided, we pop the soonest-expiring one off.
	if ( entry == nil ) then
		entry = runlist[#runlist]
	end

	for i,v in ipairs( runlist ) do
		if v == entry then
			entry._removed = true
			table.remove( runlist, i )
			break
		end
	end

	timer._updateNextTime()

	return entry
end

function timer:enterFrame( event )
	-- faster to access a local timer var than a global one
	local timer = timer

	local runlist = timer._runlist

	-- If the listener throws an error and the runlist was empty, then we may
	-- not have cleaned up properly. So check that we have a non-empty runlist.
	if #runlist > 0 then
		local currentTime = event.time
		local timerEvent = { name="timer", time=currentTime }

		--print( "T(cur,fire) = "..currentTime..","..timer._nextTime )
		-- fire all expired timers
		local toInsert = {}
		while currentTime >= timer._nextTime do
			local entry = timer._remove()

			-- we cannot modify the runlist array, so we use _cancelled and _pauseTime
			-- flags to ensure that listeners are not called.
			if not entry._expired and not entry._cancelled and not entry._pauseTime then
				local iterations = entry._iterations

				timerEvent.source = entry
				local count = entry._count
				if count then
					timerEvent.count = count
					entry._count = count + 1
				end

				local listener = entry._listener
				if type( listener ) == "function" then
					listener( timerEvent )
				else
					-- must be a table b/c we only add when type is table or function
					local method = listener.timer
					method( listener, timerEvent )
				end

				if iterations then
					if iterations == 0 then
						entry._iterations = nil
						entry._delay = nil

						-- We need to expire the entry here if we don't want the extra trigger [Alex]
						iterations = nil
						entry._expired = true
					else
						if iterations > 0 then
							entry._iterations = iterations - 1
						end

						local fireTime = entry._time + entry._delay
						entry._time = fireTime
						if entry._inFrameIterations then
							timer._insert( timer, entry, fireTime )
						else
							toInsert[#toInsert+1] = {timer, entry, fireTime}
						end
					end
				else
					-- mark timer entry so we know it's finished
					entry._expired = true
				end
			end

			if ( timer._nextTime == nil ) then
				break;
			end
		end
		for i,v in ipairs(toInsert) do
			timer._insert(unpack(v))
		end
	end
end

return timer
