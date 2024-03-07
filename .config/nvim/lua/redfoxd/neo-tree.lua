local M = {
  "nvim-neo-tree/neo-tree.nvim",
  event = "VimEnter",
  dependencies = { "MunifTanjim/nui.nvim" },
  cmd = "Neotree",
}

function M.config()
  require("neo-tree").setup({
    auto_clean_after_session_restore = true,
    sources = { "filesystem", "buffers", "git_status", "document_symbols" },
    open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
    event_handlers = {
      {
        event = "neo_tree_buffer_enter",
        handler = function(_) vim.opt_local.signcolumn = "auto" end,
      },
    },
    default_component_configs = {
      indent = {
        with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
        expander_collapsed = "",
        expander_expanded = "",
        expander_highlight = "NeoTreeExpander",
      },
    },
    -- see `:h neo-tree-custom-commands-global`
    commands = {
      copy_selector = function(state)
          local node = state.tree:get_node()
          local filepath = node:get_id()
          local filename = node.name
          local modify = vim.fn.fnamemodify

          local vals = {
            ["BASENAME"] = modify(filename, ":r"),
            ["EXTENSION"] = modify(filename, ":e"),
            ["FILENAME"] = filename,
            ["PATH (CWD)"] = modify(filepath, ":."),
            ["PATH (HOME)"] = modify(filepath, ":~"),
            ["PATH"] = filepath,
            ["URI"] = vim.uri_from_fname(filepath),
          }

          local options = vim.tbl_filter(function(val) return vals[val] ~= "" end, vim.tbl_keys(vals))
          if vim.tbl_isempty(options) then
            return
          end
          table.sort(options)
          vim.ui.select(options, {
            prompt = "Choose to copy to clipboard:",
            format_item = function(item) return ("%s: %s"):format(item, vals[item]) end,
          }, function(choice)
            local result = vals[choice]
            if result then
              vim.fn.setreg("+", result)
            end
          end)
      end,
      find_in_dir = function(state)
          local node = state.tree:get_node()
          local path = node:get_id()
          require("telescope.builtin").live_grep {
            cwd = node.type == "directory" and path or vim.fn.fnamemodify(path, ":h"),
          }
      end,
    }, -- A list of functions
    window = { -- see https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup for
      -- possible options. These can also be functions that return these options.

      mappings = {
        ["<space>"] = false,
        ["Y"] = "copy_selector",
        ["F"] = "find_in_dir",
        ["o"] = 'open',
        ["oc"] = false,
        ["od"] = false,
        ["og"] = false,
        ["om"] = false,
        ["on"] = false,
        ["os"] = false,
        ["ot"] = false,
      },
      fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
        ["<C-j>"] = "move_cursor_down",
        ["<C-k>"] = "move_cursor_up",
      },
    },
    filesystem = {
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = true,
      },
      follow_current_file = {
        enabled = true, -- This will find and focus the file in the active buffer every time
      },
      use_libuv_file_watcher = true, -- This will use the OS level file watchers to detect changes
      -- instead of relying on nvim autocmd events.
    },
  })
end

return M
