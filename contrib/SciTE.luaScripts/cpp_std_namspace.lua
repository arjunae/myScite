-- benötigt: LuaSec (ssl.https)
local https = require("ssl.https")

local base_url  = "https://en.cppreference.com"
local index_url = base_url .. "/w/cpp/header"

-- Hilfsfunktion: holt den gesamten Body von einer URL als String zurück
local function fetch(url)
    local body, code = https.request(url)
    if code ~= 200 then
        error(string.format("Fehler beim Laden von %s (HTTP %d)", url, code))
    end
    return body
end

-- Datei zum Speichern der Ergebnisse
local output_file = io.open("headers.api", "w")

-- 1) Index-Seite holen
local idx = fetch(index_url)

-- 2) Alle Header-Namen und URLs extrahieren
local headers = {}
for rel in idx:gmatch('href="(/w/cpp/header/[%w_%-]+)"') do
    local name = rel:match("/w/cpp/header/(.+)")
    headers[name] = base_url .. rel
end

-- Set zur Vermeidung von Duplikaten
local seen = {}

-- 3) Jede Header-Seite durchgehen und std::…-Einträge extrahieren
for header, url in pairs(headers) do
    io.stderr:write(string.format("==> Verarbeite Header: %s\n", header))
    local content = fetch(url)
    -- Schrittweise Matching: std::Identifier und C++XX
    for line in content:gmatch("([^\r\n]+)") do
        local ident = line:match("std::[%w_:]+")
        if ident and not seen[ident] then
            seen[ident] = true
            output_file:write(string.format("%s |fdesc: %s\n", ident, "<"..header.."> "))
        end
    end
end

-- Datei schließen
output_file:close()
