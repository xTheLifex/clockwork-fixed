
local STATIC_WHITELIST = {
	"prop_physics",
	"prop_ragdoll",
	"prop_effect",
	"gmod_",
	"edit_"
}

-- A function to check if an entity can be static.
function cwStaticEnts:CanEntityStatic(entity)
	if entity:IsValid() and not entity.cwInventory and not cwStorage.containerList[entity:GetModel()] then
		local class = entity:GetClass()

		for i = 1, #STATIC_WHITELIST do
			if string.find(class, STATIC_WHITELIST[i]) then
				return true
			end
		end
	end

	return false
end

-- A function to save an entity.
function cwStaticEnts:SaveEntity(entity)
	if IsValid(entity) and Clockwork.plugin:Call("CanEntityStatic", entity) then
		table.insert(self.staticEnts, entity)
	end
end

-- A function to return the static mode boolean variable.
function cwStaticEnts:GetStaticMode()
	return self.staticMode[1]
end

-- A function to load the static entities.
function cwStaticEnts:LoadStaticEnts()
	self.staticMode = Clockwork.kernel:RestoreSchemaData("maps/" .. game.GetMap() .. "/static_entities/static_mode") or {false}

	local classTable = Clockwork.kernel:RestoreSchemaData("maps/" .. game.GetMap() .. "/static_entities/classtable")
	local staticEnts = {}
	self.staticEnts = {}

	if classTable and type(classTable) == "table" then
		for k, v in pairs(classTable) do
			local loadTable = Clockwork.kernel:RestoreSchemaData("maps/" .. game.GetMap() .. "/static_entities/" .. v)

			if loadTable and #loadTable > 0 then
				for k2, v2 in ipairs(loadTable) do
					table.insert(staticEnts, v2)
				end

				if v == "prop_physics" then
					Clockwork.kernel:SaveSchemaData("maps/" .. game.GetMap() .. "/static_entities/backup/" .. v, loadTable)
					Clockwork.kernel:DeleteSchemaData("maps/" .. game.GetMap() .. "/static_entities/" .. v)
				end
			end
		end
	end

	local staticProps = Clockwork.kernel:RestoreSchemaData("plugins/props/" .. game.GetMap())

	if staticProps and #staticProps > 0 then
		for k, v in ipairs(staticProps) do
			v.class = "prop_physics"
			table.insert(staticEnts, v)
		end
	end

	for k, v in pairs(staticEnts) do
		local entity = ents.Create(v.class)
		entity:SetMaterial(v.material)
		entity:SetAngles(v.angles)
		entity:SetModel(v.model)
		entity:SetPos(v.position)
		entity:SetSkin(v.skin or 0)
		entity:SetNWString("physDesc", v.physdesc)
		entity:SetOwnerKey(v.ownerkey)
    
		if v.bNoCollision == nil or v.bNoCollision then
			entity:SetCollisionGroup(COLLISION_GROUP_WORLD)
		end

		if (istable(v.bodyGroups)) then
			for k2, v2 in pairs(v.bodyGroups) do
				entity:SetBodygroup(k2, v2)
			end
		end

		if not v.renderMode then
			v.renderMode = 0
			v.renderFX = 0
		end

		if v.color.a < 255 and v.renderMode == 0 then
			v.renderMode = 1
		end

		entity:SetColor(v.color)
		entity:SetRenderMode(v.renderMode)
		entity:SetRenderFX(v.renderFX)
		entity:Spawn()

		Clockwork.plugin:Call("OnStaticEntityLoaded", entity, v)

		entity:Activate()

		Clockwork.entity:MakeSafe(entity, true, true, true)
		table.insert(self.staticEnts, entity)
	end
end

