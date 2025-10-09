#include "aquarium_mqtt.h"

void setup() {
  // Initialize Serial for debugging
  Serial.begin(115200);
  
  // Run the setup function that contains all the WiFi and MQTT logic
  aquarium_setup();
}

void loop() {
  // Run the loop function that handles all MQTT messages and sensor publishing
  aquarium_loop();
}