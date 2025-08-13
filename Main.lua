local CheemsScripts = {
	{
		PlacesIds = {2753915549, 4442272183, 7449423635},
		UrlPath = "BloxFruits.luau"
	},
	{
		PlacesIds = {10260193230},
		UrlPath = "MemeSea.luau"
	},
}

local cheemsFetcher, cheemsUrls = {}, {}

local _ENV = (getgenv or getrenv or getfenv)()

cheemsUrls.Owner = "https://raw.githubusercontent.com/cheemshub/"
cheemsUrls.Repository = cheemsUrls.Owner .. "Scripts/refs/heads/main/"
cheemsUrls.Translator = cheemsUrls.Repository .. "Translator/"
cheemsUrls.Utils = cheemsUrls.Repository .. "Utils/"

do
	local last_exec = _ENV.cheems_execute_debounce
	if last_exec and (tick() - last_exec) <= 5 then
		return nil
	end
	_ENV.cheems_execute_debounce = tick()
end

do
	local executor = syn or fluxus
	local queueteleport = queue_on_teleport or (executor and executor.queue_on_teleport)

	if not _ENV.cheems_added_teleport_queue and type(queueteleport) == "function" then
		local ScriptSettings = {...}
		local SettingsCode = ""

		_ENV.cheems_added_teleport_queue = true

		local Success, EncodedSettings = pcall(function()
			return game:GetService("HttpService"):JSONEncode(ScriptSettings)
		end)

		if Success and EncodedSettings then
			SettingsCode = "unpack(game:GetService('HttpService'):JSONDecode('" .. EncodedSettings .. "'))"
		end

		pcall(queueteleport, ("loadstring(game:HttpGet('%smain.luau'))(%s)"):format(cheemsUrls.Repository, SettingsCode))
	end
end

do
	if _ENV.cheems_error_message then
		_ENV.cheems_error_message:Destroy()
	end

	local identifyexecutor = identifyexecutor or (function() return "Unknown" end)

	local function CreateMessageError(Text)
		_ENV.loadedFarm = nil
		_ENV.OnFarm = false

		local Message = Instance.new("Message", workspace)
		Message.Text = string.gsub(Text, cheemsUrls.Owner, "")
		_ENV.cheems_error_message = Message

		error(Text, 2)
	end

	local function formatUrl(Url)
		for key, path in cheemsUrls do
			if Url:find("{" .. key .. "}") then
				return select(1, Url:gsub("{" .. key .. "}", path))
			end
		end
		return Url
	end

	function cheemsFetcher.get(Url)
		local success, response = pcall(function()
			return game:HttpGet(formatUrl(Url))
		end)

		if success then
			return response
		else
			CreateMessageError(`[1] [{ identifyexecutor() }] failed to get http/url/raw: { Url }\n>>{ response }<<`)
		end
	end

	function cheemsFetcher.load(Url: string, concat: string?)
		local raw = cheemsFetcher.get(Url) .. (if concat then concat else "")
		local runFunction, errorText = loadstring(raw)

		if type(runFunction) ~= "function" then
			CreateMessageError(`[2] [{ identifyexecutor() }] sintax error: { Url }\n>>{ errorText }<<`)
		else
			return runFunction
		end
	end
end

local function IsPlace(Script)
	if Script.PlacesIds and table.find(Script.PlacesIds, game.PlaceId) then
		return true
	elseif Script.GameId and Script.GameId == game.GameId then
		return true
	end
end

for _, Script in CheemsScripts do
	if IsPlace(Script) then
		return cheemsFetcher.load("{Repository}Games/" .. Script.UrlPath)(cheemsFetcher, ...)
	end
end
