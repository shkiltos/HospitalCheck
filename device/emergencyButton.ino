#include <ESP8266WiFi.h>
#include <ESP8266WiFiMulti.h>
#include <ESP8266HTTPClient.h>

#define USE_SERIAL Serial
#include <WiFiClientSecureBearSSL.h>

// If secure
// Fingerprint. Needs to be updated
const uint8_t fingerprint[20] = {0x50, 0xab, 0x51, 0xcb, 0xa1, 0xd6, 0x49, 0xf8, 0x5a, 0x71, 0x72, 0x2d, 0xbd, 0x40, 0x74, 0x0f, 0xa8, 0xf4, 0x25, 0x68};

// Post request body
const String postData = "{\"app_key\": \"***************\", "  
      " \"app_secret\": \"***********************************\", " 
      "\"target_type\": \"app\", " 
      "\"content\": \"Come help me please!\"}";

ESP8266WiFiMulti WiFiMulti;

#define NOTIFICATION_URL "https://api.pushed.co/1/push"

#ifndef STASSID
#define STASSID "__wifi__name__"
#define STAPSK  "__wifi__password__"
#endif

#define BUTTON_PIN 5
#define LED_PIN 4

boolean buttonWasUp = true;

void setup() {
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);

  blink(1, 200);
  USE_SERIAL.begin(115200);

  USE_SERIAL.println();
  USE_SERIAL.println();
  USE_SERIAL.println();

  for (uint8_t t = 4; t > 0; t--) {
    Serial.printf("[SETUP] WAIT %d...\n", t);
    Serial.flush();
    delay(1000);
  }

  ESP8266WiFiMulti WiFiMulti;

  WiFi.mode(WIFI_STA);
  WiFiMulti.addAP(STASSID, STAPSK);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println(F("\n\rWiFi connected!"));
  // blink to inform that wifi connected
  blink(3, 200);
}

void loop() {
  boolean buttonIsUp = digitalRead(BUTTON_PIN);

  if (buttonWasUp && !buttonIsUp) {
    delay(10);
    buttonIsUp = digitalRead(BUTTON_PIN);
    if (!buttonIsUp) { 
      // blink the led
      blink(1, 300);
      sendNotification();
    }
  }
 
  buttonWasUp = buttonIsUp;

}

void blink(int times, int msec)
{
  for(int i=0; i< times; i++)
  {
    digitalWrite(LED_PIN, HIGH);
    delay(msec);
    digitalWrite(LED_PIN, LOW);
  }
}

void sendNotification() 
{
 // wait for WiFi connection
  if ((WiFiMulti.run() == WL_CONNECTED)) {

    std::unique_ptr<BearSSL::WiFiClientSecure>client(new BearSSL::WiFiClientSecure);

    // If secure
    client->setFingerprint(fingerprint);

    // If insecure
    //client->setInsecure();

    HTTPClient https;

    Serial.print("[HTTPS] begin...\n");
    if (https.begin(*client, NOTIFICATION_URL)) {  // HTTPS

      Serial.print("[HTTPS] POST...\n");
      
      https.addHeader("Content-Type", "application/json");

      // start connection and send HTTP header and body
      int httpCode = https.POST(postData);

      // httpCode will be negative on error
      if (httpCode > 0) {
        // HTTP header has been send and Server response header has been handled
        Serial.printf("[HTTPS] POST... code: %d\n", httpCode);

        // file found at server
        if (httpCode == HTTP_CODE_OK || httpCode == HTTP_CODE_MOVED_PERMANENTLY) {
          blink(1, 2000);
          String payload = https.getString();
          Serial.println(payload);
        }
      } else {
        Serial.printf("[HTTPS] POST... failed, error: %s\n", https.errorToString(httpCode).c_str());
        blink(2, 150);
      }

      https.end();
    } else {
      Serial.printf("[HTTPS] Unable to connect\n");
      blink(2, 150);
    }
  }
}
