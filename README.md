# dotnetforge.nvim

Asistente para crear proyectos **C# / .NET** dentro de Neovim, con interfaz estilo IntelliJ IDEA sobre [volt](https://github.com/smartpenter/volt).
Clon hermano de `javaforge.nvim` adaptado a .NET — **usa NuGet, no Maven** — con 18 plantillas `dotnet new` completas.

Incluye wizard de proyectos y popup *New C# Class*.

---

## Wizard (`DotnetForge` / `DotnetNewProject`)

- **Campos inteligentes**: Name, Location, Namespace, Framework (`net8.0` / `net9.0` / `net10.0` + `-windows` para WPF/WinForms). Namespace derivado a PascalCase con sync bidireccional.
- **Ubicación**: picker con historial `dotnetforge_locations`.
- **SDK**: `dotnet --list-sdks` + `DOTNET_ROOT` + PATH + `C:\Program Files\dotnet\sdk` | `lua/dotnetforge/utils.lua:48`
- **TFM**: `<TargetFramework>` + imagen Docker `mcr.microsoft.com/dotnet/sdk:8.0` → `aspnet:8.0`.

### Plantillas (18) — `lua/dotnetforge/catalog.lua`

| Grupo | Plantilla | `dotnet new` | Genera (NuGet) |
|-------|-----------|--------------|----------------|
| 🖥️ General | **Console App** | `console` | `Microsoft.NET.Sdk` + `Program.cs` |
|  | **Class Library** | `classlib` | `Class1.cs` |
|  | **Worker Service** | `worker` | `Microsoft.Extensions.Hosting` + `Worker.cs` |
| 🌐 ASP.NET Core | **Web API** | `webapi` | `Microsoft.NET.Sdk.Web` + `Swashbuckle.AspNetCore` (chips EF Core/Swagger/Auth) |
|  | **MVC** | `mvc` | `Controllers/HomeController.cs` + `Views/Home/Index.cshtml` |
|  | **Razor Pages** | `webapp` | `Pages/Index.cshtml` |
|  | **Blazor** | `blazor` | `Components/App.razor` |
|  | **Blazor WASM** | `blazorwasm` | `Microsoft.NET.Sdk.BlazorWebAssembly` |
|  | **Empty Web** | `web` | `MapGet("/")` mínimo |
| 🔌 Servicios | **gRPC Service** | `grpc` | `Grpc.AspNetCore` + `Protos/greet.proto` |
| 🖼️ Desktop | **WPF App** | `wpf` | `<UseWPF>true</UseWPF>` + `App.xaml/MainWindow.xaml` |
|  | **WPF Library** | `wpflib` | `<UseWPF>true</UseWPF>` |
|  | **WinForms App** | `winforms` | `<UseWindowsForms>true</UseWindowsForms>` + `Form1.cs` |
|  | **WinForms Library** | `winformslib` | `<UseWindowsForms>true</UseWindowsForms>` |
| 🧪 Testing | **xUnit** | `xunit` | `xunit`, `Microsoft.NET.Test.Sdk`, `coverlet.collector` |
|  | **NUnit** | `nunit` | `NUnit`, `NUnit3TestAdapter` |
|  | **MSTest** | `mstest` | `MSTest.TestFramework` |
| 📦 Solución | **Solution** | `sln` | `.sln` blank |

> Todas usan `<RootNamespace>` = Namespace del wizard y `<ImplicitUsings>enable</ImplicitUsings>` + `<Nullable>enable</Nullable>`.

En Web API los **chips** `EF Core / Swagger / Auth` añaden `PackageReference` NuGet correspondientes (`lua/dotnetforge/generators/webapi.lua:5`).

### Features

| Feature | Acción |
|---------|--------|
| Create Git repository | `git init` + `.gitignore` (`bin/ obj/ .vs/`) |
| Add sample code | Código real por plantilla (ver tabla) |
| Add tests (NuGet) | Stub `[Fact]/[Test]/[TestMethod]` |
| Add .editorconfig & .gitattributes | Meta |
| **Multi-project (Core/App) + .sln** | `src/Core/Core.csproj` + `src/App/App.csproj` + `ProjectReference` + `.sln` (`lua/dotnetforge/generators/multiproject.lua`) |
| Add Dockerfile & docker-compose | `sdk:8.0 → aspnet:8.0` + `dotnet publish` (solo webs) |

Sidebar agrupa plantillas por categoría con iconos ( `🖥️ General | 🌐 ASP.NET Core | 🔌 Servicios | 🖼️ Desktop | 🧪 Testing | 📦 Solución` ) — `lua/dotnetforge/ui/views/new_project.lua:45`.

### New C# Class (`DotnetForgeNew`)

11 tipos: `class/interface/record/enum/struct/exception` + `entity/controller/service/repository/worker` — namespace autodetectado vía `<RootNamespace>` + sufijos (`UserController.cs`).

### Delete (`DotnetForgeDelete`)

Busca `*.cs` en raíces `*.csproj/ *.sln`, lista `namespace.clase [root]`, borra tests asociados.

---

## Requisitos

| Requisito | Obligatorio |
|-----------|-------------|
| Neovim >=0.10 | Sí |
| [volt](https://github.com/smartpenter/volt) | Sí |
| .NET SDK 8/9 | Para compilar |
| git | Opcional |

> Plugin genera sin necesidad de `dotnet` instalado.

## Instalación (lazy.nvim)

```lua
{
  "tu-usuario/dotnetforge.nvim",
  dependencies = { "smartpenter/volt" },
  opts = {
    project = {
      default_location = "~/code",
      default_namespace = "MyApp",
      default_framework = "net8.0",
      default_template = "console",
    },
    git = { enabled = true },
  },
}
```

## Uso

```vim
:DotnetForge              " wizard (alias :DotnetNewProject, :CSharpForge)
:DotnetForgeNew           " popup clase
:DotnetForgeNew entity
:DotnetForgeNewNamespace
:DotnetForgeDelete
:DotnetProjectInfo
:DotnetForgeClose
```

## ¿Qué necesita .NET vs Java?

- **SDK**: `dotnet --list-sdks` → TFM `net8.0/9.0/10.0` (`<TargetFramework>`). No `pom.xml`.
- **NuGet**: `PackageReference` en `.csproj` (no `<dependency>` Maven). Cada plantilla declara sus paquetes (gRPC, xUnit, etc.).
- **Templates**: mapean 1:1 a `dotnet new` (`console`, `classlib`, `webapi`, `mvc`, `wpf`, `xunit`, `sln`…).
- **Sln**: análogo a `multi-module` Maven — `.sln` + `ProjectReference`.
- **Desktop**: requiere `-windows` TFM (`UseWPF`/`UseWindowsForms`).
- **Testing**: NuGet `Microsoft.NET.Test.Sdk` + framework (`xunit` vs `NUnit` vs `MSTest`).

## Estructura

```
lua/dotnetforge/
  catalog.lua              catálogo 18 plantillas agrupadas
  init.lua                 comandos :DotnetForge*
  state.lua                estado + default_template
  utils.lua                detect_sdks() + recents
  health.lua               checkhealth dotnetforge
  core/{detector,project,validator,scaffold}
  generators/{console,webapi,wpf,dotnet_templates,multiproject,docker,extras}
  ui/{window,input,actions,components,highlights,views/new_project}
  scaffold/{kinds,templates,ui,ui_delete}
tests/run.lua
```

## Licencia

MIT
