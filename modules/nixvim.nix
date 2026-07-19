{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.workstation.nixvim;
in
{
  imports = [
    inputs.nixvim.nixosModules.nixvim
  ];
  options.workstation.nixvim.enable =
    lib.mkEnableOption "Nvim configuration";
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ripgrep
    ];
    environment.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    programs.nixvim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      opts = {
        ignorecase = true;
        smartcase = true;
        undofile = true;
        scrolloff = 10;
        hlsearch = true;
        incsearch = true;
        showmatch = true;
        number = true;
        relativenumber = true;
        clipboard = "unnamedplus";
        tabstop = 2;
        shiftwidth = 2;
        softtabstop = 2;
        expandtab = true;
        smartindent = true;
      };
      globals = {
        mapleader = " ";
        clipboard = {
        name = "wl-clipboard";
        copy = {
          "+" = [
            "wl-copy"
            "--type"
            "text/plain"
          ];
          "*" = [
            "wl-copy"
            "--type"
            "text/plain"
          ];
        };
        paste = {
          "+" = [
            "wl-paste"
            "--no-newline"
          ];
          "*" = [
            "wl-paste"
            "--no-newline"
          ];
        };
      };
      };
      colorschemes.tokyonight.enable = true;
      plugins = {
        nix.enable = true;
        nvim-autopairs.enable = true;
        bufferline.enable = true;
        lualine = {
          enable = true;
          settings = {
            sections = {
              lualine_c = [
                "filename"
                { __raw = ''
                  function()
                    local wc = vim.fn.wordcount()
                    if wc.words and wc.words > 0 then
                      return "words " .. wc.words
                    end
                    return ""
                  end
                ''; }
              ];
            };
          };
        };
        mini = {
          enable = true;
          modules = {
            ai = { };
            pairs = { };
          };
        };
        noice.enable = true;
        web-devicons.enable = true;
        treesitter = {
          enable = true;
          settings = {
            ensure_installed = [
              "bash"
              "html"
              "javascript"
              "json"
              "lua"
              "markdown"
              "markdown_inline"
              "nix"
              "python"
              "query"
              "regex"
              "rust"
              "tsx"
              "typescript"
              "vim"
              "yaml"
            ];
          };
        };
        indent-blankline = {
          enable = true;
          settings = {
            indent = {
              char = "│";
            };
            scope = {
              show_start = false;
              show_end = false;
              show_exact_scope = true;
            };
            exclude = {
              filetypes = [
                ""
                "checkhealth"
                "help"
                "lspinfo"
                "packer"
                "TelescopePrompt"
                "TelescopeResults"
                "yaml"
              ];
              buftypes = [
                "terminal"
                "quickfix"
              ];
            };
          };
        };
        treesitter-textobjects.enable = true;
        trouble = {
          enable = true;
          settings.use_diagnostic_signs = true;
        };
        which-key.enable = true;
        lsp = {
          enable = true;
          servers = {
            pyright.enable = true;
            ts_ls.enable = true;
            jsonls.enable = true;
          };
        };
        telescope.enable = true;
        vimwiki = {
          enable = true;
          settings = {
            global_ext = 0;
            path = "~/vimwiki/";
            syntax = "markdown";
            ext = ".md";
          };
        };
      };
      extraPlugins = with pkgs.vimPlugins; [
        flash-nvim
        nui-nvim
        snacks-nvim
        ts-comments-nvim
      ];
      extraConfigLua = ''
        -- flash.nvim
        require("flash").setup({})
        -- ts-comments
        require("ts-comments").setup({})

        -- ============================================================
        --  COLEMAK-DHM KEYBINDINGS
        -- ============================================================

        -- Movement: hjkl → h n e i
        vim.keymap.set({'n', 'v'}, 'n', 'j', { noremap = true })
        vim.keymap.set({'n', 'v'}, 'e', 'k', { noremap = true })
        vim.keymap.set({'n', 'v'}, 'i', 'l', { noremap = true })
        vim.keymap.set('o', 'n', 'j', { noremap = true })
        vim.keymap.set('o', 'e', 'k', { noremap = true })
        -- intentionally no 'o' mapping for i → text objects must keep working

        -- End-of-word: k = e (original), K = E
        vim.keymap.set({'n', 'o', 'x'}, 'k',  'e',  { noremap = true })
        vim.keymap.set({'n', 'o', 'x'}, 'K',  'E',  { noremap = true })
        vim.keymap.set({'n', 'o', 'x'}, 'gk', 'ge', { noremap = true })
        vim.keymap.set({'n', 'o', 'x'}, 'gK', 'gE', { noremap = true })

        -- Search navigation: l/L = n/N
        vim.keymap.set({'n', 'o', 'x'}, 'l', 'n', { noremap = true })
        vim.keymap.set({'n', 'o', 'x'}, 'L', 'N', { noremap = true })

        -- Join lines: j = J
        vim.keymap.set('n', 'j', 'J', { noremap = true })

        -- Fast scrolling
        -- vim.keymap.set('n', 'N', '5j', { noremap = true })
        -- vim.keymap.set('n', 'E', '5k', { noremap = true })

        -- Insert mode fallback (since i is remapped to l)
        vim.keymap.set('n', '<leader>i', 'i', { noremap = true })
        vim.keymap.set('n', '<leader>I', 'I', { noremap = true })

        -- ============================================================
        --  QUALITY OF LIFE
        -- ============================================================

        -- ; as :
        vim.keymap.set('n', ';', ':', { noremap = true })

        -- tn to escape insert mode
        vim.keymap.set('i', 'tn', '<Esc>', { noremap = true })

        -- paste without yanking
        vim.keymap.set('v', 'p', '"_dP', { noremap = true })

        -- buffer navigation: Ctrl+h/l (terminal-safe, works everywhere)
        -- NOTE: <C-Tab> / <C-S-Tab> are unreliable in terminals — they send
        -- the same escape sequences as <Tab> / <S-Tab> on most terminal emulators
        vim.keymap.set('n', '<C-l>', ':bnext<CR>',    { noremap = true, silent = true, desc = 'Next buffer' })
        vim.keymap.set('n', '<C-h>', ':bprevious<CR>', { noremap = true, silent = true, desc = 'Prev buffer' })

        -- new tab with Ctrl+t
        vim.keymap.set('n', '<C-t>', ':tabnew<CR>', { noremap = true, silent = true, desc = 'New tab' })

        -- clear search highlight
        vim.keymap.set('n', '<Esc>', ':nohlsearch<CR>', { noremap = true, silent = true })

        -- centered scrolling
        vim.keymap.set('n', '<C-d>', '<C-d>zz', { noremap = true })
        vim.keymap.set('n', '<C-u>', '<C-u>zz', { noremap = true })

        -- <leader> keybindings
        vim.keymap.set("n", "<leader>ff", function() Snacks.picker.files() end, { desc = "Find files" })
        vim.keymap.set("n", "<leader>fr", function() Snacks.picker.recent() end, { desc = "Recent files" })
        vim.keymap.set("n", "<leader>fs", ":w<CR>", { desc = "Save file" })
        vim.keymap.set("n", "<leader>r", [[:%s/(\d\+\(:\d\+\)\{1,2})\s*//g]], { desc = "Strip timestamps" })

        -- move selected lines down in visual mode
        vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { noremap = true })

        -- date/time insert
        vim.keymap.set('n', '<F5>', '"=strftime(\'%Y-%m-%d\')<CR>p',          { noremap = true })
        vim.keymap.set('n', '<F6>', '"=strftime(\'%Y-%m-%d %H:%M:%S\')<CR>p', { noremap = true })
        vim.keymap.set('i', '<F5>', '<C-R>=strftime(\'%Y-%m-%d\')<CR>',        { noremap = true })
        vim.keymap.set('i', '<F6>', '<C-R>=strftime(\'%Y-%m-%d %H:%M:%S\')<CR>', { noremap = true })

        -- restore cursor position on reopen
        vim.api.nvim_create_autocmd("BufReadPost", {
          callback = function()
            local mark = vim.api.nvim_buf_get_mark(0, '"')
            local lcount = vim.api.nvim_buf_line_count(0)
            if mark[1] > 1 and mark[1] <= lcount then
              vim.api.nvim_win_set_cursor(0, mark)
            end
          end,
        })

        -- ============================================================
        --  SNACKS
        -- ============================================================

        local snacks = require("snacks")
        snacks.setup({
          lazy = {
            enabled = false,
          },
          dashboard = {
            enabled = true,
            width = 60,
            pane_gap = 4,
            autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
            preset = {
              pick = nil,
              keys = {
                { icon = " ", key = "f", desc = "Find File",       action = ":lua Snacks.dashboard.pick('files')" },
                { icon = " ", key = "n", desc = "New File",        action = ":ene | startinsert" },
                { icon = " ", key = "g", desc = "Find Text",       action = ":lua Snacks.dashboard.pick('live_grep')" },
                { icon = " ", key = "r", desc = "Recent Files",    action = ":lua Snacks.dashboard.pick('oldfiles')" },
                { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                { icon = " ", key = "w", desc = "Vimwiki",        action = ":VimwikiIndex" },
                { icon = "󰒲 ", key = "L", desc = "Lazy",           action = ":Lazy", enabled = package.loaded.lazy ~= nil },
                { icon = " ", key = "q", desc = "Quit",            action = ":qa" },
              },
              header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
            },
            formats = {
              icon = function(item)
                if (item.file and item.icon == "file") or item.icon == "directory" then
                  return Snacks.dashboard.icon(item.file, item.icon)
                end
                return { item.icon, width = 2, hl = "icon" }
              end,
              footer = { "%s", align = "center" },
              header = { "%s", align = "center" },
              file = function(item, ctx)
                local fname = vim.fn.fnamemodify(item.file, ":~")
                fname = ctx.width and #fname > ctx.width and vim.fn.pathshorten(fname) or fname
                if #fname > ctx.width then
                  local dir = vim.fn.fnamemodify(fname, ":h")
                  local file = vim.fn.fnamemodify(fname, ":t")
                  if dir and file then
                    file = file:sub(-(ctx.width - #dir - 2))
                    fname = dir .. "/…" .. file
                  end
                end
                local dir, file = fname:match("^(.*)/(.+)$")
                return dir and { { dir .. "/", hl = "dir" }, { file, hl = "file" } }
                  or { { fname, hl = "file" } }
              end,
            },
            sections = {
              { section = "header" },
              { section = "keys", gap = 1, padding = 1 },
            },
          },
          picker = {
            enabled = true,
            sources = {
              files = {
                hidden = true,
                ignored = false,
                exclude = { "**/.local/**", "**/.cache/**", "**/.var/**", "**/.rustup/**", "**/.steam/**", "**/.mozilla/**", "**/.vscode", "**/.cargo/**", "**/vscode-oss/**" },
              },
              grep = {
                hidden = true,
                ignored = false,
                exclude = { "**/.local/**", "**/.cache/**", "**/.var/**", "**/.rustup/**", "**/.steam/**", "**/.mozilla/**", "**/.vscode/**", "**/.cargo/**", "**/vscode-oss/**" },
              },
            },
          },
        })

        -- command and keymap for dashboard
        vim.api.nvim_create_user_command("SnacksDashboard", function()
          snacks.dashboard.open()
        end, {})
        vim.keymap.set("n", "<leader>ss", function()
          snacks.dashboard.open()
        end, { desc = "Snacks Dashboard" })
      '';
    };
  };
}
