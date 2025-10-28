ESP32 MQTT Requirements
1. Connection Setup
Connect to Adafruit IO MQTT broker at io.adafruit.com:1883
Authenticate with:
Username: XiaohanYu1
Key: *find in key file*

2. SUBSCRIBE TO (Listen for commands from App)
The ESP32 should subscribe to these feeds to receive control commands:


XiaohanYu1/feeds/HEATER_CTRL


Receives heater/temperature control commands
Expected payload: JSON with fish_id, target_temperature, timestamp
XiaohanYu1/feeds/PH_CTRL


Receives pH control commands
Expected payload: JSON with fish_id, target_ph, timestamp
XiaohanYu1/feeds/PUMP_CTRL


Receives water pump control commands
Expected payload: JSON with fish_id, state (1=ON, 0=OFF), timestamp


3. PUBLISH TO (Send sensor data to App)
The ESP32 should publish sensor readings and status to these feeds:


XiaohanYu1/feeds/TEMP_SENSOR


Send temperature readings
Payload options:
JSON: {"fish_id": "Neon Tetra", "temperature": 23.5, "timestamp": "..."}
Simple: 23.5 (applied globally to all fish)
XiaohanYu1/feeds/PH_SENSOR


Send pH readings
Payload options:
JSON: {"fish_id": "Neon Tetra", "ph": 6.5, "timestamp": "..."}
Simple: 6.5 (applied globally)
XiaohanYu1/feeds/SYS_STATUS


Send system status updates
Payload: JSON {"fish_id": "...", "status": "OK/ERROR", "pump_on": true/false, "message": "..."}
XiaohanYu1/feeds/WATER_AMMONIUM


Send ammonium sensor status
Payload: true (good/green) or false (bad/red)
Also accepts: 1/0 or JSON {"status": true/false}
XiaohanYu1/feeds/WATER_NITRATE


Send nitrate sensor status
Payload: true (good/green) or false (bad/red)
XiaohanYu1/feeds/WATER_NITRITE

Send nitrite sensor status
Payload: true (good/green) or false (bad/red)
