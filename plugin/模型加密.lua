local mt = {}

mt.info = {
    name = '模型加密',
    version = 1.0,
    author = '最萌小汐',
    description = '将slk格式地图使用的模型进行简单加密。'
}

local w2l

local function encrypt_name(name)
	return name .. '体'
end

local cache = {}
local function rename_files()
	for name in pairs(cache) do
		local buf = w2l:file_load('resource', name)
		if buf then
			w2l:file_remove('resource', name)
			w2l:file_save('resource', encrypt_name(name:sub(1, -5)) .. name:sub(-4), buf)
		end
	end
end

local function encrypt_file(name)
	local buf = w2l:file_load('resource', name)
	if not buf then
		return false
	end
	cache[name] = true
	return true
end

local function encrypt_model(name)
	local ok
	if encrypt_file(name .. '.mdl') then
		ok = true
	end
	if encrypt_file(name .. '.mdx') then
		ok = true
	end
	if ok then
		encrypt_file(name .. '_portrait.mdl')
		encrypt_file(name .. '_portrait.mdx')
		return true
	else
		return false
	end
end

local function encrypt_jass(path)
	local jass = w2l:file_load('jass', path)
	if not jass then
		return
	end
	
	local new_jass = jass:gsub('([^\\]")([^%c"]*)(%.[mM][dD][lLxX]")', function(str1, name, str2)
		if encrypt_model(name) then
			return str1 .. encrypt_name(name) .. str2
		end
	end)
	
	w2l:file_save('jass', path, new_jass)
end

local function encrypt_jasses()
	encrypt_jass 'war3map.j'
	encrypt_jass 'scripts/war3map.j'
end

