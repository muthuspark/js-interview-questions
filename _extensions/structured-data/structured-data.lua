-- Structured Data filter for Quarto
-- Injects Article JSON-LD for posts and WebSite JSON-LD for the homepage

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
        return site_url:gsub("%s+$", ""):gsub("/$", "")
      end
    end
  end
  return nil
end

-- Month name to number mapping
local month_map = {
  january=1, february=2, march=3, april=4, may=5, june=6,
  july=7, august=8, september=9, october=10, november=11, december=12
}

-- Convert various date formats to ISO 8601 (YYYY-MM-DD)
local function to_iso_date(date_str)
  if not date_str then return nil end
  -- MM/DD/YYYY
  local m, d, y = date_str:match("(%d+)/(%d+)/(%d+)")
  if m and d and y then
    return string.format("%s-%02d-%02d", y, tonumber(m), tonumber(d))
  end
  -- Already ISO format (YYYY-MM-DD)
  if date_str:match("%d%d%d%d%-%d%d%-%d%d") then
    return date_str
  end
  -- "Month DD, YYYY" (Pandoc stringified date)
  local month_name, day, year = date_str:match("(%a+)%s+(%d+),%s*(%d+)")
  if month_name and day and year then
    local mn = month_map[month_name:lower()]
    if mn then
      return string.format("%s-%02d-%02d", year, mn, tonumber(day))
    end
  end
  return nil
end

-- JSON-escape a string
local function json_escape(s)
  if not s then return "" end
  s = s:gsub('\\', '\\\\')
  s = s:gsub('"', '\\"')
  s = s:gsub('\n', '\\n')
  s = s:gsub('\r', '\\r')
  s = s:gsub('\t', '\\t')
  return s
end

-- Stringify a Pandoc MetaValue to plain text
local function meta_to_string(val)
  if not val then return nil end
  if type(val) == "string" then return val end
  if pandoc.utils.type(val) == "Inlines" then
    return pandoc.utils.stringify(val)
  end
  if pandoc.utils.type(val) == "Blocks" then
    return pandoc.utils.stringify(val)
  end
  return pandoc.utils.stringify(val)
end

-- Detect if this is a post (not homepage/about)
local function get_post_path()
  local path = ""

  if PANDOC_STATE and PANDOC_STATE.input_files and #PANDOC_STATE.input_files > 0 then
    local input_file = PANDOC_STATE.input_files[1]
    path = input_file:match("posts/([^/]+)/") or ""
    if path ~= "" then
      return "posts/" .. path .. "/"
    end
  end

  local doc_path = os.getenv("QUARTO_DOCUMENT_PATH")
  if doc_path then
    path = doc_path:match("posts/([^/]+)/") or ""
    if path ~= "" then
      return "posts/" .. path .. "/"
    end
  end

  local cwd = io.popen("pwd"):read("*l")
  if cwd then
    path = cwd:match("posts/([^/]+)$") or ""
    if path ~= "" then
      return "posts/" .. path .. "/"
    end
  end

  return nil
end

local function inject_header(meta, html)
  local block = pandoc.RawBlock('html', html)
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
end

function Meta(meta)
  local site_url = get_site_url()
  if not site_url then
    io.stderr:write("Structured data filter: Could not find site-url in _quarto.yml\n")
    return meta
  end

  local post_path = get_post_path()

  if post_path then
    -- Article schema for blog posts
    local title = json_escape(meta_to_string(meta.title) or "")
    local description = json_escape(meta_to_string(meta.description) or "")
    local date_raw = meta_to_string(meta.date)
    local date_iso = to_iso_date(date_raw) or ""
    local url = site_url .. "/" .. post_path

    local jsonld = string.format([[<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "%s",
  "description": "%s",
  "datePublished": "%s",
  "author": {
    "@type": "Person",
    "name": "Muthu Krishnan",
    "url": "%s"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Mastering Javascript"
  },
  "url": "%s",
  "mainEntityOfPage": {
    "@type": "WebPage",
    "@id": "%s"
  }
}
</script>]], title, description, date_iso, site_url, url, url)

    inject_header(meta, jsonld)
  else
    -- WebSite schema for homepage
    local description = json_escape(meta_to_string(meta.description) or "")

    local jsonld = string.format([[<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Mastering Javascript",
  "description": "%s",
  "url": "%s"
}
</script>]], description, site_url)

    inject_header(meta, jsonld)
  end

  return meta
end
