-- file : application.lua
local module = {}
m = nil

local function isStateOn()
  if file.exists("on.state") then
     return true
  else
     return false
  end
end

-- function to turn on and write state
local function makeOn()
  local pin = gpio.HIGH
  if config.RELAY_MODE == "nc" then
    pin = gpio.LOW
  end
  gpio.write(config.RELAY_PIN, pin);
  file.open("on.state", "w+")
  file.write("1")
  file.close()
end

-- function to turn off and remove state
local function makeOff()
  local pin = gpio.LOW
  if config.RELAY_MODE == "nc" then
    pin = gpio.HIGH
  end
  gpio.write(config.RELAY_PIN, pin);
  file.remove("on.state")
end

local function checkPrerequisites()
    -- Basically check for the existence of `on.state` file
    -- If it exists then the relay is in `on` state
    local pin = gpio.HIGH
    if isStateOn() then
      if (config.RELAY_MODE == "nc") then
        pin = gpio.LOW
      else
        pin = gpio.HIGH
      end
    else
      if (config.RELAY_MODE == "nc") then
        pin = gpio.HIGH
      else
        pin = gpio.LOW
      end
    end
    gpio.write(config.RELAY_PIN, pin);
end

local function sendHttp(client, statusCode, httpText)
    if (statusCode == "200") then
        statusCode = statusCode .. " OK"
    elseif statusCode == "401" then
        statusCode = statusCode .. " Unauthorized"
    elseif statusCode == "400" then
        statusCode = statusCode .. " Bad Request"
    end

    local htmlBuffer = "HTTP/1.0 ".. statusCode .."\r\nServer:nodemcu-wifi-relay\r\nAccess-Control-Allow-Origin:*\r\nContent-Type:application/json\r\nConnection:close\r\n\r\n";

    -- return HTTP result
    client:send(htmlBuffer .. httpText);
    collectgarbage();
end

local function checkAuth(auth)
    -- auth token is basically SHA1(secret + SHA1(id)) (HMACSHA1?)
    local sha1Id = crypto.toHex(crypto.hash("sha1", config.ID))
    local sha1Auth = crypto.toHex(crypto.hash("sha1", config.SECRET .. sha1Id))
    print(sha1Auth)
    if (sha1Auth == auth) then
        return true
    else
        return false
    end
end

function module.start()
    -- Which relay we use
    gpio.mode(config.RELAY_PIN, gpio.OUTPUT)

    -- Check for initial
    checkPrerequisites()

    -- HTTP Server
    srv=net.createServer(net.TCP)
    srv:listen(80,function(conn) --change port number if required. Provides flexibility when controlling through internet.
        conn:on("receive", function(client,request)

            -- parse HTTP proto texts
            local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
            if(method == nil)then
                _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
            end
            -- parse QS
            local _GET = {}
            if (vars ~= nil)then
                for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                    _GET[k] = v
                end
            end

            -- auth
            if config.AUTH == 1 then
                -- check for auth
                local auth = _GET.auth
                if auth == "" or auth == nil then
                    sendHttp(client, "401", '{"code":401,"message":"Missing Auth!"}')
                    return
                end
                -- check the auth
                if checkAuth(auth) then 
                    -- OK, moving on :)
                else
                    sendHttp(client, "401", '{"code":401,"message":"Invalid Auth!"}')
                    return
                end
            end

            if (_GET.pin == "ON") then
               makeOn();
               sendHttp(client, "200", config.STATE_ON)
            elseif (_GET.pin == "OFF") then
               makeOff()
               sendHttp(client, "200", config.STATE_OFF)
            else
                if file.exists("on.state") then
                    sendHttp(client, "200", config.STATE_ON)
                else
                    sendHttp(client, "200", config.STATE_OFF)
                end
            end
        end)
        conn:on("sent", function(client) client:close() end)
    end)
end

return module
