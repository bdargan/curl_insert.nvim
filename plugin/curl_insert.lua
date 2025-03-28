--plugin/curl-insert.lua
-- Plugin loader for curl_insert

if vim.fn.has("nvim-0.8.0") == 0 then
	vim.notify("Curl Insert Plugin requires Neovim 0.8.0 or higher", vim.log.levels.ERROR)
	return
end

-- Load the plugin
require("curl_insert").setup()

vim.keymap.set(
	"n",
	"<leader>mL",
	":CurlMarkdownLink<CR>",
	{ noremap = true, desc = "Create markdown link from URL under cursor or from selection" }
)
