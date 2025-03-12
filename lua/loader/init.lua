---@class PluginLoader
---@field plugins table<string, PluginConfig> Table of plugins to be loaded and their configurations
---@field config table Configuration options for the plugin loader
local M = {}

M.plugins = {}

---@class PluginConfig
---@field cmds string[]|nil Commands that trigger plugin loading
---@field keys string[]|nil Keybinds that trigger plugin loading
---@field events string[]|nil Events that trigger plugin loading
---@field deps string[]|nil Dependencies for the plugin
---@field config function|nil Optional function to configure the plugin after loading
---@field loaded boolean Whether the plugin has been loaded or not
---@field file string|nil The plugin config file to be imported
---@field filetypes string[]|nil Filetypes that trigger the plugin loading

-- Abbreviations for Neovim API functions
local api = vim.api
local newCmd, delCmd = api.nvim_create_user_command, api.nvim_del_user_command
local newAu, delAu = api.nvim_create_autocmd, api.nvim_del_autocmd
local KBOpts = { silent = true }

--- Plugin loader configuration
---@class PluginLoaderConfig
---@field notifyOnLoad boolean Whether to enable notifications
---@field highlights table<string, string> Highlight colors for UI elements
M.config = {
	notifyOnLoad = false,
	highlights = {
		header = "#c797ff", -- Header color
		loaded = "#1df914", -- Loaded plugin indicator
		notLoaded = "#dc143c", -- Not loaded plugin indicator
		info = "#89b4fa", -- Info text color
	},
}

--- Set highlight groups for the plugin loader UI
---@param group string Highlight group name
---@param fg string Foreground color (hex)
---@param bg string|nil Background color (hex), optional
local function setHighlight(group, fg, bg)
	api.nvim_set_hl(0, group, { fg = fg, bg = bg })
end

--- Load a plugin and its dependencies
---@param plugins table<string, PluginConfig> Table of plugins
---@param name string Name of the plugin to load
---@param config PluginConfig Plugin configuration
local function loadPlugin(plugins, name, config)
	if M.plugins[name].loaded then
		return
	end

	-- Load dependencies first
	if config.deps then
		for _, dep in ipairs(config.deps) do
			loadPlugin(plugins, dep, plugins[dep])
		end
	end

	-- Load the plugin
	vim.cmd("packadd " .. name)
	if M.config.notifyOnLoad then
		vim.notify("Loaded " .. name, vim.log.levels.INFO)
	end

	-- Execute the plugin's configuration function, if defined
	if config.config then
		config.config()
	end

	-- Import the plugin's configig file, if defined
	if config.file then
		require(config.file)
	end

	M.plugins[name].loaded = true
end

--- Register and set up plugins for lazy loading
---@param plugins table<string, PluginConfig> Table of plugins to register
M.load = function(plugins)
	for name, config in pairs(plugins) do
		M.plugins[name] = vim.tbl_extend("keep", config, { loaded = false })

		-- Lazy-load plugins on specific commands
		if config.cmds then
			for _, cmd in ipairs(config.cmds) do
				newCmd(cmd, function(args)
					delCmd(cmd) -- Remove the placeholder command
					loadPlugin(plugins, name, config)
					vim.cmd(cmd .. " " .. args.args) -- Execute the command with arguments
				end, { nargs = "*" }) -- Accepts arguments
			end
		end

		-- Lazy-load plugins on keypress
		if config.keys then
			for _, key in ipairs(config.keys) do
				vim.keymap.set("n", key, function()
					vim.keymap.del("n", key) -- Remove placeholder keymap
					loadPlugin(plugins, name, config)
					api.nvim_feedkeys(api.nvim_replace_termcodes(key, true, false, true), "m", true) -- Re-run keypress
				end, KBOpts)
			end
		end

		-- Lazy-load plugins on specific events
		if config.events then
			local id
			id = newAu(config.events, {
				callback = function()
					loadPlugin(plugins, name, config)
					delAu(id) -- Remove the autocmd after execution
				end,
			})
		end

		-- Lazy-load plugins on specific filetyps
		if config.filetypes then
			local id
			id = newAu("FileType", {
				pattern = config.filetypes,
				callback = function()
					loadPlugin(plugins, name, config)
					delAu(id)
				end,
			})
		end
	end
end

--- Display a UI showing plugin load status
M.ui = function()
	-- Window dimensions
	local width = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.6)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- Create a new buffer for the UI
	local buf = api.nvim_create_buf(false, true)
	local lines = { " 🚀 Package Loader", string.rep("─", width) }

	-- Display plugin loading status
	for name, config in pairs(M.plugins) do
		local sign = config.loaded and "✓" or "x"
		local pluginLine = string.format("  %s %s", sign, name)
		table.insert(lines, pluginLine)

		if config.keys then
			table.insert(lines, "     Keybinds: " .. table.concat(config.keys, ", "))
		end
		if config.events then
			table.insert(lines, "     Events: " .. table.concat(config.events, ", "))
		end
		if config.cmds then
			table.insert(lines, "     Commands: " .. table.concat(config.cmds, ", "))
		end
		if config.filetypes then
			table.insert(lines, "     Filetypes: " .. table.concat(config.filetypes, ", "))
		end
	end

	-- Footer
	table.insert(lines, string.rep("─", width))
	table.insert(lines, "Press 'q' to quit")

	-- Configure buffer settings
	api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].readonly = true
	vim.bo[buf].swapfile = false
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].filetype = "loader"
	api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
	api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })

	-- Apply syntax highlighting to UI elements
	api.nvim_buf_add_highlight(buf, 0, "loaderheader", 0, 0, -1)
	for i, line in ipairs(lines) do
		if line:sub(3, 3) == "✓" then
			api.nvim_buf_add_highlight(buf, 0, "loaderloaded", i - 1, 2, 3)
		elseif line:sub(3, 3) == "x" then
			api.nvim_buf_add_highlight(buf, 0, "loadernotLoaded", i - 1, 2, 3)
		elseif line:find("Keybinds:") or line:find("Events:") or line:find("Commands:") then
			api.nvim_buf_add_highlight(buf, 0, "loaderinfo", i - 1, 0, -1)
		end
	end

	-- Create the floating window
	api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})
end

--- Configure plugin loader settings, including UI highlights
---@param opts table Custom configuration overrides
M.setup = function(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})

	-- Apply highlight settings from the configuration
	for name, color in pairs(M.config.highlights) do
		setHighlight("loader" .. name, color)
	end

	-- Create a command to show the loader UI
	api.nvim_create_user_command("LoaderInfo", function()
		M.ui()
	end, {})
end

return M
