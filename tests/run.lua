-- tests/run.lua for dotnetforge
local failures = 0
local function ok(cond, msg)
  if cond then print("[PASS] " .. msg) else print("[FAIL] " .. msg) failures = failures + 1 end
end
local function eq(a,b,msg) ok(a==b, msg .. string.format(" (esperado=%s obtenido=%s)", tostring(b), tostring(a))) end
local function isdir(p) return vim.fn.isdirectory(p)==1 end

local mods = {
  "dotnetforge","dotnetforge.state","dotnetforge.utils","dotnetforge.mappings","dotnetforge.ui","dotnetforge.ui.window","dotnetforge.ui.input","dotnetforge.ui.actions","dotnetforge.ui.views.new_project","dotnetforge.ui.highlights","dotnetforge.ui.components","dotnetforge.core.detector","dotnetforge.core.project","dotnetforge.core.validator","dotnetforge.generators","dotnetforge.generators.console","dotnetforge.generators.webapi","dotnetforge.generators.wpf","dotnetforge.generators.docker","dotnetforge.health",
}
for _, m in ipairs(mods) do
  local loaded, err = pcall(require, m)
  ok(loaded, "carga modulo " .. m .. (loaded and "" or (" -> " .. tostring(err))))
end

local tmp = vim.fs.joinpath(vim.uv.os_tmpdir(), "opencode", "df_test_" .. os.time())
local utils = require("dotnetforge.utils")
local console_gen = require("dotnetforge.generators.console")
local webapi_gen = require("dotnetforge.generators.webapi")
utils.recents_path = vim.fs.joinpath(tmp, "recents.txt")

local function mkproject(opts)
  opts = opts or {}
  return {
    name = opts.name or "Demo",
    location = tmp,
    namespace = opts.namespace or "Demo",
    framework = opts.framework or "net8.0",
    template = opts.template or "console",
    webapi = opts.webapi or { efcore=false, swagger=true, auth=false },
    features = {
      git = opts.git == true,
      sample_code = opts.sample_code ~= false,
      tests = opts.tests ~= false,
      meta_files = opts.meta_files == true,
      multi_project = opts.multi_project == true,
      docker = opts.docker == true,
    },
  }
end

utils.ensure_dir(tmp)

-- console generate
local root_c = vim.fs.joinpath(tmp, "console")
eq(console_gen.generate(mkproject({}), root_c), true, "console.generate ok")
ok(isdir(root_c), "console crea dir")
eq(vim.fn.filereadable(vim.fs.joinpath(root_c, "Demo.csproj")), 1, "console escribe csproj")
local csproj = utils.read_file(vim.fs.joinpath(root_c, "Demo.csproj")) or ""
ok(csproj:find("<TargetFramework>net8.0</TargetFramework>") ~= nil, "csproj contiene TFM")
ok(csproj:find("<RootNamespace>Demo</RootNamespace>") ~= nil, "csproj RootNamespace")

-- webapi generate
local root_w = vim.fs.joinpath(tmp, "webapi")
local pw = mkproject({ template="webapi", webapi={ swagger=true, efcore=true } })
webapi_gen.generate(pw, root_w)
eq(vim.fn.filereadable(vim.fs.joinpath(root_w, "Demo.csproj")), 1, "webapi escribe csproj")
local wcs = utils.read_file(vim.fs.joinpath(root_w, "Demo.csproj")) or ""
ok(wcs:find("Swashbuckle") ~= nil, "webapi incluye Swagger")
ok(wcs:find("EntityFrameworkCore") ~= nil, "webapi incluye EFCore")
eq(vim.fn.filereadable(vim.fs.joinpath(root_w, "Program.cs")), 1, "webapi Program.cs")
eq(vim.fn.filereadable(vim.fs.joinpath(root_w, "appsettings.json")), 1, "webapi appsettings.json")

-- validator
local validator = require("dotnetforge.core.validator")
local valid_empty = validator.validate_project({ name="", location="", namespace="", framework="net8.0", template="console" })
ok(valid_empty == false, "validator rechaza vacio")
local valid_ok = validator.validate_project({ name="MyApp", location="/tmp", namespace="MyApp", framework="net8.0", template="console" })
ok(valid_ok == true, "validator acepta proyecto valido")
local valid_sln = validator.validate_project({ name="MySln", location="/tmp", namespace="", framework="", template="sln" })
ok(valid_sln == true, "validator acepta sln sin namespace")

-- multiproject
local mp = require("dotnetforge.generators.multiproject")
local root_mp = vim.fs.joinpath(tmp, "mp")
local pmp = mkproject({ template="console", multi_project=true })
pmp.name = "MultiDemo"
pmp.namespace = "MultiDemo"
eq(mp.generate(pmp, root_mp), true, "multiproject generate ok")
ok(vim.fn.filereadable(vim.fs.joinpath(root_mp, "MultiDemo.sln"))==1, "multiproject sln")
ok(vim.fn.filereadable(vim.fs.joinpath(root_mp, "src/Core/Core.csproj"))==1, "multiproject Core csproj")
ok(vim.fn.filereadable(vim.fs.joinpath(root_mp, "src/App/App.csproj"))==1, "multiproject App csproj")

-- scaffold
local scaffold = require("dotnetforge.core.scaffold")
local kinds = require("dotnetforge.scaffold.kinds")
ok(kinds.is_valid("class"), "kinds valid")
local templ = require("dotnetforge.scaffold.templates")
local content = templ.render("class", "Demo", "MyClass", {})
ok(content:find("class MyClass") ~= nil, "template class")

-- state sync
local st = require("dotnetforge.state")
st.setup({})
st.reset()
st.update({ name="My App" })
require("dotnetforge.ui.actions").sync_defaults()
eq(st.get().namespace, "MyApp", "namespace deriva de name")

-- health
local health = require("dotnetforge.health")
ok(type(health.check)=="function", "health.check existe")
local h_ok = pcall(health.check)
ok(h_ok, "health check no falla")

if failures>0 then print(string.format("%d fallos", failures)) vim.cmd("cquit 1") else print("Todo ok") vim.cmd("qall!") end
