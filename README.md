# AEG / Electrolux dryer and Fujitsu FGLair air conditioners in SmartThings (bridge + Edge driver)

Get an **AEG or Electrolux tumble dryer** (and washer-dryer) into SmartThings with status, remaining time, door and a "cycle finished" state you can use for notifications. Uses the **official Electrolux Group Developer API**.

Also: **Fujitsu air conditioners with an FGLair wifi adapter** (power, mode, setpoint, fan, swing, room and outdoor temperature) through the cloud the FGLair app uses. Details: [smartthings-fujitsu-fglair](https://github.com/Stoeckie/smartthings-fujitsu-fglair) (same bridge and driver; one bridge serves both).

Both are cloud only, and SmartThings Edge drivers can not reach the internet. So there are two parts:

```
Electrolux cloud --live events--> bridge (Windows pc or Docker, port 8787) <--LAN-- Edge driver on the hub
FGLair (Ayla) cloud --poll 60 s-->
```

* `bridge/`: small Python service for a pc that is always on: Windows (installer) or any Docker host (Linux, NAS, Raspberry Pi)
* `driver/`: SmartThings Edge driver "Stoeckie Bridge (local)" that finds the bridge and creates the devices

## What you get

Per dryer:

* `dryerOperatingState`: run / pause / stop, job state (drying, cooling, wrinkle prevent, finished), completion time
* `remoteControlStatus`
* `contactSensor`: door open / closed
* Start, pause and stop commands (when remote control is enabled on the appliance)

Routine example: *Dryer job state = Finished → send notification*.

Per air conditioner (FGLair):

* `switch`: on / off
* `airConditionerMode`: auto, cool, dry, fan only, heat (what the unit supports)
* `thermostatCoolingSetpoint`: the target temperature in every mode (16 to 30 °C, 0.5 steps)
* `airConditionerFanMode`: quiet, low, medium, high, auto
* `fanOscillationMode`: fixed, vertical, horizontal, all (what the unit supports)
* `temperatureMeasurement`: room temperature (models with a sensor) and an `outdoor` component with the outdoor temperature

## 1. Bridge (Windows pc)

1. Copy the `bridge` folder to the pc, e.g. `C:\StoeckieBridge`.
2. Double-click `install.bat`. It installs Python if needed (winget), the packages, a firewall rule for port 8787 (Windows asks for permission once) and a scheduled task that starts the bridge at logon and restarts it on failure. Then the setup page opens.
3. Log in at **developer.electrolux.one** with your AEG / Electrolux app account (e-mail and password; if you normally log in with Google/Apple or a code, set a password first). Create an **API key** and **generate a token**.
4. Paste API key, access token and refresh token on the setup page: `setup.bat` or http://localhost:8787/setup (only reachable on the pc itself).
5. FGLair: enter the e-mail and password of the FGLair app on the same setup page (region Europe for EU accounts).
6. `check.bat` tests the logins and lists your appliances. `restart.bat` restarts the bridge and writes `devices.json`. Log: `bridge.log`.

Set the Windows network to **Private** and give the pc a fixed IP (DHCP reservation), otherwise the hub can not reach the bridge.

The bridge refreshes the tokens itself and saves them in `config.json`. Credentials only live in that file on the pc (it is in `.gitignore`).

Security: the setup page only answers on the pc itself (or the networks in `STBRIDGE_SETUP_ALLOW`), only when opened by IP or `localhost`, and refuses forms posted from other websites. The LAN API (`/stbridge/...`) only answers private and local addresses.

Test without appliances: `venv\Scripts\python.exe stoeckie_bridge.py --demo`.

## 1b. Bridge in Docker (instead of Windows)

```
cd bridge
docker compose up -d --build
```

* Uses host networking, so the hub finds the bridge on the host IP, port 8787. Data (config.json with the refreshed tokens, log) lives in `bridge/data`.
* Setup page: http://localhost:8787/setup on the Docker host. From another computer: set `STBRIDGE_SETUP_ALLOW: "192.168.x.0/24"` in `docker-compose.yml`.
* Or pass the credentials once as `ELECTROLUX_API_KEY`, `ELECTROLUX_ACCESS_TOKEN`, `ELECTROLUX_REFRESH_TOKEN` and `FGLAIR_USERNAME`, `FGLAIR_PASSWORD`, `FGLAIR_REGION` (only read on the first start; after that `data/config.json` wins).
* Without host networking (Docker Desktop on Windows/Mac): use `ports: ["8787:8787"]` instead of `network_mode: host`, and set `STBRIDGE_SETUP_ALLOW`.

## 2. Edge driver (hub)

1. Enroll your hub in the channel: https://bestow-regional.api.smartthings.com/invite/qWjBdybRNG2y (Stoeckie Edge Drivers) and install **Stoeckie Bridge (local)**.
2. SmartThings app: **Add device → Scan nearby**. The driver scans the hub's subnet on port 8787 and creates a "Stoeckie Bridge" device; the dryer and air conditioners appear at the next poll.

Bridge LAN API (no auth, LAN only): `GET /stbridge/info`, `GET /stbridge/devices`, `POST /stbridge/devices/<id>/command` with `{"cmd": "run|pause|resume|stop|refresh"}`.

## FGLair notes

* FGLair has no local API and no official cloud API. The bridge uses [ayla-iot-unofficial](https://pypi.org/project/ayla-iot-unofficial/), the library the Home Assistant Fujitsu FGLair integration uses. It can stop working when Fujitsu changes the cloud.
* Units the library does not know (for example AC-UTY wired controllers) are skipped with a line in `bridge.log` that shows the model; open an issue with that line.
* Airstage (newer Fujitsu modules) has a local API and is not covered here.

## Development

```
pip install -r bridge/requirements.txt pytest lupa
python -m pytest bridge/tests driver/tests
```

The FGLair test runs against a fake Ayla cloud; the driver test runs `driver/src/init.lua` with a mocked SmartThings runtime against the bridge in `--demo` mode.

## Škoda (official MyŠkoda public API)

The bridge also reads a **Škoda** car through Škoda's official public API (free, personal use): battery %, charging on/off and power, at home (saved charging location), plug, doors, and climate on/off. In SmartThings the main switch starts and stops charging; the Climate switch starts and stops the air conditioning.

1. In the MyŠkoda app (version 8.16 or newer) create an API key: open **go.skoda.eu/api-keys** on your phone and pick your car.
2. Enter the key and the VIN (17 characters) in the **Škoda** section of the setup page.

The API allows 20 calls per hour, so the bridge reads the car every 10 minutes (`"poll_minutes"` in `config.json`, at least 5) and 30 s after a command (once more 60 s later when the car has not reported the change yet). Interval and climate temperature can be changed on the setup page or in the car's settings in the SmartThings app. Keys expire; the setup page shows until when.

## iRobot favorites (optional)

With the [iRobot Roomba (local)](https://github.com/Stoeckie/smartthings-irobot-roomba-local) Edge driver, the bridge can read the names and rooms of your iRobot app favorites, so they show up in SmartThings without setup. Enter the e-mail and password of the iRobot app in the **iRobot** section of the setup page. The bridge only reads the favorites (twice a day, or when you press Refresh on the robot); the robot itself is controlled locally by the hub. Uses [roombapy-prime](https://github.com/johnnyh1975/roombapy-prime), an unofficial client: iRobot limits the number of logins per account.

## Siemens / Bosch?

Not needed: Home Connect appliances have an official SmartThings integration (Add device → Home Connect).

## License

Apache 2.0, see LICENSE. Not affiliated with AB Electrolux, AEG, Fujitsu General, Ayla Networks or Samsung SmartThings.
