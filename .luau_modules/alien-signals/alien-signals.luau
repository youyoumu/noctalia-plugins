local NONE = 0b0000000
local MUTABLE = 0b0000001
local WATCHING = 0b0000010
local RECURSED_CHECK = 0b0000100
local RECURSED = 0b0001000
local DIRTY = 0b0010000
local PENDING = 0b0100000

export type ReactiveNode = {
	deps: Link?,
	depsTail: Link?,
	subs: Link?,
	subsTail: Link?,
	flags: ReactiveFlags,
}

export type Link = {
	version: number,
	dep: ReactiveNode,
	sub: ReactiveNode,
	prevSub: Link?,
	nextSub: Link?,
	prevDep: Link?,
	nextDep: Link?,
}

type Stack<T> = {
	value: T,
	prev: Stack<T>?,
}

export type ReactiveFlags = number

local ReactiveFlags = {
	None = NONE,
	Mutable = MUTABLE,
	Watching = WATCHING,
	RecursedCheck = RECURSED_CHECK,
	Recursed = RECURSED,
	Dirty = DIRTY,
	Pending = PENDING,
}

local function createReactiveSystem(props: {
	update: (sub: ReactiveNode) -> boolean,
	notify: (sub: ReactiveNode) -> (),
	unwatched: (sub: ReactiveNode) -> (),
})
	local update = props.update
	local notify = props.notify
	local unwatched = props.unwatched

	local function isValidLink(checkLink: Link, sub: ReactiveNode): boolean
		local link = sub.depsTail
		while link do
			if link == checkLink then
				return true
			end
			link = link.prevDep
		end
		return false
	end

	local function link(dep: ReactiveNode, sub: ReactiveNode, version: number): ()
		local prevDep = sub.depsTail
		if prevDep and prevDep.dep == dep then
			return
		end
		local nextDep = if prevDep then prevDep.nextDep else sub.deps
		if nextDep and nextDep.dep == dep then
			nextDep.version = version
			sub.depsTail = nextDep
			return
		end
		local prevSub = dep.subsTail
		if prevSub and prevSub.version == version and prevSub.sub == sub then
			return
		end
		local newLink: Link = {
			version = version,
			dep = dep,
			sub = sub,
			prevDep = prevDep,
			nextDep = nextDep,
			prevSub = prevSub,
		}
		sub.depsTail = newLink
		dep.subsTail = newLink
		if nextDep then
			nextDep.prevDep = newLink
		end
		if prevDep then
			prevDep.nextDep = newLink
		else
			sub.deps = newLink
		end
		if prevSub then
			prevSub.nextSub = newLink
		else
			dep.subs = newLink
		end
	end

	local function unlink(link: Link, sub: ReactiveNode?): Link?
		local _sub = sub or link.sub
		local dep = link.dep
		local prevDep = link.prevDep
		local nextDep = link.nextDep
		local nextSub = link.nextSub
		local prevSub = link.prevSub
		if nextDep then
			nextDep.prevDep = prevDep
		else
			_sub.depsTail = prevDep
		end
		if prevDep then
			prevDep.nextDep = nextDep
		else
			_sub.deps = nextDep
		end
		if nextSub then
			nextSub.prevSub = prevSub
		else
			dep.subsTail = prevSub
		end
		if prevSub then
			prevSub.nextSub = nextSub
		else
			dep.subs = nextSub
			if not nextSub then
				unwatched(dep)
			end
		end
		return nextDep
	end

	local function propagate(link: Link): ()
		local next = link.nextSub
		local stack: Stack<Link?>?

		repeat
			local sub = link.sub

			local flags = sub.flags

			if not bit32.btest(flags, bit32.bor(RECURSED_CHECK, RECURSED, DIRTY, PENDING)) then
				sub.flags = bit32.bor(flags, PENDING)
			elseif not bit32.btest(flags, bit32.bor(RECURSED_CHECK, RECURSED)) then
				flags = NONE
			elseif not bit32.btest(flags, RECURSED_CHECK) then
				sub.flags = bit32.bor(bit32.band(flags, bit32.bnot(RECURSED)), PENDING)
			elseif not bit32.btest(flags, bit32.bor(DIRTY, PENDING)) and isValidLink(link, sub) then
				sub.flags = bit32.bor(flags, bit32.bor(RECURSED, PENDING))
				flags = bit32.band(flags, MUTABLE)
			else
				-- selene: allow(if_same_then_else)
				flags = NONE
			end

			if bit32.btest(flags, WATCHING) then
				notify(sub)
			end

			if bit32.btest(flags, MUTABLE) then
				local subSubs = sub.subs
				if subSubs then
					link = subSubs
					local nextSub = link.nextSub
					if nextSub then
						stack = { value = next, prev = stack }
						next = nextSub
					end
					continue
				end
			end

			link = next :: Link

			if link then
				next = link.nextSub
				continue
			end

			local continueTop = false

			while stack do
				link = stack.value :: Link
				stack = stack.prev
				if link then
					next = link.nextSub
					continueTop = true
					break
				end
			end

			if continueTop then
				continue
			end

			break
		until false
	end

	local function shallowPropagate(link: Link): ()
		repeat
			local sub = link.sub
			local flags = sub.flags
			if bit32.band(flags, bit32.bor(PENDING, DIRTY)) == PENDING then
				sub.flags = bit32.bor(flags, DIRTY)
				if bit32.btest(flags, WATCHING) then
					notify(sub)
				end
			end
			link = link.nextSub :: Link
		until not link
	end

	local function checkDirty(link: Link, sub: ReactiveNode): boolean
		local stack: Stack<Link>?
		local checkDepth = 0
		local dirty = false

		repeat
			local dep = link.dep
			local flags = dep.flags

			if bit32.btest(sub.flags, DIRTY) then
				dirty = true
			elseif bit32.band(flags, bit32.bor(MUTABLE, DIRTY)) == bit32.bor(MUTABLE, DIRTY) then
				if update(dep) then
					local subs = dep.subs :: Link
					if subs.nextSub then
						shallowPropagate(subs)
					end
					dirty = true
				end
			elseif bit32.band(flags, bit32.bor(MUTABLE, PENDING)) == bit32.bor(MUTABLE, PENDING) then
				if link.nextSub or link.prevSub then
					stack = { value = link, prev = stack }
				end
				link = dep.deps :: Link
				sub = dep
				checkDepth += 1
				continue
			end

			if not dirty then
				local nextDep = link.nextDep
				if nextDep then
					link = nextDep
					continue
				end
			end

			local continueTop = false

			while checkDepth ~= 0 do
				checkDepth -= 1
				local firstSub = sub.subs :: Link
				local hasMultipleSubs = firstSub.nextSub ~= nil
				if hasMultipleSubs then
					link = (stack :: Stack<Link>).value
					stack = (stack :: Stack<Link>).prev
				else
					link = firstSub
				end
				if dirty then
					if update(sub) then
						if hasMultipleSubs then
							shallowPropagate(firstSub)
						end
						sub = link.sub
						continue
					end
					dirty = false
				else
					sub.flags = bit32.band(sub.flags, bit32.bnot(PENDING))
				end
				sub = link.sub
				local nextDep = link.nextDep
				if nextDep then
					link = nextDep
					continueTop = true
					break
				end
			end

			if continueTop then
				continue
			end

			return dirty
		until false
	end

	return {
		link = link,
		unlink = unlink,
		propagate = propagate,
		checkDirty = checkDirty,
		shallowPropagate = shallowPropagate,
	}
