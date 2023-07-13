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
	items = {u8'Светлая тема', u8'Темная тема'},
	array = {}
}

local autopm = {
	toggle = new.int(tonumber(config.settings.autoPM)),
	items = {u8'Выключен', u8'Включен', u8'Только друзья'},
	array = {}
}

local anticheat = {
	toggle = new.bool(0),
	items = {u8'Игнорировать', u8'Отправить на спавн', u8'Кикнуть', u8'Забанить', u8'Debug'},
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


	msgChat('TrainingHelper by Gerald.myr запущен | /binds | /cmds | /menu')

	sampRegisterChatCommand('binds', function(id)
		msgChat('Z - реальное время | ПКМ + X - fast /pm | I - friend list')
	end)


	sampRegisterChatCommand('cmds', function(id)
		msgChat('/faddname - добавить друга по нику | /faddid - добавить друга по ID')
		msgChat('/isafk ID - чек на AFK | /cc - очистить чат | /notepad - блокнот для заметок')
		msgChat('/friendlist - список всех друзей | /delf NICK - удалить друга | /hint - подсказки по текстовым командам')
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

		imgui.Begin(u8'Текстовые команды by OfficerBoss', hintWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

		if imgui.CollapsingHeader(u8"  Массивы") then
			imgui.Text(u8"- #random(num1, num2)# - сгенерировать случайное число от num1 до num2.")
			imgui.Text(u8"- #array(num, playerid*)# - вернуть данные внутри массива num.")
			imgui.Text(u8"- #server(num)# - вернуть данные внутри массива num слот (сервер).")
			imgui.Text(u8"- #retval(0 - 9, playerid*)# - возвращаемые параметры для игрока")
			imgui.Text(u8"- #retstr(0 - 9, playerid*)# - возвращаемые параметры для игрока текстовые")
			imgui.Text(u8"- #ext(cbid actionid)# - Возвращает содержимое строки определенного блока.")
			imgui.Text(u8"- #pvar(name, playerid*)# - Содержимое переменной name игрока playerid.")
			imgui.Text(u8"- #vdata(vehicleid num)# - Массив транспорта. ")
			imgui.Text(u8"- #oArray(objectid)# - значение массива объекта objectid")
			imgui.Text(u8"- #strcmp(str1, str2, caps*)# - сверка текста")
			imgui.Text(u8"- #strfind(str, synstr, caps*)# - поиск substr в str")
			imgui.Text(u8"- #srtdel(str, start, end)# - удалит символы с start до end в str")
			imgui.Text(u8"- #strlen(str)# - длина строки")
			imgui.Text(u8"- #strins(str, substr, pos)# - вставляет substr в str на месте pos")
			imgui.Text(u8"- #customRaycast(xyz1 angle dist 0/1 x/y/z/xyz)# - возврат коллизии (#raycast#) с любой точки")
		end

		if imgui.CollapsingHeader(u8"  Арифметика") then
			imgui.Text(u8"- #round(number method*)# or #floatround(number method*)# - округление числа number методом method*")
			imgui.Text(u8"* round - метод по дефолту, округляет к ближ. целому числу")
			imgui.Text(u8"* floor - округляет вниз")
			imgui.Text(u8"* ceil - округляет вверх")
			imgui.Text(u8"* tozero - округляет ближе к 0")
			imgui.Text(u8"- #log(number base)# - логарифм с базой base от числа number")
			imgui.Text(u8"- #sin(number method*)# - синус number")
			imgui.Text(u8"- #cos(number method*)# - косинус number")
			imgui.Text(u8"- #tan(number method*)# - тангенс number")
			imgui.Text(u8"* radian - по дефолту")
			imgui.Text(u8"* degrees")
			imgui.Text(u8"* grades")
			imgui.Text(u8"- #sqroot(number)# - квадратный корень числа number")
			imgui.Text(u8"- #power(numb1 numb2)# - возведение числа numb1 в степень numb2")
			imgui.Text(u8"- #raycast(cam/pos dist col(0/1) coord(x/y/z/xyz))# - возврат коллизии")
			imgui.Text(u8"- #floatnum(numb1 type numb2)# - точный рассчёт (+, -, /, *) числа numb1 к numb2")
		end

		if imgui.CollapsingHeader(u8"  Команды") then
			imgui.Text(u8"- #teamOnline(1-10)# - вывести онлайн команды.")
			imgui.Text(u8"- #team# - вернуть ID команды в которой состоит игрок.")
			imgui.Text(u8"- #teamName# - Название команды в которой состоит игрок. ")
		end

		if imgui.CollapsingHeader(u8"  Данные Мира") then
			imgui.Text(u8"- #online# - вывести онлайн мира")
			imgui.Text(u8"- #time# - время мира.")
			imgui.Text(u8"- #weather# - погода мира.")
			imgui.Text(u8"- #timestamp# - время в секундах от 01.01.1970")
			imgui.Text(u8"- #worldName# - название мира")
			imgui.Text(u8"- #worldDesc# - описание мира")
			imgui.Text(u8"- #vehCount# - количество машин в мире")
			imgui.Text(u8"- #objectCount# - количество объектов в мире")
			imgui.Text(u8"- #maxObj# or #maxObjectCount# - лимит объектов в мире")
			imgui.Text(u8"- #getDate(category*)# category: day, month, year, days/daynum")
			imgui.Text(u8"- #getTime(*category)# category: hour, minute, second")
			imgui.Text(u8"- #playerCount(category item)# - количество человек соответсвующим category = item")
			imgui.Text(u8"- #playerList(item category id)# - ID игрока id, который соответствует category = item")
			imgui.Text(u8"- #randomPlayer(*category *item)# - ID случайного игрока соответствующего category = item")
			imgui.Text(u8"* category: team, skin, veh, data, wanted, action, dead, alive, score, gun/weapon, channel,")
			imgui.Text(u8"* afk, vip, taser, surfingveh, int, attach, attachmodel, retval, vehseat")
			imgui.Text(u8" - #getZ(x y)# - получить Z координату по X и Y координате")
			imgui.Text(u8"- #GetDist(xyz1 xyz2)# - получить расстояние между xyz1 и xyz2")
			imgui.Text(u8"- #front(dist <x/y>, *playerid)# - координаты впереди игрока playerid на расстоянии dist")
			imgui.Text(u8"- #getzone(x, y)# - получить название зоны по координатам X Y")
			imgui.Text(u8"- #getzoneid(x, y)# - получить ID зоны по координатам X Y")
			imgui.Text(u8"- #actionXYZ(actionid)# #actionX/Y/Z(actionid)# - координаты 3д текста actionid")
		end

		if imgui.CollapsingHeader(u8"  Объекты") then
			imgui.Text(u8"- #GetDistObject(objectid)# - получить расстояние до объекта objectid")
			imgui.Text(u8"- #oArray(objectid)# - значение массива объекта objectid")
			imgui.Text(u8"- #oState(objectid)# - состояние объекта objectid (0 - скрыт / 1 - виден)")
			imgui.Text(u8"- #oMoveXYZ(objectid)# (#oMoveX/Y/Z(objectid)#) - координаты перемещения объекта objectid")
			imgui.Text(u8"- #oMove(objectid)# - !ПРОВЕРИТЬ! - статус объекта (0 - стоит / 1 - перемещается)")
			imgui.Text(u8"- #rxyz(objectid)# (#rx/y/z(objectid)#) - поворот объекта objectid")
			imgui.Text(u8"- #oxyz(objectid)# (#ox/y/z(objectid)#) - координаты  объекта objectid")
			imgui.Text(u8"- #omodel(objectid)# - модель объекта objectid")
			imgui.Text(u8"- #nearObj(dist modelid)# - ближайший объект модели modelid в радиусе dist от игрока")
		end

		if imgui.CollapsingHeader(u8"  Данные игрока") then
			imgui.Text(u8"- #name(playerid*)# - Игровой ник игрока.")
			imgui.Text(u8"- #ping(playerid*)# - пинг игрока")
			imgui.Text(u8"- #netstat(playerid*)# - потери пакетов в % (Качество соединения. Идеально: 0%)")
			imgui.Text(u8"- #score(playerid*)# - очки игрока.")
			imgui.Text(u8"- #money(playerid*)# - деньги игрока.")
			imgui.Text(u8"- #health(playerid*)# - здоровье игрока.")
			imgui.Text(u8"- #armour(playerid*)# - броня игрока.")
			imgui.Text(u8"- #playerid# - ID игрока.")
			imgui.Text(u8"- #xyz(playerid*)# - координаты игрока.")
			imgui.Text(u8"- #x/y/z(playerid*)# - отдельно координаты игрока по X Y Z")
			imgui.Text(u8"- #speed(playerid*)# - скорость игрока.")
			imgui.Text(u8"- #gun(playerid*)# - ID оружия в руках игрока.")
			imgui.Text(u8"- #ammo(playerid*)# - количество патрон в оружии")
			imgui.Text(u8"- #fa(playerid*)# - получить значение поворота игрока")
			imgui.Text(u8"- #GetDistPlayer(playerid)# - получить расстояние до игрока")
			imgui.Text(u8"- #wanted(playerid*)# - уровень розыска игрока.")
			imgui.Text(u8"- #skin(playerid*)# - скин игрока.")
			imgui.Text(u8"- #attach(1-10)(playerid*)# - модель аттача в слоте.")
			imgui.Text(u8"- #acid(playerid*)# - ID аккаунта игрока из /stats")
			imgui.Text(u8"- #afk(playerid*)# - Число в секундах сколько игрок бездействует или в меню.")
			imgui.Text(u8"- #ban(playerid*)# - Возвращает 1 если у игрока есть активные варны и 0 если нет.")
			imgui.Text(u8"- #channel(playerid*)# - Канал рации игрока.")
			imgui.Text(u8"- #death(playerid*)# - Сколько осталось секунд стадии игрока. Если он жив - 0.")
			imgui.Text(u8"- #drunk(playerid*)# - Урoвень оьяениня игрока. Если уровень меньше 2000, игрок трезвый.")
			imgui.Text(u8"- #hr(playerid*)# - Процент попадения выстрелов игрока.")
			imgui.Text(u8"- #target(playerid*)# - ID игрока которого выделил через ПКМ игрок.")
			imgui.Text(u8"- #waterlvl(playerid*)# - Глубина воды под игроком. Если игрок не в воде - 0.0")
			imgui.Text(u8"- #anim(*playerid*)# - анимация игрока")
			imgui.Text(u8"- #vehicle(playerid*)# or #veh(playerid*)# - ID машины игрока")
			imgui.Text(u8"- #gunName(*playerid)# - название оружие игрока")
			imgui.Text(u8"- #moder(*playerid)# - уровень модератора игрока (999 - хост)")
			imgui.Text(u8"- #specState(*playerid)# - bool состояние слежки игрока")
			imgui.Text(u8"- #specTarget(*playerid)# - ID игрока за которым наблюдает playerid")
			imgui.Text(u8"- #int(*playerid)# - интерьер игрока")
			imgui.Text(u8"- #vip(*playerid)# - наличие VIP-статуса у игрока")
			imgui.Text(u8"- #chatStyle(*playerid)# - стиль чата (анимация общения)")
			imgui.Text(u8"- #freeze(*playerid)# - bool состояние заморозки игрока")
			imgui.Text(u8"- #freezeTime(*playerid)# - время заморозки в мс")
			imgui.Text(u8"- #gm(*playerid)# - bool состояние режима бога у игрока")
			imgui.Text(u8"- #mute(*playerid)# - bool состояние мута игрока")
			imgui.Text(u8"- #muteTime(*playerid)# - время мута игрока в секундах")
			imgui.Text(u8"- #taser(*playerid)# - bool состояние тайзера у игрока")
			imgui.Text(u8"- #lastActor(*playerid)# - !???!")
			imgui.Text(u8"- #clist(*playerid)# - Clist игрока (цвет ника)")
			imgui.Text(u8"- #fightStyle(*playerid)# - стиль драки игрока")
			imgui.Text(u8"- #isWorld(playerid)# - bool состояние присутствия в мире игрока")
			imgui.Text(u8"- #nearply(*playerid)# - ближайший игрок до playerid")
			imgui.Text(u8"- #pame(slot, *playerid)# - текст в слоте slot пэйма(/pame) у игрока playerid")
			imgui.Text(u8"- #weaponState(*playerid)# or #gunState(*playerid)# - состояние оружия у игрока")
			imgui.Text(u8"- #GetDistPlayer(targetid, *playerid)# - расстояние от игрока playerid до игрока targetid")
			imgui.Text(u8"- #GetDistPos(x y z *playerid)# - расстояние от игрока playerid до координат xyz")
			imgui.Text(u8"- #GetDistVeh(vehid, *playerid)# - расстояние от игрока playerid до транспорта vehid")
			imgui.Text(u8"- #getDistAction(actionid, *playerid)# - расстояние от игрока до 3д текста actionid")
			imgui.Text(u8"- #GetDistActor(actorid, *playerid)# - расстояние от игрока до актёта actorid")
			imgui.Text(u8"- #zone(*playerid)# - название зоны в которой находится игрок playerid")
			imgui.Text(u8"- #key(side, *playerid)# - !УЗНАТЬ!")
			imgui.Text(u8"- #nearAction(range<1-200>, *playerid)# -  ближайший 3д текст в радиусе range")
			imgui.Text(u8"- #nearActor(dist, skinid)# - ближайший актёр со скином skinid в радиусе dist от игрока")
		end

		if imgui.CollapsingHeader(u8"  Транспорт") then
			imgui.Text(u8"- #vehicle(playerid*)# - вернуть ID транспорта.")
			imgui.Text(u8"- #vehName(vehid*)# - название транспорта.")
			imgui.Text(u8"- #vehHealth(vehid*)# - здоровье транспорта.")
			imgui.Text(u8"- #vehColor(vehid*)# - цвет транспорта. В RGB формате без { }.")
			imgui.Text(u8"- #vehColor1(*playerid)# - первый цвет машины в RGB")
			imgui.Text(u8"- #vehColor2(*playerid)# - второй цвет машины в RGB")
			imgui.Text(u8"- #VehModel(vehid*)# - модель транспорта в котором сидит игрок")
			imgui.Text(u8"- #getVehModel(400 - 611)# - Название транспорта по его модели.")
			imgui.Text(u8"- #vehPos(vehicleid)# - Координаты X y Z транспорта")
			imgui.Text(u8"- #GetVehName(vehid)# - получить название транспорта")
			imgui.Text(u8"- #GetDistVeh(vehid)# - получить расстояние до транспорта")
			imgui.Text(u8"- #nearveh(playerid*)# - возвращает ID транспортна, рядом с которым вы находитесь (R=3m)")
			imgui.Text(u8"- #vehSeat(playerid*)# - Место которое занимает игрок в транспорте:")
			imgui.Text(u8"* -1 - вне машины, 0 - водитель, 1 - пассажир справа, 2 - сзади за водителем, 3 - сзади справа.")
			imgui.Text(u8"- #siren(vehid)# - bool состояние сирены у машины")
			imgui.Text(u8"- #vehParam(vehid param)# - bool состояние параметра param у машины vehid")
			imgui.Text(u8"- #surfingVeh(*playerid)# - ID машины на которой сверху едет игрок")
			imgui.Text(u8"- #gearState(vehid)# - !передача авто?!")
		end

		if imgui.CollapsingHeader(u8"  Проходы") then
			imgui.Text(u8"- Я не особо с этим разобрался, на самом деле...")
			imgui.Text(u8"- #pXYZ(passid)# #pX/Y/Z(passid)# - координаты прохода")
			imgui.Text(u8"- #pRX(passid)# - ??????????????????")
			imgui.Text(u8"- #pInt(passid)# - интерьер прохода")
			imgui.Text(u8"- #pLock(passid)# - bool состояние закрытости прохода")
			imgui.Text(u8"- #pOwner(passid)# - владелец прохода (?)")
			imgui.Text(u8"- #pVehicle(passid)# - bool состояние закрытости для транспорта прохода")
			imgui.Text(u8"- #pModel(passid)# - модель объекта прохода")
			imgui.Text(u8"- #pStatus(passid)# or #pState(passid)# - состояние прохода")
			imgui.Text(u8"- #pTeam(passid)# - команда, которой принадлежит проход")
			imgui.Text(u8"- #passinfo(*playerid)# - информация о проходе")
		end

		if imgui.CollapsingHeader(u8"  Актёры") then
			imgui.Text(u8"- #actorState(actorid)# or #actorStatus(actorid)# - bool состояние жизни актёра")
			imgui.Text(u8"- #actorAnim(actorid)# - анимация актёра")
			imgui.Text(u8"- #actorAltAnim(actorid)# - дополнительная анимация актёра")
			imgui.Text(u8"- #actorSkin(actorid)# - скин актёра")
			imgui.Text(u8"- #actorHealth(actorid)# - здоровье актёра")
			imgui.Text(u8"- #actorInvulnerable(actorid)# or #actorGM(actorid)# - bool состояние бессметрия актёра")
			imgui.Text(u8"- #actorXYZ(actorid)# #actorX/Y/Z(actorid)# - координаты актёра")
		end

		if imgui.CollapsingHeader(u8"  Аттачи") then
			imgui.Text(u8"- #attach(slot, *playerid)# - есть ли аттач в слоте slot")
			imgui.Text(u8"- #attachModel(slot, *playerid)# - модель аттача в слоте slot")
			imgui.Text(u8"- #isAttachModel(modelid, *playerid)# - есть ли у игрока аттач с моделью modelid")
			imgui.Text(u8"- #attachBone(slot, *playerid)# - кость к которой прикреплён аттач в слоте slot")
			imgui.Text(u8"- #attachOffsetXYZ(slot, *playerid)# #attachOffsetX/Y/Z(slot, *playerid)# - сдвиг по координатам от центра")
			imgui.Text(u8"- #attachRotXYZ(slot, *playerid)# #attachRotX/Y/Z(slot, *playerid)# - поворот аттача")
			imgui.Text(u8"- #attachScaleXYZ(slot, *playerid)# #attachScaleX/Y/Z(slot, *playerid)# - размеры аттача")
		end

		if imgui.CollapsingHeader(u8"  Аттачи Транспорта") then
			imgui.Text(u8"- #vAttach(slot, vehicleid)# - есть ли аттач в слоте slot")
			imgui.Text(u8"- #vAttachModel(slot,*vehicleid)# модель аттача в слоте slot")
			imgui.Text(u8"- #isvAttachModel(modelid, vehicleid)# есть ли у транспорта аттач с моделью modelid")
			imgui.Text(u8"- #vAttachXYZ(slot, vehicleid)# #vAttachX/Y/Z(slot, vehicleid)# - размеры аттача")
			imgui.Text(u8"- #vAttachRotXYZ(slot, vehicleid)# #vAttachRotX/Y/Z(slot, vehicleid)# - поворот аттача")
			imgui.Text(u8"- #vAttachOffsetXYZ(slot, vehicleid)# #vAttachOffsetX/Y/Z(slot, vehicleid)# - сдвиг по координатам от центра")
		end

		if imgui.CollapsingHeader(u8"  Ворота(/gate)") then
			imgui.Text(u8"- #gateStatus(gateid)# or #gateState(gateid)# - bool статус открытия ворот")
			imgui.Text(u8"- #gateID(gateid)# (MODEL) - модель объекта ворот")
			imgui.Text(u8"- #gateTeam(gateid)# - команда который принадлежат ворота")
			imgui.Text(u8"- #gateType(gateid)# - тип ворот (?!)")
			imgui.Text(u8"- #gateLocal(gateid)# - ?!")
			imgui.Text(u8"- #gateSpeed(gateid)# - скорость открытия ворот")
			imgui.Text(u8"- #gateStartPosXYZ(gateid)# #gateStartPosX/Y/Z(gateid)# - начальные координаты ворот")
			imgui.Text(u8"- #gateStartPosRXYZ(gateid)# #gateStartPosRX/Y/Z(gateid)# - начальный поворот ворот")
			imgui.Text(u8"- #gateStopPosX/Y/Z(gateid)# or gateEndPos(gateid) - конечные координаты ворот")
			imgui.Text(u8"- #gateStopPosRXYZ(gateid)# #gateStopPosRX/Y/Z(gateid)# - конечный поворот ворот")
		end

		if imgui.CollapsingHeader(u8"  Прочее") then
			imgui.Text(u8"Объяснение что такое #raycast#:")
			imgui.Text(u8"- #raycast(cam/pos расстояние 0/1) - вернуть точку коллизии между камерой игрока/игроком и объектом. ")
			imgui.Text(u8"3й параметр отвечает за возврат в случае отсутсвия коллизии. Если 1 - вернет координаты конечной точки.")
			imgui.Text(u8"Если 0 - вернет 0.0 0.0 0.0")
		end

		imgui.End()
    end
)


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

		if imgui.Selectable(u8'Основное', tab == 0, 0, imgui.ImVec2(75, 15)) then tab = 0 end
		imgui.SameLine()
        if imgui.Selectable(u8'Палитра', tab == 1, 0, imgui.ImVec2(75, 15)) then tab = 1 end
		imgui.SameLine()
		if imgui.Selectable(u8'Античит', tab == 2, 0, imgui.ImVec2(75, 15)) then tab = 2 end

		imgui.Separator()


		if tab == 0 then

			imgui.Text(u8'XYZAngle: ' .. round(positionX, 1) .. ' ' .. round(positionY, 1) .. ' ' .. round(positionZ, 1) .. ' ' .. math.floor(getCharHeading(PLAYER_PED)))
			imgui.PushItemWidth(145)

			if imgui.Combo(u8'Аuto /pm', autopm['toggle'], autopm['array'], 3) then
				config.settings.autoPM = autopm['toggle'][0]
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

			if imgui.Checkbox(u8'Автоматическая настройка КБ', autoCB) then
				config.settings.autoCB = autoCB[0]
				inicfg.save(config, directIni)
			end

			imgui.TextQuestionSameLine('( ? )', u8'При отправке команды /cb скрипт автоматически создаст КБ на Ввод диалога и укажет радиус 0.1')

			if imgui.Checkbox(u8'Подсветка ID объектов на O', objHL) then
				config.settings.objHL = objHL[0]
				inicfg.save(config, directIni)
			end

			if imgui.Checkbox(u8'Показывать XYZAngle на экране', showCoords) then
				config.settings.showCoords = showCoords[0]
				inicfg.save(config, directIni)
			end

			imgui.Checkbox(u8'/ch mode', chMode)

			imgui.TextQuestionSameLine('( ? )', u8'При включенном копчейз моде вы сможете имитировать поворотники в /callsign клавишами Q и E\nТакже скрипт может написать в колсигн "спасибо" при нажатии на R\nА ещё будут показываться хп автомобилей в зоне видимости')

			if imgui.Checkbox(u8'AntiTroll mode', antiTroll) then
				config.settings.antiTroll = antiTroll[0]
				inicfg.save(config, directIni)
			end

			imgui.TextQuestionSameLine('( ? )', u8'В чате перестанут показываться сообщения игроков: Iesons, monreal_de_pari, Bobrovsky (список может пополниться)')

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
			imgui.InputTextMultiline(u8'Паттерн пунктов', anticheat['acPattern'], 65535, imgui.ImVec2(130, 20))
			imgui.TextQuestionSameLine('                            ', u8'Вы должны ввести пункты, которые будут отредактированы скриптом.\nПримеры: 0-44 (с нулевого по 44, тоесть все) | 0-23 35 39 44')
			imgui.Checkbox(u8'Тумблер', anticheat['toggle'])
			imgui.TextQuestionSameLine('( ? )', u8'Включает вид античита если он выключен и наоборот выключает если он включен')
			imgui.PushItemWidth(70)
			imgui.InputInt(u8"Кол-во варнингов", anticheat['warnings'], 1)
			imgui.TextQuestionSameLine('( ? )', u8'Нужное количество подозрений от античита для выдачи наказания')
			imgui.PushItemWidth(70)
			imgui.InputInt(u8"Обнуление варнингов", anticheat['warningsRemove'], 1)
			imgui.TextQuestionSameLine('( ? )', u8'Время в секундах, через которое обнуляется количетсво подозрений от античита')
			imgui.PushItemWidth(150)
			imgui.Combo(u8'Наказание', anticheat['punishment'], anticheat['array'], 5)
			if anticheat['punishment'][0] == 3 then
				imgui.PushItemWidth(85)
				imgui.InputInt(u8"Время", anticheat['banTime'], 1)
				imgui.TextQuestionSameLine('( ? )', u8'Время бана в минутах (0 - навсегда)')
			end
			imgui.Checkbox(u8'Реагировать на модеров', anticheat['modReact'])
			imgui.TextQuestionSameLine('( ? )', u8'Работает как тумблер. Чтобы выключить реагирование в античите, проведите ещё один цикл с включенным параметром')
			imgui.Checkbox(u8'Сообщать модераторам', anticheat['modMsg'])
			imgui.TextQuestionSameLine('( ? )', u8'Работает как тумблер. Чтобы выключить реагирование в античите, проведите ещё один цикл с включенным параметром')
			if imgui.Button(u8'Настроить', imgui.ImVec2(75,20)) then
				antiCheat(split(u8:decode(str(anticheat['acPattern'])), ' '))
			end

			imgui.PopStyleVar(1)

		end

		imgui.End()
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
