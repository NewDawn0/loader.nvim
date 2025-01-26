local loader = require("loader")
loader.setup()
loader.load({
	["vim-startuptime"] = { cmds = { "StartupTime" } },
	["comment.nvim"] = {
		keys = { "gcc", "gcb" },
		config = function()
			require("comment")
		end,
	},
	-- Example with dependency
	["nvim-treesitter"] = {
		events = { "BufReadPre" },
		deps = { "nvim-web-devicons" },
		config = function()
			require("ts")
		end,
	},
	-- Dependency
	["nvim-web-devicons"] = {
		config = function()
			require("nvim-web-devicons").setup({})
		end,
	},
})
