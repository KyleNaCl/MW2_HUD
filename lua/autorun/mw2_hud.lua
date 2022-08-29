
print("[HUD] \tLoaded mw2_hud.lua")

if CLIENT then

local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true,
	["CHudDeathNotice"] = true
}
local AmmoIcon = {
	["2"] = "models/Items/combine_rifle_ammo01.mdl",
	["9"] = "models/Items/AR2_Grenade.mdl"
}
local HeavyDamage = {
	["8"] = true,
	["64"] = true,
	["72"] = true,
	["256"] = true,
	["33554432"] = true,
	["67108864"] = true,
	["536870912"] = true,
	["1073741826"] = true
}
local Killfeed = {}
Killfeed_Panels = Killfeed_Panels or {}
if #Killfeed_Panels > 0 then
	for _,p in ipairs(Killfeed_Panels) do
		if p then
			p:Remove()
		end
	end
end
Killfeed_Panels = {}

local White = Color(255,255,255,255)
local Black = Color(0,0,0,255)
local Mat = Material("vgui/gradient-r")
local DrawName = true
local CacheWeapon = nil
local WeaponDrawTimer = 0

SecondaryAmmoIcon = SecondaryAmmoIcon or nil
if SecondaryAmmoIcon then SecondaryAmmoIcon:Remove() end
SecondaryAmmoIcon = nil

hook.Add("HUDShouldDraw", "MW2_ForceHide", function(name)
	if hide[name] then return false end
end)

local W = ScrW()
local H = ScrH()
local ReloadKey = "R"

timer.Create("MW2_UpdateScreen",5,0,function()
	if LocalPlayer() then
		W = ScrW()
		H = ScrH()
		DrawName = not DrawName
		ReloadKey = string.upper(input.LookupBinding("reload"))
	end
end)

function drawCompass(x_, y_, yaw)
	render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	render.PushFilterMin( TEXFILTER.ANISOTROPIC )

	local m = Matrix()
	m:SetAngles(Angle(0,yaw - 45,0))
	local letter = { "N", " |", "E", " |", "S", " |", "W", " |"}

	for a = 1, 8 do
		m:Rotate( Angle( 0, 45, 0 ) )
		m:SetTranslation( Vector(x_,y_,0) )
		m:Translate(Vector(-6,-125,0))
		local Cur = m:GetAngles()[2] + 180
		if Cur > 125 and Cur < 255 then
			cam.PushModelMatrix( m )
				draw.SimpleTextOutlined(letter[a], "ScoreboardDefault", 0, 0, White, 0, 0, 1, Black)
			cam.PopModelMatrix()
		end
	end

	render.PopFilterMag()
	render.PopFilterMin()
end

local function drawCircle(x_, y_, start, end_, radius_, fid)
	local cache = { 
		x = x_ + math.cos( math.rad( -start + 90 ) ) * radius_, 
		y = y_ - math.sin( math.rad( -start + 90) ) * radius_
	}
	for a = start + fid, end_, fid do
		local t_x = x_ + math.cos( math.rad( -a + 90 ) ) * radius_
		local t_y = y_ - math.sin( math.rad( -a + 90) ) * radius_
		surface.DrawLine(cache.x , cache.y, t_x, t_y )
		cache.x = t_x
		cache.y = t_y
	end
end

local ModelCache = {}
local function GetSecondaryAmmoModel(weapon, ammo)
	if AmmoIcon[ammo] then return AmmoIcon[ammo] end
	local class = weapon:GetClass()
	if ModelCache[class] and ModelCache[class] != "none" then return ModelCache[class] end
	if ModelCache[class] == "none" then return nil end
	local details = weapons.GetStored(class)
	if details then
		if details.Base == "tfa_gun_base" then
			if details.Secondary then
				if details.Secondary.ProjectileModel then
					ModelCache[class] = details.Secondary.ProjectileModel
					return ModelCache[class]
				end
			end
			ModelCache[class] = "none"
		end
	end
	return nil
end

local function getTeamName(ply)
	if exsto ~= nil then
		return exsto.Ranks[ply:GetRank()].Name
	elseif evolve ~= nil then
		return evolve.ranks[ply:EV_GetRank()].Title
	elseif maestro ~= nil then
		return maestro.userrank(ply)
	end
	return team.GetName(ply:Team() or 1001)
