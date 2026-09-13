-- lua/dotnetforge/generators/init.lua
-- Dispatcher con catálogo completo (NuGet, no Maven)

local M = {}
local catalog = require("dotnetforge.catalog")
local dotnet_templates = require("dotnetforge.generators.dotnet_templates")

function M.generate(project, root)
  if not catalog.is_valid(project.template) then
    return dotnet_templates.generate(project, root)
  end
  -- Casos que tienen generador dedicado legacy
  if project.template == "webapi" then
    return require("dotnetforge.generators.webapi").generate(project, root)
  end
  if project.template == "wpf" then
    return require("dotnetforge.generators.wpf").generate(project, root)
  end
  if project.template == "console" then
    return require("dotnetforge.generators.console").generate(project, root)
  end
  -- Resto vía dotnet_templates genérico
  return dotnet_templates.generate(project, root)
end

return M
