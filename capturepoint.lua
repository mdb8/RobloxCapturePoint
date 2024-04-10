local teams = {
	['Arnor'] = true;
	['Dol Guldur'] = true;
	['Lake Town'] = true;
	['Dwarves'] = true;
	['Rhudaur'] = true;
	['Evil Men'] = true;
	['Elves'] = true;
	['Red Mountains'] = true;
	['Goblins'] = true;
	['Dol Amroth'] = true;
	['Angmar'] = true;
	['Grey Rangers'] = true;
	['Umbar'] = true;
	['Men'] = true;
	['Gundabad'] = true;
	['Blue Mountains'] = true;
	['Khazad-d�m'] = true;
	['Hobbits'] = true;
	['Lindon'] = true;
	['Gondor'] = true;
	['Iron Hills'] = true;
	['Erebor'] = true;
	['Rhun'] = true;
	['Haradrim'] = true;
	['Mordor'] = true;
	['Orcs'] = true;
	['Gobblins'] = true;
	['Isengard'] = true;
	['Woodland Realm'] = true;
	['Rohan'] = true;
	['Dale'] = true;
	['Lothlorien'] = true;
	['Misty Mountains'] = true;
}

local plrs = game:GetService('Players')
local teams = game:GetService('Teams')

local push,pop = table.insert,table.remove

local points = workspace:WaitForChild('points')

local teleporters = workspace:WaitForChild('teleporters')

local whitelist = {}
--glitchpoint
game:GetService('Players').PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		push(whitelist,char)
		char:WaitForChild('Humanoid').Died:Connect(function()
			for i,v in next,whitelist do
				if v == char then
					pop(whitelist,i)
				end
			end
		end)
	end)
end)

game:GetService('Players').PlayerRemoving:Connect(function(plr)
	for i,v in next,whitelist do
		if v.Name == plr.Name then
			pop(whitelist,i)
		end
	end
end)

local createRegion3 = function(p,s)
	return Region3.new(p-s/2,p+s/2)
end

local capturetime = 30

local getValueFromTable = function(t,v)
	for _,a in next,t do
		if a == v then
			return true
		end
	end
	return false
end

local dskey = 'capturePointStatusesV3'

local statusdatastore = game:GetService('DataStoreService'):GetDataStore(dskey)

local capturedstatuses = {}
--local capturing = {}
--local capturingtimes = {}

game:BindToClose(function()
	statusdatastore:UpdateAsync(dskey,function(old) return capturedstatuses end)
end)

local data = statusdatastore:GetAsync(dskey)
if data then
	capturedstatuses = data
	for k,v in next,capturedstatuses do
		points[k]:WaitForChild('BillboardGui'):WaitForChild('TextLabel').Text = 'Currently Owned by '..v
		teleporters[k]:WaitForChild('BillboardGui'):WaitForChild('TextLabel').Text = 'Currently Owned by '..v
	end
end

for _,teleporter in next,teleporters:GetChildren() do
	teleporter.ClickDetector.MouseClick:Connect(function(plr)
		if points:FindFirstChild(teleporter.Name) and plr.Team and capturedstatuses[teleporter.Name] == plr.Team.Name then
			plr.Character.HumanoidRootPart.CFrame = points[teleporter.Name].CFrame
		end
	end)
end

for _,point in next,points:GetChildren() do
	local region = createRegion3(point.Position,point.Size)
	local text = point:WaitForChild('BillboardGui'):WaitForChild('TextLabel')
	local currentholder
	if capturedstatuses[point.Name] then
		currentholder = capturedstatuses[point.Name]
	end
	local captureingtimes = {}
	spawn(function()
		while wait(1) do
			local capturing = {}
			if #workspace:FindPartsInRegion3WithWhiteList(region,whitelist,500) > 0 then
				for _,v in next,workspace:FindPartsInRegion3WithWhiteList(region,whitelist,500) do
					local plr = plrs:GetPlayerFromCharacter(v.Parent)
					if plr and plr.Team and teams[plr.Team.Name] and not getValueFromTable(capturing,plr.Team.Name) then
						push(capturing,plr.Team.Name)
					end
				end
				if #capturing == 1 and #capturing > 0 and currentholder ~= capturing[1] then
					local name = capturing[1]
					if captureingtimes[name] then
						captureingtimes[name] = captureingtimes[name] + 1
					else
						captureingtimes[name] = 1
					end
					text.Text = 'Currently Being Captured by '..name..': '..captureingtimes[capturing[1] ]..' / '..capturetime
					if captureingtimes[name] >= capturetime then
						captureingtimes = {}
						capturedstatuses[point.Name] = name
						currentholder = name
						if teleporters:FindFirstChild(point.Name) then
							teleporters[point.Name].BillboardGui.TextLabel.Text = 'Currently Owned by '..name
						end
						text.Text = 'Currently Owned by '..name
					end
				elseif #capturing > 1 then
					text.Text = 'Contested'
				elseif #capturing <= 0 and currentholder then
					text.Text = 'Currently Owned by '..currentholder
				end
			end
		end
	end)
end