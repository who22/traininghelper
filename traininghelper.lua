script_name('trainingHelper') 
script_author('Gerald.myr') 

require 'lib.moonloader'

local scriptVersion = 6
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

local russian_characters = {
    [168] = '�', [184] = '�', [192] = '�', [193] = '�', [194] = '�', [195] = '�', [196] = '�', [197] = '�', [198] = '�', [199] = '�', [200] = '�', [201] = '�', [202] = '�', [203] = '�', [204] = '�', [205] = '�', [206] = '�', [207] = '�', [208] = '�', [209] = '�', [210] = '�', [211] = '�', [212] = '�', [213] = '�', [214] = '�', [215] = '�', [216] = '�', [217] = '�', [218] = '�', [219] = '�', [220] = '�', [221] = '�', [222] = '�', [223] = '�', [224] = '�', [225] = '�', [226] = '�', [227] = '�', [228] = '�', [229] = '�', [230] = '�', [231] = '�', [232] = '�', [233] = '�', [234] = '�', [235] = '�', [236] = '�', [237] = '�', [238] = '�', [239] = '�', [240] = '�', [241] = '�', [242] = '�', [243] = '�', [244] = '�', [245] = '�', [246] = '�', [247] = '�', [248] = '�', [249] = '�', [250] = '�', [251] = '�', [252] = '�', [253] = '�', [254] = '�', [255] = '�',
}

local directIni = 'thConfig.ini'
local config = inicfg.load({
	friends = {
	'Goodman',
	},
	settings = {
		autoPM = 0,
		carLock = false
	}
}, directIni)

local new = imgui.new

local notepadWindow = new.bool(false)
local menuWindow = new.bool(false)

local color = new.float[3](1.0, 1.0, 1.0)

local notepad = new.char[65535]('')

local autoPMitems = {u8'��������', u8'�������', u8'������ ������'}
local punishmentItems = {u8'������������', u8'��������� �� �����', u8'�������', u8'��������', u8'Debug'}
local autoPM = new.int(tonumber(config.settings.autoPM))
local autoPMarr = {}

local carLock = new.bool(config.settings.carLock)

local punishment = new.int(0)
local toggle = new.bool(0)
local modReact = new.bool(0)
local warnings = new.int(3)
local banTime = new.int(0)
local acPattern = new.char[65535]('')
local warningsRemove = new.int(10)
local punishmentArr = {}

local tab = 0

local resX, resY = getScreenResolution()

