#include "aquarium_mqtt.h"
#include <WiFi.h>
#include "esp_eap_client.h"
#include <Adafruit_NeoPixel.h>
#include "Adafruit_MQTT.h"
#include "Adafruit_MQTT_Client.h"
#include <ArduinoJson.h>

// WiFi Credentials
const char* ssid = "PAL3.0";
const char* eap_username = "yu1206";
const char* eap_password = "xxxxxxxxxxx";

// Adafruit IO MQTT Broker Configuration
#define AIO_SERVER      "io.adafruit.com"
#define AIO_SERVERPORT  1883
#define AIO_USERNAME    "XiaohanYu1"
#define AIO_KEY         "xxxxxxxxxxxx"

// Hardware Pin Definitions
#define HEATER_RELAY_PIN 25
#define PH_RELAY_PIN     26
#define PUMP_RELAY_PIN   27
#define RGB_LED_PIN 38

Adafruit_NeoPixel pixels(1, RGB_LED_PIN, NEO_GRB + NEO_KHZ800);
WiFiClient client;
Adafruit_MQTT_Client mqtt(&client, AIO_SERVER, AIO_SERVERPORT, AIO_USERNAME, AIO_KEY);

// MQTT Feeds 
Adafruit_MQTT_Publish tempSensorFeed = Adafruit_MQTT_Publish(&mqtt, AIO_USERNAME "/feeds/TEMP_SENSOR");
Adafruit_MQTT_Publish phSensorFeed = Adafruit_MQTT_Publish(&mqtt, AIO_USERNAME "/feeds/PH_SENSOR");
Adafruit_MQTT_Publish sysStatusFeed = Adafruit_MQTT_Publish(&mqtt, AIO_USERNAME "/feeds/SYS_STATUS");
Adafruit_MQTT_Subscribe heaterControlFeed = Adafruit_MQTT_Subscribe(&mqtt, AIO_USERNAME "/feeds/HEATER_CTRL");
Adafruit_MQTT_Subscribe phControlFeed = Adafruit_MQTT_Subscribe(&mqtt, AIO_USERNAME "/feeds/PH_CTRL");
Adafruit_MQTT_Subscribe pumpControlFeed = Adafruit_MQTT_Subscribe(&mqtt, AIO_USERNAME "/feeds/PUMP_CTRL");

// Global Variables for Timers 
unsigned long lastSensorPublish = 0;
const long sensorPublishInterval = 30000;

// Helper function prototypes (private to this file) 
static void MQTT_connect();
static void handleControlMessage(const char* device, const char* message);
static void publishSensorData();
static float getTemperature();
static float getPH();
static void WiFiEvent(WiFiEvent_t event, WiFiEventInfo_t info);


void aquarium_setup() {
  pixels.begin();
  pixels.clear();
  pixels.show();

  pinMode(HEATER_RELAY_PIN, OUTPUT);
  pinMode(PH_RELAY_PIN, OUTPUT);
  pinMode(PUMP_RELAY_PIN, OUTPUT);
  digitalWrite(HEATER_RELAY_PIN, LOW);
  digitalWrite(PH_RELAY_PIN, LOW);
  digitalWrite(PUMP_RELAY_PIN, LOW);
  
  Serial.println("\n--- Aquarium MQTT Controller ---");
  Serial.print("Connecting to WiFi: "); Serial.println(ssid);

  WiFi.disconnect(true);
  WiFi.mode(WIFI_STA);
  WiFi.onEvent(WiFiEvent);
  
  esp_eap_client_set_username((uint8_t *)eap_username, strlen(eap_username));
  esp_eap_client_set_password((uint8_t *)eap_password, strlen(eap_password));
  esp_wifi_sta_enterprise_enable();
  
  WiFi.begin(ssid);

  Serial.println("Waiting for WiFi connection...");
  while (WiFi.status() != WL_CONNECTED) { delay(500); }

  mqtt.subscribe(&heaterControlFeed);
  mqtt.subscribe(&phControlFeed);
  mqtt.subscribe(&pumpControlFeed);

  Serial.println("\n--- Setup Complete ---");
}

