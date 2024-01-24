local component = require('component')
local reactor = component['reactor_chamber']
local me = component['me_interface']
local history, durability_items = {}, {['IC2:reactorVentGold'] = 9500}
local heating_scheme, kernels = {'plating_heat', 'quad_kernel_uran'}, {single_kernel_uran=true, quad_kernel_uran=true, quad_kernel_mox=true}

local schemes_amount = {
	heating = {
		gold_exchanger = 1,
		plating_heat = 5,
		quad_kernel_uran = 2,
		single_kernel_uran = 1
	},
	scheme_420 = {
		gold_exchanger = 28,
		vent_exchanger = 11,
		plating = 7,
		switch_exchanger = 1,
		quad_kernel_uran = 7
	},
	scheme_1500 = {
		diamond_exchanger = 27,
		switch_exchanger = 11,
		vent_exchanger = 11,
		quad_kernel_mox = 5
	}
}

local schemes_all = {
	scheme_420 = {
		'quad_kernel_uran', 'vent_exchanger', 'gold_exchanger', 'switch_exchanger',
		'gold_exchanger', 'gold_exchanger', 'vent_exchanger', 'gold_exchanger',
		'plating', 'plating', 'vent_exchanger', 'gold_exchanger',
		'gold_exchanger', 'vent_exchanger', 'gold_exchanger', 'gold_exchanger',
		'quad_kernel_uran', 'gold_exchanger', 'plating', 'gold_exchanger',
		'quad_kernel_uran', 'gold_exchanger', 'gold_exchanger', 'quad_kernel_uran',
		'gold_exchanger', 'gold_exchanger', 'vent_exchanger', 'vent_exchanger',
		'gold_exchanger', 'gold_exchanger', 'vent_exchanger', 'gold_exchanger',
		'gold_exchanger', 'vent_exchanger', 'gold_exchanger', 'plating',
		'gold_exchanger', 'quad_kernel_uran', 'gold_exchanger', 'gold_exchanger',
		'quad_kernel_uran', 'gold_exchanger', 'gold_exchanger', 'quad_kernel_uran',
		'gold_exchanger', 'plating', 'gold_exchanger', 'vent_exchanger',
		'plating', 'gold_exchanger', 'vent_exchanger', 'plating',
		'gold_exchanger', 'vent_exchanger'
	},
	scheme_1500 = {
		'diamond_exchanger', 'switch_exchanger', 'diamond_exchanger', 'switch_exchanger',
		'diamond_exchanger', 'switch_exchanger', 'diamond_exchanger', 'switch_exchanger',
		'diamond_exchanger', 'quad_kernel_mox', 'diamond_exchanger', 'vent_exchanger',
		'diamond_exchanger', 'vent_exchanger', 'diamond_exchanger', 'vent_exchanger',
		'diamond_exchanger', 'quad_kernel_mox', 'diamond_exchanger', 'switch_exchanger',
		'diamond_exchanger', 'switch_exchanger', 'diamond_exchanger', 'vent_exchanger',
		'diamond_exchanger', 'switch_exchanger', 'diamond_exchanger', 'vent_exchanger',
		'diamond_exchanger', 'vent_exchanger', 'diamond_exchanger', 'quad_kernel_mox',
		'diamond_exchanger', 'vent_exchanger', 'diamond_exchanger', 'vent_exchanger',
		'diamond_exchanger', 'switch_exchanger', 'diamond_exchanger', 'switch_exchanger',
		'diamond_exchanger', 'switch_exchanger', 'diamond_exchanger', 'switch_exchanger',
		'diamond_exchanger', 'quad_kernel_mox', 'diamond_exchanger', 'vent_exchanger',
		'diamond_exchanger', 'vent_exchanger', 'diamond_exchanger', 'vent_exchanger',
		'diamond_exchanger', 'quad_kernel_mox'
	}
}

