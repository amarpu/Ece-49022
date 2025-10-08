**ESP32 & Flutter IoT Controller**

As a part of the Fintastic 4+1 project, this repository focuses on the App Design and connectivity side of our goals.

We want to control an ESP32 microcontroller using a Flutter mobile application, and we have the complete code for three different communication methods:

Bluetooth Low Energy (BLE): The flutter app communicates with the ESP32 via a Bluetooth connection.

Local Area Network (LAN): The Flutter app communicates directly with the ESP32 over a local WiFi network. This is ideal for situations where both the phone and the device are on the same network.

Wide Area Network (WAN) via MQTT: The Flutter app and the ESP32 communicate through a central MQTT broker (like Adafruit IO). This allows the app to control the ESP32 from anywhere in the world with an internet connection.

**Project Structure & Key Files**

This repository contains several versions of the project, documenting its evolution from Bluetooth LE to the final MQTT implementation.

**Current & Working Code**

These folders contain the most up-to-date and functional versions of the project.

* WiFi MQTT Front End - Flutter/frontend

Purpose: The latest and most polished Flutter application. It features an improved user interface for controlling the ESP32 over the internet (WAN) using MQTT. This is the recommended mobile app to use.

* wifi_mqtt_setup_but_as_functions.ino

Purpose: The latest and refactored Arduino code for the ESP32. It connects to the MQTT broker and has been organized into functions for better readability and maintenance. This is the recommended code to flash onto the ESP32.

* WiFi MQTT - ESP32/sketch_sep30a

Purpose: The initial working version of the ESP32 code for MQTT communication. It's functional but has been improved upon by wifi_mqtt_setup_but_as_functions.ino.

* WiFi MQTT - Flutter/wifi_mqtt

Purpose: The initial working version of the Flutter app for MQTT communication. It has the core logic but has been superseded by the improved design in the WiFi MQTT Front End folder.

**archived Archived / Outdated Code**

These folders represent earlier stages of the project and should be considered deprecated. They are kept for historical reference.

* WiFi LAN Test - ESP32/sketch_sep30a

Status: Outdated.

Description: The ESP32 code for the direct LAN connection (acting as a web server). It works but is limited to local network control.

* WiFi LAN Test - Flutter/wifi_test

Status: Outdated.

Description: The Flutter app for the direct LAN connection. It requires the ESP32's local IP address to function.

* esp32_Transmission_Arduino_IDE_Working

Status: Outdated.

Description: An early version of the project that used Bluetooth Low Energy (BLE) for communication. This was replaced by the more flexible WiFi/MQTT approach.

* esp32_ble_app - Working Copy

Status: Outdated.

Description: The Flutter app corresponding to the BLE version of the project.
