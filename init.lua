return {
  -- Configure AstroNvim updates
  updater = {
    remote = "origin", -- remote to use
    channel = "stable", -- "stable" or "nightly"
    version = "latest", -- "latest", tag name, or regex search like "v1.*" to only do updates before v2 (STABLE ONLY)
    branch = "nightly", -- branch name (NIGHTLY ONLY)
    commit = nil, -- commit hash (NIGHTLY ONLY)
    pin_plugins = nil, -- nil, true, false (nil will pin plugins on stable only)
    skip_prompts = false, -- skip prompts about breaking changes
    show_changelog = true, -- show the changelog after performing an update
    auto_quit = false, -- automatically quit the current session after a successful update
    remotes = { -- easily add new remotes to track
      --   ["remote_name"] = "https://remote_url.come/repo.git", -- full remote url
      --   ["remote2"] = "github_user/repo", -- GitHub user/repo shortcut,
      --   ["remote3"] = "github_user", -- GitHub user assume AstroNvim fork
    },
  },

  -- Set colorscheme to use
  colorscheme = "astrodark",

  -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
  diagnostics = {
    virtual_text = true,
    underline = true,
  },

  lsp = {
    -- customize lsp formatting options
    formatting = {
      -- control auto formatting on save
      format_on_save = {
        enabled = true, -- enable or disable format on save globally
        allow_filetypes = { -- enable format on save for specified filetypes only
          -- "go",
        },
        ignore_filetypes = { -- disable format on save for specified filetypes
          -- "python",
        },
      },
      disabled = { -- disable formatting capabilities for the listed language servers
        -- "sumneko_lua",
      },
      timeout_ms = 10000, -- default format timeout
      -- filter = function(client) -- fully override the default formatting function
      --   return true
      -- end
    },
    -- enable servers that you already have installed without mason
    servers = {
      "puppet",
      "pylsp",
      -- "pyright"
    },
    config = {
      -- example for addings schemas to yamlls
      -- yamlls = { -- override table for require("lspconfig").yamlls.setup({...})
      --   settings = {
      --     yaml = {
      --       schemas = {
      --         ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*.{yml,yaml}",
      --         ["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
      --         ["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/*.{yml,yaml}",
      --       },
      --     },
      --   },
      -- },
      -- Example disabling formatting for a specific language server
      -- gopls = { -- override table for require("lspconfig").gopls.setup({...})
      --   on_attach = function(client, bufnr)
      --     client.resolved_capabilities.document_formatting = false
      --   end
      -- }
      ["puppet"] = {
        cmd = {
          "puppet-languageserver",
          "--stdio",
          "--local-workspace",
          "/home/dakr/GIT/solute/infrastructure/puppetcfg",
        },
        root_dir = function(fname)
          local root_files = {
            "manifests",
            ".puppet-lint.rc",
            "hiera.yaml",
          }
          return require("lspconfig").util.find_git_ancestor(fname)
              or require("lspconfig").util.root_pattern(unpack(root_files))(fname)
              or require("lspconfig").util.path.dirname(fname)
        end,
      },
      ["pylsp"] = {
        --cmd = {vim.env["HOME"] .. "/.virtualenvs/solute-pyformat/bin/pylsp", "--log-file", "/tmp/lsplog", "-v"},
        --cmd = {vim.env["HOME"] .. "/.virtualenvs/solute-pyformat/bin/pylsp"},
        cmd = {vim.env["HOME"] .. "/.local/bin/pylsp"},
        settings = {
          pylsp = {
            plugins = {
              solute_pyformat = {
                enabled = true,
              },
            },
          },
        },
      }
    },
  },

  -- Configure require("lazy").setup() options
  lazy = {
    defaults = { lazy = true },
    performance = {
      rtp = {
        -- customize default disabled vim plugins
        disabled_plugins = { "tohtml", "gzip", "matchit", "zipPlugin", "netrwPlugin", "tarPlugin" },
      },
    },
  },

  -- This function is run last and is a good place to configuring
  -- augroups/autocommands and custom filetypes also this just pure lua so
  -- anything that doesn't fit in the normal config locations above can go here
  polish = function()
    -- Set up custom filetypes
    -- vim.filetype.add {
    --   extension = {
    --     foo = "fooscript",
    --   },
    --   filename = {
    --     ["Foofile"] = "fooscript",
    --   },
    --   pattern = {
    --     ["~/%.config/foo/.*"] = "fooscript",
    --   },
    -- }

    -- Only show diagnostics for "our" code,
    vim.api.nvim_create_autocmd("FileType", {
        pattern = {"python"},
        callback = function()
            prefixes = {
                vim.env.SOLUTE_DEV_ROOT,
                vim.env.HOME .. "/GIT/tues",
                vim.env.HOME .. "/GIT/pgpeek",
            }
            path = vim.api.nvim_buf_get_name(0)
            buf = vim.api.nvim_win_get_buf(0)
            -- bail out if something looks like an installed module, we sometimes
            -- visit and even edit these for debugging, but we never want to lint
            -- or auto format them, we explicitly check them first because they
            -- may still live below one of our prefixes somewhere in the filesystem
            if string.find(path, "(.*/site-packages/.*|.*/.tox/.*)") ~= nil then
                vim.diagnostic.disable(buf)
                return
            end

            for _, prefix in ipairs(prefixes) do
                if string.find(path, "^" .. prefix) ~= nil then
                    vim.diagnostic.enable(buf)
                    return
                end
            end
            -- finally, disable for everything else, assuming it is foreign code
            vim.diagnostic.disable(buf)
        end,
    })

    -- Format Python code on-save
    vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = buffer,
        callback = function()
            if vim.bo.filetype == "python" then
                vim.lsp.buf.formatting({async = false})
            end
        end
    })

  end,
}
