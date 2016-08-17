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

function module.start()
    -- Which relay we use
    gpio.mode(config.RELAY_PIN, gpio.OUTPUT)

    -- Check for initial
    checkPrerequisites()

    -- HTTP Server
    srv=net.createServer(net.TCP)
    srv:listen(80,function(conn) --change port number if required. Provides flexibility when controlling through internet.
        conn:on("receive", function(client,request)
            local html_buffer = "HTTP/1.0 200 OK\r\nServer:relay\r\nAccess-Control-Allow-Origin:*\r\nContent-Type:text/json\r\nConnection:close\r\n\r\n";

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

            if(_GET.pin == "ON")then
               makeOn();
               html_buffer = html_buffer .. config.STATE_ON;
            elseif(_GET.pin == "OFF")then
               makeOff()
               html_buffer = html_buffer .. config.STATE_OFF;
            else
                if file.exists("on.state") then
                  html_buffer = html_buffer .. config.STATE_ON;
                else
                  html_buffer = html_buffer .. config.STATE_OFF;
                end
            end

            -- return HTTP result
            client:send(html_buffer);
            client:close();
            collectgarbage();
        end)
    end)
end

return module
