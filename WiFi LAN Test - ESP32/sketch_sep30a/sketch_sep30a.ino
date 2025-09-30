/*
 * ESP32-S3 MQTT Client for Adafruit IO
 * Connects to WPA2-Enterprise WiFi, then connects to an MQTT broker (Adafruit IO)
 * to listen for commands to control the onboard RGB LED.
 *
 * This replaces the WebServer with an MQTT client, allowing for control over the internet.
 *
 * REQUIRED LIBRARIES:
 * - Adafruit NeoPixel
 * - Adafruit MQTT Library
 */

 // IF THIS DOESN'T WORK, LET LUCAS KNOW

#include <WiFi.h>
#include "esp_eap_client.h"
#include <Adafruit_NeoPixel.h>
#include "Adafruit_MQTT.h"
#include "Adafruit_MQTT_Client.h"

// --- WiFi Credentials (Your School's Network) ---
const char* ssid = "PAL3.0";
const char* eap_username = "yu1206";
const char* eap_password = "PASSWORD";  //Change this

// --- Adafruit IO MQTT Broker Configuration ---
#define AIO_SERVER      "io.adafruit.com"
#define AIO_SERVERPORT  1883
#define AIO_USERNAME    "XiaohanYu1"
#define AIO_KEY         "_aio_NTnz10gHo8ptPPrgOyJGFKTpS3dd" // CHANGE THSI TOO

// --- Onboard RGB LED (NeoPixel) Setup ---
#define RGB_LED_PIN 38
Adafruit_NeoPixel pixels(1, RGB_LED_PIN, NEO_GRB + NEO_KHZ800);
bool ledState = false;

// --- MQTT Client Setup ---
WiFiClient client;
Adafruit_MQTT_Client mqtt(&client, AIO_SERVER, AIO_SERVERPORT, AIO_USERNAME, AIO_KEY);

// Setup a feed called 'led-control' for subscribing to changes.
Adafruit_MQTT_Subscribe ledFeed = Adafruit_MQTT_Subscribe(&mqtt, AIO_USERNAME "/feeds/led-control");

// --- Function Prototypes ---
void WiFiEvent(WiFiEvent_t event, WiFiEventInfo_t info);
void MQTT_connect();

// --- Main Setup and Loop ---
void setup() {
  Serial.begin(115200);
  while (!Serial) { delay(10); }

  pixels.begin();
  pixels.clear();
  pixels.show();

  Serial.println("\n--- ESP32 MQTT Client ---");
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

  // Subscribe to the feed for LED control
  mqtt.subscribe(&ledFeed);

  Serial.println("\n--- Setup Complete ---");
}

void loop() {
  MQTT_connect();

  Adafruit_MQTT_Subscribe *subscription;
  while ((subscription = mqtt.readSubscription(5000))) {
    if (subscription == &ledFeed) {
      Serial.print(F("Received message on led-control feed: "));
      Serial.println((char *)ledFeed.lastread);

      if (strcmp((char *)ledFeed.lastread, "ON") == 0) {
        Serial.println("aTurning LED ON (Blue)");
        pixels.setPixelColor(0, pixels.Color(0, 0, 150));
        pixels.show();
        ledState = true;
      }
      if (strcmp((char *)ledFeed.lastread, "OFF") == 0) {
        Serial.println("Turning LED OFF");
        pixels.clear();
        pixels.show();
        ledState = false;
      }
    }
  }

  if (!mqtt.ping()) {
    mqtt.disconnect();
  }
}

// --- Helper Functions ---

// Function to connect and reconnect as necessary to the MQTT server.
void MQTT_connect() {
  int8_t ret;

  // Stop if already connected.
  if (mqtt.connected()) {
    return;
  }

  Serial.print("Connecting to MQTT... ");

  uint8_t retries = 3;
  while ((ret = mqtt.connect()) != 0) { // connect will return 0 for connected
       Serial.println(mqtt.connectErrorString(ret));
       Serial.println("Retrying MQTT connection in 5 seconds...");
       mqtt.disconnect();
       delay(5000);  // wait 5 seconds
       retries--;
       if (retries == 0) {
         // basically die and wait for WDT to reset me
         while (1);
       }
  }
  Serial.println("MQTT Connected!");
}

// WiFi Event Handler for Debugging
void WiFiEvent(WiFiEvent_t event, WiFiEventInfo_t info){
  switch (event) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      Serial.print("\nObtained IP address: ");
      Serial.println(WiFi.localIP());
      break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      Serial.println("\nDisconnected from WiFi. Retrying...");
      break;
    default:
      break;
  }
}
