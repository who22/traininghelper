script_name('trainingHelper') 
script_author('Gerald.myr') 

require 'lib.moonloader'

local scriptVersion = 101
local updState = false

local scriptPath = thisScript().path
local scriptUrl = 'https://raw.githubusercontent.com/who22/traininghelper/main/traininghelper.lua'
local updatePath = getWorkingDirectory() .. '/thUpdate.ini'
local updateUrl = 'https://raw.githubusercontent.com/who22/traininghelper/main/thUpdate.ini'

local dlstatus = require('moonloader').download_status
local sampev = require 'samp.events'
local inicfg = require 'inicfg'
local imgui = require 'mimgui'
local encoding = require 'encoding'
local ffi = require 'ffi'

encoding.default = 'CP1251'
u8 = encoding.UTF8

local str = ffi.string

local directIni = 'thConfig'
local config = inicfg.load({
	friends = {
	'Goodman',
	},
	settings = {
		autoPM = 0,
		carLock = false,
		copyPos = false,
		autoCB = false,
		objHL = false,
		showCoords = false,
		antiTroll = false,
		style = 0
	}
}, directIni)

local new = imgui.new

local hintWindow = new.bool(false)

local notepadWindow = new.bool(false)
local notepad = new.char[65535]('')

local menuWindow = new.bool(false)
local tab = 0

local color = new.float[3](1.0, 1.0, 1.0)

local carLock = new.bool(config.settings.carLock)
local copyPos = new.bool(config.settings.copyPos)
local autoCB = new.bool(config.settings.autoCB)
local objHL = new.bool(config.settings.objHL)
local showCoords = new.bool(config.settings.showCoords)
local antiTroll = new.bool(config.settings.antiTroll)
local chMode = new.bool(false)

local showObject = false
font = renderCreateFont('Arial', 8, 5)

local resX, resY = getScreenResolution()

local style = {
	style = new.int(config.settings.style),
	items = {u8'������� ����', u8'������ ����'},
	array = {}
}

local autopm = {
	toggle = new.int(tonumber(config.settings.autoPM)),
	items = {u8'��������', u8'�������', u8'������ ������'},
	array = {}
}

local anticheat = {
	toggle = new.bool(0),
	items = {u8'������������', u8'��������� �� �����', u8'�������', u8'��������', u8'Debug'},
	array = {},
	punishment = new.int(0),
	modReact = new.bool(0),
	modMsg = new.bool(0),
	warnings = new.int(3),
	banTime = new.int(0),
	acPattern = new.char[65535](''),
	warningsRemove = new.int(10)
}

