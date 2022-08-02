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
    [168] = 'Ё', [184] = 'ё', [192] = 'А', [193] = 'Б', [194] = 'В', [195] = 'Г', [196] = 'Д', [197] = 'Е', [198] = 'Ж', [199] = 'З', [200] = 'И', [201] = 'Й', [202] = 'К', [203] = 'Л', [204] = 'М', [205] = 'Н', [206] = 'О', [207] = 'П', [208] = 'Р', [209] = 'С', [210] = 'Т', [211] = 'У', [212] = 'Ф', [213] = 'Х', [214] = 'Ц', [215] = 'Ч', [216] = 'Ш', [217] = 'Щ', [218] = 'Ъ', [219] = 'Ы', [220] = 'Ь', [221] = 'Э', [222] = 'Ю', [223] = 'Я', [224] = 'а', [225] = 'б', [226] = 'в', [227] = 'г', [228] = 'д', [229] = 'е', [230] = 'ж', [231] = 'з', [232] = 'и', [233] = 'й', [234] = 'к', [235] = 'л', [236] = 'м', [237] = 'н', [238] = 'о', [239] = 'п', [240] = 'р', [241] = 'с', [242] = 'т', [243] = 'у', [244] = 'ф', [245] = 'х', [246] = 'ц', [247] = 'ч', [248] = 'ш', [249] = 'щ', [250] = 'ъ', [251] = 'ы', [252] = 'ь', [253] = 'э', [254] = 'ю', [255] = 'я',
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
local autoPMitems = {u8'Выключен', u8'Включен', u8'Только друзья'}
local autoPM = new.int(tonumber(config.settings.autoPM))
local autoPMTable = new['const char*'][#autoPMitems](autoPMitems)

local resX, resY = getScreenResolution()

function msgChat(msg) 
	sampAddChatMessage('[trainingHelper] {FFFFFF}'..msg, 0x05A90CE)
end

function main()


	repeat wait(0) until isSampAvailable()
	
	
	if sampGetCurrentServerAddress() ~= '37.230.162.117' then 
		msgChat('Брат ты не на {90ce5a}TRAINING SERVER{FFFFFF}.... я отключаюсь ведь мне тут не место :(');
		script:unload()
	else


		msgChat('TrainingHelper запущен | /binds - бинды | /cmds - команды')


		sampRegisterChatCommand('binds', function(id)
			msgChat('Z - реальное время | ПКМ + X - fast /pm | I - friend list')
		end)


		sampRegisterChatCommand('cmds', function(id)
			msgChat('/faddname - добавить друга по нику | /faddid - добавить друга по ID')
			msgChat('/menu - меню с разными функциями скрипта | /isafk ID - чек на AFK | /cc - очистить чат')
			msgChat('/friendlist - список всех друзей | /notepad - блокнот для заметок | /delf - удалить друга')
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
				return msgChat('Введи айди, а не это {5A90CE}' .. id .. '{FFFFFF}, спасибо')
			else
				if sampIsPlayerConnected(id) then
					local name = sampGetPlayerNickname(tonumber(id))
					local friendList = config.friends
					config.friends[#friendList + 1] = name
					inicfg.save(config, directIni)
					msgChat('У тебя новый друг, а может и подружка... {5A90CE}'..name..'{FFFFFF} ура!!!')
				end
			end
		end)


		sampRegisterChatCommand('faddname', function(name)
			local friendList = config.friends
			config.friends[#friendList + 1] = name

			inicfg.save(config, directIni)
			msgChat('У тебя новый друг, а может и подружка... {5A90CE}'..name..'{FFFFFF} ура!!!')
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
					msgChat('Вы потеряли хорошего друга, а может и подружку... {5A90CE}'..name..'{FFFFFF}, прощай :(')
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

			msgChat('Список всех друзей:')
			for pos = 1, #friendList do
				friend = friendList[pos]
				sampAddChatMessage(friend, 0x0FFFFFF)
			end
		end)


		downloadUrlToFile(updateUrl, updatePath, function(id, status)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				local updateIni = inicfg.load(nil, updatePath)
				if tonumber(updateIni.info.version) > scriptVersion then
					msgChat('Обнаружена новая версия скрипта!')
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
							msgChat('Скрипт обновлён!')
							thisScript():reload()
						end
					end)
					break
				end


				if isKeyJustPressed(VK_I) then
					local friendList = config.friends
					local friend = nil
					local res = ''

					msgChat('{5A90CE}Список друзей онлайн:')

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
						msgChat('{DE3131}Внимание! {FFFFFF}Срочно спать, завтра в школу! Мамка пизды даст!')
					end

					_, playerID = sampGetPlayerIdByCharHandle(playerPed)
					msgChat('ID:' .. ' {90ce5a}' .. playerID .. ' {FFFFFF}' .. 'Время:' .. ' {90ce5a}' .. os.date('%H:%M:%S').. ' {FFFFFF}' .. 'Игровое время:' .. ' {90ce5a}' .. getTimeOfDay() .. ':00')
				end
	
				if isKeyJustPressed(VK_X) then
					local result, target = getCharPlayerIsTargeting(playerHandle)
					if not result then
						msgChat('Зажми {90ce5a}ПКМ{FFFFFF}, наведи на игрока и уже потом тыкни {90ce5a}X{FFFFFF}.')
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

		imgui.Begin(u8'Блокнот', notepadWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

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
		if imgui.Combo(u8'Аuto /pm', autoPM, autoPMTable, 3) then
			if autoPM[0] == 0 then
				config.settings.autoPM = 0
				msgChat('AutoPM функция выключена!')
			end
			if autoPM[0] == 1 then
				config.settings.autoPM = 1
				msgChat('AutoPM функция включена!')
			end
			if autoPM[0] == 2 then
				config.settings.autoPM = 2
				msgChat('AutoPM функция включена только для друзей!')
			end
			inicfg.save(config, directIni)
		end

		imgui.PushItemWidth(200)
		imgui.ColorPicker3("##", color, imgui.ColorEditFlags.NoSidePreview + imgui.ColorEditFlags.DisplayHex)

		imgui.End()
    end
)


function sampev.onServerMessage(color, text)
	if string.find(text, 'PM от') and color == -65281 and tonumber(config.settings.autoPM) ~= 0 then
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

	if string.find(string.rlower(text), 'ауе') then
		return false
	end
end


function sampev.onSendChat(text)
	if string.find(string.rlower(text), 'ворона пидор') then
		msgChat('Вы признались в том, что любите сосать члены')
		return { '!я люблю сосать члены' }
	end

	if string.find(string.rlower(text), 'ауе') then
		msgChat('Вы признались в том, что вы экстремист')
		return { '![ экстремизм ]  жизнь ворам' }
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
        elseif ch == 168 then -- Ё
            output = output .. russian_characters[184]
        else
            output = output .. string.char(ch)
        end
    end
    return output
end