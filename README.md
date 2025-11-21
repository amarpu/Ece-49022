# ESP32 & Flutter IoT Controller

**Project:** Fintastic 4+1  
**Focus:** App Design & Connectivity

This repository houses the source code for controlling an ESP32 microcontroller via a Flutter mobile application. It documents the evolution of our connectivity approach, culminating in a Wide Area Network (WAN) solution.

## Communication Protocols

We explored three distinct methods of communication during development:

1. **Wide Area Network (WAN) via MQTT (Final Implementation)**
   * **How it works:** The Flutter app and ESP32 communicate through a central MQTT broker (e.g., Adafruit IO).
   * **Benefit:** Allows control of the ESP32 from anywhere in the world with an internet connection.

2. **Local Area Network (LAN)**
   * **How it works:** The Flutter app communicates directly with the ESP32 over a local WiFi network.
   * **Limitation:** Both the phone and device must be on the same network.

3. **Bluetooth Low Energy (BLE)**
   * **How it works:** Direct Bluetooth connection between phone and device.
   * **Status:** Replaced by WiFi/MQTT for better range and flexibility.

---

## 📂 Project Structure

### 🚀 Current & Working Code (MQTT)
*Use these files for the most up-to-date, functional version of the project.*

* `Flutter/frontend`
  * **Description:** The latest, polished Flutter application. Features an improved UI for controlling the ESP32 over the internet. **(Recommended)**

* `ESP32/sketch_oct9a`
  * **Description:** The primary ESP32 sketch. Handles WiFi credentials and subscribes to the MQTT feeds used by the frontend app.

### ⚠️ Deprecated / Reference Code (MQTT)
*Functional, but superseded by the files above.*

* `ESP32/sketch_sep30a`
  * **Description:** Initial working version of the MQTT logic. (See `wifi_mqtt_setup_but_as_functions.ino` for the logic expansion).

* `Flutter/wifi_mqtt`
  * **Description:** Initial working version of the MQTT app. Contains core logic but lacks the UI improvements found in `frontend`.

---

## 📦 Archive
*These folders represent earlier development stages (LAN & BLE). They are kept for historical reference and are no longer supported.*

**Local Area Network (LAN) Versions**
* `ESP32/sketch_sep30a` (LAN Variant): Acts as a local web server.
* `Flutter/wifi_test`: Requires the ESP32's local IP address to function.

**Bluetooth (BLE) Versions**
* `esp32_Transmission_Arduino_IDE_Working`: Early BLE prototype.
* `esp32_ble_app`: Corresponding Flutter app for BLE control.
