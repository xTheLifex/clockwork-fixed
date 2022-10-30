local PLUGIN = PLUGIN
local Clockwork = Clockwork

-- Called when the client initializes.
function PLUGIN:Initialize()
	CW_CONVAR_ITEMESP = Clockwork.kernel:CreateClientConVar("cwItemESP", 0, false, true)
	CW_CONVAR_PROPESP = Clockwork.kernel:CreateClientConVar("cwPropESP", 0, false, true)
	CW_CONVAR_SALEESP = Clockwork.kernel:CreateClientConVar("cwSaleESP", 0, false, true)
	CW_CONVAR_CWENTESP = Clockwork.kernel:CreateClientConVar("cwEntESP", 0, false, true)
	CW_CONVAR_PIANOESP = Clockwork.kernel:CreateClientConVar("cwPianoESP", 0, false, true)
	CW_CONVAR_NPCESP = Clockwork.kernel:CreateClientConVar("cwNPCESP", 0, false, true)
end

-- Called when the admin ESP info is needed.
function PLUGIN:GetAdminESPInfo(info)
	--ItemESP
	if CW_CONVAR_ITEMESP:GetInt() == 1 then
		for k, v in pairs(ents.GetAll()) do
			if v:GetClass() == "cw_item" then
				if v:IsValid() then
					local position = v:GetPos()
					local itemTable = Clockwork.entity:FetchItemTable(v)

					if itemTable then
						local itemname = itemTable("name")
						local name = "<" .. itemname .. ">"

						info[#info + 1] = {
							position = position,
							color = Color(0, 255, 255, 255),
							text = name
						}
					end
				end
			end
		end
	end

	--PropESP
	if CW_CONVAR_PROPESP:GetInt() == 1 then
		for k, v in pairs(ents.GetAll()) do
			if v:GetClass() == "prop_physics" then
				if v:IsValid() then
					local position = v:GetPos()
					local name = v:GetModel()

					if name then
						info[#info + 1] = {
							position = position,
							color = Color(0, 255, 0, 255),
							text = name
						}
					end
				end
			end
		end
	end

	--CWEntESP
	if CW_CONVAR_CWENTESP:GetInt() == 1 then
		for k, v in pairs(ents.GetAll()) do
			if v:IsValid() then
				local class = v:GetClass()

				if string.find(class, "cw_") then
					--Half useless table of joy, will fix dis latur
					local position = v:GetPos()

					local entCheck = {
						["cw_unionlight"] = "Union Light",
						["cw_notepad"] = "NotePad",
						["cw_terminal"] = "Terminal",
						["cw_compressor"] = "Compressor",
						["cw_emplacementgun"] = "Emplacement Gun",
						["cw_forcefield"] = "Forcefield",
						["cw_paper"] = "Paper"
					}

					if class == "cw_cash" then
						local name = v:GetDTInt(0) .. " " .. Clockwork.option:GetKey("name_cash")

						info[#info + 1] = {
							position = position,
							color = Color(0, 115, 0, 255),
							text = "[" .. name .. "]"
						}
					elseif class == "cw_shipment" then
						local itemTable = v:GetItemTable()
						local name = "Shipment] - [" .. itemTable("name")

						info[#info + 1] = {
							position = position,
							color = Color(120, 0, 180, 255),
							text = "[" .. name .. "]"
						}
					elseif class == "cw_radio" then
						local frequency = v:GetFrequency()
						local color

						if frequency == "" then
							frequency = "No Freq"
						end

						if not v:IsOff() then
							color = Color(0, 255, 0, 255)
						else
							color = Color(255, 150, 0, 255)
						end

						local name = "Radio] - [" .. frequency

						info[#info + 1] = {
							position = position,
							color = color,
							text = "[" .. name .. "]"
						}
					elseif class == "cw_combinelock" then
						local color

						if v:IsLocked() then
							color = Color(255, 150, 0, 255)
						else
							color = Color(0, 255, 0, 255)
						end

						info[#info + 1] = {
							position = position,
							color = color,
							text = "[Combine Lock]"
						}
					elseif class == "cw_unionlock" then
						local color

						if v:IsLocked() then
							color = Color(0, 100, 255, 255)
						else
							color = Color(0, 255, 0, 255)
						end

						info[#info + 1] = {
							position = position,
							color = color,
							text = "[Union Lock]"
						}
					elseif class == "cw_vendingmachine" then
						local stock = v:GetStock()
						local name = "[Vending Machine] - [" .. stock .. "]"

						info[#info + 1] = {
							position = position,
							color = Color(0, 160, 180, 255),
							text = name
						}
					elseif class == "cw_rationdispenser" then
						local color
						local rationTime = v:GetDTFloat(0)
						local curTime = CurTime()
						local flashTime = v:GetDTFloat(1)

						if v:IsLocked() then
							color = Color(255, 150, 0, 255)
						elseif rationTime > curTime then
							color = Color(0, 0, 255, 255)
						elseif flashTime and flashTime >= curTime then
							color = Color(255, 0, 0, 255)
						else
							color = Color(0, 255, 0, 255)
						end

						info[#info + 1] = {
							position = position,
							color = color,
							text = "[Ration Dispenser]"
						}
					elseif class == "cw_book" then
						local index = v:GetDTInt(0)
						local itemTable = Clockwork.item:FindByID(index)
						local name = itemTable.name

						info[#info + 1] = {
							position = position,
							color = Color(0, 180, 120, 255),
							text = "[" .. name .. "]"
						}
					else
						for k2, v2 in pairs(entCheck) do
							if class == k2 then
								local name = v2

								info[#info + 1] = {
									position = position,
									color = Color(0, 40, 255, 255),
									text = "[" .. name .. "]"
								}

								break
							end
						end
					end
				end
			end
		end
	end

	--PianoESP
	if CW_CONVAR_PIANOESP:GetInt() == 1 then
		for k, v in pairs(ents.GetAll()) do
			if v:GetClass() == "gmt_instrument_piano" then
				if v:IsValid() then
					local position = v:GetPos() + Vector(0, 0, 80)
					local name = "[Piano]"

					if name then
						info[#info + 1] = {
							position = position,
							color = Color(255, 100, 255, 255),
							text = name
						}
					end
				end
			end
		end
	end

	--SalesmanESP
	if CW_CONVAR_SALEESP:GetInt() == 1 then
		for k, v in pairs(ents.GetAll()) do
			if v:GetClass() == "cw_salesman" then
				if v:IsValid() then
					local position = v:GetPos()
					local salename = v:GetNWString("Name")
					local name = "[Salesman - " .. salename .. "]"

					info[#info + 1] = {
						position = position,
						color = Color(255, 230, 0, 255),
						text = name
					}
				end
			end
		end
	end

	--NPCESP
	if CW_CONVAR_NPCESP:GetInt() == 1 then
		for k, v in pairs(ents.GetAll()) do
			if v:IsValid() then
				if string.find(v:GetClass(), "npc_") then
					if not string.find(v:GetClass(), "scanner") then
						local position = v:GetPos() + Vector(0, 0, 80)
						local name = "[NPC] - [" .. v:GetClass() .. "]"

						info[#info + 1] = {
							position = position,
							color = Color(0, 100, 100, 255),
							text = name
						}
					end
				end
			end
		end
	end

	--Fixes all non-humanoid models
	for k, v in pairs(player.GetAll()) do
		if v:HasInitialized() then
			local physBone = v:LookupBone("ValveBiped.Bip01_Head1")

			if not physBone then
				position = v:GetPos() + Vector(0, 0, 80)

				info[#info + 1] = {
					position = position,
					color = cwTeam.GetColor(v:Team()),
					text = v:Name() .. " (" .. v:Health() .. "/" .. v:GetMaxHealth() .. ")"
				}
			end
		end
	end
end