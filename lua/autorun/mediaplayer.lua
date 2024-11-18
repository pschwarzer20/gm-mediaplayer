local basepath = "mediaplayer/"

local function IncludeMP( filepath )
	include( basepath .. filepath )
end

local function PreLoadMediaPlayer()
	-- Check if MediaPlayer has already been loaded
	if MediaPlayer then
		MediaPlayer.__refresh = true

		-- HACK: Lua refresh fix; access local variable of baseclass lib
		local _, BaseClassTable = debug.getupvalue(baseclass.Get, 1)
		for classname, _ in pairs(BaseClassTable) do
			if classname:find("mp_") then
				BaseClassTable[classname] = nil
			end
		end
	end
end

local function PostLoadMediaPlayer()
	if SERVER then
		-- Reinstall media players on Lua refresh
		for _, mp in pairs(MediaPlayer.GetAll()) do
			if mp:GetType() == "entity" and IsValid(mp) then
				local ent = mp:GetEntity()
				local snapshot = mp:GetSnapshot()
				local listeners = table.Copy(mp:GetListeners())

				-- remove media player
				mp:Remove()

				-- install new media player
				ent:InstallMediaPlayer()

				-- restore settings
				mp = ent._mp
				mp:RestoreSnapshot( snapshot )
				mp:SetListeners( listeners )
			end
		end
	end
end

local function LoadMediaPlayer()
	PreLoadMediaPlayer()

	-- shared includes
	IncludeCS "includes/extensions/sh_url.lua"
	IncludeCS "includes/modules/EventEmitter.lua"

	if SERVER then
		-- Add mediaplayer models
		resource.AddWorkshop( "546392647" )

		-- download clientside includes
		AddCSLuaFile "includes/modules/browserpool.lua"
		AddCSLuaFile "includes/modules/inputhook.lua"
		AddCSLuaFile "includes/modules/htmlmaterial.lua"
		AddCSLuaFile "includes/modules/spritesheet.lua"

		-- initialize serverside mediaplayer
		IncludeMP "init.lua"
	else
		-- clientside includes
		include "includes/modules/browserpool.lua"
		include "includes/modules/inputhook.lua"
		include "includes/modules/htmlmaterial.lua"
		include "includes/modules/spritesheet.lua"

		-- initialize clientside mediaplayer
		IncludeMP "cl_init.lua"
	end

	--
	-- Media Player menu includes; remove these if you would rather not include
	-- the sidebar menu.
	--
	if SERVER then
		AddCSLuaFile "mp_menu/cl_init.lua"
		include "mp_menu/init.lua"
	else
		include "mp_menu/cl_init.lua"
	end

	PostLoadMediaPlayer()
end

-- First time load
LoadMediaPlayer()