local function encrypt_lua(path)
	local lua = w2l:file_load('scripts', path)
	if not lua then
		return
	end
	
	new_lua = lua:gsub([[([^\]['"])(%C*)(%.[mM][dD][lLxX]['"])]], function(str1, name, str2)
		if encrypt_model(name) then
			return str1 .. encrypt_name(name) .. str2
		end
	end)
	new_lua = new_lua:gsub([[([^\]%[%[)(%C*)(%.[mM][dD][lLxX]%]%])]], function(str1, name, str2)
		if encrypt_model(name) then
			return str1 .. encrypt_name(name) .. str2
		end
	end)

	w2l:file_save('scripts', path, new_lua)
end

local function encrypt_luas()
	for type, name, buf in w2l:file_pairs() do
		if type == 'scripts' then
			encrypt_lua(name)
		end
	end
end

local function encrypt_objs()
	for _, objs in pairs(w2l.slk) do
		for name, obj in pairs(objs) do
			for key, data in pairs(obj) do
				if type(data) == 'string' then
					if data:sub(-4) == '.mdx' or data:sub(-4) == '.mdl' then
						local name = data:sub(1, -5)
						if encrypt_model(name) then
							obj[key] = encrypt_name(name) .. data:sub(-4)
						end
					end
				elseif type(data) == 'table' then
					for i, v in ipairs(data) do
						if type(v) == 'string' then
							if v:sub(-4) == '.mdx' or v:sub(-4) == '.mdl' then
								local name = v:sub(1, -5)
								if encrypt_model(name) then
									data[i] = encrypt_name(name) .. v:sub(-4)
								end
							end
						end
					end
				end
			end
		end
	end
end

local function encrypt_txt(path)
	local buf = w2l:file_load('map', path)
	if not buf then
		return
	end
	
	local new_txt = buf:gsub('([=,])([^,%c]*)(%.[mM][dD][lLxX])', function(str1, name, str2)
		if encrypt_model(name) then
			return str1 .. encrypt_name(name) .. str2
		end
	end)
	
	w2l:file_save('map', path, new_txt)
end

local function encrypt_slk(path)
	local buf = w2l:file_load('map', path)
	if not buf then
		return
	end
	
	local new_slk = buf:gsub('(")(%C*)(%.[mM][dD][lLxX]")', function(str1, name, str2)
		if encrypt_model(name) then
			return str1 .. encrypt_name(name) .. str2
		end
	end)
	
	w2l:file_save('map', path, new_slk)
end

local function encrypt_others()
	encrypt_slk 'units\\abilitysounds.slk'
	encrypt_txt 'units\\aieditordata.txt'
	encrypt_slk 'units\\ambiencesounds.slk'
	encrypt_slk 'units\\animlookups.slk'
	encrypt_slk 'units\\animsounds.slk'
	encrypt_txt 'units\\chathelp-war3-dede.txt'
	encrypt_txt 'units\\chathelp-war3-enus.txt'
	encrypt_slk 'units\\clifftypes.slk'
	encrypt_txt 'units\\commandfunc.txt'
	encrypt_txt 'units\\commandstrings.txt'
	encrypt_txt 'units\\config.txt'
	encrypt_txt 'units\\customkeyinfo.txt'
	encrypt_txt 'units\\customkeyssample.txt'
	encrypt_txt 'units\\d2xtrailercaptions.txt'
	encrypt_slk 'units\\dialogsounds.slk'
	encrypt_txt 'units\\directx end user eula.txt'
	encrypt_slk 'units\\eaxdefs.slk'
	encrypt_slk 'units\\environmentsounds.slk'
	encrypt_txt 'units\\eula.txt'
	encrypt_txt 'units\\ghostcaptions.txt'
	encrypt_txt 'units\\helpstrings.txt'
	encrypt_txt 'units\\humaned.txt'
	encrypt_txt 'units\\humanop.txt'
	encrypt_txt 'units\\iconindex_bel.txt'
	encrypt_txt 'units\\iconindex_def.txt'
	encrypt_txt 'units\\iconindex_def2.txt'
	encrypt_txt 'units\\introx.txt'
	encrypt_txt 'units\\license.txt'
	encrypt_slk 'units\\lightningdata.slk'
	encrypt_txt 'units\\local.txt'
	encrypt_txt 'units\\machelpstrings.txt'
	encrypt_txt 'units\\macstrings.txt'
	encrypt_txt 'units\\macworldeditstrings.txt'
	encrypt_slk 'units\\midisounds.slk'
	encrypt_txt 'units\\newaccount-dede.txt'
	encrypt_txt 'units\\newaccount-enus.txt'
	encrypt_txt 'units\\nightelfed.txt'
	encrypt_slk 'units\\notused_unitdata.slk'
	encrypt_slk 'units\\notused_unitui.slk'
	encrypt_slk 'units\\old_unitcombatsounds.slk'
	encrypt_txt 'units\\orced.txt'
	encrypt_txt 'units\\outrox.txt'
	encrypt_txt 'units\\patch.txt'
	encrypt_slk 'units\\portraitanims.slk'
	encrypt_slk 'units\\spawndata.slk'
	encrypt_slk 'units\\splatdata.slk'
	encrypt_txt 'units\\startupstrings.txt'
	encrypt_slk 'units\\t_spawndata.slk'
	encrypt_slk 'units\\t_splatdata.slk'
	encrypt_txt 'units\\telemetry.txt'
	encrypt_txt 'units\\termsofservice-dede.txt'
	encrypt_txt 'units\\termsofservice-enus.txt'
	encrypt_slk 'units\\terrain.slk'
	encrypt_txt 'units\\textures.txt'
	encrypt_txt 'units\\tipstrings.txt'
	encrypt_txt 'units\\tutorialin.txt'
	encrypt_txt 'units\\tutorialop.txt'
	encrypt_slk 'units\\ubersplatdata.slk'
	encrypt_slk 'units\\uisounds.slk'
	encrypt_txt 'units\\undeaded.txt'
	encrypt_slk 'units\\unitacksounds.slk'
	encrypt_slk 'units\\unitcombatsounds.slk'
	encrypt_txt 'units\\uniteditordata.txt'
	encrypt_txt 'units\\unitglobalstrings.txt'
	encrypt_txt 'units\\war3mapextra.txt'
	encrypt_txt 'units\\war3mapskin.txt'
	encrypt_txt 'units\\war3skins.txt'
	encrypt_txt 'units\\war3x.txt'
	encrypt_slk 'units\\water.slk'
	encrypt_slk 'units\\weather.slk'
	encrypt_txt 'units\\wowtrailercaptions.txt'
end

function mt:on_complete_data(w2l_)
	w2l = w2l_
	if w2l.config.mode ~= 'slk' then
		return
	end
	encrypt_jasses()
	encrypt_luas()
	encrypt_objs()
	encrypt_others()
	rename_files()
end

return mt
