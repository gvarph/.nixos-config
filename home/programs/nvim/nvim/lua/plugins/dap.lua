return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"mfussenegger/nvim-dap-python",
		"rcarriga/nvim-dap-ui",
		"theHamsta/nvim-dap-virtual-text",
		"nvim-neotest/nvim-nio",
	},
	keys = {
		{
			"<F1>",
			function()
				require("dap").continue()
			end,
			mode = { "n", "i" },
			desc = "Debug - Start/Continue Debugger",
		},
		{
			"<F2>",
			function()
				require("dap").step_over()
			end,
			mode = { "n", "i" },
			desc = "Debug - Step Over",
		},
		{
			"<F3>",
			function()
				require("dap").step_into()
			end,
			mode = { "n", "i" },
			desc = "Debug - Step Into",
		},
		{
			"<F5>",
			function()
				require("dap").step_back()
			end,
			mode = { "n", "i" },
			desc = "Debug - Step Out",
		},
		{
			"<F6>",
			function()
				require("dap").step_out()
			end,
			mode = { "n", "i" },
			desc = "Debug - Step Out",
		},
		{
			"<F7>",
			function()
				require("dap").toggle_breakpoint()
			end,
			mode = { "n", "i" },
			desc = "Debug - Toggle Breakpoint",
		},

		{
			"<F8>",
			function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end,
			mode = { "n", "i" },
			desc = "Debug - Set Conditional Breakpoint",
		},

		{
			"<F9>",
			function()
				require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
			end,
			mode = { "n", "i" },
			desc = "Debug - Set Log Point",
		},

		{
			"<leader>dc",
			function()
				require("dap").clear_breakpoints()
			end,
			desc = "[D]ebug - [C]lear breakpoints",
		},

		{
			"<leader>d?",
			function()
				require("dapui").eval(nil, { enter = true })
			end,
			desc = "[D]ebug - evaluate current line and show in float",
		},

		{
			"<leader>dd",
			function()
				require("dapui").toggle()
			end,
			desc = "[D]ebug - toggle UI",
		},
		{
			"<leader>dpr",
			function()
				require("dap-python").test_method()
			end,
			desc = "[D]ebug - [P]ython [R]un test method",
		},
	},
	config = function()
		require("nvim-dap-virtual-text").setup({
			enabled = true, -- enable this plugin (the default)
			enabled_commands = true, -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
			highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
			highlight_new_as_changed = false, -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
			show_stop_reason = true, -- show stop reason when stopped for exceptions
			commented = false, -- prefix virtual text with comment string
			only_first_definition = true, -- only show virtual text at first definition (if there are multiple)
			all_references = false, -- show virtual text on all all references of the variable (not only definitions)
			filter_references_pattern = "<module", -- filter references (not definitions) pattern when all_references is activated (Lua gmatch pattern, default filters out Python modules)
			-- experimental features:
			virt_text_pos = "eol", -- position of virtual text, see `:h nvim_buf_set_extmark()`
			all_frames = false, -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
			virt_lines = false, -- show virtual lines instead of virtual text (will flicker!)
			virt_text_win_col = nil, -- position the virtual text at a fixed window column (starting from the first text column) ,
			-- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
		})

		require("dapui").setup({
			icons = { expanded = "▾", collapsed = "▸" },
			mappings = {
				-- Use a table to apply multiple mappings
				expand = { "<CR>", "<2-LeftMouse>" },
				open = "o",
				remove = "d",
				edit = "e",
				repl = "r",
				toggle = "t",
			},
			-- Expand lines larger than the window
			expand_lines = true,
			layouts = {
				{
					elements = {
						"scopes",
						"breakpoints",
						"stacks",
						"watches",
					},
					size = 60,
					position = "left",
				},
				{
					elements = {
						"repl",
						"console",
					},
					size = 20,
					position = "bottom",
				},
			},
			floating = {
				max_height = nil, -- These can be integers or a float between 0 and 1.
				max_width = nil, -- Floats will be treated as percentage of your screen.
				border = "single", -- Border style. Can be 'single', 'double' or 'rounded'
				mappings = {
					close = { "q", "<Esc>" },
				},
			},
			windows = { indent = 1 },
			render = {
				max_type_length = nil, -- Can be integer or nil.
			},
		})

		local dap, dapui = require("dap"), require("dapui")

		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end

		local shims_dir = require("common").shims_dir

		require("dap-python").resolve_python = function()
			local venv_dir = vim.fn.system({ "poetry", "env", "info", "--path" }):gsub("\n", "")
			return venv_dir .. "/bin/python"
		end
		require("dap-python").setup(shims_dir .. "python")
		require("dap-python").test_runner = "pytest"

		require("dap").configurations.python = {
			{
				name = "Pytest: Current File",
				type = "python",
				request = "launch",
				module = "pytest",
				args = {
					"${file}",
					"-sv",
					"--log-cli-level=INFO",
				},
				console = "integratedTerminal",
			},
		}
	end,
}