end
local function getTeamColor(ply)
	if evolve then
		return evolve.ranks[ply:EV_GetRank()].Color or White
	elseif maestro then
		return maestro.rankcolor(maestro.userrank(ply)) or team.GetColor(ply:Team() or 1001)
	end
	return team.GetColor(ply:Team() or 1001)
end

hook.Add("HUDPaintBackground", "MW2_HUD", function()
	if not LocalPlayer() then return end

	local Ply = LocalPlayer()
	local Heal = math.Clamp(Ply:Health(),0,100)
	local Batt = math.Clamp(Ply:Armor(),0,100)


	-- LEFT SIDE --

	local center = Vector( 100, H - 50, 0 )

	surface.SetDrawColor( 0, 0, 0, 200 )
	surface.DrawRect(center.x + 100, center.y - 1, 500, 4)

	drawCircle(center.x,center.y,-40,90,101,13)
	drawCircle(center.x,center.y,-40,90,98,13)

	surface.SetDrawColor( 200, 200, 200, 255 )
	surface.DrawRect(center.x + 100, center.y, 500, 2)

	drawCircle(center.x,center.y,-40,90,100,13)
	drawCircle(center.x,center.y,-40,90,99.2,13)


	local DrawText = string.upper(Ply:Name())
	local DrawColorVec = Ply:GetPlayerColor()
	local DrawColor = Color(DrawColorVec[1] * 255,DrawColorVec[2] * 255,DrawColorVec[3] * 255,255)
	if not DrawName then
		DrawText = string.upper(getTeamName(Ply)) --string.upper(team.GetName(Ply:Team() or 1001))
		DrawColor = getTeamColor(Ply) --team.GetColor(Ply:Team() or 1001)
	end

	draw.SimpleText(DrawText,"ScoreboardDefault",center.x + 113,center.y - 27,Black,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
	draw.SimpleText(DrawText,"ScoreboardDefault",center.x + 111,center.y - 30,DrawColor,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)

	local HealthPoly = {
		{ x = center.x + 130, y = center.y - 16 },
		{ x = center.x + 132, y = center.y - 16 },
		{ x = center.x + 144, y = center.y - 6 },
		{ x = center.x + 139, y = center.y - 6 },
	}
	surface.SetMaterial(Mat)
	surface.SetDrawColor( 0, 0, 0, 100 )
	surface.DrawPoly({
		{ x = HealthPoly[1].x, y = HealthPoly[1].y + 4, u = 0.005, v = 0 },
		{ x = HealthPoly[2].x + 310, y = HealthPoly[2].y + 4, u = 1, v = 0 },
		{ x = HealthPoly[3].x + 310, y = HealthPoly[3].y + 4, u = 1, v = 0 },
		{ x = HealthPoly[4].x, y = HealthPoly[4].y + 4, u = 0.005, v = 0 },
	})
	draw.NoTexture()
	surface.SetDrawColor( 255, 255, 255, 100 )
	surface.DrawPoly({
		{ x = HealthPoly[1].x + 310 - 1, y = HealthPoly[1].y + 4, u = 0.05, v = 0 },
		{ x = HealthPoly[2].x + 310 + 2, y = HealthPoly[2].y + 4, u = 1, v = 0 },
		{ x = HealthPoly[3].x + 310 + 1, y = HealthPoly[3].y + 4, u = 1, v = 0 },
		{ x = HealthPoly[4].x + 310 + 1, y = HealthPoly[4].y + 4, u = 0.05, v = 0 },
	})

	if Heal > 0 then
		surface.SetMaterial(Mat)
		surface.SetDrawColor( 120, 255, 120, 255 )
		surface.DrawPoly({
			{ x = HealthPoly[1].x - 5 + Heal / 4, y = HealthPoly[1].y, u = 0.005, v = 0 },
			{ x = HealthPoly[2].x + Heal * 3, y = HealthPoly[2].y, u = 1, v = 0 },
			{ x = HealthPoly[3].x + Heal * 3, y = HealthPoly[3].y, u = 1, v = 0 },
			{ x = HealthPoly[4].x - 5 + Heal / 4, y = HealthPoly[4].y, u = 0.005, v = 0 },
		})
		local Move = Heal * 3
		draw.NoTexture()
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawPoly({
			{ x = HealthPoly[1].x + Move - 1, y = HealthPoly[1].y - 1, u = 0.05, v = 0 },
			{ x = HealthPoly[2].x + Move + 3, y = HealthPoly[2].y - 1, u = 1, v = 0 },
			{ x = HealthPoly[3].x + Move + 3, y = HealthPoly[3].y, u = 1, v = 0 },
			{ x = HealthPoly[4].x + Move + 2, y = HealthPoly[4].y, u = 0.05, v = 0 },
		})
		surface.SetDrawColor( 0, 0, 0, 255 )
		surface.DrawLine(HealthPoly[1].x + Move - 1, HealthPoly[1].y - 1, HealthPoly[4].x + Move + 1, HealthPoly[4].y)
		draw.SimpleTextOutlined(Ply:Health(),"ScoreboardDefaultTitle",center.x + 120,center.y + 4,White,TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM,1.5,Black)
	end

	local ArmorPoly = {
		{ x = center.x + 144, y = center.y + 7 },
		{ x = center.x + 132, y = center.y + 17 },
		{ x = center.x + 130, y = center.y + 17 },
		{ x = center.x + 139, y = center.y + 7 },
	}

	surface.SetMaterial(Mat)
	surface.SetDrawColor( 0, 0, 0, 100 )
	surface.DrawPoly({
		{ x = ArmorPoly[1].x + 310, y = ArmorPoly[1].y - 3, u = 1, v = 0 },
		{ x = ArmorPoly[2].x + 310, y = ArmorPoly[2].y - 3, u = 1, v = 0 },
		{ x = ArmorPoly[3].x, y = ArmorPoly[3].y - 3, u = 0.005, v = 0 },
		{ x = ArmorPoly[4].x, y = ArmorPoly[4].y - 3, u = 0.005, v = 0 },
	})
	draw.NoTexture()
	surface.SetDrawColor( 255, 255, 255, 100 )
	surface.DrawPoly({
		{ x = ArmorPoly[1].x + 310 + 1, y = ArmorPoly[1].y - 3, u = 1, v = 0 },
		{ x = ArmorPoly[2].x + 310 + 2, y = ArmorPoly[2].y - 3, u = 1, v = 0 },
		{ x = ArmorPoly[3].x + 310 - 1, y = ArmorPoly[3].y - 3, u = 0.005, v = 0 },
		{ x = ArmorPoly[4].x + 310 + 1, y = ArmorPoly[4].y - 3, u = 0.005, v = 0 },
	})

	if Batt > 0 then
		surface.SetMaterial(Mat)
		surface.SetDrawColor( 120, 120, 255, 255 )
		surface.DrawPoly({
			{ x = ArmorPoly[1].x + Batt * 3, y = ArmorPoly[1].y, u = 1, v = 0 },
			{ x = ArmorPoly[2].x + Batt * 3, y = ArmorPoly[2].y, u = 1, v = 0 },
			{ x = ArmorPoly[3].x - 5 + Batt / 4, y = ArmorPoly[3].y, u = 0.005, v = 0 },
			{ x = ArmorPoly[4].x - 5 + Batt / 4, y = ArmorPoly[4].y, u = 0.005, v = 0 },
		})
		local Move = Batt * 3
		draw.NoTexture()
		surface.SetDrawColor( 225, 225, 225, 255 )
		surface.DrawPoly({
			{ x = ArmorPoly[1].x + Move + 3, y = ArmorPoly[1].y, u = 1, v = 0 },
			{ x = ArmorPoly[2].x + Move + 3, y = ArmorPoly[2].y + 1, u = 1, v = 0 },
			{ x = ArmorPoly[3].x + Move - 1, y = ArmorPoly[3].y + 1, u = 0.005, v = 0 },
			{ x = ArmorPoly[4].x + Move + 2, y = ArmorPoly[4].y, u = 0.005, v = 0 },
		})
		surface.SetDrawColor( 0, 0, 0, 255 )
		surface.DrawLine(ArmorPoly[4].x + Move, ArmorPoly[4].y, ArmorPoly[3].x + Move - 2, ArmorPoly[3].y + 1)
		draw.SimpleTextOutlined(Ply:Armor(),"ScoreboardDefaultTitle",center.x + 120,center.y,White,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP,1.5,Black)
	end


	-- RIGHT SIDE --

	center = Vector( W - 100, H - 50, 0 )

	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(center.x - 600, center.y - 1, 500, 4)

	drawCircle(center.x,center.y,-90,40,101,13)
	drawCircle(center.x,center.y,-90,40,98,13)

	surface.SetDrawColor(200, 200, 200, 255)
	surface.DrawRect(center.x - 600, center.y, 500, 2)

	drawCircle(center.x,center.y,-90,40,100,13)
	drawCircle(center.x,center.y,-90,40,99.2,13)


	local Weap = Ply:GetActiveWeapon()
	if IsValid(Weap) and not Ply:InVehicle() then

		-- PRIMARY AMMO --

		local AmmoType = Weap:GetPrimaryAmmoType()
		if AmmoType != -1 then
			local ClipSize = Weap:GetMaxClip1()
			local InClip = Weap:Clip1()
			local MaxClip = math.max(ClipSize,InClip)
			local Col = White
			local AmmoCount = Ply:GetAmmoCount(AmmoType)
			if AmmoCount <= ClipSize then
				Col = Color(255,100,100,255)
			end
			local Fade = 0
			if InClip <= ClipSize * 0.25 and ClipSize > 0 then
				Fade = math.Truncate(math.sin(CurTime() * 8) * 50 - 51)
			end
			local w_ = draw.SimpleTextOutlined(tostring(AmmoCount),"ScoreboardDefaultTitle",center.x - 120,center.y,Col,TEXT_ALIGN_RIGHT,TEXT_ALIGN_BOTTOM,1.5,Black)
			if ClipSize > 200 then
				draw.SimpleTextOutlined(tostring(InClip) .. " / ","ScoreboardDefaultTitle",center.x - 120 - w_,center.y,White,TEXT_ALIGN_RIGHT,TEXT_ALIGN_BOTTOM,1.5,Black)
			elseif ClipSize > 51 then
				local x = 0
				for a = 1, MaxClip , 1 do
					surface.SetDrawColor( 0, 0, 0, 200 )
					surface.DrawRect(center.x - 140 - w_ - (math.mod((a - 1),20) * 14) + 1, center.y - (10 + (x * 7)) + 1, 7, 4)
					if a <= InClip then 
						surface.SetDrawColor( 225, 225 + Fade, 225 + Fade, 225 )
					else
						surface.SetDrawColor( 75, 75, 75, 225 )
					end
					surface.DrawRect(center.x - 140 - w_ - (math.mod((a - 1),20) * 14), center.y - (10 + (x * 7)), 7, 4)
					if math.mod(a, 20) == 0 then x = x + 1 end
				end
			else
				local IsHeavy = HeavyDamage[tostring(game.GetAmmoDamageType(AmmoType))]
				for a = 1, MaxClip , 1 do
					surface.SetDrawColor( 0, 0, 0, 200 )
					if IsHeavy then
						surface.DrawRect(center.x - 145 - w_ - ((a - 1) * 14) + 1, center.y - 33 + 1, 8, 28)
					else
						surface.DrawRect(center.x - 135 - w_ - ((a - 1) * 7) + 1, center.y - 28 + 1, 3, 22)
					end
					if a <= InClip then 
						surface.SetDrawColor( 225, 225 + Fade, 225 + Fade, 225 )
					else
						surface.SetDrawColor( 75, 75, 75, 225 )
					end
					if IsHeavy then
						surface.DrawRect(center.x - 145 - w_ - ((a - 1) * 14), center.y - 33, 8, 28)
					else
						surface.DrawRect(center.x - 135 - w_ - ((a - 1) * 7), center.y - 28, 3, 22)
					end
				end
			end
			if Fade != 0 then
				local dc = Color(255 + Fade * 1.5,255 + Fade * 1.5,255 + Fade * 1.5,255)
				local te = "[" .. ReloadKey .. "]  RELOAD"
				if AmmoCount == 0 then
					dc = Color(255,255 + Fade * 1.5,255 + Fade * 1.5,255)
					te = "LOW AMMO"
					if InClip == 0 then
						te = "NO AMMO"
					end
				end
				draw.SimpleTextOutlined(te, "GModNotify", W / 2, H * 0.58,dc, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP,1,Black)
			end
		end

		-- SECONDARY AMMO --

		AmmoType = Weap:GetSecondaryAmmoType()
		if Weap != CacheWeapon then
			if SecondaryAmmoIcon != nil then
				SecondaryAmmoIcon:Remove()
			end

			if AmmoType != -1 then
				local Icon = GetSecondaryAmmoModel(Weap,tostring(AmmoType))

				if Icon != nil then 
					SecondaryAmmoIcon = vgui.Create("DModelPanel")
					SecondaryAmmoIcon:SetSize(80,80)
					SecondaryAmmoIcon:SetModel(Icon)
					local min, max = SecondaryAmmoIcon:GetEntity():GetModelBounds()
					SecondaryAmmoIcon:SetPos(center.x - 40, center.y - 20)
					SecondaryAmmoIcon:SetFOV(20)
					SecondaryAmmoIcon:SetCamPos(Vector(30,30,max[3] * 1.5))
					SecondaryAmmoIcon:SetLookAt(Vector(0,0,max[3] / 2))
				end
			end

			WeaponDrawTimer = 400
		end
		if AmmoType != -1 then
			local AmmoCount = Ply:GetAmmoCount(AmmoType)
			local Col = White
			if AmmoCount == 0 then
				Col = Color(255,100,100,255)
			end
			draw.SimpleTextOutlined(tostring(AmmoCount), "ScoreboardDefaultTitle", center.x + 20, center.y + 30,Col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,1,Black)
		end
		if WeaponDrawTimer > 0 then
			local alpha = math.Clamp(WeaponDrawTimer, 0, 100)
			draw.SimpleTextOutlined(string.upper(Weap:GetPrintName()), "ScoreboardDefault", center.x - 110, center.y - 40, Color(255,255,255,alpha * 2.55), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM,1,Color(0,0,0,alpha * 2.55))
			WeaponDrawTimer = WeaponDrawTimer - 1
		end
	end
	CacheWeapon = Weap

	drawCompass(center.x,center.y,Ply:EyeAngles()[2])

	-- KILLFEED --

	center = Vector( W - 20, H - 200, 0 )

	if #Killfeed > 0 then
		for _,k in ipairs(Killfeed) do
			if k["y"] == 0 then k["y"] = center[2] end
			k["attacker_color"].a = k["alpha"]
			k["victim_color"].a = k["alpha"]
			local Temp_Outline = Color(0,0,0,k["alpha"])

			if k["y"] > center[2] - (_ * 25) then k["y"] = k["y"] - (_ + math.Clamp(_ - 1,0,1)) else k["y"] = center[2] - (_ * 25) end

			local v_width, v_height = draw.SimpleTextOutlined(" " .. k["victim"], "ScoreboardDefault", center[1], k["y"], k["victim_color"], TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 1, Temp_Outline)
			local w_width, w_height = draw.SimpleTextOutlined(" [" .. k["weapon"] .. "]", "GModNotify", center[1] - v_width, k["y"], Color(255,255,255,k["alpha"]), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 1, Temp_Outline)
			local a_width, a_height = draw.SimpleTextOutlined(k["attacker"], "ScoreboardDefault", center[1] - v_width - w_width, k["y"], k["attacker_color"], TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 1, Temp_Outline)

			if k["state"] and (CurTime() > k["time"] + 6 or _ > 10)  then k["state"] = false end
			if k["state"] then
				k["alpha"] = k["alpha"] + 5
			else
				k["alpha"] = k["alpha"] - 5
			end
			k["alpha"] = math.Clamp(k["alpha"], 0, 255)
			if k["alpha"] == 1 then
				table.remove(Killfeed,_)
			end
		end
	end
end)

local LookupCache = {}

net.Receive("mw2_killfeed", function(len)
	local attacker = net.ReadString()
	local a_team = net.ReadUInt(10)
	local lookup = net.ReadBool()
	local inflictor = net.ReadString()
	local victim = net.ReadString()
	local v_team = net.ReadUInt(10)

	if a_team == 0 then
		attacker = language.GetPhrase(attacker)
	end
	if v_team == 0 then
		victim = language.GetPhrase(victim)
	end
	if inflictor[1] == "#" then
		inflictor = language.GetPhrase(inflictor)
	elseif lookup then
		if LookupCache[inflictor] then
			inflictor = LookupCache[inflictor]
		else
			local old = inflictor
			local tab = weapons.Get(inflictor)
			if tab then
				if tab.PrintName != "" then
					inflictor = tab.PrintName
				end
			else
				local tab = scripted_ents.Get(inflictor)
				if tab then
					PrintTable(tab)
					if tab.PrintName != "" then
						inflictor = tab.PrintName
					end
				end
			end
			LookupCache[old] = inflictor
		end
	end

	local a_color = team.GetColor(a_team)
	if a_team == 0 then a_color = Color(255,50,50,255) end
	local v_color = team.GetColor(v_team)
	if v_team == 0 then v_color = Color(255,50,50,255) end

	table.insert(Killfeed_Panels, 1, model_icon)
	table.insert(Killfeed, 1, {
		["attacker"] = attacker,
		["attacker_color"] = a_color,
		--["icon"] = model_icon,
		--["icon_height"] = 25,
		--["icon_width"] = size,
		["weapon"] = inflictor,
		["victim"] = victim,
		["victim_color"] = v_color,
		["state"] = true,
		["alpha"] = 1,
		["y"] = 0,
		["time"] = CurTime()
	})
end)

hook.Add("DrawDeathNotice", "MW2_ForceHide_Deaths", function(x, y)
	x, y = -50, -50
	return true
end)

elseif SERVER then

util.AddNetworkString("mw2_killfeed")

local SendKills = {}
timer.Create("MW2_Process_Killfeed", 0.05, 0, function()
	if #SendKills > 0 then
		net.Start("mw2_killfeed")
			net.WriteString(SendKills[1]["a"])
			net.WriteUInt(SendKills[1]["t"], 10)
			net.WriteBool(SendKills[1]["b"])
			net.WriteString(SendKills[1]["i"])
			net.WriteString(SendKills[1]["v"])
			net.WriteUInt(SendKills[1]["vt"], 10)
		net.Broadcast()
		table.remove(SendKills, 1)
	end
end)

local function GetInfo(entity)
	if entity:IsNPC() then
		return entity:GetClass(), 0
	elseif entity:IsWorld() then
		return "world", 0
	else
		if entity:IsVehicle() then
			local dri = entity:GetDriver()
			if IsValid(dri) then
				return dri:Name(), dri:Team()
			end
		end
		local owner = entity:GetOwner()
		if IsValid(owner) then
			if owner:IsPlayer() then
				return owner:Name(), owner:Team()
			end
		end
	end
	if entity:IsPlayer() then
		return entity:Name(), entity:Team()
	end
	return entity:GetClass(), 0
end

local function SendData(attacker, inflictor, victim)
	local a, t = GetInfo(attacker)
	local i = ""
	local v, vt = GetInfo(victim)

	if inflictor:IsPlayer() then inflictor = inflictor:GetActiveWeapon() end
	if inflictor then
		if inflictor:IsNPC() then
			i = "killed"
		elseif inflictor:IsWeapon() then
			i = inflictor:GetPrintName()
		elseif inflictor:IsVehicle() then
			i = "killed"
		end
		if i == "" then
			i = inflictor:GetClass()
		end
	end

	if attacker == victim then i = "suicide" end
	if attacker == inflictor then i = "killed" end
	if not i or i == "" then i = "world" end --i = "models/gibs/hgibs.mdl"
	if i == "Scripted Weapon" then i = inflictor:GetClass() end

	table.insert(SendKills, {
		["a"] = a,
		["t"] = t,
		["b"] = tobool(i == "Scripted Weapon" or string.find(i, '_')),
		["i"] = i,
		["v"] = v,
		["vt"] = vt or 0
	})
end

hook.Add("PlayerDeath", "MW2_PlayerDeath", function(victim, inflictor, attacker)
	SendData(attacker, inflictor, victim)
end)

hook.Add("OnNPCKilled", "MW2_NPCDeath", function(npc, attacker, inflictor)
	SendData(attacker, inflictor, npc)
end)

end
