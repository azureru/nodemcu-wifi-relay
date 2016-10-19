-- file: setup.lua
local module = {}

local function wifi_wait_ip()
  if wifi.sta.getip()== nil then
    print("IP unavailable, Waiting...")
  else
    tmr.stop(1)
    print("\n====================================")
    print("ID is: " .. config.ID)
    print("ESP8266 mode is: " .. wifi.getmode())
    print("MAC address is: " .. wifi.ap.getmac())
    print("IP is "..wifi.sta.getip())
    print("====================================")
    app.start()
  end
end

local function wifi_start(list_aps)
    local found = false

    print("List Aps ...\r\n")
    if list_aps then
        for key,value in pairs(list_aps) do
            print(" " .. key)
            if config.SSID and config.SSID[key] then
                wifi.setmode(wifi.STATION);
                wifi.setphymode(config.SIGNAL_MODE)
                if config.STATIC == 1 then
                    cfg = {
                        ip      = config.IP,
                        netmask = config.NETMASK,
                        gateway = config.GATEWAY
                      }
                    wifi.sta.setip(cfg)
                end
                print("Connecting...")
                wifi.sta.config(key, config.SSID[key])
                wifi.sta.connect()
                found = true
                --config.SSID = nil  -- can save memory
                tmr.alarm(1, 2500, 1, wifi_wait_ip)
            end
        end
        if found ~= true then
            -- cannot find access point - restart the node to
            -- force reinit
            print('Cannot found AP')
            node.restart()
        end
    else
        -- error on getting AP list - restart the node to
        -- force reinit
        print("Error getting AP list")
        node.restart()
    end
end

function module.start()
    -- Which relay we use
    gpio.mode(config.RELAY_PIN, gpio.OUTPUT)

    -- initial set relay state based on the state file
    -- so the relay immediately recover in event of power failure
    local pin = gpio.HIGH
    if file.exists("on.state") then
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

    -- Start the WIFI connection
    print("Configuring Wifi... ")

    if wifi.sta.status() == wifi.STA_GOTIP then
        -- already connected - no need to proceed the wifi connect below
        print('Already Connected... ')
        return
    end

    wifi.setmode(wifi.STATION);
    wifi.sta.getap(wifi_start)
end

return module
