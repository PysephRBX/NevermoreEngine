local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NevermoreEngine   = require(ReplicatedStorage:WaitForChild("NevermoreEngine"))
local LoadCustomLibrary = NevermoreEngine.LoadLibrary

local MakeMaid = LoadCustomLibrary("Maid").MakeMaid
local CameraStack = LoadCustomLibrary("CameraStack")
local FadeBetweenCamera = LoadCustomLibrary("FadeBetweenCamera")


local CameraStateTweener = {}
CameraStateTweener.ClassName = "CameraStateTweener"
CameraStateTweener.__index = CameraStateTweener

function CameraStateTweener.new(CameraEffect, Speed)
	local self = setmetatable({}, CameraStateTweener)
	
	self.Maid = MakeMaid()
	local CameraBelow, Assign = CameraStack:GetNewStateBelow()
	self.CameraBelow = CameraBelow
	self.FadeBetween = FadeBetweenCamera.new(CameraBelow, CameraEffect)
	Assign(self.FadeBetween)
	
	CameraStack:Add(self.FadeBetween)
	
	self.FadeBetween.Speed = Speed or 20
	self.FadeBetween.Target = 0
	self.FadeBetween.Value = 0
	
	self.Maid.CleanupCameraStack = function()	
		CameraStack:Remove(self.FadeBetween)
	end
	
	return self
end

function CameraStateTweener:GetCameraBelow()
	return self.CameraBelow
end

function CameraStateTweener:SetTarget(Target, DoNotAnimate)
	self.FadeBetween.Target = Target or error("No target")
	if DoNotAnimate then
		self.FadeBetween.Value = self.FadeBetween.Target
		self.FadeBetween.Velocity = 0
	end
	return self
end

function CameraStateTweener:SetSpeed(Speed)
	self.FadeBetween.Speed = Speed
	
	return self
end

function CameraStateTweener:Show(DoNotAnimate)
	self:SetTarget(1, DoNotAnimate)
end


function CameraStateTweener:SetVisible(IsVisible, DoNotAnimate)
	if IsVisible then
		self:Show(DoNotAnimate)
	else
		self:Hide(DoNotAnimate)
	end
end

function CameraStateTweener:Hide(DoNotAnimate)
	self:SetTarget(0, DoNotAnimate)
end

function CameraStateTweener:Finish(DoNotAnimate, Callback)
	self:Hide(DoNotAnimate)
	
	if self.FadeBetween.HasReachedTarget then
		Callback()
	else
		spawn(function()
			while not self.FadeBetween.HasReachedTarget do
				wait(0.05)
			end
			Callback()
		end)
	end
end

function CameraStateTweener:GetFader()
	return self.FadeBetween
end

function CameraStateTweener:Destroy()
	self.Maid:DoCleaning()
end

return CameraStateTweener