imgui.OnInitialize(function()
	autoPMarr = new['const char*'][#autoPMitems](autoPMitems)
	punishmentArr = new['const char*'][#punishmentItems](punishmentItems)
end)

function msgChat(msg) 
	sampAddChatMessage('[trainingHelper] {FFFFFF}'..msg, 0x05A90CE)
end

function main()


	repeat wait(0) until isSampAvailable()
	
	
	if sampGetCurrentServerAddress() ~= '37.230.162.117' then 
		msgChat('���� �� �� �� {90ce5a}TRAINING SERVER{FFFFFF}.... � ���������� ���� ��� ��� �� ����� :(');
		script:unload()
	end


	msgChat('TrainingHelper ������� | /binds - ����� | /cmds - ������� | /menu - ����������� ����')


	sampRegisterChatCommand('binds', function(id)
		msgChat('Z - �������� ����� | ��� + X - fast /pm | I - friend list')
	end)


	sampRegisterChatCommand('cmds', function(id)
		msgChat('/faddname - �������� ����� �� ���� | /faddid - �������� ����� �� ID')
		msgChat('/isafk ID - ��� �� AFK | /cc - �������� ��� | /notepad - ������� ��� �������')
		msgChat('/friendlist - ������ ���� ������ | /delf - ������� �����')
	end)


	sampRegisterChatCommand('notepad', function()
		notepadWindow[0] = not notepadWindow[0]
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
				config.friends[#friendList + 1] = name
				inicfg.save(config, directIni)
				msgChat('� ���� ����� ����, � ����� � ��������... {5A90CE}'..name..'{FFFFFF} ���!!!')
			end
		end
	end)


	sampRegisterChatCommand('faddname', function(name)
		local friendList = config.friends
		config.friends[#friendList + 1] = name

		inicfg.save(config, directIni)
		msgChat('� ���� ����� ����, � ����� � ��������... {5A90CE}'..name..'{FFFFFF} ���!!!')
	end)


	sampRegisterChatCommand('delf', function (name)
		local friendList = config.friends
		local friend = nil

		for pos = 1, #friendList do
			friend = friendList[pos]
			if friend == name then
				config.friends[pos] = config.friends[#friendList]
				config.friends[#friendList] = nil
				inicfg.save(config, directIni)
				msgChat('�� �������� �������� �����, � ����� � ��������... {5A90CE}'..name..'{FFFFFF}, ������ :(')
			end
		end
	end)


	sampRegisterChatCommand('isafk', function (arg)
		if sampIsPlayerConnected(arg) then
			if sampIsPlayerPaused(arg) then 
				msgChat(sampGetPlayerNickname(arg) .. '(' .. arg .. ')' .. ': {808080}AFK')
			else 
				msgChat(sampGetPlayerNickname(arg) .. '(' .. arg .. ')' .. ': {90ce5a}ONLINE')
			end
		end
	end)


	sampRegisterChatCommand('friendlist', function ()
		local friendList = config.friends

		msgChat('������ ���� ������:')
		for pos = 1, #friendList do
			friend = friendList[pos]
			sampAddChatMessage(friend, 0x0FFFFFF)
		end
	end)


	downloadUrlToFile(updateUrl, updatePath, function(id, status)
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			updIni = inicfg.load(nil, updatePath)
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
					msgChat('������ �������!')
					thisScript():reload()
				end
			end)
			break
		end


		if not sampIsChatInputActive() and not sampIsDialogActive() then

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
								res = '{FFFFFF}' .. friend .. '(' .. id .. ')'
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
				if config.settings.carLock == true then
					sampSendChat('/lock')
				end
			end

		end
		wait(1)

	end

end


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


local menuFrame = imgui.OnFrame(
    function() return menuWindow[0] end,
    function(player)
		local positionX, positionY, positionZ = getCharCoordinates(PLAYER_PED)

		imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(245, 295))

		imgui.Begin(u8' trainingHelper', menuWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

		imgui.SetCursorPos(imgui.ImVec2(5, 25))

		imgui.PushStyleVarVec2(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0.5, 0.5))
		if imgui.Button(u8'��������', imgui.ImVec2(75, 20)) then tab = 0 end
		imgui.SameLine(85)
		if imgui.Button(u8'�������', imgui.ImVec2(75, 20)) then tab = 1 end
		imgui.SameLine(165)
		if imgui.Button(u8'�������', imgui.ImVec2(75, 20)) then tab = 2 end
		imgui.PopStyleVar(1)

		imgui.Separator()

		if tab == 0 then

			imgui.SetWindowFontScale(1.1)
			imgui.Text(u8'XYZAngle: ' .. round(positionX, 1) .. ' ' .. round(positionY, 1) .. ' ' .. round(positionZ, 1) .. ' ' .. math.floor(getCharHeading(PLAYER_PED)))
			imgui.SetWindowFontScale(1)
			imgui.PushItemWidth(145)

			if imgui.Combo(u8'�uto /pm', autoPM, autoPMarr, 3) then
				config.settings.autoPM = autoPM[0]
				inicfg.save(config, directIni)
			end

			imgui.TextQuestionSameLine('( ? )', u8'����� ��� �������� ��������� �� �����,\n��� ����� ����� ���� ���������� �����.\n��� ������ ��������� /pm!')

			if imgui.Checkbox(u8'�������/������� ���� �� L', carLock) then
				config.settings.carLock = carLock[0]
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
			imgui.InputTextMultiline(u8'������� �������', acPattern, 65535, imgui.ImVec2(130, 20))
			imgui.TextQuestionSameLine('                            ', u8'�� ������ ������ ������, ������� ����� ��������������� ��������.\n�������: 0-44 (� �������� �� 44, ������ ���) | 0-23 35 39 44')
			imgui.Checkbox(u8'�������', toggle)
			imgui.TextQuestionSameLine('( ? )', u8'�������� ��� �������� ���� �� �������� � �������� ��������� ���� �� �������')
			imgui.PushItemWidth(70)
			imgui.InputInt(u8"���-�� ���������", warnings, 1)
			imgui.TextQuestionSameLine('( ? )', u8'������ ���������� ���������� �� �������� ��� ������ ���������')
			imgui.PushItemWidth(70)
			imgui.InputInt(u8"��������� ���������", warningsRemove, 1)
			imgui.TextQuestionSameLine('( ? )', u8'����� � ��������, ����� ������� ���������� ���������� ���������� �� ��������')
			imgui.PushItemWidth(150)
			imgui.Combo(u8'���������', punishment, punishmentArr, 5)
			if punishment[0] == 3 then
				imgui.PushItemWidth(85)
				imgui.InputInt(u8"�����", banTime, 1)
				imgui.TextQuestionSameLine('( ? )', u8'����� ���� � ������� (0 - ��������)')
			end
			imgui.Checkbox(u8'����������� �� �������', modReact)
			imgui.TextQuestionSameLine('( ? )', u8'�������� ��� �������. ����� ��������� ������������ � ��������, ��������� ��� ���� ���� � ���������� ����������')
			if imgui.Button(u8'���������', imgui.ImVec2(75,20)) then
				antiCheat(split(u8:decode(str(acPattern)), ' '))
			end

			imgui.PopStyleVar(1)

		end

		imgui.End()
    end
)


function sampev.onServerMessage(color, text)
	if string.find(text, 'PM ��') and color == -65281 and tonumber(config.settings.autoPM) ~= 0 then
		if not sampIsChatInputActive() then

			local modText = string.match(text, '%(%( (.+) %)%)')
			local pID = string.match(modText, '%((%d+)%)')
			print(modText .. ' ' .. pID)

			if tonumber(config.settings.autoPM) == 1 then 
				sampSetChatInputEnabled(true)
				sampSetChatInputText('/rep ')
			end
			
			if tonumber(config.settings.autoPM) == 2 then

				local friendList = config.friends
				local friend = nil

				for pos = 1, #friendList do
					friend = friendList[pos]
					if friend:lower() == sampGetPlayerNickname(pID):lower() then
						sampSetChatInputEnabled(true)
						sampSetChatInputText('/rep ')
					end
				end
			end

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
			if toggle[0] == true then
				sampSendDialogResponse(32700, 1, 0, nil)
			end
			if warnings[0] ~= 0 then
				sampSendDialogResponse(32700, 1, 1, nil)
				sampSendDialogResponse(32700, 1, 0, tostring(warnings[0]))
			end
			if punishment[0] ~= 0 then
				sampSendDialogResponse(32700, 1, 2, nil)
				sampSendDialogResponse(32700, 1, punishment[0], nil)
				sampSendDialogResponse(32700, 0, 0, nil)
			end
			if punishment[0] == 3 and banTime ~= 0 then
				sampSendDialogResponse(32700, 1, 3, nil)
				sampSendDialogResponse(32700, 1, 0, tostring(banTime[0]))
			end
			sampSendDialogResponse(32700, 1, 4, nil)
			sampSendDialogResponse(32700, 1, 0, tostring(warningsRemove[0]))
			if modReact[0] == true then
				sampSendDialogResponse(32700, 1, 6, nil)
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