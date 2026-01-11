#!/bin/bash
# Fix sitemap URLs to match canonical URLs (remove /index.html)
sed -i 's|/index\.html</loc>|/</loc>|g' docs/sitemap.xml