-- A function to save the static entities.
function cwStaticEnts:SaveStaticEnts()
	local staticEnts = {}

	if type(self.staticEnts) == "table" then
		for k, v in pairs(self.staticEnts) do
			if IsValid(v) then
				local entTable = {}
				local physicsObject = v:GetPhysicsObject()
				local class = v:GetClass()

				staticEnts[class] = staticEnts[class] or {}

				entTable.class = class
				entTable.color = v:GetColor()
				entTable.model = v:GetClass() == "prop_effect" and v.AttachedEntity:GetModel() or v:GetModel()
				entTable.angles = v:GetAngles()
				entTable.position = v:GetPos()
				entTable.material = v:GetMaterial()
				entTable.renderMode = v:GetRenderMode()
				entTable.renderFX = v:GetRenderFX()
				entTable.bNoCollision = v:GetCollisionGroup() == COLLISION_GROUP_WORLD
				entTable.skin = v:GetSkin()
				entTable.physdesc = v:GetNWString("physDesc")
				entTable.ownerkey = v:GetOwnerKey()

				local bodyGroups = v:GetBodyGroups()

				if (istable(bodyGroups)) then
					entTable.bodyGroups = {}

					for _, v2 in pairs(bodyGroups) do
						if (v:GetBodygroup(v2.id) > 0) then
							entTable.bodyGroups[v2.id] = v:GetBodygroup(v2.id)
						end
					end
				end

				if IsValid(physicsObject) then
					entTable.moveable = physicsObject:IsMoveable()
				end

				Clockwork.plugin:Call("OnStaticEntitySaved", v, entTable)
				table.insert(staticEnts[class], entTable)
			end
		end

		local classTable = {}

		for k, v in pairs(staticEnts) do
			if k == "prop_physics" then
				Clockwork.kernel:SaveSchemaData("plugins/props/" .. game.GetMap(), v)
			else
				Clockwork.kernel:SaveSchemaData("maps/" .. game.GetMap() .. "/static_entities/" .. k, v)

				if not classTable[k] then
					table.insert(classTable, k)
				end
			end
		end

		for k, v in pairs(_player.GetAll()) do
			if Clockwork.player:IsAdmin(v) then
				Clockwork.datastream:Start(v, "StaticESPSync", self.staticEnts)
			end
		end

		Clockwork.kernel:SaveSchemaData("maps/" .. game.GetMap() .. "/static_entities/classtable", classTable)
	end
end

function cwStaticEnts:OnStaticEntitySaved(entity, entTable)
	if entity:GetClass() == "gmod_lamp" then
		entTable.texture = entity:GetFlashlightTexture()
		entTable.fov = entity:GetLightFOV()
		entTable.distance = entity:GetDistance()
		entTable.brightness = entity:GetBrightness()
	elseif entity:GetClass() == "gmod_light" then
		entTable.brightness = entity:GetBrightness()
		entTable.size = entity:GetLightSize()
	elseif entity:GetClass() == "prop_ragdoll" then
		local boneTable = {}

		for i = 0, entity:GetPhysicsObjectCount() - 1 do
			local bone = entity:GetPhysicsObjectNum(i)

			table.insert(boneTable, {
				ang = bone:GetAngles(),
				pos = bone:GetPos()
			})
		end

		entTable.bones = boneTable
	end
end

function cwStaticEnts:OnStaticEntityLoaded(entity, entTable)
	if entTable.bones then
		for i, v in ipairs(entTable.bones) do
			local bone = entity:GetPhysicsObjectNum(i - 1)

			bone:SetAngles(v.ang)
			bone:SetPos(v.pos)
		end
	elseif IsValid(entity:GetPhysicsObject()) then
		entity:GetPhysicsObject():EnableMotion(entTable.moveable)
	end

	if entTable.texture then
		entity:SetFlashlightTexture(entTable.texture)
		entity:SetLightFOV(entTable.fov)
		entity:SetDistance(entTable.distance)
		entity:SetBrightness(entTable.brightness)
		entity:SetToggle(false)
		entity:Switch(true)
	end

	if entTable.size then
		entity:SetBrightness(entTable.brightness)
		entity:SetLightSize(entTable.size)
		entity:SetOn(true)
	end
end
