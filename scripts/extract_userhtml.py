"""Extract the real page HTML from a GAS HtmlService wrapper page.

The /exec response is a Google sandbox wrapper; the actual page is a JS-escaped
string under "userHtml" (quotes appear as \x22, inner escaped quotes as \\\x22).
"""
import json
import re
import sys

src = open(sys.argv[1], encoding='utf-8').read()
m = re.search(r'\\x22userHtml\\x22:\\x22(.*?)(?<!\\)\\x22', src, re.S)
if not m:
    sys.exit('userHtml not found')
t = m.group(1).replace('\\/', '/')
# JS \xNN / \uNNNN / \\ unescape; literal UTF-8 Chinese survives via latin-1 roundtrip
t = t.encode('utf-8').decode('unicode_escape').encode('latin-1', 'backslashreplace').decode('utf-8')
# userHtml is double-escaped: after the JS \xNN pass it is still a JSON-style
# string (\" \\ \n ...). Second pass via json.loads.
t = json.loads('"' + t.replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t') + '"')
open(sys.argv[2], 'w', encoding='utf-8').write(t)
print('ok', len(t))