end

type Effect = ReactiveNode & {
	fn: () -> (),
}

type Computed<T = any> = ReactiveNode & {
	value: T?,
	getter: (previousValue: T?) -> T,
}

type Signal<T = any> = ReactiveNode & {
	currentValue: T,
	pendingValue: T,
}

local link: (dep: ReactiveNode, sub: ReactiveNode, version: number) -> ()
local unlink: (link: Link, sub: ReactiveNode?) -> Link?
local propagate: (link: Link) -> ()
local checkDirty: (link: Link, sub: ReactiveNode) -> boolean
local shallowPropagate: (link: Link) -> ()

local cycle = 0
local batchDepth = 0
local notifyIndex = 0
local queued: { Effect? } = {}
local queuedLength = 0
local activeSub: ReactiveNode?

local function getActiveSub(): ReactiveNode?
	return activeSub
end

local function setActiveSub(sub: ReactiveNode?)
	local prevSub = activeSub
	activeSub = sub
	return prevSub
end

local function purgeDeps(sub: ReactiveNode)
	local depsTail = sub.depsTail
	local dep = if depsTail then depsTail.nextDep else sub.deps
	while dep do
		dep = unlink(dep, sub)
	end
end

local function setNotPending(sub: ReactiveNode, flags: ReactiveFlags)
	sub.flags = bit32.band(flags, bit32.bnot(PENDING))
