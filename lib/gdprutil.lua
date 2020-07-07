-- gdprutil.lua

local M = {}

local _g = require("lib.globalVariables")
local _data = require("lib.data")

-- References:
-- https://en.wikipedia.org/wiki/Member_state_of_the_European_Union
-- https://www.iso.org/iso-3166-country-codes.html
-- https://en.wikipedia.org/wiki/ISO_3166-1
-- https://en.wikipedia.org/wiki/General_Data_Protection_Regulation

M.EUCountryCodeList = {
	["AT"] = "Austria",
	["BE"] = "Belgium",
	["BG"] = "Bulgaria",
	["HR"] = "Croatia",
	["CY"] = "Cypress",
	["CZ"] = "Czechia", -- aka "Czech Republic"
	["DK"] = "Denmark",
	["EE"] = "Estonia",
	["FI"] = "Finland",
	["FR"] = "France",
	["DE"] = "Germany",
	["GR"] = "Greece",
	["HU"] = "Hungary",
	["IE"] = "Ireland",
	["IT"] = "Italy",
	["LV"] = "Latvia",
	["LT"] = "Lithuania",
	["LU"] = "Luxembourg",
	["MT"] = "Malta",
	["NL"] = "Netherlands",
	["PL"] = "Poland",
	["PT"] = "Portugal",
	["RO"] = "Romania",
	["SK"] = "Slovakia",
	["SI"] = "Slovenia",
	["ES"] = "Spain",
	["SE"] = "Sweden",
	["GB"] = "United Kingdom",
	-- the following non-EU-but-EEA counties should probably also be included (formal adoption still pending as of this writing)
	["IS"] = "Iceland",
	["LI"] = "Liechtenstein",
	["NO"] = "Norway",
}

local consent = _data:get("consent")
local country = system.getPreference("locale", "country", "string")
local isEUCountry = M.EUCountryCodeList[country] ~= nil
if _g.debug then
	isEUCountry = true
end

M.isEUCountry = function()
	return isEUCountry
end

M.getConsent = function()
	return consent
end

M.setConsent = function(bool)
	consent = bool
	_data:update("consent", consent)
	_data:save()
end 

M.hasResponded = function()
	if M.isEUCountry() then
		if M.getConsent() ~= nil then
			return true
		end
	else
		return true
	end

	return false
end

M.hasUserConsent = function()
	if M.isEUCountry() then
		if M.getConsent() then
			return true
		end
	else
		return true
	end

	return false
end

--- anonymizes an ip address by replacing the lower-order octet(s) with innocuous characters
-- @param ip String the IPv4 address to be anonymized
-- @param noctets Number Optional the number of lower-order octets to strip, valid range 1 - 2, default 1
-- @param char String a single character string to be used as replacement, default "x"
-- @return String the anonymized ip address, with lower-order octet numbers replaced with the replacement char
-- @usage technically this is a **replacement** method rather than a **stripping** method.
--   however, using a blank ("") replacement char will function as a strip method.
-- @usage this function will **attempt** to provide a "useful" string reponse even if an invalid input ip is given,
--   but results cannot be guaranteed, so try to pass only valid ip address strings
--
M.anonymizeIP = function(ip,noctets,char)
	if (type(ip)~="string") then
		if (_g.debug) then
			print("gdprutil.anonymizeIP():  invalid ip address provided: " .. tostring(ip) .. " (" .. type(ip) .. ")")
		end
		ip = ""
	end
	if (type(noctets)~="number") then noctets = 1 end
	noctets = math.max(1, math.min(2, noctets))
	if (type(char)~="string") then char = "x" end
	if (#char > 1) then char = string.sub(char,1,1) end
	local i,j,a,b = string.find(ip, noctets==1 and "(%d+%.%d+%.%d+)(%.%d+)" or "(%d+%.%d+)(%.%d+%.%d+)")
	if (i and char=="") then b = string.gsub(b,"%.","") end
	return i and a..string.gsub(i and b,"%d",char) or string.gsub("0.0.0.0", "%d", char)
end


return M