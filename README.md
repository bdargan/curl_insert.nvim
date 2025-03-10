# Curl Insert Plugin for Neovim
A simple Neovim plugin that fetches content from a URL using curl and inserts it into your current buffer at the cursor position.
Prerequisites

Neovim (0.5.0 or higher recommended)
curl must be available in your system PATH

Installation## Health Checks

The plugin includes a health check module that verifies:

1. Curl is installed and in your PATH
2. Curl version is at least 8.7 (recommended minimum version)

You can run the health check with:

```
:checkhealth curl_insert
```

The plugin will also automatically check curl requirements on startup and display warnings if necessary.### Load Content to a New Buffer with Correct Filetype

```
:CurlToBuf https://example.com/data.json
```

This will:
1. Fetch the content from the URL
2. Create a new buffer in a vertical split
3. Load the content into the buffer
4. Detect the content type (JSON, HTML, XML, CSS, JavaScript, etc.)
5. Set the appropriate filetype for syntax highlighting
6. For JSON, it will also try to format the content using `jq` if available

You can also use the URL under your cursor or from selection:

```
```# Curl Insert Plugin for Neovim

A simple Neovim plugin that fetches content from a URL using `curl` and inserts it into your current buffer at the cursor position.

## Requirements

- Neovim (0.8.0 or higher)
- `curl` must be available in your system PATH
- Optional: `jq` for pretty printing JSON in the buffer view

## Technical Notes

- Uses Neovim's modern `vim.system` API for non-blocking asynchronous HTTP requests
- Properly schedules UI updates to avoid concurrency issues
- Uses pattern matching for URL detection and content type detection

## Installation

### Using Packer

```lua
use {
  'username/curl-insert',
  config = function()
    require('curl_insert').setup()
  end
}
```

### Using Lazy.nvim

```lua
{
  'username/curl-insert',
  config = function()
    require('curl_insert').setup()
  end
}
```

### Manual Installation

1. Create the plugin directory:

```bash
mkdir -p ~/.config/nvim/lua/curl_insert
```

2. Copy the `curl_insert.lua` file to this directory:

```bash
cp curl_insert.lua ~/.config/nvim/lua/curl_insert/init.lua
```

3. Add this to your `init.lua`:

```lua
require('curl_insert').setup()
```

## Usage

Once the plugin is installed, you can use it with the following commands:

### Specify a URL

```
:CurlInsert https://example.com
```

This will fetch the content from the URL and insert it at your current cursor position.

### Use URL Under Cursor or From Selection

```
:CurlInsertUnderCursor
```

This command works in two ways:
1. In normal mode: Detects the URL under your cursor
2. In visual mode: Extracts a URL from your selected text

The plugin can recognize:
- URLs starting with http:// or https://
- URLs starting with www. (automatically prefixed with http://)

### Create Markdown Link with Page Title

```
:CurlMarkdownLink
```

This will:
1. Detect the URL under your cursor or from your visual selection
2. Fetch the page and extract its title
3. Create a markdown link in the format `[Page Title](URL)`
4. Insert the markdown link at your cursor position

You can also specify a URL directly:

```
:CurlMarkdownLinkUrl https://example.com
```

## Configuration

### Custom Keymappings

You can add your own keymappings in your Neovim config:

```lua
-- For specifying URL manually
vim.keymap.set('n', '<leader>ci', ':CurlInsert ', { noremap = true, desc = 'Curl Insert command' })

-- For URL under cursor (normal mode)
vim.keymap.set('n', '<leader>cu', ':CurlInsertUnderCursor<CR>', { noremap = true, desc = 'Curl Insert URL under cursor' })

-- For URL in selection (visual mode)
vim.keymap.set('v', '<leader>cu', ':CurlInsertUnderCursor<CR>', { noremap = true, desc = 'Curl Insert URL from selection' })

-- For creating markdown link from URL under cursor (normal mode)
vim.keymap.set('n', '<leader>cm', ':CurlMarkdownLink<CR>', { noremap = true, desc = 'Create markdown link from URL under cursor' })

-- For creating markdown link from URL in selection (visual mode)
vim.keymap.set('v', '<leader>cm', ':CurlMarkdownLink<CR>', { noremap = true, desc = 'Create markdown link from URL in selection' })

-- For loading URL content to new buffer (normal mode)
vim.keymap.set('n', '<leader>cb', ':CurlToBufferUnderCursor<CR>', { noremap = true, desc = 'Fetch URL under cursor to new buffer' })

-- For loading URL content to new buffer (visual mode)
vim.keymap.set('v', '<leader>cb', ':CurlToBufferUnderCursor<CR>', { noremap = true, desc = 'Fetch URL from selection to new buffer' })
```

### Advanced Usage

If you need to access the plugin functions directly:

```lua
-- Fetch and insert content from a URL
require('curl_insert').fetch_and_insert('https://example.com')
```

## Troubleshooting

- Make sure `curl` is installed and accessible in your PATH
- Check if the URL is accessible from your terminal using `curl URL`
- If you get SSL errors, you might need to update your system's CA certificates

## License

MIT
