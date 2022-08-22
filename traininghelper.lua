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
    [168] = 'Ё', [184] = 'ё', [192] = 'А', [193] = 'Б', [194] = 'В', [195] = 'Г', [196] = 'Д', [197] = 'Е', [198] = 'Ж', [199] = 'З', [200] = 'И', [201] = 'Й', [202] = 'К', [203] = 'Л', [204] = 'М', [205] = 'Н', [206] = 'О', [207] = 'П', [208] = 'Р', [209] = 'С', [210] = 'Т', [211] = 'У', [212] = 'Ф', [213] = 'Х', [214] = 'Ц', [215] = 'Ч', [216] = 'Ш', [217] = 'Щ', [218] = 'Ъ', [219] = 'Ы', [220] = 'Ь', [221] = 'Э', [222] = 'Ю', [223] = 'Я', [224] = 'а', [225] = 'б', [226] = 'в', [227] = 'г', [228] = 'д', [229] = 'е', [230] = 'ж', [231] = 'з', [232] = 'и', [233] = 'й', [234] = 'к', [235] = 'л', [236] = 'м', [237] = 'н', [238] = 'о', [239] = 'п', [240] = 'р', [241] = 'с', [242] = 'т', [243] = 'у', [244] = 'ф', [245] = 'х', [246] = 'ц', [247] = 'ч', [248] = 'ш', [249] = 'щ', [250] = 'ъ', [251] = 'ы', [252] = 'ь', [253] = 'э', [254] = 'ю', [255] = 'я',
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

local autoPMitems = {u8'Выключен', u8'Включен', u8'Только друзья'}
local punishmentItems = {u8'Игнорировать', u8'Отправить на спавн', u8'Кикнуть', u8'Забанить', u8'Debug'}
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
		msgChat('Брат ты не на {90ce5a}TRAINING SERVER{FFFFFF}.... я отключаюсь ведь мне тут не место :(');
		script:unload()
	end


	msgChat('TrainingHelper запущен | /binds - бинды | /cmds - команды | /menu - графическое меню')


	sampRegisterChatCommand('binds', function(id)
		msgChat('Z - реальное время | ПКМ + X - fast /pm | I - friend list')
	end)


	sampRegisterChatCommand('cmds', function(id)
		msgChat('/faddname - добавить друга по нику | /faddid - добавить друга по ID')
		msgChat('/isafk ID - чек на AFK | /cc - очистить чат | /notepad - блокнот для заметок')
		msgChat('/friendlist - список всех друзей | /delf - удалить друга')
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
			updIni = inicfg.load(nil, updatePath)
			if tonumber(updIni.info.version) > scriptVersion then
				msgChat('Обнаружена новая версия скрипта!')
				updState = true
			end
			os.remove(updatePath)
		end
	end)


	while true do


		if updState then
			downloadUrlToFile(scriptUrl, scriptPath, function(id, status)
				if status == dlstatus.STATUS_ENDDOWNLOADDATA then
					msgChat('Скрипт обновлён!')
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

				msgChat('{5A90CE}Список друзей онлайн:')

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

		imgui.Begin(u8'Блокнот', notepadWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

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
		if imgui.Button(u8'Основное', imgui.ImVec2(75, 20)) then tab = 0 end
		imgui.SameLine(85)
		if imgui.Button(u8'Палитра', imgui.ImVec2(75, 20)) then tab = 1 end
		imgui.SameLine(165)
		if imgui.Button(u8'Античит', imgui.ImVec2(75, 20)) then tab = 2 end
		imgui.PopStyleVar(1)

		imgui.Separator()

		if tab == 0 then

			imgui.SetWindowFontScale(1.1)
			imgui.Text(u8'XYZAngle: ' .. round(positionX, 1) .. ' ' .. round(positionY, 1) .. ' ' .. round(positionZ, 1) .. ' ' .. math.floor(getCharHeading(PLAYER_PED)))
			imgui.SetWindowFontScale(1)
			imgui.PushItemWidth(145)

			if imgui.Combo(u8'Аuto /pm', autoPM, autoPMarr, 3) then
				config.settings.autoPM = autoPM[0]
				inicfg.save(config, directIni)
			end

			imgui.TextQuestionSameLine('( ? )', u8'Когда вам приходит сообщение от друга,\nвам нужно всего лишь напечатать ответ.\nБез всяких написаний /pm!')

			if imgui.Checkbox(u8'Закрыть/открыть авто на L', carLock) then
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
			imgui.InputTextMultiline(u8'Паттерн пунктов', acPattern, 65535, imgui.ImVec2(130, 20))
			imgui.TextQuestionSameLine('                            ', u8'Вы должны ввести пункты, которые будут отредактированы скриптом.\nПримеры: 0-44 (с нулевого по 44, тоесть все) | 0-23 35 39 44')
			imgui.Checkbox(u8'Тумблер', toggle)
			imgui.TextQuestionSameLine('( ? )', u8'Включает вид античита если он выключен и наоборот выключает если он включен')
			imgui.PushItemWidth(70)
			imgui.InputInt(u8"Кол-во варнингов", warnings, 1)
			imgui.TextQuestionSameLine('( ? )', u8'Нужное количество подозрений от античита для выдачи наказания')
			imgui.PushItemWidth(70)
			imgui.InputInt(u8"Обнуление варнингов", warningsRemove, 1)
			imgui.TextQuestionSameLine('( ? )', u8'Время в секундах, через которое обнуляется количетсво подозрений от античита')
			imgui.PushItemWidth(150)
			imgui.Combo(u8'Наказание', punishment, punishmentArr, 5)
			if punishment[0] == 3 then
				imgui.PushItemWidth(85)
				imgui.InputInt(u8"Время", banTime, 1)
				imgui.TextQuestionSameLine('( ? )', u8'Время бана в минутах (0 - навсегда)')
			end
			imgui.Checkbox(u8'Реагировать на модеров', modReact)
			imgui.TextQuestionSameLine('( ? )', u8'Работает как тумблер. Чтобы выключить реагирование в античите, проведите ещё один цикл с включенным параметром')
			if imgui.Button(u8'Настроить', imgui.ImVec2(75,20)) then
				antiCheat(split(u8:decode(str(acPattern)), ' '))
			end

			imgui.PopStyleVar(1)

		end

		imgui.End()
    end
)


function sampev.onServerMessage(color, text)
	if string.find(text, 'PM от') and color == -65281 and tonumber(config.settings.autoPM) ~= 0 then
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