void aquarium_loop() {
  MQTT_connect();

  Adafruit_MQTT_Subscribe *subscription;
  while ((subscription = mqtt.readSubscription(1000))) {
    if (subscription == &heaterControlFeed) {
      handleControlMessage("Heater", (char *)heaterControlFeed.lastread);
    }
    if (subscription == &phControlFeed) {
      handleControlMessage("pH", (char *)phControlFeed.lastread);
    }
    if (subscription == &pumpControlFeed) {
      handleControlMessage("Pump", (char *)pumpControlFeed.lastread);
    }
  }

  unsigned long currentMillis = millis();
  if (currentMillis - lastSensorPublish >= sensorPublishInterval) {
    lastSensorPublish = currentMillis;
    publishSensorData();
  }

  if (!mqtt.ping()) {
    mqtt.disconnect();
  }
}

static void handleControlMessage(const char* device, const char* message) {
    Serial.printf("Received message for %s: %s\n", device, message);

    StaticJsonDocument<100> doc;
    DeserializationError error = deserializeJson(doc, message);

    if (error) {
        Serial.print(F("deserializeJson() failed: "));
        Serial.println(error.c_str());
        sysStatusFeed.publish("Error: Invalid JSON received.");
        return;
    }

    const char* action = doc["action"];
    
    if (strcmp(device, "Heater") == 0) {
        if (strcmp(action, "ON") == 0) {
            digitalWrite(HEATER_RELAY_PIN, HIGH);
            sysStatusFeed.publish("Heater turned ON");
        } else if (strcmp(action, "OFF") == 0) {
            digitalWrite(HEATER_RELAY_PIN, LOW);
            sysStatusFeed.publish("Heater turned OFF");
        }
    } else if (strcmp(device, "Pump") == 0) {
        if (strcmp(action, "ON") == 0) {
            digitalWrite(PUMP_RELAY_PIN, HIGH);
            sysStatusFeed.publish("Pump turned ON");
        } else if (strcmp(action, "OFF") == 0) {
            digitalWrite(PUMP_RELAY_PIN, LOW);
            sysStatusFeed.publish("Pump turned OFF");
        }
    } else if (strcmp(device, "pH") == 0) {
        if (strcmp(action, "DOSE") == 0) {
            digitalWrite(PH_RELAY_PIN, HIGH);
            sysStatusFeed.publish("pH dosing started...");
            delay(2000);
            digitalWrite(PH_RELAY_PIN, LOW);
            sysStatusFeed.publish("pH dosing complete.");
        }
    }
}

static void publishSensorData() {
    float temp = getTemperature();
    float ph = getPH();
    Serial.printf("Publishing Temp: %.2f C, pH: %.2f\n", temp, ph);
    tempSensorFeed.publish(temp);
    phSensorFeed.publish(ph);
}

static float getTemperature() {
    return 25.5 + ((float)random(0, 100) / 100.0);
}

static float getPH() {
    return 6.8 + ((float)random(0, 40) / 100.0);
}

static void MQTT_connect() {
  int8_t ret;
  if (mqtt.connected()) return;

  Serial.print("Connecting to MQTT... ");
  pixels.setPixelColor(0, pixels.Color(150, 75, 0));
  pixels.show();

  uint8_t retries = 3;
  while ((ret = mqtt.connect()) != 0) {
       Serial.println(mqtt.connectErrorString(ret));
       Serial.println("Retrying MQTT connection in 5 seconds...");
       mqtt.disconnect();
       delay(5000);
       if (--retries == 0) while (1);
  }
  Serial.println("MQTT Connected!");
  pixels.setPixelColor(0, pixels.Color(0, 0, 150));
  pixels.show();
}

static void WiFiEvent(WiFiEvent_t event, WiFiEventInfo_t info){
  if (event == ARDUINO_EVENT_WIFI_STA_GOT_IP) {
      Serial.print("\nObtained IP address: ");
      Serial.println(WiFi.localIP());
  } else if (event == ARDUINO_EVENT_WIFI_STA_DISCONNECTED) {
      Serial.println("\nDisconnected from WiFi. Retrying...");
  }
}