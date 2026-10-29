# AEG / Electrolux dryer in SmartThings (bridge + Edge driver)

Get an **AEG or Electrolux tumble dryer** (and washer-dryer) into SmartThings with status, remaining time, door and a "cycle finished" state you can use for notifications. Uses the **official Electrolux Group Developer API**.

The Electrolux API is cloud only, and SmartThings Edge drivers can not reach the internet. So there are two parts:

```
Electrolux cloud --live events--> bridge (Windows pc or Docker, port 8787) <--LAN-- Edge driver on the hub
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

## 1. Bridge (Windows pc)

1. Copy the `bridge` folder to the pc, e.g. `C:\StoeckieBridge`.
2. Double-click `install.bat`. It installs Python if needed (winget), the packages, a firewall rule for port 8787 (Windows asks for permission once) and a scheduled task that starts the bridge at logon and restarts it on failure. Then the setup page opens.
3. Log in at **developer.electrolux.one** with your AEG / Electrolux app account (e-mail and password; if you normally log in with Google/Apple or a code, set a password first). Create an **API key** and **generate a token**.
4. Paste API key, access token and refresh token on the setup page: `setup.bat` or http://localhost:8787/setup (only reachable on the pc itself).
5. `check-aeg.bat` tests the login and lists your appliances. `restart.bat` restarts the bridge and writes `devices.json`. Log: `bridge.log`.

Set the Windows network to **Private** and give the pc a fixed IP (DHCP reservation), otherwise the hub can not reach the bridge.

The bridge refreshes the tokens itself and saves them in `config.json`. Credentials only live in that file on the pc (it is in `.gitignore`).

Test without appliances: `venv\Scripts\python.exe stoeckie_bridge.py --demo`.

## 1b. Bridge in Docker (instead of Windows)

```
cd bridge
docker compose up -d --build
```

* Uses host networking, so the hub finds the bridge on the host IP, port 8787. Data (config.json with the refreshed tokens, log) lives in `bridge/data`.
* Setup page: http://localhost:8787/setup on the Docker host. From another computer: set `STBRIDGE_SETUP_ALLOW: "192.168.x.0/24"` in `docker-compose.yml`.
* Or pass the credentials once as `ELECTROLUX_API_KEY`, `ELECTROLUX_ACCESS_TOKEN`, `ELECTROLUX_REFRESH_TOKEN` (only read on the first start; after that the bridge keeps refreshed tokens in `data/config.json`).
* Without host networking (Docker Desktop on Windows/Mac): use `ports: ["8787:8787"]` instead of `network_mode: host`, and set `STBRIDGE_SETUP_ALLOW`.

## 2. Edge driver (hub)

1. Enroll your hub in the channel: https://bestow-regional.api.smartthings.com/invite/qWjBdybRNG2y (Stoeckie Edge Drivers) and install **Stoeckie Bridge (local)**.
2. SmartThings app: **Add device → Scan nearby**. The driver scans the hub's subnet on port 8787 and creates a "Stoeckie Bridge" device; the dryer appears at the next poll.

Bridge LAN API (no auth, LAN only): `GET /stbridge/info`, `GET /stbridge/devices`, `POST /stbridge/devices/<id>/command` with `{"cmd": "run|pause|resume|stop|refresh"}`.

## Siemens / Bosch?

Not needed: Home Connect appliances have an official SmartThings integration (Add device → Home Connect).

## License

Apache 2.0, see LICENSE. Not affiliated with AB Electrolux, AEG or Samsung SmartThings.
