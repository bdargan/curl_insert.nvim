local M = {}

M.curl_command = {
	"curl",
	"--silent", -- Silent mode (no progress bar)
	"--location",
}

-- Function to fetch a page and create a markdown link with the page title
function M.fetch_title_and_create_link(url)
	-- Get the current cursor position
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor_pos[1], cursor_pos[2]

	local html_content = M.fetch(url)

	-- Extract title from HTML
	local title = M.extract_title(html_content)

	-- Create markdown link
	local markdown_link = M.create_markdown_link(url, title)

	-- Schedule the buffer modification to happen in the main Neovim event loop
	vim.schedule(function()
		-- Insert the markdown link at the current cursor position
		vim.api.nvim_buf_set_text(
			0, -- Current buffer
			row - 1,
			col, -- Start position (0-indexed row)
			row - 1,
			col + #url,
			{ markdown_link } -- Text to insert
		)

		-- Move cursor to the end of the inserted text
		vim.api.nvim_win_set_cursor(0, { row, col + #markdown_link })
		vim.notify("Markdown link created for " .. url, vim.log.levels.INFO)
	end)
end

-- Function to get selected text
function M.get_visual_selection()
	vim.notify("get_visual_selection", vim.log.levels.INFO)

	-- Save the current register content and selection type
	local reg_save = vim.fn.getreg('"')
	local regtype_save = vim.fn.getregtype('"')

	-- Yank the visual selection to the unnamed register
	vim.cmd("normal! gvy")

	-- Get the content of the unnamed register
	local selection = vim.fn.getreg('"')

	-- Restore the register
	vim.fn.setreg('"', reg_save, regtype_save)

	-- Return the selected text
	return selection
end

-- Function to extract URL from text (selection or under cursor)
function M.extract_url_from_text(text)
	vim.notify("extract_url_from_text", vim.log.levels.DEBUG)

	if not text or text == "" then
		return nil
	end

	-- Look for a URL pattern in the text
	local url = text:match("https?://[%w-_%.%?%.:/%+=&]+")

	-- If no http/https URL found, try www pattern
	if not url then
		local www_url = text:match("www%.[%w-_%.%?%.:/%+=&]+")
		if www_url then
			url = "http://" .. www_url
		end
	end

	return url
end

-- Function to get URL from selection or under cursor
function M.get_url()
	-- Check if in visual mode (has a selection)
	local mode = vim.api.nvim_get_mode().mode
	if mode:sub(1, 1) == "v" or mode:sub(1, 1) == "V" then
		-- Get selected text and extract URL from it
		local selection = M.get_visual_selection()
		return M.extract_url_from_text(selection)
	else
		-- No selection, try to get URL under cursor
		return M.get_url_under_cursor()
	end
end

-- Function to extract URL from the word under cursor
function M.get_url_under_cursor()
	-- Get the current buffer and cursor position
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- vim api is 0 based, but lua isnt

	vim.notify("get_url_under_cursor" .. line .. " " .. col, vim.log.levels.DEBUG)

	-- Find the beginning of the URL
	local start_idx = col
	while start_idx > 0 and not line:sub(start_idx, start_idx):match("[ \t\n\r]") do
		start_idx = start_idx - 1
	end

	if line:sub(start_idx, start_idx):match("[ \t\n\r]") then
		start_idx = start_idx + 1 -- Adjust after finding a non-URL character
	else
		vim.notify("url not found" .. line, vim.log.levels.DEBUG)
		return nil
	end

	vim.notify("start_idx", start_idx, vim.log.levels.DEBUG)

	-- Find the end of the URL
	local end_idx = col
	while end_idx <= #line and not line:sub(end_idx, end_idx):match("[ \t\n\r]") do
		end_idx = end_idx + 1
	end
	end_idx = end_idx - 1 -- Adjust after finding a non-URL character

	-- Extract the URL
	local url = line:sub(start_idx, end_idx)

	-- Basic URL validation (could be expanded)
	if url:match("^https?://") then
		return url
	elseif url:match("^\\w%\\.") then
		return "http://" .. url
	end

	return nil
end

-- Function to extract title from HTML content
function M.extract_title(html_content)
	-- Simple pattern matching to find the title
	local title = html_content:match("<title>(.-)</title>")

	-- Clean up title by trimming and removing newlines if found
	if title then
		title = title:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
		title = title:gsub("[\r\n]", " ") -- Replace newlines with space
		title = title:gsub("%s+", " ") -- Replace multiple spaces with single space
	end

	return title or "No Title Found"
end

-- Function to create markdown link
function M.create_markdown_link(url, title)
	return "[" .. title .. "](" .. url .. ")"
end

function M.fetch(url)
	-- local location = url or vim.fn.input("Location: ")
	if not url or url == "" then
		vim.notify("Please provide a URL", vim.log.levels.ERROR)
		return
	end
	local options = {
		wait = 30000,
	}
	local command = {
		"curl",
		"--silent", -- Silent mode (no progress bar)
		"--location",
		url,
	}

	local results = vim.system(command, options):wait()
	if results.code ~= 0 then
		error("failed to call curl: " .. (results.stderr or "empty stderr"))
		vim.notify("failed to call curl: " .. (results.stderr or "empty stderr"), vim.log.levels.ERROR)
		return
	end

	if not results.stdout or results.stdout == "" then
		vim.notify("No content received from " .. url, vim.log.levels.WARN)
		return
	end

	--Optional: Force garbage collection to avoid issues.
	--	collectgarbage()
	return results.stdout
end

-- Function to execute curl and insert the response into the current buffer
function M.fetch_and_insert(url)
	-- Get the current cursor position
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor_pos[1], cursor_pos[2]
	local content = M.fetch(url)
	local lines = vim.split("\n")

	-- Schedule the buffer modification to happen in the main Neovim event loop
	vim.schedule(function()
		-- Insert the response at the current cursor position
		vim.api.nvim_buf_set_text(
			0, -- Current buffer
			row - 1,
			col, -- Start position (0-indexed row)
			row - 1,
			col, -- End position
			content -- Lines to insert
		)

		-- Move cursor to the end of the inserted text
		vim.api.nvim_win_set_cursor(0, { row + #lines - 1, col })
		vim.notify("Content from " .. url .. " inserted", vim.log.levels.INFO)
	end)
end

-- Function to detect content type
function M.detect_content_type(content)
	-- Check for JSON
	if content:match("^%s*[{%[]") and (content:match("[}%]]%s*$")) then
		-- Try to parse as JSON to confirm
		local success, _ = pcall(function()
			vim.fn.json_decode(content)
		end)
		if success then
			return "json"
		end
	end

	-- Check for HTML
	if content:match("<!DOCTYPE html>") or content:match("<html") then
		return "html"
	end

	-- Check for XML
	if content:match("^%s*<%?xml") or content:match("^%s*<[%w_:]+[%s>]") then
		return "xml"
	end

	-- Check for CSS
	if content:match("^%s*[%.#]?[%w_-]+%s*{") then
		return "css"
	end

	-- Check for JavaScript
	if
		content:match("function%s+[%w_]+%s*%(")
		or content:match("const%s+[%w_]+%s*=")
		or content:match("let%s+[%w_]+%s*=")
		or content:match("var%s+[%w_]+%s*=")
	then
		return "javascript"
	end

	-- Default to text
	return "text"
end

-- Function to create a new buffer with content
function M.create_buffer_with_content(content, url, content_type)
	-- Create a new buffer
	local buf = vim.api.nvim_create_buf(true, true)

	-- Set buffer name based on URL
	local filename = url:match("([^/]+)$") or "output"
	local buffer_name = "curl_" .. filename
	vim.api.nvim_buf_set_name(buf, buffer_name)

	-- Set content in the buffer
	local lines = {}
	for line in content:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Set buffer filetype based on content
	vim.api.nvim_buf_set_option(buf, "filetype", content_type)

	-- Open the buffer in a new window
	vim.cmd("vsplit")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)

	-- For JSON, try to format it nicely
	if content_type == "json" then
		vim.cmd("silent! %!jq .")
	end

	return buf
end

-- Function to fetch a page and create a new buffer with the content
function M.fetch_to_buffer(url)
	-- Validate that a URL was provided
	if not url or url == "" then
		vim.notify("Please provide a URL", vim.log.levels.ERROR)
		return
	end

	-- Execute curl command using vim.system
	local content = M.fetch(url)
	if not content or content == "" then
		vim.notify("No content received from " .. url, vim.log.levels.WARN)
		return
	end

	-- Detect content type
	local content_type = M.detect_content_type(content)

	-- Create a new buffer with the content
	vim.schedule(function()
		M.create_buffer_with_content(content, url, content_type)
		vim.notify("Content from " .. url .. " loaded in new buffer", vim.log.levels.INFO)
	end)
end

-- Create user commands for calling the functions
function M.setup()
	-- Command with URL as argument
	vim.api.nvim_create_user_command("CurlInsert", function(opts)
		M.fetch_and_insert(opts.args)
	end, {
		nargs = 1,
		desc = "Fetch content from URL and insert at cursor position",
	})

	-- Command to use URL under cursor or from selection
	vim.api.nvim_create_user_command("CurlInsertUnderCursor", function()
		local url = M.get_url()
		if url then
			M.fetch_and_insert(url)
		else
			vim.notify("No valid URL found under cursor or in selection", vim.log.levels.ERROR)
		end
	end, {
		nargs = 0,
		desc = "Fetch content from URL under cursor or in selection and insert at cursor position",
		range = true,
	})

	vim.api.nvim_create_user_command("CurlToBuf", function()
		local url = M.get_url()
		if url then
			M.fetch_to_buffer(url)
		else
			vim.notify("No valid URL found under cursor or in selection", vim.log.levels.ERROR)
		end
	end, {
		nargs = 0,
		desc = "Fetch content to new buffer from URL under cursor or in selection and insert at cursor position",
		range = true,
	})

	-- Command to create markdown link with title from URL under cursor or selection
	vim.api.nvim_create_user_command("CurlMarkdownLink", function()
		local url = M.get_url()
		if url then
			vim.notify("fetch_title_and_create_link" .. url, vim.log.levels.DEBUG)
			M.fetch_title_and_create_link(url)
		else
			vim.notify("No valid URL found under cursor or in selection", vim.log.levels.ERROR)
		end
	end, {
		nargs = 0,
		desc = "Create markdown link with title from URL under cursor or in selection",
		range = true,
	})

	-- Command to create markdown link with title from specified URL
	vim.api.nvim_create_user_command("CurlMarkdownLinkUrl", function(opts)
		M.fetch_title_and_create_link(opts.args)
	end, {
		nargs = 1,
		desc = "Create markdown link with title from specified URL",
	})

	-- Optional keymapping examples (commented out by default)
	-- vim.keymap.set('n', '<leader>cI', ':CurlInsert<CR>', { noremap = true, desc = 'Curl Insert body from URL under cursor or selection' })
	-- vim.keymap.set('n', '<leader>mL', ':CurlMarkdownLink<CR>', { noremap = true, desc = 'Create markdown link from URL under cursor or from selection' })
	-- vim.keymap.set('v', '<leader>cm', ':CurlMarkdownLink<CR>', { noremap = true, desc = 'Create markdown link from URL in selection' })
end

return M
