-- HelperFunctions.lua
local AutocompleteHelper = {}

function AutocompleteHelper.isModuleScript(instance: Instance): boolean
	return instance.ClassName == "ModuleScript" and not instance:IsDescendantOf(game.CoreGui)
end

function AutocompleteHelper.isService(instance: Instance): boolean
	local service 
	
	local success, err = pcall(function()
		service = game:FindService(instance.ClassName)
	end)
	
	if success then
		return true
	else 
		return false
	end
end

function AutocompleteHelper.getServiceForModule(module: Instance): string?
	for _, service in pairs(game:GetChildren()) do
		if module:IsDescendantOf(service) then
			return tostring(service)
		end
	end
	return nil
end

function AutocompleteHelper.getModuleFullNamePath(module: Instance): string
	return module:GetFullName()
end

function AutocompleteHelper.shouldProcessName(name: string): boolean
	return name:match("[%w]+") == name and name:match("%d") == nil
end

function AutocompleteHelper.getModuleInitializationString(moduleService: string, moduleName: string, path: string, document: ScriptDocument): string
	local serviceAbstraction = string.format('local %s = game:GetService("%s")', moduleService, moduleService)
	local moduleAbstraction = string.format('local %s = require(%s)', moduleName, path)

	for i = 1, document:GetLineCount() do
		local lineString = document:GetLine(i)
		if lineString:match("local " .. moduleService) then
			return moduleAbstraction
		end
	end

	return serviceAbstraction .. "\n" .. moduleAbstraction
end

function AutocompleteHelper.getServiceInitializationString(serviceName: string): string
	return string.format('local %s = game:GetService("%s")', serviceName, serviceName)
end

return AutocompleteHelper
