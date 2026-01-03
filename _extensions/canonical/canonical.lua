-- Canonical URL filter for Quarto
-- Adds canonical link and og:url meta tags to prevent duplicate content issues

-- Read site-url from _quarto.yml
local function get_site_url()
  local quarto_yml_paths = {
    "_quarto.yml",
    "../_quarto.yml",
    "../../_quarto.yml",
    "../../../_quarto.yml"
  }

  for _, path in ipairs(quarto_yml_paths) do
    local file = io.open(path, "r")
    if file then
      local content = file:read("*all")
      file:close()
      local site_url = content:match("site%-url:%s*['\"]?([^'\"\n]+)['\"]?")
      if site_url then
        return site_url:gsub("%s+$", "")
      end
    end
  end
  return nil
end

function Meta(meta)
  local site_url = get_site_url()

  if not site_url then
    io.stderr:write("Canonical filter: Could not find site-url in _quarto.yml\n")
    return meta
  end

  -- Try to get path from various Quarto sources
  local path = ""

  -- Method 1: Use PANDOC_STATE if available (Pandoc 2.17+)
  if PANDOC_STATE and PANDOC_STATE.input_files and #PANDOC_STATE.input_files > 0 then
    local input_file = PANDOC_STATE.input_files[1]
    path = input_file:match("posts/([^/]+)/") or ""
    if path ~= "" then
      path = "posts/" .. path .. "/"
    end
  end

  -- Method 2: Try quarto-specific environment variables
  if path == "" then
    local doc_path = os.getenv("QUARTO_DOCUMENT_PATH")
    if doc_path then
      path = doc_path:match("posts/([^/]+)/") or ""
      if path ~= "" then
        path = "posts/" .. path .. "/"
      end
    end
  end

  -- Method 3: Use current working directory as hint
  if path == "" then
    local cwd = io.popen("pwd"):read("*l")
    if cwd then
      path = cwd:match("posts/([^/]+)$") or ""
      if path ~= "" then
        path = "posts/" .. path .. "/"
      end
    end
  end

  -- Build canonical URL
  local canonical_url = site_url:gsub("/$", "") .. "/" .. path

  -- Inject the canonical and og:url tags
  local canonical_html = '<link rel="canonical" href="' .. canonical_url .. '">\n<meta property="og:url" content="' .. canonical_url .. '">'
  local block = pandoc.RawBlock('html', canonical_html)

  if meta["header-includes"] == nil then
    meta["header-includes"] = pandoc.MetaList({pandoc.MetaBlocks({block})})
  else
    local current = meta["header-includes"]
    if pandoc.utils.type(current) == "List" then
      current:insert(pandoc.MetaBlocks({block}))
    else
      meta["header-includes"] = pandoc.MetaList({current, pandoc.MetaBlocks({block})})
    end
  end

  return meta
end
