#!/usr/bin/lua

require("luci.model.uci")
require("luci.httpclient")
require("luci.ip")
require("luci.sys")
require("luci.util")
require("nixio.fs")

-- Init state session
local uci = luci.model.uci.cursor_state()

function sendHeartbeat()
    local nodenumber = getNodeNumber()
    local registratorserver = uci:get("ffwizard", "settings", "registrator") or "reg.weimarnetz.de"
    local network = uci:get("ffwizard", "settings", "ipschema") or "ffweimar"

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

    local code, response, msg = httpclient.request_raw(uri, options)

    if code == 200 then
             print("Registrator: "..nodenumber.." successfully updated")
    elseif code == 201 then
             print("Registrator: "..nodenumber.." successfully created")
    elseif code then
             print("Registrator: failed to update nodenumber "..nodenumber.." with code "..code)
    end
end

function registerNode()
    local nodenumber = getNodeNumber()
    local registratorserver = uci:get("ffwizard", "settings", "registrator") or "reg.weimarnetz.de"
    local network = uci:get("ffwizard", "settings", "ipschema") or "ffweimar"

    local params = {}
    params['mac'] = getMac()
    params['pass'] = getPubkey("rsa")
    local httpclient = luci.httpclient
    -- TODO: add https support, needs TLS context
    local options = {
        method = "POST",
        params = params,

    }
    local uri = "http://"..registratorserver.."/"..network.."/knoten"

    local code, response, msg = httpclient.request_raw(uri, options)

    if code == 200 then
        print("Registrator: "..nodenumber.." successfully created")
    elseif code then
        print("Registrator: failed to update nodenumber "..nodenumber.." with code "..code)
    end
end

function getStatus()
    local nodenumber = uci:get("ffwizard", "settings", "nodenumber") or -1
    local registratorserver = uci:get("ffwizard", "settings", "registrator") or "reg.weimarnetz.de"
    local network = uci:get("ffwizard", "settings", "ipschema") or "ffweimar"

    local httpclient = luci.httpclient
    -- TODO: add https support, needs TLS context
    local options = {
        method = "GET",
    }
    local uri = "http://"..registratorserver.."/"..network.."/knoten/"..nodenumber

    local code, response, msg = httpclient.request_raw(uri, options)

    if code == 200 then
        print("Registrator: "..nodenumber.." found")
        return msg
    elseif code then
        print("Registrator: could not find nodenumber "..nodenumber.." with code "..code)
        return nil
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


if getStatus() ~= nil then
    sendHeartbeat()
elseif getNodeNumber() > 0 then
    sendHeartbeat()
end
