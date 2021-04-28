--- Octree implementation
-- @classmod Octree

local OctreeRegionUtils = require(script.OctreeRegionUtils)
local OctreeNode = require(script.OctreeNode)

local EPSILON = 1e-9

local Octree = {}
Octree.ClassName = "Octree"
Octree.__index = Octree

function Octree.new()
	-- code might look uglier, but is faster
	return setmetatable({
		_maxRegionSize = {512, 512, 512}, -- these should all be the same number
		_maxDepth = 4,
		_regionHashMap = {}
	}, Octree)
end

function Octree:ClearNodes()
	self._maxRegionSize = {512, 512, 512} -- these should all be the same number
	self._maxDepth = 4
	-- table.clear is better for this usecase
	table.clear(self._regionHashMap)
end

function Octree:GetAllNodes()
	local options = {}

	for _, regionList in pairs(self._regionHashMap) do
		for _, region in pairs(regionList) do
			for node, _ in pairs(region.nodes) do
				table.insert(options, node)
			end
		end
	end

	return options
end

function Octree:CreateNode(position, object)
	assert(typeof(position) == "Vector3", "Bad position value")
	assert(object, "Bad object value")

	local node = OctreeNode.new(self, object)

	node:SetPosition(position)
	return node
end

function Octree:RadiusSearch(position, radius)
	assert(typeof(position) == "Vector3")
	assert(type(radius) == "number")

	return self:_radiusSearch(position.X, position.Y, position.Z, radius)
end

function Octree:KNearestNeighborsSearch(position, k, radius)
	assert(typeof(position) == "Vector3")
	assert(type(radius) == "number")

	local objects, nodeDistances2 = self:_radiusSearch(position.x, position.y, position.z, radius)

	local sortable = {}
	for index, dist2 in pairs(nodeDistances2) do
		table.insert(sortable, {
			dist2 = dist2;
			index = index;
		})
	end

	table.sort(sortable, function(a, b)
		return a.dist2 < b.dist2
	end)

	local knearest = {}
	local knearestDist2 = {}
	for i = 1, math.min(#sortable, k) do
		local sorted = sortable[i]
		-- table.insert is better
		table.insert(knearestDist2, sorted.dist2)
		table.insert(knearest, objects[sorted.index])
	end

	return knearest, knearestDist2
end

function Octree:GetOrCreateLowestSubRegion(px, py, pz)
	return OctreeRegionUtils.getOrCreateSubRegionAtDepth(self:_getOrCreateRegion(px, py, pz), px, py, pz, self._maxDepth)
end

function Octree:_radiusSearch(px, py, pz, radius)
	local objectsFound = {}
	local nodeDistances2 = {}

	local maxDepth = self._maxDepth
	local searchRadiusSquared = OctreeRegionUtils.getSearchRadiusSquared(radius, self._maxRegionSize[1], EPSILON)

	--debug.profilebegin('_regionHashMap loop')
	for _, regionList in pairs(self._regionHashMap) do
		for _, region in pairs(regionList) do
			local rpos = region.position

			-- ^2 is faster than localizing and performing x*x
			if (px - rpos[1])^2 + (py - rpos[2])^2 + (pz - rpos[3])^2 <= searchRadiusSquared then
				OctreeRegionUtils.getNeighborsWithinRadius(region, radius, px, py, pz, objectsFound, nodeDistances2, maxDepth)
			end
		end
	end
	--debug.profileend()

	return objectsFound, nodeDistances2
end

function Octree:_getRegion(px, py, pz)
	return OctreeRegionUtils.findRegion(self._regionHashMap, self._maxRegionSize, px, py, pz)
end

function Octree:_getOrCreateRegion(px, py, pz)
	return OctreeRegionUtils.getOrCreateRegion(self._regionHashMap, self._maxRegionSize, px, py, pz)
end

return Octree