local component = require('component')
local computer = require('computer')
local me = component['me_interface']
local redstone = component['redstone']
local reactor = component['reactor_chamber']
local history, heating_scheme, durability_items = {}, {'plating_heat', 'quad_kernel_uran'}, {['IC2:reactorCoolantSix'] = 9500, ['IC2:reactorVentGold'] = 2500}

local schemes_amount = {
	heating = {
		plating_heat = 45,
		single_kernel = 1,
		quad_kernel = 9,
		gold_exchanger = 1
	},
	working_scheme = {
		quad_kernel = 8,
		litium = 10,
		cooling_elements = 7
	}
}

local schemes_all = {
    working_scheme = {
        [3] = 'cooling_elements', [7] = 'cooling_elements', [11] = 'litium', [12] = 'quad_kernel', [13] = 'litium', [15] = 'litium', [16] = 'quad_kernel' , [17] = 'litium',
        [19] = 'cooling_elements', [20] = 'quad_kernel', [21] = 'litium', [22] = 'quad_kernel', [23] = 'cooling_elements', [24] = 'quad_kernel', [25] = 'litium', [26] = 'quad_kernel', [27] = 'cooling_elements',
        [29] = 'litium', [30] = 'quad_kernel', [31] = 'litium', [33] = 'litium', [34] = 'quad_kernel', [35] = 'litium', [39] = 'cooling_elements', [43] = 'cooling_elements'
    }, -- 10 version later... Иногда что-то правильное - хорошо забытое старое
	heating = {
        [1] = 'plating_heat', [2] = 'plating_heat', [3] = 'quad_kernel', [4] = 'plating_heat', [5] = 'plating_heat',
        [6] = 'plating_heat', [7] = 'plating_heat', [8] = 'plating_heat', [9] = 'plating_heat', [10] = 'plating_heat',
        [11] = 'plating_heat', [12] = 'quad_kernel', [13] = 'plating_heat', [14] = 'plating_heat', [15] = 'plating_heat',
        [16] = 'plating_heat', [17] = 'plating_heat', [18] = 'plating_heat', [19] = 'quad_kernel', [20] = 'quad_kernel',
        [21] = 'quad_kernel', [22] = 'quad_kernel', [23] = 'quad_kernel', [24] = 'plating_heat', [25] = 'plating_heat',
        [26] = 'plating_heat', [27] = 'plating_heat', [28] = 'plating_heat', [29] = 'plating_heat', [30] = 'quad_kernel',
        [31] = 'plating_heat', [32] = 'plating_heat', [33] = 'plating_heat', [34] = 'plating_heat', [35] = 'plating_heat',
        [36] = 'plating_heat', [37] = 'plating_heat', [38] = 'plating_heat', [39] = 'quad_kernel', [40] = 'plating_heat',
        [41] = 'plating_heat', [42] = 'plating_heat', [43] = 'plating_heat', [44] = 'plating_heat', [45] = 'plating_heat',
        [46] = 'plating_heat', [47] = 'plating_heat', [48] = 'plating_heat', [49] = 'plating_heat', [50] = 'plating_heat',
        [51] = 'plating_heat', [52] = 'plating_heat', [53] = 'plating_heat', [54] = 'plating_heat'
    },
    unfill_heating = {3, 12, 19, 20, 21, 22, 23, 30, 39},
    unfill_working = {3, 11, 12, 13, 19, 20, 21, 22, 23, 29, 30, 31, 39, 24, 25, 26 ,27, 15 ,16 , 17, 7, 33, 34, 35, 43}
}

local items = {
	single_kernel = {
		name = 'Одинарный стержень уран',
		fp = {id='IC2:reactorUraniumSimple', dmg=nil}
	},
	quad_kernel = {
		name = 'Счетверённый стержень уран',
		fp = {id='IC2:reactorUraniumQuad', dmg=nil}
	},
	cooling_elements = {
		name = '60к Охлаждающий элемент',
		fp = {id='IC2:reactorCoolantSix', dmg=nil}
	},
	plating_heat = {
		name = 'Теплоёмкая реакторная пластина',
		fp = {id='IC2:reactorPlatingHeat', dmg=0}
	},
	gold_exchanger = {
		name = 'Разогнанный теплоотвод',
		fp = {id='IC2:reactorVentGold', dmg=nil}
	},
	litium = {
		name = "Литий",
		fp = {id='IC2:reactorLithiumCell', dmg=nil}
	}
}

local function unfill_reactor(scheme)
    local reactor_history, slots = reactor.getAllStacks(), {}
    if scheme == 'all' then
        for i=1, 54 do table.insert(slots, i) end
    else
        slots = schemes_all[scheme]
    end
    for _, slot in ipairs(slots) do
        if reactor_history[slot] and me.pullItem('UP', slot) == 1 and history[reactor_history[slot].all().id] then
            table.insert(history[reactor_history[slot].all().id], {id=reactor_history[slot].all().id, dmg=reactor_history[slot].all().dmg, nbt_hash=reactor_history[slot].all().nbt_hash}) -- КОСТЯ НЕ БЕЙ, ДЕТЕЙ НЕЛЬЗЯ БИТЬ
            -- P.S Я отсталый и использовал .basic, со словами "Выводит одно и тоже". На этот фикс мы потратили 3 ЧАСА И ПЕРЕПИСАЛИ ПОЛОВИНУ ЛОГИКИ
        end
    end
end

