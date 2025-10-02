#include <WiFi.h>
#include <WebServer.h>
#include "esp_eap_client.h"
#include <Adafruit_NeoPixel.h> // Library for the RGB LED

// WiFi Credentials for WPA2-Enterprise
const char* ssid = "PAL3.0"; 
const char* eap_username = "yu1206"; // AND THIS
const char* eap_password = "PASSWORD_HERE"; // CHANGE THIS HERE

// Web Server Setup
WebServer server(80);

// Onboard RGB LED (NeoPixel) Setup - OUR BOARD DOESN'T HAVE THIS - MY TESTING BOARD DOES
#define RGB_LED_PIN 38
Adafruit_NeoPixel pixels(1, RGB_LED_PIN, NEO_GRB + NEO_KHZ800);
bool ledState = false;

// WiFi Event Handler for Debugging
void WiFiEvent(WiFiEvent_t event, WiFiEventInfo_t info){
  Serial.println();
  Serial.printf("[WiFi Event] event: %d\n", event);
  switch (event) {
    case ARDUINO_EVENT_WIFI_STA_START: Serial.println("WiFi station started."); break;
    case ARDUINO_EVENT_WIFI_STA_CONNECTED: Serial.println("WiFi connected to AP."); break;
    case ARDUINO_EVENT_WIFI_STA_GOT_IP: Serial.print("Obtained IP address: "); Serial.println(WiFi.localIP()); break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      Serial.println("Disconnected from WiFi.");
      Serial.print("Reason code: "); Serial.println(info.wifi_sta_disconnected.reason);
      if (info.wifi_sta_disconnected.reason == 201) {
        Serial.println("Reason: AUTHENTICATION FAILED. Check credentials.");
      }
      Serial.println("Retrying connection...");
      break;
    default: Serial.printf("Unhandled event: %d\n", event); break;
  }
}

// Web Server Handler Functions 
void handleRoot() {
  server.send(200, "text/plain", "Hello from your ESP32-S3!");
}
void handleLedOn() {
  pixels.setPixelColor(0, pixels.Color(0, 0, 150)); // Set to a medium blue
  pixels.show(); // This sends the updated color to the LED
  ledState = true;
  server.send(200, "text/plain", "LED is now ON (Blue)");
}
void handleLedOff() {
  pixels.clear(); // Set pixel 0 to 'off'
  pixels.show(); // This sends the updated color to the LED
  ledState = false;
  server.send(200, "text/plain", "LED is now OFF");
}
void handleStatus() {
  String jsonResponse = "{\"status\":\"";
  jsonResponse += (ledState ? "on" : "off");
  jsonResponse += "\"}";
  server.send(200, "application/json", jsonResponse);
}
void handleNotFound(){
  server.send(404, "text/plain", "404: Not found");
}

void setup() {
  Serial.begin(115200);
  while (!Serial) { delay(10); }

  pixels.begin();
  pixels.clear();
  pixels.show();

  Serial.println("\n--- ESP32 WiFi Setup ---");
  Serial.print("Connecting to "); Serial.println(ssid);

  WiFi.disconnect(true);
  WiFi.mode(WIFI_STA);
  WiFi.onEvent(WiFiEvent);
  
  // Set only the username and password
  esp_eap_client_set_username((uint8_t *)eap_username, strlen(eap_username));
  esp_eap_client_set_password((uint8_t *)eap_password, strlen(eap_password));
  esp_wifi_sta_enterprise_enable();
  
  WiFi.begin(ssid);

  Serial.println("Waiting for WiFi connection...");
  while (WiFi.status() != WL_CONNECTED) { delay(500); }

  Serial.println("\n--- Setup Complete ---");
  Serial.print("ESP32 IP Address: "); Serial.println(WiFi.localIP());

  server.on("/", handleRoot);
  server.on("/led_on", handleLedOn);
  server.on("/led_off", handleLedOff);
  server.on("/status", handleStatus);
  server.onNotFound(handleNotFound);

  server.begin();
  Serial.println("HTTP server started");
}

void loop() {
  server.handleClient();
}

