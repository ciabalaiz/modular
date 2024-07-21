-- Handler.lua
--!nocheck
local ScriptEditorService = game:GetService("ScriptEditorService")
local ServerScriptService = game:GetService("ServerScriptService")

local AutocompleteHelper = require(script:WaitForChild("HelperFunctions"))
-- local WidgetHandler = require(script:WaitForChild("WidgetHandler"))
local Modules = {}
local Services = {}
local Active = false

--> Types
type Request = {
	position: {
		line: number,
		character: number,
	},
	textDocument: {
		document: ScriptDocument?,
		script: LuaSourceContainer?,
	},
}

type Response = {
	items: {
		{
			label: string,
			kind: Enum.CompletionItemKind?,
			tags: { Enum.CompletionItemTag }?,
			detail: string?,
			documentation: {
				value: string,
			}?,
			overloads: number?,
			learnMoreLink: string?,
			codeSample: string?,
			preselect: boolean?,
			textEdit: {
				newText: string,
				replace: {
					start: { line: number, character: number },
					["end"]: { line: number, character: number },
				},
			}?,
		}
	},
}

--> Functions
local function onChange(document: ScriptDocument, changesArray)
	local lineValues = document:GetLine()
	local Symbol = script.Parent.Symbol

	-- original hacky code xD
	Active = string.match(lineValues, Symbol.Value) ~= nil
end

local function onAdded(descendant: Instance)
	if not AutocompleteHelper.isModuleScript(descendant) then return end

	table.insert(Modules, descendant)
end

local function onRemoving(descendant: Instance)
	if not AutocompleteHelper.isModuleScript(descendant) then return end

	for i, module in ipairs(Modules) do
		if module == descendant then
			table.remove(Modules, i)
			break
		end
	end
end


local function getAllModulesAndServices()
	Services = {}
	Modules = {}
	
	for _, instance in ipairs(game:GetChildren()) do
		if AutocompleteHelper.isService(instance) then
			table.insert(Services, instance)
		end
	end

	for _, module in ipairs(game:GetDescendants()) do
		if AutocompleteHelper.isModuleScript(module) then
			table.insert(Modules, module)
		end
	end
end

local function autocompleteCallback(request, response)

	if not Active then 
		return response 
	end

	local replaceTemplate = nil
	
	for _, item in ipairs(response.items) do
		if item.textEdit then
			replaceTemplate = table.clone(item.textEdit.replace)
			replaceTemplate.start.character -= 1
			break
		end
	end

	if not replaceTemplate then return response end

	-- modules
	for _, module in ipairs(Modules) do
		local moduleName = tostring(module)

		if not AutocompleteHelper.shouldProcessName(moduleName) then continue end

		local moduleService = AutocompleteHelper.getServiceForModule(module)

		if not moduleService then continue end

		local path = AutocompleteHelper.getModuleFullNamePath(module)
		local finalText = AutocompleteHelper.getModuleInitializationString(moduleService, moduleName, path, request.textDocument.document)

		local item = {
			label = moduleName,
			detail = path,
			textEdit = {
				newText = finalText,
				replace = replaceTemplate
			}
		}

		table.insert(response.items, item)
	end

	-- services
	for _, service in ipairs(Services) do
		local serviceName = service.ClassName

		if not AutocompleteHelper.shouldProcessName(serviceName) then continue end

		local finalText = AutocompleteHelper.getServiceInitializationString(serviceName)

		local item = {
			label = serviceName,
			detail = "Service",
			textEdit = {
				newText = finalText,
				replace = replaceTemplate
			}
		}

		table.insert(response.items, item)
	end

	return response
end

local function createToolbar()
	-- local toolbar = plugin:CreateToolbar("AutoCompleteModules")
	-- local newButton = toolbar:CreateButton("Symbol Change", "Change the symbol used for autocomplete", "rbxassetid://11963352805")
	-- 
	-- local Widget = WidgetHandler:CreateWidget(plugin) -- module scripts dont have the plugin object so we pass dat
	-- 
	-- newButton.Click:Connect(function()
	-- 	Widget.Enabled = not Widget.Enabled 
	-- end)
	-- 
	-- Widget:BindToClose(function()
	-- 	newButton:SetActive(false)
	-- end)
end

--> Init
pcall(function()
	ScriptEditorService:DeregisterAutocompleteCallback("somenameitreallydoesntmatter")
end)

ScriptEditorService:RegisterAutocompleteCallback("somenameitreallydoesntmatter", 69, autocompleteCallback)
ScriptEditorService.TextDocumentDidChange:Connect(onChange)

game.DescendantAdded:Connect(onAdded)
game.DescendantRemoving:Connect(onRemoving)

getAllModulesAndServices()