local function dozakaz(name, kolvo)
	local crafts = me.getCraftables()
	for i=1, #crafts do
		if crafts[i].getItemStack().name == name.id then
			local craft = crafts[i].request(kolvo)
			while true do
				if craft.isDone() or craft.isCanceled() then
					break
				end
				os.sleep(0.1)
			end
			for k=1, kolvo do table.insert(history[name.id], name) end
			return table.pack(craft.isDone())
		end
	end
	print('Нет шаблона')
	os.exit()
end
local function export(item, slot, delete)
	if #history[items[item]['fp'].id] > 0 then
		me.exportItem(history[items[item]['fp'].id][1], 'UP', 1, slot)
		if not delete then
			table.insert(history[items[item]['fp'].id], history[items[item]['fp'].id][1])
		end
		table.remove(history[items[item]['fp'].id], 1)
	end
end
local function wait(temp, more)
	if more then
		while reactor.getHeat() < temp do os.sleep(0) end
	else
		while reactor.getHeat() > temp do os.sleep(0) end
	end
end
local function is_working(scheme)
	for item in pairs(schemes_amount[scheme]) do
		if #history[items[item].fp.id] < schemes_amount[scheme][item] then
			print('[' .. items[item]['name'] .. '] Недостаточно ' .. schemes_amount[scheme][item]-#history[items[item].fp.id] .. ' шт в ' .. scheme .. '\nНе хотите ли дозаказать?(y/n)')
			io.write('=> ')
			if io.read() == 'y' then
				local is_crafting = dozakaz(items[item]['fp'], schemes_amount[scheme][item]-#history[items[item].fp.id])
				if not is_crafting[1] then
					print(is_crafting[2])
					return
				else
					print('[' .. items[item]['name'] .. '] Craft completed')
				end
			else
				os.exit()
			end
		end
	end
	return true
end
local function fill_reactor(scheme)
	if not is_working(scheme) then
		return
	end
	for slot, item in pairs(schemes_all[scheme]) do
		export(item, slot, true)
	end
end
local function controller(skolko)
	if #history[items['litium']['fp'].id] < skolko then		
		print('Недостаточно ', skolko-#history[items['litium']['fp'].id],' литиевых стержней\nНе хотите ли дозаказать?(y/n)')
		io.write('=> ')
		if io.read() == 'y' then
			dozakaz(items['litium']['fp'], #history[items['litium']['fp'].id]-skolko)
		else
			os.exit()
		end		
	end
	fill_reactor('working_scheme')
	local achieved = 0
	redstone.setOutput(1, 1)
	local achieved, start_time = 0, computer.uptime()
	while true do
		local reactor_elements = reactor.getAllStacks()
		for k, v in ipairs({3, 19, 23, 39, 7, 27, 43}) do
			if reactor_elements[v].basic().dmg >= 9500 then
				redstone.setOutput(1, 0)
				reactor.destroyStack(v)
				if #history[items['cooling_elements']['fp'].id] == 0 then
					print('Закончились охлаждающие стержни на 60к, сделано трития: ' .. achieved)
					os.exit()
				else
					export('cooling_elements', v, true)
					redstone.setOutput(1, 1)
				end
			end
		end
		for k, v in ipairs({12, 20, 22, 30, 18, 24, 26, 34}) do
			if reactor_elements[v] and reactor_elements[v].basic().id == 'IC2:reactorUraniumQuaddepleted' then
				me.pullItem('UP', v)
				if #history[items['quad_kernel']['fp'].id] == 0 then
					redstone.setOutput(1, 0)
					print('Закончились Счетверённые стержни, сделано трития: ' .. achieved)
					os.exit()
				else export('quad_kernel', v, true) end
			end
		end
		for k, v in ipairs({11, 13, 21, 29, 31, 15, 17, 33, 35, 25}) do
			if reactor_elements[v] and reactor_elements[v].basic().id == 'IC2:itemTritiumCell' then
				me.pullItem('UP', v)
				achieved = achieved + 1
				if #history[items['litium']['fp'].id] > 0 then
					export('litium', v, true)
				end
			end
		end
		if achieved >= skolko then 
			redstone.setOutput(1, 0)
			print('[Тритий ' .. achieved .. 'x] Сделано за ' .. computer.uptime()-start_time .. ' сек')
			break
		end
		os.sleep(0)
	end
end
local function heating()
	unfill_reactor('all')
	fill_reactor('heating')
	redstone.setOutput(1, 1)
	wait(68000, true)
	redstone.setOutput(1, 0)
	unfill_reactor('unfill_heating')
	redstone.setOutput(1, 1)
	export('gold_exchanger', 3, false)
	wait(67980, false)
	me.pullItem('UP', 3)
	export('single_kernel', 3, false)
	wait(67996, true)
	redstone.setOutput(1, 0)
	unfill_reactor('unfill_working')
end

for item in pairs(items) do
	history[items[item].fp.id] = {}
end
for _, item in pairs(me.getAvailableItems()) do
	if (history[item['fingerprint'].id] and not durability_items[item['fingerprint'].id]
		or durability_items[item['fingerprint'].id] and item['fingerprint'].dmg < durability_items[item['fingerprint'].id]) then
		for k=1, item.size do
			table.insert(history[item['fingerprint'].id], item['fingerprint'])
		end
	end
end
print('[1] Активировать производство лития\n[2] Выход')
io.write('=> ')
local act = io.read()
if act == '1' then
	if reactor.getHeat() < 67000 then
		unfill_reactor('all')
		heating()
	end
	unfill_reactor('unfill_working')
	print('Сколько произвести')
	io.write('=> ')
	skolko = io.read()
	if tonumber(skolko) ~= nil then
		controller(tonumber(skolko))
	else
		print('Каждое число это символ, но не каждый символ это число!')
	end
elseif act == '2' then
	os.exit()	
else
	print('Выбран некорректный пункт')
end
