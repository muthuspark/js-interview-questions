#!/bin/bash
# Fix sitemap URLs to match canonical URLs (remove /index.html)
sed -i 's|/index\.html</loc>|/</loc>|g' docs/sitemap.xml

# Deduplicate sitemap entries (keep latest lastmod for each URL)
python3 -c "
import xml.etree.ElementTree as ET

tree = ET.parse('docs/sitemap.xml')
root = tree.getroot()
ns = {'s': 'http://www.sitemaps.org/schemas/sitemap/0.9'}

# Collect unique URLs, keeping the last occurrence (latest lastmod)
seen = {}
for url_elem in root.findall('s:url', ns):
    loc = url_elem.find('s:loc', ns)
    if loc is not None:
        seen[loc.text] = url_elem

# Remove all url elements, then re-add only unique ones
for url_elem in list(root.findall('s:url', ns)):
    root.remove(url_elem)
for url_elem in seen.values():
    root.append(url_elem)

ET.register_namespace('', 'http://www.sitemaps.org/schemas/sitemap/0.9')
tree.write('docs/sitemap.xml', xml_declaration=True, encoding='UTF-8')
"
