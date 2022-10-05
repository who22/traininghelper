script_name('trainingHelper') 
script_author('Gerald.myr') 

require 'lib.moonloader'

local scriptVersion = 93
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
		style = 0
	}
}, directIni)

local new = imgui.new

local style = new.int(config.settings.style)

local notepadWindow = new.bool(false)
local menuWindow = new.bool(false)

local color = new.float[3](1.0, 1.0, 1.0)

local notepad = new.char[65535]('')

local autoPMitems = {u8'Выключен', u8'Включен', u8'Только друзья'}
local punishmentItems = {u8'Игнорировать', u8'Отправить на спавн', u8'Кикнуть', u8'Забанить', u8'Debug'}
local autoPM = new.int(tonumber(config.settings.autoPM))
local autoPMarr = {}

local carLock = new.bool(config.settings.carLock)
local copyPos = new.bool(config.settings.copyPos)
local autoCB = new.bool(config.settings.autoCB)

local styleItems = {u8'Светлая тема', u8'Темная тема'}
local styleArr = {}

local punishment = new.int(0)
local toggle = new.bool(0)
local modReact = new.bool(0)
local modMsg = new.bool(0)
local warnings = new.int(3)
local banTime = new.int(0)
local acPattern = new.char[65535]('')
local warningsRemove = new.int(10)
local punishmentArr = {}

local tab = 0

local showObject = false
font = renderCreateFont('Arial', 8, 5)

local resX, resY = getScreenResolution()

imgui.OnInitialize(function()
	autoPMarr = new['const char*'][#autoPMitems](autoPMitems)
	punishmentArr = new['const char*'][#punishmentItems](punishmentItems)
	styleArr = new['const char*'][#styleItems](styleItems)
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


	approveStyle()


	msgChat('TrainingHelper запущен | /binds - бинды | /cmds - команды | /menu - графическое меню')


	sampRegisterChatCommand('binds', function(id)
		msgChat('Z - реальное время | ПКМ + X - fast /pm | I - friend list')
	end)


	sampRegisterChatCommand('cmds', function(id)
		msgChat('/faddname - добавить друга по нику | /faddid - добавить друга по ID')
		msgChat('/isafk ID - чек на AFK | /cc - очистить чат | /notepad - блокнот для заметок')
		msgChat('/friendlist - список всех друзей | /delf NICK - удалить друга')
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
				config.friends[#friendList + 1] = tostring(name)
				inicfg.save(config, directIni)
				msgChat('У тебя новый друг, а может и подружка {5A90CE}' .. name .. '{FFFFFF}!')
			end
		end
	end)


	sampRegisterChatCommand('faddname', function(name)
		local friendList = config.friends
		config.friends[#friendList + 1] = tostring(name)

		inicfg.save(config, directIni)
		msgChat('У тебя новый друг, а может и подружка {5A90CE}' .. name .. '{FFFFFF}!')
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
				msgChat('Вы потеряли хорошего друга, а может и подружку. {5A90CE}'..name..'{FFFFFF}, прощай :(')
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

		msgChat('Список всех друзей:')
		for pos = 1, #friendList do
			friend = friendList[pos]
			sampAddChatMessage(tostring(friend), 0x0FFFFFF)
		end
	end)


	downloadUrlToFile(updateUrl, updatePath, function(id, status)
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			local updIni = inicfg.load(nil, updatePath)
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
					msgChat('Скрипт обновлен!')
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
					renderFontDrawText(font, model, x1, y1, -1)
				end
			end
		end


		if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then

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

			if isKeyJustPressed(VK_O) then
				showObject = not showObject
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

		if imgui.Selectable(u8'Основное', tab == 0, 0, imgui.ImVec2(75, 15)) then tab = 0 end
		imgui.SameLine()
        if imgui.Selectable(u8'Палитра', tab == 1, 0, imgui.ImVec2(75, 15)) then tab = 1 end
		imgui.SameLine()
		if imgui.Selectable(u8'Античит', tab == 2, 0, imgui.ImVec2(75, 15)) then tab = 2 end

		imgui.Separator()


		if tab == 0 then

			imgui.Text(u8'XYZAngle: ' .. round(positionX, 1) .. ' ' .. round(positionY, 1) .. ' ' .. round(positionZ, 1) .. ' ' .. math.floor(getCharHeading(PLAYER_PED)))
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

			if imgui.Checkbox(u8'Копирование позиции при /savepos', copyPos) then
				config.settings.copyPos = copyPos[0]
				inicfg.save(config, directIni)
			end

			if imgui.Checkbox(u8'Дефолтная настройка КБ', autoCB) then
				config.settings.autoCB = autoCB[0]
				inicfg.save(config, directIni)
			end

			imgui.TextQuestionSameLine('( ? )', u8'При отправке команды /cb скрипт автоматически создаст КБ на Ввод диалога и укажет радиус 1')

			imgui.SetCursorPos(imgui.ImVec2(5, 265))
			imgui.PushItemWidth(110)
			if imgui.Combo('##theme', style, styleArr, 2) then
				config.settings.style = style[0]
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
			imgui.Checkbox(u8'Сообщать модераторам', modMsg)
			imgui.TextQuestionSameLine('( ? )', u8'Работает как тумблер. Чтобы выключить реагирование в античите, проведите ещё один цикл с включенным параметром')
			if imgui.Button(u8'Настроить', imgui.ImVec2(75,20)) then
				antiCheat(split(u8:decode(str(acPattern)), ' '))
			end

			imgui.PopStyleVar(1)

		end

		imgui.End()
    end
)


local backgroundFrame = imgui.OnFrame(
    function() return true end,
    function(player)

		player.HideCursor = true
		
		local dl = imgui.GetBackgroundDrawList()

		dl:AddText(imgui.ImVec2(resX - 140, resY - 20), 0xFFFFFFFF, 'trainingHelper ver. 0.' .. scriptVersion)

    end
)


function sampev.onServerMessage(color, text)
	if string.find(text, 'PM от') and color == -65281 and tonumber(config.settings.autoPM) ~= 0 then
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
end


function sampev.onSendCommand(cmd)
	if cmd == "/savepos" and copyPos[0] then
		local x, y, z = getCharCoordinates(PLAYER_PED)

		setClipboardText(round(x, 2) .. ' ' .. round(y, 2) .. ' ' .. round(z, 2))
	end

	if cmd == "/cb" and autoCB[0] then
		print("ПОЙМАЛ!")
		lua_thread.create(function()
			wait(150)
			sampSendDialogResponse(32700, 1, 0, '1') -- radius 1.00

			sampSendDialogResponse(32700, 1, 11, nil) -- activate type

			sampSendDialogResponse(32700, 1, 31, nil) -- on dialog
		end)
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

			sampSendDialogResponse(32700, 1, 1, nil)
			sampSendDialogResponse(32700, 1, 0, tostring(warnings[0]))

			sampSendDialogResponse(32700, 1, 2, nil)
			sampSendDialogResponse(32700, 1, punishment[0], nil)
			sampSendDialogResponse(32700, 0, 0, nil)

			if punishment[0] == 3 then
				sampSendDialogResponse(32700, 1, 3, nil)
				sampSendDialogResponse(32700, 1, 0, tostring(banTime[0]))
			end

			sampSendDialogResponse(32700, 1, 4, nil)
			sampSendDialogResponse(32700, 1, 0, tostring(warningsRemove[0]))

			if modReact[0] == true then
				sampSendDialogResponse(32700, 1, 6, nil)
			end

			if modMsg[0] == true then
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