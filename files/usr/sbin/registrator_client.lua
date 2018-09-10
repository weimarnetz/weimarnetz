#!/usr/bin/lua

require("luci.model.uci")
require("luci.httpclient")
require("luci.ip")
require("luci.sys")
require("luci.util")
require("nixio.fs")

-- Init state session
local uci = luci.model.uci.cursor_state()

function heartbeat()
    local nodenumber = uci:get("ffwizard", "settings", "nodenumber") or -1
    local registratorserver = uci:get("ffwizard", "settings", "registrator") or "reg.weimarnetz.de"
    local network = uci:get("ffwizard", "settings", "ipschema") or "ffweimar"

    local macAddress = getMac()
    local pass = getPubkey("dss")
    local httpclient = luci.httpclient
    -- TODO: add https support, needs TLS context
    local options = {
        method = "PUT",
        headers = {
            ["Content-Type"] = "application/json",
        },
    }
    local uri = "http://"..registratorserver.."/"..network.."/knoten/"..nodenumber.."?mac=".. macAddress .."&pass="..pass

    local response, code, msg = httpclient.request_to_buffer(uri, options)

    print(code)

    if code == 200 then
             print("Registrator: "..nodenumber.." successfully updated")
    elseif code then
             print("Registrator: failed to update nodenumber "..nodenumber.." with code "..code)
    end
end

function status()
    local nodenumber = uci:get("ffwizard", "settings", "nodenumber") or -1
    local registratorserver = uci:get("ffwizard", "settings", "registrator") or "reg.weimarnetz.de"
    local network = uci:get("ffwizard", "settings", "ipschema") or "ffweimar"

    local httpclient = luci.httpclient
    -- TODO: add https support, needs TLS context
    local options = {
        method = "GET",
        headers = {
            ["Content-Type"] = "application/json",
        },
    }
    local uri = "http://"..registratorserver.."/"..network.."/knoten/"..nodenumber

    local response, code, msg = httpclient.request_to_buffer(uri, options)

    print(code)

    if code == 200 then
        print("Registrator: "..nodenumber.." found")
    elseif code then
        print("Registrator: could not find nodenumber "..nodenumber.." with code "..code)
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


status(url)