imgui.OnInitialize(function()
	autopm['array'] = new['const char*'][#autopm['items']](autopm['items'])
	anticheat['array'] = new['const char*'][#anticheat['items']](anticheat['items'])
	style['array'] = new['const char*'][#style['items']](style['items'])

	approveStyle()
end)

function msgChat(msg) 
	sampAddChatMessage('[trainingHelper] {FFFFFF}'..msg, 0x05A90CE)
end

function main()


	repeat wait(0) until isSampAvailable()


	msgChat('TrainingHelper by Gerald.myr ������� | /binds | /cmds | /menu')

	sampRegisterChatCommand('binds', function(id)
		msgChat('Z - �������� ����� | ��� + X - fast /pm | I - friend list')
	end)


	sampRegisterChatCommand('cmds', function(id)
		msgChat('/faddname - �������� ����� �� ���� | /faddid - �������� ����� �� ID')
		msgChat('/isafk ID - ��� �� AFK | /cc - �������� ��� | /notepad - ������� ��� �������')
		msgChat('/friendlist - ������ ���� ������ | /delf NICK - ������� ����� | /hint - ��������� �� ��������� ��������')
	end)


	sampRegisterChatCommand('notepad', function()
		notepadWindow[0] = not notepadWindow[0]
	end)


	sampRegisterChatCommand('hint', function()
		hintWindow[0] = not hintWindow[0]
	end)
		

	sampRegisterChatCommand('menu', function()
		menuWindow[0] = not menuWindow[0]
	end)


	sampRegisterChatCommand('cc', function()
		for i = 1, 15 do
			sampAddChatMessage(' ')
		end
	end)


	sampRegisterChatCommand('faddid', function(id)
		if tonumber(id) == nil then
			return msgChat('����� ����, � �� ��� {5A90CE}' .. id .. '{FFFFFF}, �������')
		else
			if sampIsPlayerConnected(id) then
				local name = sampGetPlayerNickname(tonumber(id))
				local friendList = config.friends
				config.friends[#friendList + 1] = tostring(name)
				inicfg.save(config, directIni)
				msgChat('� ���� ����� ����, � ����� � �������� {5A90CE}' .. name .. '{FFFFFF}!')
			end
		end
	end)


	sampRegisterChatCommand('faddname', function(name)
		local friendList = config.friends
		config.friends[#friendList + 1] = tostring(name)

		inicfg.save(config, directIni)
		msgChat('� ���� ����� ����, � ����� � �������� {5A90CE}' .. name .. '{FFFFFF}!')
	end)


	sampRegisterChatCommand('delf', function (name)
		local friendList = config.friends
		local friend = nil

		for pos = 1, #friendList do
			friend = tostring(friendList[pos])
			if friend == tostring(name) then
				config.friends[pos] = config.friends[#friendList]
				config.friends[#friendList] = nil
				inicfg.save(config, directIni)
				msgChat('�� �������� �������� �����, � ����� � ��������. {5A90CE}'..name..'{FFFFFF}, ������ :(')
			end
		end
	end)


	sampRegisterChatCommand('isafk', function (id)
		if sampIsPlayerConnected(id) then
			if sampIsPlayerPaused(id) then 
				msgChat(sampGetPlayerNickname(id) .. '(' .. id .. ')' .. ': {808080}AFK')
			else 
				msgChat(sampGetPlayerNickname(id) .. '(' .. id .. ')' .. ': {90ce5a}ONLINE')
			end
		end
	end)


	sampRegisterChatCommand('friendlist', function ()
		local friendList = config.friends

		msgChat('������ ���� ������:')
		for pos = 1, #friendList do
			friend = friendList[pos]
			sampAddChatMessage(tostring(friend), 0x0FFFFFF)
		end
	end)


	downloadUrlToFile(updateUrl, updatePath, function(id, status)
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			local updIni = inicfg.load(nil, updatePath)
			if tonumber(updIni.info.version) > scriptVersion then
				msgChat('���������� ����� ������ �������!')
				updState = true
			end
			os.remove(updatePath)
		end
	end)


	while true do


		if updState then
			downloadUrlToFile(scriptUrl, scriptPath, function(id, status)
				if status == dlstatus.STATUS_ENDDOWNLOADDATA then
					msgChat('������ ��������!')
					thisScript():reload()
				end
			end)
			break
		end


		if showObject then
			for _, v in pairs(getAllObjects()) do
				if isObjectOnScreen(v) then
					local _, x, y, z = getObjectCoordinates(v)
					local x1, y1 = convert3DCoordsToScreen(x,y,z)
					local model = getObjectModel(v)
					renderFontDrawText(font, '{80FFFFFF}' .. model, x1, y1, -1)
				end
			end
		end

		if chMode[0] then
			for _, v in pairs(getAllVehicles()) do
				if isCarOnScreen(v) then
					local x, y, z = getCarCoordinates(v)
					local pedX, pedY, pedZ = getCharCoordinates(PLAYER_PED)
					local dist = math.sqrt(((pedX-x)^2)+((pedY-y)^2)+((pedZ-z)^2))
					if dist < 30.0 then
						local x1, y1 = convert3DCoordsToScreen(x,y,z-1)
						local hp = getCarHealth(v)
						renderFontDrawText(font, '{FF898585}' .. hp .. '.0', x1, y1, -1)
					end
				end
			end
		end


		if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then

			if isKeyJustPressed(VK_I) then
				local friendList = config.friends
				local friend = nil
				local res = ''

				msgChat('{5A90CE}������ ������ ������:')

				for id = 0, 500 do
					if sampIsPlayerConnected(id) then
						for pos = 1, #friendList do
							friend = tostring(friendList[pos])
							if friend:lower() == sampGetPlayerNickname(id):lower() then
								res = '{FFFFFF}' .. sampGetPlayerNickname(id) .. '(' .. id .. ')'
									if sampIsPlayerPaused(id) then
										res = res .. ' {808080}[AFK]{FFFFFF}'
									end
								sampAddChatMessage(res)
							end
						end
					end
				end
			end

			if isKeyJustPressed(VK_Z) then
				local hour = tonumber(os.date('%H'))

				if hour > 20 then
					msgChat('{DE3131}��������! {FFFFFF}������ �����, ������ � �����! ����� ����� ����!')
				end

				_, playerID = sampGetPlayerIdByCharHandle(playerPed)
				msgChat('ID:' .. ' {90ce5a}' .. playerID .. ' {FFFFFF}' .. '�����:' .. ' {90ce5a}' .. os.date('%H:%M:%S').. ' {FFFFFF}' .. '������� �����:' .. ' {90ce5a}' .. getTimeOfDay() .. ':00')
			end

			if isKeyJustPressed(VK_X) then
				local result, target = getCharPlayerIsTargeting(playerHandle)
				if not result then
					msgChat('����� {90ce5a}���{FFFFFF}, ������ �� ������ � ��� ����� ����� {90ce5a}X{FFFFFF}.')
				else
					_, pID  = sampGetPlayerIdByCharHandle(target)
					sampSetChatInputEnabled(true)
					sampSetChatInputText('/pm ' .. pID .. ' ')
				end
			end

			if isKeyJustPressed(VK_L) then
				if config.settings.carLock then
					sampSendChat('/lock')
				end
			end

			if isKeyJustPressed(VK_O) and objHL[0] then
				showObject = not showObject
			end

			if isKeyJustPressed(VK_Q) and chMode[0] and isCharInAnyCar(PLAYER_PED) then
				sampSendChat('/callsign')
            	sampSendDialogResponse(32700, 1, 0, '{FFD800}<<<<<<')
			end

			if isKeyJustPressed(VK_E) and chMode[0] and isCharInAnyCar(PLAYER_PED) then
				sampSendChat('/callsign')
            	sampSendDialogResponse(32700, 1, 0, '{FFD800}>>>>>>')
			end

			if isKeyJustPressed(VK_R) and chMode[0] and isCharInAnyCar(PLAYER_PED) then
				sampSendChat('/callsign')
            	sampSendDialogResponse(32700, 1, 0, '{0F1B81}THANKS')
			end

		end
		wait(1)

	end

end


local hintFrame = imgui.OnFrame(
    function() return hintWindow[0] end,
    function(player)
		imgui.SetNextWindowPos(imgui.ImVec2(200, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(750, 400))

		imgui.Begin(u8'��������� ������� by OfficerBoss', hintWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

		if imgui.CollapsingHeader(u8"  �������") then
			imgui.Text(u8"- #random(num1, num2)# - ������������� ��������� ����� �� num1 �� num2.")
			imgui.Text(u8"- #array(num, playerid*)# - ������� ������ ������ ������� num.")
			imgui.Text(u8"- #server(num)# - ������� ������ ������ ������� num ���� (������).")
			imgui.Text(u8"- #retval(0 - 9, playerid*)# - ������������ ��������� ��� ������")
			imgui.Text(u8"- #retstr(0 - 9, playerid*)# - ������������ ��������� ��� ������ ���������")
			imgui.Text(u8"- #ext(cbid actionid)# - ���������� ���������� ������ ������������� �����.")
			imgui.Text(u8"- #pvar(name, playerid*)# - ���������� ���������� name ������ playerid.")
			imgui.Text(u8"- #vdata(vehicleid num)# - ������ ����������. ")
			imgui.Text(u8"- #oArray(objectid)# - �������� ������� ������� objectid")
			imgui.Text(u8"- #strcmp(str1, str2, caps*)# - ������ ������")
			imgui.Text(u8"- #strfind(str, synstr, caps*)# - ����� substr � str")
			imgui.Text(u8"- #srtdel(str, start, end)# - ������ ������� � start �� end � str")
			imgui.Text(u8"- #strlen(str)# - ����� ������")
			imgui.Text(u8"- #strins(str, substr, pos)# - ��������� substr � str �� ����� pos")
			imgui.Text(u8"- #customRaycast(xyz1 angle dist 0/1 x/y/z/xyz)# - ������� �������� (#raycast#) � ����� �����")
		end

		if imgui.CollapsingHeader(u8"  ����������") then
			imgui.Text(u8"- #round(number method*)# or #floatround(number method*)# - ���������� ����� number ������� method*")
			imgui.Text(u8"* round - ����� �� �������, ��������� � ����. ������ �����")
			imgui.Text(u8"* floor - ��������� ����")
			imgui.Text(u8"* ceil - ��������� �����")
			imgui.Text(u8"* tozero - ��������� ����� � 0")
			imgui.Text(u8"- #log(number base)# - �������� � ����� base �� ����� number")
			imgui.Text(u8"- #sin(number method*)# - ����� number")
			imgui.Text(u8"- #cos(number method*)# - ������� number")
			imgui.Text(u8"- #tan(number method*)# - ������� number")
			imgui.Text(u8"* radian - �� �������")
			imgui.Text(u8"* degrees")
			imgui.Text(u8"* grades")
			imgui.Text(u8"- #sqroot(number)# - ���������� ������ ����� number")
			imgui.Text(u8"- #power(numb1 numb2)# - ���������� ����� numb1 � ������� numb2")
			imgui.Text(u8"- #raycast(cam/pos dist col(0/1) coord(x/y/z/xyz))# - ������� ��������")
			imgui.Text(u8"- #floatnum(numb1 type numb2)# - ������ ������� (+, -, /, *) ����� numb1 � numb2")
		end

		if imgui.CollapsingHeader(u8"  �������") then
			imgui.Text(u8"- #teamOnline(1-10)# - ������� ������ �������.")
			imgui.Text(u8"- #team# - ������� ID ������� � ������� ������� �����.")
			imgui.Text(u8"- #teamName# - �������� ������� � ������� ������� �����. ")
		end

		if imgui.CollapsingHeader(u8"  ������ ����") then
			imgui.Text(u8"- #online# - ������� ������ ����")
			imgui.Text(u8"- #time# - ����� ����.")
			imgui.Text(u8"- #weather# - ������ ����.")
			imgui.Text(u8"- #timestamp# - ����� � �������� �� 01.01.1970")
			imgui.Text(u8"- #worldName# - �������� ����")
			imgui.Text(u8"- #worldDesc# - �������� ����")
			imgui.Text(u8"- #vehCount# - ���������� ����� � ����")
			imgui.Text(u8"- #objectCount# - ���������� �������� � ����")
			imgui.Text(u8"- #maxObj# or #maxObjectCount# - ����� �������� � ����")
			imgui.Text(u8"- #getDate(category*)# category: day, month, year, days/daynum")
			imgui.Text(u8"- #getTime(*category)# category: hour, minute, second")
			imgui.Text(u8"- #playerCount(category item)# - ���������� ������� �������������� category = item")
			imgui.Text(u8"- #playerList(item category id)# - ID ������ id, ������� ������������� category = item")
			imgui.Text(u8"- #randomPlayer(*category *item)# - ID ���������� ������ ���������������� category = item")
			imgui.Text(u8"* category: team, skin, veh, data, wanted, action, dead, alive, score, gun/weapon, channel,")
			imgui.Text(u8"* afk, vip, taser, surfingveh, int, attach, attachmodel, retval, vehseat")
			imgui.Text(u8" - #getZ(x y)# - �������� Z ���������� �� X � Y ����������")
			imgui.Text(u8"- #GetDist(xyz1 xyz2)# - �������� ���������� ����� xyz1 � xyz2")
			imgui.Text(u8"- #front(dist <x/y>, *playerid)# - ���������� ������� ������ playerid �� ���������� dist")
			imgui.Text(u8"- #getzone(x, y)# - �������� �������� ���� �� ����������� X Y")
			imgui.Text(u8"- #getzoneid(x, y)# - �������� ID ���� �� ����������� X Y")
			imgui.Text(u8"- #actionXYZ(actionid)# #actionX/Y/Z(actionid)# - ���������� 3� ������ actionid")
		end

		if imgui.CollapsingHeader(u8"  �������") then
			imgui.Text(u8"- #GetDistObject(objectid)# - �������� ���������� �� ������� objectid")
			imgui.Text(u8"- #oArray(objectid)# - �������� ������� ������� objectid")
			imgui.Text(u8"- #oState(objectid)# - ��������� ������� objectid (0 - ����� / 1 - �����)")
			imgui.Text(u8"- #oMoveXYZ(objectid)# (#oMoveX/Y/Z(objectid)#) - ���������� ����������� ������� objectid")
			imgui.Text(u8"- #oMove(objectid)# - !���������! - ������ ������� (0 - ����� / 1 - ������������)")
			imgui.Text(u8"- #rxyz(objectid)# (#rx/y/z(objectid)#) - ������� ������� objectid")
			imgui.Text(u8"- #oxyz(objectid)# (#ox/y/z(objectid)#) - ����������  ������� objectid")
			imgui.Text(u8"- #omodel(objectid)# - ������ ������� objectid")
			imgui.Text(u8"- #nearObj(dist modelid)# - ��������� ������ ������ modelid � ������� dist �� ������")
		end

		if imgui.CollapsingHeader(u8"  ������ ������") then
			imgui.Text(u8"- #name(playerid*)# - ������� ��� ������.")
			imgui.Text(u8"- #ping(playerid*)# - ���� ������")
			imgui.Text(u8"- #netstat(playerid*)# - ������ ������� � % (�������� ����������. ��������: 0%)")
			imgui.Text(u8"- #score(playerid*)# - ���� ������.")
			imgui.Text(u8"- #money(playerid*)# - ������ ������.")
			imgui.Text(u8"- #health(playerid*)# - �������� ������.")
			imgui.Text(u8"- #armour(playerid*)# - ����� ������.")
			imgui.Text(u8"- #playerid# - ID ������.")
			imgui.Text(u8"- #xyz(playerid*)# - ���������� ������.")
			imgui.Text(u8"- #x/y/z(playerid*)# - �������� ���������� ������ �� X Y Z")
			imgui.Text(u8"- #speed(playerid*)# - �������� ������.")
			imgui.Text(u8"- #gun(playerid*)# - ID ������ � ����� ������.")
			imgui.Text(u8"- #ammo(playerid*)# - ���������� ������ � ������")
			imgui.Text(u8"- #fa(playerid*)# - �������� �������� �������� ������")
			imgui.Text(u8"- #GetDistPlayer(playerid)# - �������� ���������� �� ������")
			imgui.Text(u8"- #wanted(playerid*)# - ������� ������� ������.")
			imgui.Text(u8"- #skin(playerid*)# - ���� ������.")
			imgui.Text(u8"- #attach(1-10)(playerid*)# - ������ ������ � �����.")
			imgui.Text(u8"- #acid(playerid*)# - ID �������� ������ �� /stats")
			imgui.Text(u8"- #afk(playerid*)# - ����� � �������� ������� ����� ������������ ��� � ����.")
			imgui.Text(u8"- #ban(playerid*)# - ���������� 1 ���� � ������ ���� �������� ����� � 0 ���� ���.")
			imgui.Text(u8"- #channel(playerid*)# - ����� ����� ������.")
			imgui.Text(u8"- #death(playerid*)# - ������� �������� ������ ������ ������. ���� �� ��� - 0.")
			imgui.Text(u8"- #drunk(playerid*)# - ��o���� �������� ������. ���� ������� ������ 2000, ����� �������.")
			imgui.Text(u8"- #hr(playerid*)# - ������� ��������� ��������� ������.")
			imgui.Text(u8"- #target(playerid*)# - ID ������ �������� ������� ����� ��� �����.")
			imgui.Text(u8"- #waterlvl(playerid*)# - ������� ���� ��� �������. ���� ����� �� � ���� - 0.0")
			imgui.Text(u8"- #anim(*playerid*)# - �������� ������")
			imgui.Text(u8"- #vehicle(playerid*)# or #veh(playerid*)# - ID ������ ������")
			imgui.Text(u8"- #gunName(*playerid)# - �������� ������ ������")
			imgui.Text(u8"- #moder(*playerid)# - ������� ���������� ������ (999 - ����)")
			imgui.Text(u8"- #specState(*playerid)# - bool ��������� ������ ������")
			imgui.Text(u8"- #specTarget(*playerid)# - ID ������ �� ������� ��������� playerid")
			imgui.Text(u8"- #int(*playerid)# - �������� ������")
			imgui.Text(u8"- #vip(*playerid)# - ������� VIP-������� � ������")
			imgui.Text(u8"- #chatStyle(*playerid)# - ����� ���� (�������� �������)")
			imgui.Text(u8"- #freeze(*playerid)# - bool ��������� ��������� ������")
			imgui.Text(u8"- #freezeTime(*playerid)# - ����� ��������� � ��")
			imgui.Text(u8"- #gm(*playerid)# - bool ��������� ������ ���� � ������")
			imgui.Text(u8"- #mute(*playerid)# - bool ��������� ���� ������")
			imgui.Text(u8"- #muteTime(*playerid)# - ����� ���� ������ � ��������")
			imgui.Text(u8"- #taser(*playerid)# - bool ��������� ������� � ������")
			imgui.Text(u8"- #lastActor(*playerid)# - !???!")
			imgui.Text(u8"- #clist(*playerid)# - Clist ������ (���� ����)")
			imgui.Text(u8"- #fightStyle(*playerid)# - ����� ����� ������")
			imgui.Text(u8"- #isWorld(playerid)# - bool ��������� ����������� � ���� ������")
			imgui.Text(u8"- #nearply(*playerid)# - ��������� ����� �� playerid")
			imgui.Text(u8"- #pame(slot, *playerid)# - ����� � ����� slot �����(/pame) � ������ playerid")
			imgui.Text(u8"- #weaponState(*playerid)# or #gunState(*playerid)# - ��������� ������ � ������")
			imgui.Text(u8"- #GetDistPlayer(targetid, *playerid)# - ���������� �� ������ playerid �� ������ targetid")
			imgui.Text(u8"- #GetDistPos(x y z *playerid)# - ���������� �� ������ playerid �� ��������� xyz")
			imgui.Text(u8"- #GetDistVeh(vehid, *playerid)# - ���������� �� ������ playerid �� ���������� vehid")
			imgui.Text(u8"- #getDistAction(actionid, *playerid)# - ���������� �� ������ �� 3� ������ actionid")
			imgui.Text(u8"- #GetDistActor(actorid, *playerid)# - ���������� �� ������ �� ����� actorid")
			imgui.Text(u8"- #zone(*playerid)# - �������� ���� � ������� ��������� ����� playerid")
			imgui.Text(u8"- #key(side, *playerid)# - !������!")
			imgui.Text(u8"- #nearAction(range<1-200>, *playerid)# -  ��������� 3� ����� � ������� range")
			imgui.Text(u8"- #nearActor(dist, skinid)# - ��������� ���� �� ������ skinid � ������� dist �� ������")
		end

		if imgui.CollapsingHeader(u8"  ���������") then
			imgui.Text(u8"- #vehicle(playerid*)# - ������� ID ����������.")
			imgui.Text(u8"- #vehName(vehid*)# - �������� ����������.")
			imgui.Text(u8"- #vehHealth(vehid*)# - �������� ����������.")
			imgui.Text(u8"- #vehColor(vehid*)# - ���� ����������. � RGB ������� ��� { }.")
			imgui.Text(u8"- #vehColor1(*playerid)# - ������ ���� ������ � RGB")
			imgui.Text(u8"- #vehColor2(*playerid)# - ������ ���� ������ � RGB")
			imgui.Text(u8"- #VehModel(vehid*)# - ������ ���������� � ������� ����� �����")
			imgui.Text(u8"- #getVehModel(400 - 611)# - �������� ���������� �� ��� ������.")
			imgui.Text(u8"- #vehPos(vehicleid)# - ���������� X y Z ����������")
			imgui.Text(u8"- #GetVehName(vehid)# - �������� �������� ����������")
			imgui.Text(u8"- #GetDistVeh(vehid)# - �������� ���������� �� ����������")
			imgui.Text(u8"- #nearveh(playerid*)# - ���������� ID �����������, ����� � ������� �� ���������� (R=3m)")
			imgui.Text(u8"- #vehSeat(playerid*)# - ����� ������� �������� ����� � ����������:")
			imgui.Text(u8"* -1 - ��� ������, 0 - ��������, 1 - �������� ������, 2 - ����� �� ���������, 3 - ����� ������.")
			imgui.Text(u8"- #siren(vehid)# - bool ��������� ������ � ������")
			imgui.Text(u8"- #vehParam(vehid param)# - bool ��������� ��������� param � ������ vehid")
			imgui.Text(u8"- #surfingVeh(*playerid)# - ID ������ �� ������� ������ ���� �����")
			imgui.Text(u8"- #gearState(vehid)# - !�������� ����?!")
		end

		if imgui.CollapsingHeader(u8"  �������") then
			imgui.Text(u8"- � �� ����� � ���� ����������, �� ����� ����...")
			imgui.Text(u8"- #pXYZ(passid)# #pX/Y/Z(passid)# - ���������� �������")
			imgui.Text(u8"- #pRX(passid)# - ??????????????????")
			imgui.Text(u8"- #pInt(passid)# - �������� �������")
			imgui.Text(u8"- #pLock(passid)# - bool ��������� ���������� �������")
			imgui.Text(u8"- #pOwner(passid)# - �������� ������� (?)")
			imgui.Text(u8"- #pVehicle(passid)# - bool ��������� ���������� ��� ���������� �������")
			imgui.Text(u8"- #pModel(passid)# - ������ ������� �������")
			imgui.Text(u8"- #pStatus(passid)# or #pState(passid)# - ��������� �������")
			imgui.Text(u8"- #pTeam(passid)# - �������, ������� ����������� ������")
			imgui.Text(u8"- #passinfo(*playerid)# - ���������� � �������")
		end

		if imgui.CollapsingHeader(u8"  �����") then
			imgui.Text(u8"- #actorState(actorid)# or #actorStatus(actorid)# - bool ��������� ����� �����")
			imgui.Text(u8"- #actorAnim(actorid)# - �������� �����")
			imgui.Text(u8"- #actorAltAnim(actorid)# - �������������� �������� �����")
			imgui.Text(u8"- #actorSkin(actorid)# - ���� �����")
			imgui.Text(u8"- #actorHealth(actorid)# - �������� �����")
			imgui.Text(u8"- #actorInvulnerable(actorid)# or #actorGM(actorid)# - bool ��������� ���������� �����")
			imgui.Text(u8"- #actorXYZ(actorid)# #actorX/Y/Z(actorid)# - ���������� �����")
		end

		if imgui.CollapsingHeader(u8"  ������") then
			imgui.Text(u8"- #attach(slot, *playerid)# - ���� �� ����� � ����� slot")
			imgui.Text(u8"- #attachModel(slot, *playerid)# - ������ ������ � ����� slot")
			imgui.Text(u8"- #isAttachModel(modelid, *playerid)# - ���� �� � ������ ����� � ������� modelid")
			imgui.Text(u8"- #attachBone(slot, *playerid)# - ����� � ������� ��������� ����� � ����� slot")
			imgui.Text(u8"- #attachOffsetXYZ(slot, *playerid)# #attachOffsetX/Y/Z(slot, *playerid)# - ����� �� ����������� �� ������")
			imgui.Text(u8"- #attachRotXYZ(slot, *playerid)# #attachRotX/Y/Z(slot, *playerid)# - ������� ������")
			imgui.Text(u8"- #attachScaleXYZ(slot, *playerid)# #attachScaleX/Y/Z(slot, *playerid)# - ������� ������")
		end

		if imgui.CollapsingHeader(u8"  ������ ����������") then
			imgui.Text(u8"- #vAttach(slot, vehicleid)# - ���� �� ����� � ����� slot")
			imgui.Text(u8"- #vAttachModel(slot,*vehicleid)# ������ ������ � ����� slot")
			imgui.Text(u8"- #isvAttachModel(modelid, vehicleid)# ���� �� � ���������� ����� � ������� modelid")
			imgui.Text(u8"- #vAttachXYZ(slot, vehicleid)# #vAttachX/Y/Z(slot, vehicleid)# - ������� ������")
			imgui.Text(u8"- #vAttachRotXYZ(slot, vehicleid)# #vAttachRotX/Y/Z(slot, vehicleid)# - ������� ������")
			imgui.Text(u8"- #vAttachOffsetXYZ(slot, vehicleid)# #vAttachOffsetX/Y/Z(slot, vehicleid)# - ����� �� ����������� �� ������")
		end

		if imgui.CollapsingHeader(u8"  ������(/gate)") then
			imgui.Text(u8"- #gateStatus(gateid)# or #gateState(gateid)# - bool ������ �������� �����")
			imgui.Text(u8"- #gateID(gateid)# (MODEL) - ������ ������� �����")
			imgui.Text(u8"- #gateTeam(gateid)# - ������� ������� ����������� ������")
			imgui.Text(u8"- #gateType(gateid)# - ��� ����� (?!)")
			imgui.Text(u8"- #gateLocal(gateid)# - ?!")
			imgui.Text(u8"- #gateSpeed(gateid)# - �������� �������� �����")
			imgui.Text(u8"- #gateStartPosXYZ(gateid)# #gateStartPosX/Y/Z(gateid)# - ��������� ���������� �����")
			imgui.Text(u8"- #gateStartPosRXYZ(gateid)# #gateStartPosRX/Y/Z(gateid)# - ��������� ������� �����")
			imgui.Text(u8"- #gateStopPosX/Y/Z(gateid)# or gateEndPos(gateid) - �������� ���������� �����")
			imgui.Text(u8"- #gateStopPosRXYZ(gateid)# #gateStopPosRX/Y/Z(gateid)# - �������� ������� �����")
		end

		if imgui.CollapsingHeader(u8"  ������") then
			imgui.Text(u8"���������� ��� ����� #raycast#:")
			imgui.Text(u8"- #raycast(cam/pos ���������� 0/1) - ������� ����� �������� ����� ������� ������/������� � ��������. ")
			imgui.Text(u8"3� �������� �������� �� ������� � ������ ��������� ��������. ���� 1 - ������ ���������� �������� �����.")
			imgui.Text(u8"���� 0 - ������ 0.0 0.0 0.0")
		end

		imgui.End()
    end
)


local notepadFrame = imgui.OnFrame(
    function() return notepadWindow[0] end,
    function(player)
		imgui.SetNextWindowPos(imgui.ImVec2(200, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(400, 400), imgui.Cond.FirstUseEver)

		imgui.Begin(u8'�������', notepadWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

		imgui.InputTextMultiline('notepad', notepad, 65535, imgui.ImVec2(385, 362.5), imgui.Cond.FirstUseEver)

		imgui.End()
    end
)


local backgroundFrame = imgui.OnFrame(
    function() return showCoords[0] end,
    function(player)
		local positionX, positionY, positionZ = getCharCoordinates(PLAYER_PED)

		player.HideCursor = true
		
		local dl = imgui.GetBackgroundDrawList()

		dl:AddText(imgui.ImVec2(10, resY - 20), 0xFFFFFFFF, 'XYZAngle: ' .. round(positionX, 1) .. ' ' .. round(positionY, 1) .. ' ' .. round(positionZ, 1) .. ' ' .. math.floor(getCharHeading(PLAYER_PED)))
end)


local menuFrame = imgui.OnFrame(
    function() return menuWindow[0] end,
    function(player)
		local positionX, positionY, positionZ = getCharCoordinates(PLAYER_PED)

		imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(245, 295))

		imgui.Begin(u8' trainingHelper', menuWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

		imgui.SetCursorPos(imgui.ImVec2(5, 25))

		if imgui.Selectable(u8'��������', tab == 0, 0, imgui.ImVec2(75, 15)) then tab = 0 end
		imgui.SameLine()
        if imgui.Selectable(u8'�������', tab == 1, 0, imgui.ImVec2(75, 15)) then tab = 1 end
		imgui.SameLine()
		if imgui.Selectable(u8'�������', tab == 2, 0, imgui.ImVec2(75, 15)) then tab = 2 end

		imgui.Separator()


		if tab == 0 then

			imgui.Text(u8'XYZAngle: ' .. round(positionX, 1) .. ' ' .. round(positionY, 1) .. ' ' .. round(positionZ, 1) .. ' ' .. math.floor(getCharHeading(PLAYER_PED)))
			imgui.PushItemWidth(145)

			if imgui.Combo(u8'�uto /pm', autopm['toggle'], autopm['array'], 3) then
				config.settings.autoPM = autopm['toggle'][0]
				inicfg.save(config, directIni)
			end

			imgui.TextQuestionSameLine('( ? )', u8'����� ��� �������� ��������� �� �����,\n��� ����� ����� ���� ���������� �����.\n��� ������ ��������� /pm!')

			if imgui.Checkbox(u8'�������/������� ���� �� L', carLock) then
				config.settings.carLock = carLock[0]
				inicfg.save(config, directIni)
			end

			if imgui.Checkbox(u8'����������� ������� ��� /savepos', copyPos) then
				config.settings.copyPos = copyPos[0]
				inicfg.save(config, directIni)
			end

			if imgui.Checkbox(u8'�������������� ��������� ��', autoCB) then
				config.settings.autoCB = autoCB[0]
				inicfg.save(config, directIni)
			end

			imgui.TextQuestionSameLine('( ? )', u8'��� �������� ������� /cb ������ ������������� ������� �� �� ���� ������� � ������ ������ 0.1')

			if imgui.Checkbox(u8'��������� ID �������� �� O', objHL) then
				config.settings.objHL = objHL[0]
				inicfg.save(config, directIni)
			end

			if imgui.Checkbox(u8'���������� XYZAngle �� ������', showCoords) then
				config.settings.showCoords = showCoords[0]
				inicfg.save(config, directIni)
			end

			imgui.Checkbox(u8'/ch mode', chMode)

			imgui.TextQuestionSameLine('( ? )', u8'��� ���������� ������� ���� �� ������� ����������� ����������� � /callsign ��������� Q � E\n����� ������ ����� �������� � ������� "�������" ��� ������� �� R\n� ��� ����� ������������ �� ����������� � ���� ���������')

			if imgui.Checkbox(u8'AntiTroll mode', antiTroll) then
				config.settings.antiTroll = antiTroll[0]
				inicfg.save(config, directIni)
			end

			imgui.TextQuestionSameLine('( ? )', u8'� ���� ���������� ������������ ��������� �������: Iesons, monreal_de_pari, Bobrovsky (������ ����� �����������)')

			imgui.SetCursorPos(imgui.ImVec2(5, 265))
			imgui.PushItemWidth(110)
			if imgui.Combo('##theme', style['style'], style['array'], 2) then
				config.settings.style = style['style'][0]
				approveStyle()
				inicfg.save(config, directIni)
			end

		end 

		if tab == 1 then

			imgui.SetCursorPos(imgui.ImVec2(imgui.GetCursorPosX(), 55))
			imgui.PushItemWidth(imgui.GetWindowWidth() - 15)
			imgui.ColorPicker3("##", color, imgui.ColorEditFlags.NoSidePreview + imgui.ColorEditFlags.DisplayHex)

		end

		if tab == 2 then

			imgui.PushStyleVarVec2(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0.5, 0.5))

			imgui.SetCursorPos(imgui.ImVec2(imgui.GetCursorPosX(), 55))
			imgui.InputTextMultiline(u8'������� �������', anticheat['acPattern'], 65535, imgui.ImVec2(130, 20))
			imgui.TextQuestionSameLine('                            ', u8'�� ������ ������ ������, ������� ����� ��������������� ��������.\n�������: 0-44 (� �������� �� 44, ������ ���) | 0-23 35 39 44')
			imgui.Checkbox(u8'�������', anticheat['toggle'])
			imgui.TextQuestionSameLine('( ? )', u8'�������� ��� �������� ���� �� �������� � �������� ��������� ���� �� �������')
			imgui.PushItemWidth(70)
			imgui.InputInt(u8"���-�� ���������", anticheat['warnings'], 1)
			imgui.TextQuestionSameLine('( ? )', u8'������ ���������� ���������� �� �������� ��� ������ ���������')
			imgui.PushItemWidth(70)
			imgui.InputInt(u8"��������� ���������", anticheat['warningsRemove'], 1)
			imgui.TextQuestionSameLine('( ? )', u8'����� � ��������, ����� ������� ���������� ���������� ���������� �� ��������')
			imgui.PushItemWidth(150)
			imgui.Combo(u8'���������', anticheat['punishment'], anticheat['array'], 5)
			if anticheat['punishment'][0] == 3 then
				imgui.PushItemWidth(85)
				imgui.InputInt(u8"�����", anticheat['banTime'], 1)
				imgui.TextQuestionSameLine('( ? )', u8'����� ���� � ������� (0 - ��������)')
			end
			imgui.Checkbox(u8'����������� �� �������', anticheat['modReact'])
			imgui.TextQuestionSameLine('( ? )', u8'�������� ��� �������. ����� ��������� ������������ � ��������, ��������� ��� ���� ���� � ���������� ����������')
			imgui.Checkbox(u8'�������� �����������', anticheat['modMsg'])
			imgui.TextQuestionSameLine('( ? )', u8'�������� ��� �������. ����� ��������� ������������ � ��������, ��������� ��� ���� ���� � ���������� ����������')
			if imgui.Button(u8'���������', imgui.ImVec2(75,20)) then
				antiCheat(split(u8:decode(str(anticheat['acPattern'])), ' '))
			end

			imgui.PopStyleVar(1)

		end

		imgui.End()
    end
)


function sampev.onServerMessage(color, text)
	if string.find(text, 'PM ��') and color == -65281 and tonumber(config.settings.autoPM) ~= 0 then
		if not sampIsChatInputActive() and not isSampfuncsConsoleActive() then

			local modText = string.match(text, '%(%( (.+) %)%)')
			local pID = string.match(modText, '%((%d+)%)')

			if tonumber(config.settings.autoPM) == 1 then 
				sampSetChatInputEnabled(true)
				sampSetChatInputText('/rep ')
			end
			
			if tonumber(config.settings.autoPM) == 2 then

				local friendList = config.friends
				local friend = nil

				for pos = 1, #friendList do
					friend = tostring(friendList[pos])
					if friend:lower() == sampGetPlayerNickname(pID):lower() then
						sampSetChatInputEnabled(true)
						sampSetChatInputText('/rep ')
					end
				end
			end

		end
	end

	if string.find(text, 'Iesons(.+):') or string.find(text, 'Bobrovsky(.+):') or string.find(text, 'monreal_de_pari(.+):') then
		if antiTroll[0] then
			return false
		end
	end

end


function sampev.onSendCommand(cmd)
	if cmd == "/savepos" and copyPos[0] then
		local x, y, z = getCharCoordinates(PLAYER_PED)

		setClipboardText(round(x, 2) .. ' ' .. round(y, 2) .. ' ' .. round(z, 2))
		printStyledString('~b~POSITION COPIED!', 1500, 7)
	end

	if cmd:find("/cb") and not cmd:find("/cblist") and not cmd:find("/cbedit") then

		if autoCB[0] then
			lua_thread.create(function()
				wait(150)
				
				sampSendDialogResponse(32700, 1, 0, '0.1')

				sampSendDialogResponse(32700, 1, 11, nil)

				sampSendDialogResponse(32700, 1, 31, nil)

				--[[if cmd:find('/cb%s') then
					wait(150)

					sampSendDialogResponse(32700, 1, 17, nil)

					sampSendDialogResponse(32700, 1, 0, cmd:match('/cb%s(.+)'))
				end]]

			end)
		end

	end
end


function imgui.TextQuestionSameLine(label, description)
    imgui.SameLine()
    imgui.TextDisabled(label)

    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
            imgui.PushTextWrapPos(600)
                imgui.TextUnformatted(description)
            imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end


function antiCheat(pattern)

	for num, item in pairs(pattern) do
		if string.find(tostring(item), '%d+%-%d+') then
			pattern[num] = pattern[#pattern]
			pattern[#pattern] = nil 
			local i, b = item:match('(%d+)%-(%d+)')
			for c = i, b do
				pattern[#pattern + 1] = c
			end
		end
	end
	
	for _, item in pairs(pattern) do
		if tonumber(item) <= 44 then

			sampSendDialogResponse(32700, 1, item, nil)

			if anticheat['toggle'][0] == true then
				sampSendDialogResponse(32700, 1, 0, nil)
			end

			sampSendDialogResponse(32700, 1, 1, nil)
			sampSendDialogResponse(32700, 1, 0, tostring(anticheat['warnings'][0]))

			sampSendDialogResponse(32700, 1, 2, nil)
			sampSendDialogResponse(32700, 1, anticheat['punishment'][0], nil)
			sampSendDialogResponse(32700, 0, 0, nil)

			if anticheat['punishment'][0] == 3 then
				sampSendDialogResponse(32700, 1, 3, nil)
				sampSendDialogResponse(32700, 1, 0, tostring(anticheat['banTime'][0]))
			end

			sampSendDialogResponse(32700, 1, 4, nil)
			sampSendDialogResponse(32700, 1, 0, tostring(anticheat['warningsRemove'][0]))

			if anticheat['modReact'][0] == true then
				sampSendDialogResponse(32700, 1, 6, nil)
			end

			if anticheat['modMsg'][0] == true then
				sampSendDialogResponse(32700, 1, 5, nil)
			end

			sampSendDialogResponse(32700, 0, 0, nil)
		end
	end

end


function split(str, delim, plain)
    local tokens, pos, plain = {}, 1, not (plain == false)
    repeat
        local npos, epos = string.find(str, delim, pos, plain)
        table.insert(tokens, string.sub(str, pos, npos and npos - 1))
        pos = epos and epos + 1
    until not pos
    return tokens
end


function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end


function approveStyle()
	imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 10.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
	style.SelectableTextAlign = imgui.ImVec2(0.5, 0.5)

	if tonumber(config.settings.style) == 0 then
		colors[clr.Text] = ImVec4(0.00, 0.00, 0.00, 1.00);
		colors[clr.TextDisabled]  = ImVec4(0.50, 0.50, 0.50, 1.00);
		colors[clr.WindowBg] = ImVec4(0.86, 0.86, 0.86, 1.00);
		colors[clr.ChildBg] = ImVec4(0.71, 0.71, 0.71, 1.00);
		colors[clr.PopupBg] = ImVec4(0.79, 0.79, 0.79, 1.00);
		colors[clr.Border] = ImVec4(0.00, 0.00, 0.00, 0.36);
		colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.10);
		colors[clr.FrameBg] = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.FrameBgHovered] = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.FrameBgActive] = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.TitleBg] = ImVec4(1.00, 1.00, 1.00, 0.81);
		colors[clr.TitleBgActive] = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.TitleBgCollapsed] = ImVec4(1.00, 1.00, 1.00, 0.51);
		colors[clr.MenuBarBg] = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.ScrollbarBg]  = ImVec4(1.00, 1.00, 1.00, 0.86);
		colors[clr.ScrollbarGrab] = ImVec4(0.37, 0.37, 0.37, 1.00);
		colors[clr.ScrollbarGrabHovered] = ImVec4(0.60, 0.60, 0.60, 1.00);
		colors[clr.ScrollbarGrabActive] = ImVec4(0.21, 0.21, 0.21, 1.00);
		colors[clr.CheckMark]  = ImVec4(0.42, 0.42, 0.42, 1.00);
		colors[clr.SliderGrab] = ImVec4(0.51, 0.51, 0.51, 1.00);
		colors[clr.SliderGrabActive] = ImVec4(0.65, 0.65, 0.65, 1.00);
		colors[clr.Button] = ImVec4(0.52, 0.52, 0.52, 0.83);
		colors[clr.ButtonHovered]  = ImVec4(0.58, 0.58, 0.58, 0.83);
		colors[clr.ButtonActive] = ImVec4(0.44, 0.44, 0.44, 0.83);
		colors[clr.Header] = ImVec4(0.65, 0.65, 0.65, 1.00);
		colors[clr.HeaderHovered] = ImVec4(0.73, 0.73, 0.73, 1.00);
		colors[clr.HeaderActive] = ImVec4(0.53, 0.53, 0.53, 1.00);
		colors[clr.Separator] = ImVec4(0.46, 0.46, 0.46, 1.00);
		colors[clr.SeparatorHovered] = ImVec4(0.45, 0.45, 0.45, 1.00);
		colors[clr.SeparatorActive] = ImVec4(0.45, 0.45, 0.45, 1.00);
		colors[clr.ResizeGrip] = ImVec4(0.23, 0.23, 0.23, 1.00);
		colors[clr.ResizeGripHovered] = ImVec4(0.32, 0.32, 0.32, 1.00);
		colors[clr.ResizeGripActive] = ImVec4(0.14, 0.14, 0.14, 1.00);
		colors[clr.PlotLines]  = ImVec4(0.61, 0.61, 0.61, 1.00);
		colors[clr.PlotLinesHovered] = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.PlotHistogram] = ImVec4(0.70, 0.70, 0.70, 1.00);
		colors[clr.PlotHistogramHovered] = ImVec4(1.00, 1.00, 1.00, 1.00);
		colors[clr.TextSelectedBg] = ImVec4(0.62, 0.62, 0.62, 1.00);
		colors[clr.ModalWindowDimBg]   = ImVec4(0.26, 0.26, 0.26, 0.60);
	elseif tonumber(config.settings.style) == 1 then
		colors[clr.Text] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
		colors[clr.TextDisabled] = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
		colors[clr.WindowBg] = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
		colors[clr.ChildBg] = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
		colors[clr.PopupBg] = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
		colors[clr.Border] = imgui.ImVec4(0.25, 0.25, 0.26, 0.54)
		colors[clr.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
		colors[clr.FrameBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
		colors[clr.FrameBgHovered] = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
		colors[clr.FrameBgActive] = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
		colors[clr.TitleBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
		colors[clr.TitleBgActive] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
		colors[clr.TitleBgCollapsed] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
		colors[clr.MenuBarBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
		colors[clr.ScrollbarBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
		colors[clr.ScrollbarGrab] = imgui.ImVec4(0.00, 0.00, 0.00, 1.00)
		colors[clr.ScrollbarGrabHovered] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
		colors[clr.ScrollbarGrabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00)
		colors[clr.CheckMark] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
		colors[clr.SliderGrab] = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
		colors[clr.SliderGrabActive] = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
		colors[clr.Button] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
		colors[clr.ButtonHovered] = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
		colors[clr.ButtonActive] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
		colors[clr.Header] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
		colors[clr.HeaderHovered] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
		colors[clr.HeaderActive] = imgui.ImVec4(0.47, 0.47, 0.47, 1.00)
		colors[clr.Separator] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
		colors[clr.SeparatorHovered] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
		colors[clr.SeparatorActive] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
		colors[clr.ResizeGrip] = imgui.ImVec4(1.00, 1.00, 1.00, 0.25)
		colors[clr.ResizeGripHovered] = imgui.ImVec4(1.00, 1.00, 1.00, 0.67)
		colors[clr.ResizeGripActive] = imgui.ImVec4(1.00, 1.00, 1.00, 0.95)
		colors[clr.Tab] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
		colors[clr.TabHovered] = imgui.ImVec4(0.28, 0.28, 0.28, 1.00)
		colors[clr.TabActive] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
		colors[clr.TabUnfocused] = imgui.ImVec4(0.07, 0.10, 0.15, 0.97)
		colors[clr.TabUnfocusedActive] = imgui.ImVec4(0.14, 0.26, 0.42, 1.00)
		colors[clr.PlotLines] = imgui.ImVec4(0.61, 0.61, 0.61, 1.00)
		colors[clr.PlotLinesHovered] = imgui.ImVec4(1.00, 0.43, 0.35, 1.00)
		colors[clr.PlotHistogram] = imgui.ImVec4(0.90, 0.70, 0.00, 1.00)
		colors[clr.PlotHistogramHovered] = imgui.ImVec4(1.00, 0.60, 0.00, 1.00)
		colors[clr.TextSelectedBg] = imgui.ImVec4(1.00, 0.00, 0.00, 0.35)
		colors[clr.DragDropTarget] = imgui.ImVec4(1.00, 1.00, 0.00, 0.90)
		colors[clr.NavHighlight] = imgui.ImVec4(0.26, 0.59, 0.98, 1.00)
		colors[clr.NavWindowingHighlight] = imgui.ImVec4(1.00, 1.00, 1.00, 0.70)
		colors[clr.NavWindowingDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.20)
		colors[clr.ModalWindowDimBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
	end
end
