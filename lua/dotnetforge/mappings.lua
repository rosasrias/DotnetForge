-- lua/dotnetforge/mappings.lua

local M = {}

function M.setup(buf)
  local opts = {
    buffer = buf,
    silent = true,
  }

  vim.keymap.set(
    "n",
    "q",
    function()
      require("dotnetforge.ui").close()
    end,
    opts
  )

  vim.keymap.set(
    "n",
    "<Esc>",
    function()
      require("dotnetforge.ui").close()
    end,
    opts
  )
end

return M
