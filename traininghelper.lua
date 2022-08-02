script_name('trainingHelper') 
script_author('Gerald.myr') 

require 'lib.moonloader'

local scriptVersion = 1
local updState = false

local scriptPath = thisScript().path
local scriptUrl = 'https://raw.githubusercontent.com/who22/traininghelper/main/traininghelper.lua'
local updatePath = getWorkingDirectory() .. '/thUpdate.ini'
local updateUrl = 'https://raw.githubusercontent.com/who22/traininghelper/main/thUpdate.ini'

local dlstatus = require('moonloader').download_status
local sampev = require 'samp.events'
local keys = require 'vkeys'
local inicfg = require 'inicfg'
local imgui = require 'mimgui'
local encoding = require 'encoding'

encoding.default = 'CP1251'
u8 = encoding.UTF8

local russian_characters = {
    [168] = '�', [184] = '�', [192] = '�', [193] = '�', [194] = '�', [195] = '�', [196] = '�', [197] = '�', [198] = '�', [199] = '�', [200] = '�', [201] = '�', [202] = '�', [203] = '�', [204] = '�', [205] = '�', [206] = '�', [207] = '�', [208] = '�', [209] = '�', [210] = '�', [211] = '�', [212] = '�', [213] = '�', [214] = '�', [215] = '�', [216] = '�', [217] = '�', [218] = '�', [219] = '�', [220] = '�', [221] = '�', [222] = '�', [223] = '�', [224] = '�', [225] = '�', [226] = '�', [227] = '�', [228] = '�', [229] = '�', [230] = '�', [231] = '�', [232] = '�', [233] = '�', [234] = '�', [235] = '�', [236] = '�', [237] = '�', [238] = '�', [239] = '�', [240] = '�', [241] = '�', [242] = '�', [243] = '�', [244] = '�', [245] = '�', [246] = '�', [247] = '�', [248] = '�', [249] = '�', [250] = '�', [251] = '�', [252] = '�', [253] = '�', [254] = '�', [255] = '�',
}

local directIni = 'moonloader\\thConfig.ini'
local config = inicfg.load({
	friends = {
	'Goodman',
	},
	settings = {
		autoPM = 0
	}
}, directIni)

local new = imgui.new

local notepadWindow = new.bool(false)
local menuWindow = new.bool(false)

local color = new.float[3](1.0, 1.0, 1.0)
local notepad = new.char[65535]('')
local autoPMitems = {u8'��������', u8'�������', u8'������ ������'}
local autoPM = new.int(tonumber(config.settings.autoPM))
local autoPMTable = new['const char*'][#autoPMitems](autoPMitems)

local resX, resY = getScreenResolution()

function msgChat(msg) 
	sampAddChatMessage('[trainingHelper] {FFFFFF}'..msg, 0x05A90CE)
end

function main()


	repeat wait(0) until isSampAvailable()
	
	
	if sampGetCurrentServerAddress() ~= '37.230.162.117' then 
		msgChat('���� �� �� �� {90ce5a}TRAINING SERVER{FFFFFF}.... � ���������� ���� ��� ��� �� ����� :(');
		script:unload()
	else


		msgChat('TrainingHelper ������� | /binds - ����� | /cmds - �������')


		sampRegisterChatCommand('binds', function(id)
			msgChat('Z - �������� ����� | ��� + X - fast /pm | I - friend list')
		end)


		sampRegisterChatCommand('cmds', function(id)
			msgChat('/faddname - �������� ����� �� ���� | /faddid - �������� ����� �� ID')
			msgChat('/menu - ���� � ������� ��������� ������� | /isafk ID - ��� �� AFK | /cc - �������� ���')
			msgChat('/friendlist - ������ ���� ������ | /notepad - ������� ��� ������� | /delf - ������� �����')
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
				local updateIni = inicfg.load(nil, updatePath)
				if tonumber(updateIni.info.version) > scriptVersion then
					msgChat('���������� ����� ������ �������!')
					updState = true
				end
				os.remove(updatePath)
			end
		end)


		while true do
			if not sampIsChatInputActive() and not sampIsDialogActive() then


				if updState then
					downloadUrlToFile(scriptUrl, scriptPath, function(id, status)
						if status == dlstatus.STATUS_ENDDOWNLOADDATA then
							msgChat('������ �������!')
							thisScript():reload()
						end
					end)
					break
				end


				if isKeyJustPressed(VK_I) then
					local friendList = config.friends
					local friend = nil
					local res = ''

					msgChat('{5A90CE}������ ������ ������:')

					for id = 0, 500 do
						if sampIsPlayerConnected(id) then
							for pos = 1, #friendList do
								friend = friendList[pos]
									if friend == sampGetPlayerNickname(id) then
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


			end
			wait(1)
		end 
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
		imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(215, 260))

		imgui.Begin(u8'trainingHelper', menuWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

		imgui.PushItemWidth(145)
		if imgui.Combo(u8'�uto /pm', autoPM, autoPMTable, 3) then
			if autoPM[0] == 0 then
				config.settings.autoPM = 0
				msgChat('AutoPM ������� ���������!')
			end
			if autoPM[0] == 1 then
				config.settings.autoPM = 1
				msgChat('AutoPM ������� ��������!')
			end
			if autoPM[0] == 2 then
				config.settings.autoPM = 2
				msgChat('AutoPM ������� �������� ������ ��� ������!')
			end
			inicfg.save(config, directIni)
		end

		imgui.PushItemWidth(200)
		imgui.ColorPicker3("##", color, imgui.ColorEditFlags.NoSidePreview + imgui.ColorEditFlags.DisplayHex)

		imgui.End()
    end
)


function sampev.onServerMessage(color, text)
	if string.find(text, 'PM ��') and color == -65281 and tonumber(config.settings.autoPM) ~= 0 then
		if not sampIsChatInputActive() then

			local modText = string.match(text, '(( .+ ))')
			local pID = string.match(modText, '(%d+)')

			if tonumber(config.settings.autoPM) == 1 then 
				sampSetChatInputEnabled(true)
				sampSetChatInputText('/pm ' .. pID .. ' ')
			end
			
			if tonumber(config.settings.autoPM) == 2 then

				local friendList = config.friends
				local friend = nil

				for pos = 1, #friendList do
					friend = friendList[pos]
					if friend == sampGetPlayerNickname(pID) then
						sampSetChatInputEnabled(true)
						sampSetChatInputText('/pm ' .. pID .. ' ')
					end
				end
			end

		end
	end

	if string.find(string.rlower(text), '���') then
		return false
	end
end


function sampev.onSendChat(text)
	if string.find(string.rlower(text), '������ �����') then
		msgChat('�� ���������� � ���, ��� ������ ������ �����')
		return { '!� ����� ������ �����' }
	end

	if string.find(string.rlower(text), '���') then
		msgChat('�� ���������� � ���, ��� �� ����������')
		return { '![ ���������� ]  ����� �����' }
	end
end


function string.rlower(s)
    s = s:lower()
    local strlen = s:len()
    if strlen == 0 then return s end
    s = s:lower()
    local output = ''
    for i = 1, strlen do
        local ch = s:byte(i)
        if ch >= 192 and ch <= 223 then
            output = output .. russian_characters[ch + 32]
        elseif ch == 168 then -- �
            output = output .. russian_characters[184]
        else
            output = output .. string.char(ch)
        end
    end
    return output
end