end

local function run(e: Effect): ()
	local flags = e.flags
	if bit32.btest(flags, DIRTY) or (bit32.btest(flags, PENDING) and checkDirty(e.deps :: Link, e)) then
		cycle += 1
		e.depsTail = nil
		e.flags = bit32.bor(WATCHING, RECURSED_CHECK)
		local prevSub = setActiveSub(e)
		local success, result: unknown = pcall(e.fn)
		activeSub = prevSub
		e.flags = bit32.band(e.flags, bit32.bnot(RECURSED_CHECK))
		purgeDeps(e)
		if not success then
			error(result)
		end
	else
		e.flags = WATCHING
	end
end

local function flush(): ()
	while notifyIndex < queuedLength do
		local effect = queued[notifyIndex] :: Effect
		queued[notifyIndex] = nil
		notifyIndex += 1
		run(effect)
	end
	notifyIndex = 0
	queuedLength = 0
end

local function getBatchDepth(): number
	return batchDepth
end

local function startBatch()
	batchDepth += 1
end

local function endBatch()
	batchDepth -= 1
	if batchDepth == 0 then
		flush()
	end
end

local function updateComputed(c: Computed): boolean
	cycle += 1
	c.depsTail = nil
	c.flags = bit32.bor(MUTABLE, RECURSED_CHECK)
	local prevSub = setActiveSub(c)
	local oldValue = c.value
	local success, result: unknown = pcall(c.getter, oldValue)
	activeSub = prevSub
	c.flags = bit32.band(c.flags, bit32.bnot(RECURSED_CHECK))
	purgeDeps(c)
	if not success then
		error(result)
	end
	if oldValue ~= result then
		c.value = result
		return true
	else
		return false
	end
end

local function updateSignal(s: Signal): boolean
	s.flags = MUTABLE
	local pendingValue = s.pendingValue
	if s.currentValue ~= pendingValue then
		s.currentValue = pendingValue
		return true
	else
		return false
	end
end

local function signalGetterSetter<T>(this: Signal<T>): (() -> T, (value: T) -> ())
	local function getter(): T
		if bit32.btest(this.flags, DIRTY) then
			if updateSignal(this) then
				local subs = this.subs
				if subs then
					shallowPropagate(subs)
				end
			end
		end
		local sub = activeSub
		while sub do
			if bit32.btest(sub.flags, bit32.bor(MUTABLE, WATCHING)) then
				link(this, sub, cycle)
				break
			end
			local subs = sub.subs
			sub = if subs then subs.sub else nil
		end
		return this.currentValue
	end

	local function setter(value: T)
		if this.pendingValue ~= value then
			this.pendingValue = value
			this.flags = bit32.bor(MUTABLE, DIRTY)
			local subs = this.subs
			if subs then
				propagate(subs)
				if batchDepth == 0 then
					flush()
				end
			end
		end
	end

	return getter, setter
end

