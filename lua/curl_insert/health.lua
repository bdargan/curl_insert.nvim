-- health.lua
-- Health check module for curl_insert plugin

local M = {}

-- Function to parse curl version from version string
local function parse_curl_version(version_str)
  -- Match the version number pattern (e.g., 7.68.0, 8.7.1)
  local major, minor = version_str:match("curl[%s%-]+(%d+)%.(%d+)")
  if major and minor then
    return tonumber(major), tonumber(minor)
  end
  return nil, nil
end

-- Main health check function
function M.check()
  -- Declare the start of the health check
  vim.health.start("Curl Insert Plugin")

  -- Check if curl is installed
  local curl_exists = vim.fn.executable("curl") == 1
  if not curl_exists then
    vim.health.error("curl is not installed or not in PATH", {
      "Install curl: https://curl.se/download.html",
      "Ensure curl is available in your PATH"
    })
    return
  end
  
  vim.health.ok("curl is installed")
  
  -- Check curl version
  local version_output = vim.fn.system("curl --version")
  local major, minor = parse_curl_version(version_output)
  
  if not major or not minor then
    vim.health.warn("Could not determine curl version", {
      "Output from curl --version was: " .. version_output:sub(1, 50) .. "..."
    })
    return
  end
  
  -- Check if version is at least 8.7
  if major > 8 or (major == 8 and minor >= 7) then
    vim.health.ok(string.format("curl version %d.%d meets minimum requirement (8.7)", major, minor))
  else
    vim.health.warn(string.format("curl version %d.%d is below recommended version 8.7", major, minor), {
      "Some features may not work correctly",
      "Consider upgrading curl: https://curl.se/download.html"
    })
  end
  
  -- Check if jq is installed (optional)
  local jq_exists = vim.fn.executable("jq") == 1
  if jq_exists then
    vim.health.ok("jq is installed (will be used for JSON formatting)")
  else
    vim.health.info("jq is not installed", {
      "jq is recommended for better JSON formatting",
      "Install jq: https://stedolan.github.io/jq/download/"
    })
  end
end

return M
