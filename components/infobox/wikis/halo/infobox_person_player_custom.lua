---
-- @Liquipedia
-- wiki=halo
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local GameAppearances = require('Module:GetGameAppearances')
local Lua = require('Module:Lua')
local Region = require('Module:Region')
local Role = require('Module:Role')
local PlayerTeamAuto = require('Module:PlayerTeamAuto')
local String = require('Module:StringUtils')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local _pagename = mw.title.getCurrentTitle().prefixedText
local _role
local _role2
local _EMPTY_AUTO_HISTORY = '<table style="width:100%;text-align:left"></table>'

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomPlayer.run(frame)
	local player = Player(frame)

	if String.isEmpty(player.args.team) then
		player.args.team = PlayerTeamAuto._main{team = 'team'}
	end

	if String.isEmpty(player.args.team2) then
		player.args.team2 = PlayerTeamAuto._main{team = 'team2'}
	end

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	_args = player.args

	return player:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'history' then
		local manualHistory = _args.history
		local automatedHistory = TeamHistoryAuto._results({
			convertrole = 'true',
			player = _pagename
		}) or ''
		automatedHistory = tostring(automatedHistory)
		if automatedHistory == _EMPTY_AUTO_HISTORY then
			automatedHistory = nil
		end

		if not (String.isEmpty(manualHistory) and String.isEmpty(automatedHistory)) then
			return {
				Title{name = 'History'},
				Center{content = {manualHistory}},
				Center{content = {automatedHistory}},
			}
		end
	elseif id == 'region' then return {}
	elseif id == 'role' then
		_role = Role.run({role = _args.role})
		_role2 = Role.run({role = _args.role2})
		return {
			Cell{name = 'Role(s)', content = {_role.display, _role2.display}}
		}
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	return {
		Cell{
			name = 'Game Appearances',
			content = GameAppearances.player({ player = _pagename })
		},
	}
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData)
	lpdbData.extradata.isplayer = _role.isPlayer or 'true'
	lpdbData.extradata.role = _role.role
	lpdbData.extradata.role2 = _role2.role

	local region = Region.run({region = _args.region, country = _args.country})
	if type(region) == 'table' then
		lpdbData.region = region.region
	end

	return lpdbData
end

return CustomPlayer