local function computedGetter<T>(this: Computed<T>): () -> T
	return function()
		local flags = this.flags
		if
			bit32.btest(flags, DIRTY)
			or (bit32.btest(flags, PENDING) and (checkDirty(this.deps :: Link, this) or setNotPending(this, flags)))
		then
			if updateComputed(this) then
				local subs = this.subs
				if subs then
					shallowPropagate(subs)
				end
			end
		elseif flags == NONE then
			this.flags = MUTABLE
			local prevSub = setActiveSub(this)
			local success, result = pcall(this.getter)
			activeSub = prevSub
			if success then
				this.value = result
			else
				error(result)
			end
		end
		if activeSub then
			link(this, activeSub, cycle)
		end
		return this.value :: T
	end
end

local function effectScopeStop(this: ReactiveNode): () -> ()
	return function()
		this.depsTail = nil
		this.flags = NONE
		purgeDeps(this)
		local sub = this.subs
		if sub then
			unlink(sub, this)
		end
	end
end

local function effectStop(this: Effect): () -> ()
	return effectScopeStop(this)
end

local function signal<T>(initialValue: T): (() -> T, (value: T) -> ())
	return signalGetterSetter({
		currentValue = initialValue,
		pendingValue = initialValue,
		flags = MUTABLE,
	})
end

local function computed<T>(getter: (previousValue: T?) -> T): () -> T
	return computedGetter({
		flags = NONE,
		getter = getter,
	})
end

local function effect(fn: () -> ()): () -> ()
	local e: Effect = {
		fn = fn,
		flags = WATCHING,
	}
	local prevSub = setActiveSub(e)
	if prevSub then
		link(e, prevSub, 0)
	end
	local success, result: unknown = pcall(fn)
	activeSub = prevSub
	if not success then
		error(result)
	end
	return effectStop(e)
end

local function effectScope(fn: () -> ()): () -> ()
	local e: ReactiveNode = {
		flags = NONE,
	}
	local prevSub = setActiveSub(e)
	if prevSub then
		link(e, prevSub, 0)
	end
	local success, result: unknown = pcall(fn)
	activeSub = prevSub
	if not success then
		error(result)
	end
	return effectScopeStop(e)
end

local reactiveSystem = createReactiveSystem({
	update = function(node)
		if node.depsTail then
			return updateComputed(node :: Computed)
		else
			return updateSignal(node :: Signal)
		end
	end,
	notify = function(effect)
		local insertIndex = queuedLength
		local firstInsertedIndex = insertIndex

		repeat
			effect.flags = bit32.band(effect.flags, bit32.bnot(WATCHING))
			queued[insertIndex] = effect :: Effect
			insertIndex += 1
			effect = (effect.subs and effect.subs.sub) :: Effect
			if not effect or bit32.band(effect.flags, WATCHING) == 0 then
				break
			end
		until false

		queuedLength = insertIndex

		insertIndex -= 1
		while firstInsertedIndex < insertIndex do
			local left = queued[firstInsertedIndex]
			queued[firstInsertedIndex] = queued[insertIndex]
			queued[insertIndex] = left
			firstInsertedIndex += 1
			insertIndex -= 1
		end
	end,
	unwatched = function(node)
		if bit32.band(node.flags, MUTABLE) == 0 then
			effectScopeStop(node)()
		elseif node.depsTail then
			node.depsTail = nil
			node.flags = bit32.bor(MUTABLE, DIRTY)
			purgeDeps(node)
		end
	end,
})

link = reactiveSystem.link
unlink = reactiveSystem.unlink
propagate = reactiveSystem.propagate
checkDirty = reactiveSystem.checkDirty
shallowPropagate = reactiveSystem.shallowPropagate

return {
	ReactiveFlags = ReactiveFlags,
	createReactiveSystem = createReactiveSystem,
	getActiveSub = getActiveSub,
	setActiveSub = setActiveSub,
	getBatchDepth = getBatchDepth,
	startBatch = startBatch,
	endBatch = endBatch,
	signal = signal,
	computed = computed,
	effect = effect,
	effectScope = effectScope,
}
