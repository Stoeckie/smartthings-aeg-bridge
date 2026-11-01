# AEG / Electrolux dryer in SmartThings

Get an **AEG or Electrolux tumble dryer** (and washer-dryer) into SmartThings with status, remaining time, door and a "cycle finished" state you can use for notifications. Uses the **official Electrolux Group Developer API**.

The code lives in **[Stoeckie/smartthings-stoeckie-bridge](https://github.com/Stoeckie/smartthings-stoeckie-bridge)**: one small bridge (Windows or Docker) plus the Edge driver **Stoeckie Bridge (local)**. The same bridge also does Fujitsu FGLair air conditioners, Škoda cars the VELUX ACTIVE departure mode and a Buienradar rain radar; you only set up what you have.

## What you get

* `dryerOperatingState`: run / pause / stop, job state (drying, cooling, wrinkle prevent, finished), completion time
* `remoteControlStatus`
* `contactSensor`: door open / closed
* Start, pause and stop (when remote control is enabled on the appliance)

Routine example: *Dryer job state = Finished → send notification*.

## Install

1. Install the bridge and the Edge driver: see [smartthings-stoeckie-bridge](https://github.com/Stoeckie/smartthings-stoeckie-bridge#1-bridge-on-windows).
2. Log in at **developer.electrolux.one** with your AEG / Electrolux app account (e-mail and password; if you normally log in with Google/Apple or a code, set a password first). Create an **API key** and **generate a token**.
3. Paste API key, access token and refresh token in the **AEG / Electrolux** section of the bridge setup page. The bridge refreshes the tokens itself.
4. SmartThings app: **Add device → Scan nearby**. The dryer appears under the Stoeckie Bridge.

Siemens and Bosch do not need this: Home Connect has an official SmartThings integration.

## License

Apache 2.0. Not affiliated with AB Electrolux, AEG or Samsung SmartThings.