local items = {
	switch_exchanger = {
		name = 'Компонентный теплообменник',
		fp = {id='IC2:reactorHeatSwitchSpread', dmg=nil}
	},
	diamond_exchanger = {
		name = 'Улучшенный теплоотвод',
		fp = {id='IC2:reactorVentDiamond', dmg=nil}
	},
	vent_exchanger = {
		name = 'Компонентный теплоотвод',
		fp = {id='IC2:reactorVentSpread', dmg=nil}
	},
	gold_exchanger = {
		name = 'Разогнанный теплоотвод',
		fp = {id='IC2:reactorVentGold', dmg=nil}
	},
	plating = {
		name = 'Реакторная обшивка',
		fp = {id='IC2:reactorPlating', dmg=0}
	},
	plating_heat = {
		name = 'Теплоёмкая реакторная пластина',
		fp = {id='IC2:reactorPlatingHeat', dmg=0}
	},
	single_kernel_uran = {
		name = 'Одинарный стержень уран',
		fp = {id='IC2:reactorUraniumSimple', dmg=nil}
	},
	quad_kernel_uran = {
		name = 'Счетверённый стержень уран',
		fp = {id='IC2:reactorUraniumQuad', dmg=nil}
	},
	quad_kernel_mox = {
		name = 'Счетверённый стержень МОХ',
		fp = {id='IC2:reactorMOXQuad', dmg=nil}
	}
}


local function unfill_reactor()
	for slot in pairs(reactor.getAllStacks()) do while me.pullItem('UP', slot) == 0 do os.sleep(0.01) end end
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
	if kernels[item] and #history[items[item]['fp'].id] > 0 or not kernels[item] then
		me.exportItem(history[items[item]['fp'].id][1], 'UP', 1, slot)
		if not delete then
			table.insert(history[items[item]['fp'].id], history[items[item]['fp'].id][1])
		end
		table.remove(history[items[item]['fp'].id], 1)
	end
end


local function wait(temp, more)
	if more then
		while reactor.getHeat() < temp do
			os.sleep(0)
		end
	else
		while reactor.getHeat() > temp do
			os.sleep(0)
		end
	end
end


local function is_working(scheme)
	for item in pairs(schemes_amount[scheme]) do
		if (#history[items[item].fp.id] < schemes_amount[scheme][item] and not kernels[item]
			or scheme == 'heating' and #history[items[item].fp.id] < schemes_amount[scheme][item]) then
			print('[' .. items[item]['name'] .. '] Недостаточно ' .. schemes_amount[scheme][item]-#history[items[item].fp.id] .. ' шт\nНе хотите ли дозаказать?(y/n)')
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
				return
			end
		end
	end
	return true
end


local function heating()
	local redstone = nil
	if component.isAvailable('redstone') then
		redstone = component['redstone']
	else
		print('[Нагерв] Не подключен красный камень')
		return
	end
	local slot = 1
	if is_working('heating') then
		for _, item in pairs(heating_scheme) do
			for amount=1, schemes_amount['heating'][item] do
				export(item, slot, false)
				slot = slot + 1
			end
		end
		redstone.setOutput(1, 1)
		wait(9920, true)
		me.pullItem('UP', schemes_amount['heating']['plating_heat']+1)
		wait(10000, true)
		me.pullItem('UP', schemes_amount['heating']['plating_heat']+2)
		export('gold_exchanger', schemes_amount['heating']['plating_heat']+1, false)
		wait(10000, false)
		me.pullItem('UP', schemes_amount['heating']['plating_heat']+1)
		export('single_kernel_uran', schemes_amount['heating']['plating_heat']+1, false)
		wait(9996, true)
		redstone.setOutput(1, 0)
		if reactor.getHeat() < 10000 then
			unfill_reactor()
		end
		return true
	end
end


local function fill_reactor(scheme, heat_reactor)
	if not is_working(scheme) then
		return
	end
	unfill_reactor()
	if heat_reactor then
		if not heating() then
			return
		end
	end
	for slot, item in ipairs(schemes_all[scheme]) do
		export(item, slot, true)
	end
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
print('[1] Уран 420\n[2] МОХ 1500 без нагрева\n[3] МОХ 1500 + нагрев\n[4] Нагрев реактора\n[5] Разгрузка реактора\n[6] Выход')
io.write('=> ')
local act = io.read()
if act == '1' then
	fill_reactor('scheme_420', false)
elseif act == '2' then
	fill_reactor('scheme_1500', false)
elseif act == '3' then
	fill_reactor('scheme_1500', true)
elseif act == '4' then
	unfill_reactor()
	heating()
elseif act == '5' then
	unfill_reactor()
elseif act == '6' then
	os.exit()
else
	print('Выбран некорректный пункт')
end
