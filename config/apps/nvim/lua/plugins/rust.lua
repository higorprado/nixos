-- Rust IDE support via rustaceanvim.
-- Only active when rust-analyzer, cargo, and rustc are all in PATH (Nix devshell/cargo).
-- DAP: prefers lldb-dap from Nix; falls back to codelldb if available.
return {
  {
    "mrcjkb/rustaceanvim",
    enabled = function()
      return vim.fn.executable("rust-analyzer") == 1 and vim.fn.executable("cargo") == 1 and vim.fn.executable("rustc") == 1
    end,
    config = function(_, opts)
      opts = opts or {}

      -- Prefer lldb-dap from Nix (stable on NixOS). Fallback to codelldb if available.
      local lldb_dap = vim.fn.exepath("lldb-dap")
      if lldb_dap ~= "" then
        opts.dap = {
          adapter = {
            type = "executable",
            command = lldb_dap,
            name = "lldb",
          },
        }
      else
        local codelldb = vim.fn.exepath("codelldb")
        if codelldb ~= "" then
          local ext = (vim.uv or vim.loop).os_uname().sysname == "Darwin" and ".dylib" or ".so"
          local candidates = {
            vim.fs.dirname(codelldb) .. "/../lib/liblldb" .. ext,
            vim.fs.dirname(codelldb) .. "/liblldb" .. ext,
          }
          if vim.env.MASON and vim.env.MASON ~= "" then
            table.insert(candidates, vim.env.MASON .. "/opt/lldb/lib/liblldb" .. ext)
          end
          local library_path
          for _, path in ipairs(candidates) do
            if vim.fn.filereadable(path) == 1 then
              library_path = path
              break
            end
          end
          if library_path then
            opts.dap = {
              adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb, library_path),
            }
          end
        end
      end

      vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
    end,
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      local ok = pcall(require, "rustaceanvim.neotest")
      if not ok then
        opts.adapters["rustaceanvim.neotest"] = false
      end
    end,
  },
}
