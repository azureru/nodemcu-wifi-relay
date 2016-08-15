-- Which relay we use
Relay1 = 1
gpio.mode(Relay1, gpio.OUTPUT)

-- Basically check for the existence of `on.state` file
-- If it exists then the relay is in `on` state
if file.exists("on.state") then
  gpio.write(Relay1, gpio.HIGH);
else
  gpio.write(Relay1, gpio.LOW);
end

-- function to turn on and write state
function makeOn()
  gpio.write(Relay1, gpio.HIGH);
  file.open("on.state", "w+")
  file.write("1")
  file.close()
end

-- function to turn off and remove state
function makeOff()
  gpio.write(Relay1, gpio.LOW);
  file.remove("on.state")
end

-- put your WIFI configuration here
-- it's hard coded - for home hack
-- but there's some module out there that can make this more pretty (e.g. http://nodemcu.readthedocs.io/en/dev/en/modules/enduser-setup/)
wifi.setmode(wifi.STATION)
cfg = {
    ip      ="10.0.1.10",
    netmask ="255.255.255.0",
    gateway ="10.0.1.1"
  }
wifi.sta.setip(cfg)
wifi.sta.config("YourWifiSSID","YourWifiPassword")
wifi.sta.autoconnect(1)

print ("Begin \r\n")
print(wifi.sta.getip())

-- The HTTP server
if srv~=nil then
  srv:close()
end
srv=net.createServer(net.TCP)
srv:listen(80,function(conn) --change port number if required. Provides flexibility when controlling through internet.
    conn:on("receive", function(client,request)
        local html_buffer = "HTTP/1.0 200 OK\r\nServer:relay\r\nContent-Type:text/html\r\nConnection:close\r\n\r\n";

        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        local _GET = {}
        if (vars ~= nil)then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                _GET[k] = v
            end
        end

        if(_GET.pin == "ON")then
           makeOn();
           html_buffer = html_buffer .. "ON";
        elseif(_GET.pin == "OFF")then
           makeOff()
           html_buffer = html_buffer .. "OFF";
        elseif (_GET.pin == "STATE")then
            if file.exists("on.state") then
              html_buffer = html_buffer .. "ON";
            else
              html_buffer = html_buffer .. "OFF";
            end
        end

        -- return HTTP result
        client:send(html_buffer);
        client:close();
        collectgarbage();
    end)
end)
