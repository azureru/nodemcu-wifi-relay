# nodemcu-wifi-relay

A HTTP based relay that I use on my home.

# Upload

- Create `config.lua` based on `config.lua.dist`
- Modify the config to match with your environment
- Upload everything to your ESP
- Run `test.lua` to make sure - test accordingly
- Rename `test.lua` into `init.lua`

# Features
- Using Boostrap code
- Save `on/off` state to a file - so the relay can recover from the previous state (e.g. when there's a blackout)
- Expose JSON API

# Building Your Own

Hardware are purchased from AliExpress

- Wemos D1 [http://s.click.aliexpress.com/e/rBuVf2vrZ]
- Relay Shield [http://s.click.aliexpress.com/e/jqbEqb6i2]
- A ripped off 5v charger
- Some heat shrink tubes
- Some 10A cables

(disclaimer: The links are affiliate links)


