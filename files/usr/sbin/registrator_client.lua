#!/usr/bin/lua

require("luci.model.uci")
require("luci.httpclient")
require("luci.ip")
require("luci.json")
require("luci.sys")
require("luci.util")
require("nixio.fs")

-- Init state session
local ltn12 = require "luci.ltn12"
local table = require "table"
local uci = luci.model.uci.cursor_state()

function request_to_buffer(uri, options)
	local source, code, msg = request_to_source(uri, options)
	local output = {}

	if not source then
		return nil, code, msg
	end
	
	source = ltn12.pump.all(source, (ltn12.sink.table(output)))
	
	if not source then
		return nil, code
    end

	local result = table.concat(output)
	
	return result, code 
end

function request_to_source(uri, options)
	local status, response, buffer, sock = luci.httpclient.request_raw(uri, options)
	if not status then
		return status, response, buffer
	elseif status ~= 200 and status ~= 206 then
		return nil, status, buffer
	end
	if response.headers["Transfer-Encoding"] == "chunked" then
        local chunksource = luci.httpclient.chunksource(sock, buffer)
        return chunksource, status
	else
        local result = ltn12.source.cat(ltn12.source.string(buffer), sock:blocksource())
        return result, status
	end
end

function sendHeartbeat()
    local nodenumber = getNodeNumber()
    local registratorserver = uci:get("ffwizard", "settings", "registrator") or "reg.weimarnetz.de"
    local network = uci:get("ffwizard", "settings", "ipschema") or "ffweimar"
    local result = {}

    local params = {}
    params['mac'] = getMac()
    params['pass'] = getPubkey("rsa")
    local httpclient = luci.httpclient
    -- TODO: add https support, needs TLS context
    local options = {
        method = "PUT",
	params = params,

    }
    local uri = "http://"..registratorserver.."/"..network.."/knoten/"..nodenumber

    local msg, code = request_to_buffer(uri, options)

    local query_result = luci.json.decode(msg)

    if code == 200 then
        local nodenumber_from_result = query_result['result']['number']
        result['success'] = true
        result['code'] = code
        result['nodenumber'] = nodenumber_from_result
        result['message']= "Registrator: ".. nodenumber_from_result .." successfully updated"
        return result
    elseif code == 201 then
        local nodenumber_from_result = query_result['result']['number']
        result['success'] = true
        result['code'] = code
        result['nodenumber'] = nodenumber_from_result
        result['message']= "Registrator: ".. nodenumber_from_result .." successfully created"
        return result
    elseif code then
        result['success'] = false
        result['code'] = code
        result['message']= "Registrator: failed to update nodenumber "..nodenumber.." with code "..code
        return result
    end
end

function registerNode()

    local params = {}
    local result = {}
    params['mac'] = getMac()
    params['pass'] = getPubkey("rsa")
    local httpclient = luci.httpclient
    -- TODO: add https support, needs TLS context
    local options = {
        method = "POST",
        params = params,
    }
    local registratorserver = uci:get("ffwizard", "settings", "registrator") or "reg.weimarnetz.de"
    local network = uci:get("ffwizard", "settings", "ipschema") or "ffweimar"
    local uri = "http://"..registratorserver.."/"..network.."/knoten"

    local msg, code = request_to_buffer(uri, options)

    local query_result = luci.json.decode(msg)

    if code == 200 then
        local nodenumber_from_result = query_result['result']['number']
        result['success'] = true
        result['code'] = code
        result['nodenumber'] = nodenumber_from_result
        result['message']= "Registrator: ".. nodenumber_from_result .." successfully updated"
        return result
    elseif code == 201 then
        local nodenumber_from_result = query_result['result']['number']
        result['success'] = true
        result['code'] = code
        result['nodenumber'] = nodenumber_from_result
        result['message']= "Registrator: ".. nodenumber_from_result .." successfully created"
        return result
    elseif code then
        result['success'] = false
        result['code'] = code
        result['message']= "Registrator: failed to register node with mac "..params.mac.." with code "..code
        return result
    end
end

function getStatus()
    local registratorserver = uci:get("ffwizard", "settings", "registrator") or "reg.weimarnetz.de"
    local network = uci:get("ffwizard", "settings", "ipschema") or "ffweimar"
    local result = {}

    local mac = getMac()
    local params = {}
    params['mac'] = mac

    -- TODO: add https support, needs TLS context
    local options = {
        method = "GET",
        params = params,
    }
    local uri = "http://"..registratorserver.."/"..network.."/knotenByMac"

    local msg, code = request_to_buffer(uri, options)

    local query_result = luci.json.decode(msg)

    if code == 200 then
        local nodenumber = query_result['result']['number']
        result['success'] = true
        result['code'] = code
        result['nodenumber'] = nodenumber
        result['message']= "Registrator: "..mac.." found with number ".. nodenumber
        return result
    elseif code then
        result['success'] = false
        result['code'] = code
        result['message'] = "Registrator: could not find mac address "..mac.." with code "..code
        return result
    end
end

function getMac()
    local laninterface = uci:get("network", "lan", "ifname")
    local parameter = {}
    parameter['name'] = laninterface
    local devicestatus = luci.util.ubus("network.device", "status", parameter)
    return devicestatus['macaddr']
end

function getPubkey(type)
    local path = "/etc/dropbear/dropbear_"..type.."_host_key"
    local file = nixio.fs.stat(path)
    if not file then
        return ""
    end
    local fingerprint = luci.sys.exec("dropbearkey -f \"" .. path .. "\" -y | awk '/Fingerprint:/ { print $3 }'")
    return fingerprint
end

function getNodeNumber()
    return tonumber(uci:get("ffwizard", "settings", "nodenumber")) or -1
end

function printUsage()
    print("Usage: "..arg[0].." <status|heartbeat|register>")
    os.exit()
end

if #arg ~= 1 then
    printUsage()
end

if arg[1] == "status" then
    print(luci.json.encode(getStatus()))
elseif arg[1] == "heartbeat" then
    local status = getStatus()
    if status['success'] == true and status['nodenumber'] == getNodeNumber() then
        print(luci.json.encode(sendHeartbeat()))
    elseif getNodeNumber() > 0 then
        print(luci.json.encode(sendHeartbeat()))
    end
elseif arg[1] == "register" then
    print(luci.json.encode(registerNode()))
else
    printUsage()
end



