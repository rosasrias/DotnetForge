local M = {}

function M.setup(opts)
	require("dotnetforge.state").setup(opts)
end
function M.open()
	require("dotnetforge.ui").open()
end
function M.close()
	require("dotnetforge.ui").close()
end

vim.api.nvim_create_user_command("DotnetForge", function()
	M.open()
end, { desc = "DotnetForge: abrir el asistente de proyectos" })
vim.api.nvim_create_user_command("DotnetNewProject", function()
	M.open()
end, { desc = "DotnetForge: crear un proyecto nuevo" })
vim.api.nvim_create_user_command("CSharpForge", function()
	M.open()
end, { desc = "DotnetForge alias" })
vim.api.nvim_create_user_command("DotnetForgeClose", function()
	M.close()
end, { desc = "DotnetForge: cerrar el asistente" })

vim.api.nvim_create_user_command("DotnetProjectInfo", function()
	local detector = require("dotnetforge.core.detector")
	local project = detector.detect()
	if not project then
		vim.notify("DotnetForge: no se encontró un proyecto .NET", vim.log.levels.WARN)
		return
	end
	vim.notify(
		table.concat({
			"DotnetForge: " .. (project.name or "?"),
			"Build: " .. (project.build_tool or "dotnet"),
			"Main: " .. (project.main_class or "sin main"),
			"Framework: " .. (project.framework or "?"),
			"Namespace: " .. (project.namespace or "?"),
		}, "\n"),
		vim.log.levels.INFO
	)
end, { desc = "DotnetForge: información del proyecto actual" })

local SCAFFOLD_KINDS = require("dotnetforge.scaffold.kinds")

vim.api.nvim_create_user_command("DotnetForgeNew", function(cmd_opts)
	require("dotnetforge.scaffold.ui").open({ kind = cmd_opts.args ~= "" and cmd_opts.args or nil })
end, {
	desc = "DotnetForge: nueva clase/interface/enum/...",
	nargs = "?",
	complete = function()
		return vim.tbl_keys(SCAFFOLD_KINDS.BY_KEY)
	end,
})

vim.api.nvim_create_user_command("DotnetForgeNewNamespace", function()
	local scaffold_ui = require("dotnetforge.scaffold.ui")
	if scaffold_ui.is_open() then
		vim.notify("DotnetForge: cierra la ventana abierta primero", vim.log.levels.WARN)
		return
	end
	local core_sc = require("dotnetforge.core.scaffold")
	vim.ui.input({ prompt = "Namespace a crear (ej: MyApp.Core): " }, function(pkg)
		if not pkg or pkg == "" then
			return
		end
		local cur = vim.api.nvim_buf_get_name(0)
		local start = cur ~= "" and vim.fs.dirname(cur) or vim.fn.getcwd()
		local roots = core_sc.find_roots(start)
		if #roots == 0 then
			vim.notify("DotnetForge: no encontre proyecto .NET", vim.log.levels.ERROR)
			return
		end
		local root = roots[1]
		if #roots > 1 then
			vim.ui.select(roots, { prompt = "Raiz destino:" }, function(choice)
				if choice then
					core_sc.create_package({ pkg = pkg, root = choice })
					vim.notify("DotnetForge: namespace creado en " .. choice, vim.log.levels.INFO)
				end
			end)
			return
		end
		core_sc.create_package({ pkg = pkg, root = root })
		vim.notify("DotnetForge: namespace creado en " .. root, vim.log.levels.INFO)
	end)
end, { desc = "DotnetForge: crear namespace" })

vim.api.nvim_create_user_command("DotnetForgeDelete", function(cmd_opts)
	require("dotnetforge.scaffold.ui_delete").open({ name = cmd_opts.args ~= "" and cmd_opts.args or nil })
end, {
	desc = "DotnetForge: eliminar clase",
	nargs = "?",
	complete = function(arglead)
		local sc = require("dotnetforge.core.scaffold")
		local cur = vim.api.nvim_buf_get_name(0)
		local start = cur ~= "" and vim.fs.dirname(cur) or vim.fn.getcwd()
		local seen = {}
		local out = {}
		for _, root in ipairs(sc.find_roots(start)) do
			for _, p in ipairs(vim.fn.globpath(root, "**/*.cs", false, true)) do
				local base = vim.fn.fnamemodify(p, ":t:r")
				if not seen[base] then
					seen[base] = true
					if arglead == "" or base:lower():find(arglead:lower(), 1, true) then
						out[#out + 1] = base
					end
				end
			end
		end
		table.sort(out)
		return out
	end,
})

-- aliases for java compatibility
vim.api.nvim_create_user_command("DotnetForgeNewPackage", function()
	vim.cmd("DotnetForgeNewNamespace")
end, { desc = "Alias" })

return M
