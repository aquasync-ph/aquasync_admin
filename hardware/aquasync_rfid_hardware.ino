/*
  ==============================================================================
  AquaSync ESP32 Custom RFID System (With OLED Display & Dual Status LEDs)
  Microcontroller: ESP32 (30-pin variant)

  PERIPHERALS & WIRING MATRIX:
  ------------------------------------------------------------------------------
  Component       | Component Pin | ESP32 Board / Rail Pin
  ----------------+---------------+---------------------------------------------
  RC522 RFID      | 3.3V          | Breadboard 3.3V Red Rail
                  | GND           | Breadboard GND Blue Rail
                  | SDA / SS      | GPIO 5
                  | SCK           | GPIO 18
                  | MOSI          | GPIO 23
                  | MISO          | GPIO 19
                  | RST           | GPIO 4
  ----------------+---------------+---------------------------------------------
  0.96" OLED      | VCC           | Breadboard 3.3V Red Rail
  (SSD1306 I2C)   | GND           | Breadboard GND Blue Rail
                  | SDA           | GPIO 21
                  | SCL           | GPIO 22
  ----------------+---------------+---------------------------------------------
  Green LED       | Anode (+)     | GPIO 13
                  | Cathode (-)   | 220 ohm Resistor -> Breadboard GND Rail
  ----------------+---------------+---------------------------------------------
  Red LED         | Anode (+)     | GPIO 14
                  | Cathode (-)   | 220 ohm Resistor -> Breadboard GND Rail
  ----------------+---------------+---------------------------------------------
  Active Buzzer   | Positive (+)  | GPIO 12
                  | Negative (-)  | Breadboard GND Rail
  ==============================================================================
*/

#include <SPI.h>
#include <MFRC522.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>

// ---------------- HARDWARE PIN DEFINITIONS ----------------
#define SS_PIN         5   // MFRC522 SDA/SS
#define RST_PIN        4   // MFRC522 RST
#define GREEN_LED_PIN 13   // Green LED (Access Granted / Success)
#define RED_LED_PIN   14   // Red LED (Error / Connecting)
#define BUZZER_PIN    12   // Active Buzzer (+)

// OLED Display Config (I2C SSD1306 128x64)
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1
#define OLED_I2C_ADDRESS 0x3C

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
MFRC522 rfid(SS_PIN, RST_PIN);

// ---------------- AQUASYNC NETWORK & SUPABASE CONFIG ----------------
const char* WIFI_SSID     = "Pake_ko_Sayo";       // Wi-Fi Name mo
const char* WIFI_PASSWORD = "Drell&Belle_20";   // Wi-Fi Password mo

// EXACT Supabase Project Endpoint & Anon Key
const char* SUPABASE_URL  = "https://qxruxonusvoxshuwxrah.supabase.co/rest/v1/rfid_qr_records";
const char* SUPABASE_KEY  = "sb_publishable_MbMRR6syNwtezcWMke6yXw_Y1cozFRo";

String lastScannedUID = "";
unsigned long lastScanTime = 0;
const unsigned long DEBOUNCE_DELAY = 3000;

// Helper function to update OLED display text
void updateOLED(const char* title, const char* line1, const char* line2 = "") {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("=== AQUASYNC RFID ===");
  display.println("---------------------");
  display.println(title);
  display.println(line1);
  if (strlen(line2) > 0) {
    display.println(line2);
  }
  display.display();
}

void beep(int durationMs, int times = 1) {
  for (int i = 0; i < times; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(durationMs);
    digitalWrite(BUZZER_PIN, LOW);
    if (times > 1) delay(60);
  }
}

void setup() {
  Serial.begin(115200);
  delay(500);

  // Initialize Pin Modes
  pinMode(GREEN_LED_PIN, OUTPUT);
  pinMode(RED_LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  digitalWrite(GREEN_LED_PIN, LOW);
  digitalWrite(RED_LED_PIN, LOW);
  digitalWrite(BUZZER_PIN, LOW);

  // Initialize I2C for OLED Display (SDA=21, SCL=22)
  Wire.begin(21, 22);
  if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_I2C_ADDRESS)) {
    Serial.println(F("[OLED] SSD1306 allocation failed (Check OLED wiring or 0x3C I2C address)"));
  } else {
    display.clearDisplay();
    updateOLED("SYSTEM STARTING...", "Connecting WiFi...");
  }

  // Initialize SPI & MFRC522 RFID (SS=5, RST=4)
  SPI.begin(18, 19, 23, 5); // SCK=18, MISO=19, MOSI=23, SS=5
  rfid.PCD_Init();

  Serial.println("\n[AquaSync] ESP32 RFID System Initialized.");

  // Connect to Wi-Fi
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("[WiFi] Connecting to: ");
  Serial.println(WIFI_SSID);

  int attempt = 0;
  while (WiFi.status() != WL_CONNECTED) {
    delay(400);
    Serial.print(".");
    digitalWrite(RED_LED_PIN, !digitalRead(RED_LED_PIN)); // Blink RED LED while connecting
    attempt++;
    if (attempt % 10 == 0) {
      updateOLED("CONNECTING WIFI...", WIFI_SSID);
    }
  }

  digitalWrite(RED_LED_PIN, LOW);
  digitalWrite(GREEN_LED_PIN, HIGH); // Solid Green LED when WiFi connected
  Serial.println("\n[WiFi] Connected Successfully!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  updateOLED("STATUS: ONLINE", "Ready to scan card", "Tap RFID Card...");
  beep(80, 3); // 3 startup beeps
}

void sendRfidToSupabase(String uid) {
  digitalWrite(GREEN_LED_PIN, LOW);
  digitalWrite(RED_LED_PIN, HIGH); // Red LED turns on while sending
  updateOLED("CARD SCANNED!", uid.c_str(), "Sending to DB...");

  WiFiClientSecure client;
  client.setInsecure(); // Skip TLS SSL certificate validation

  HTTPClient http;
  if (http.begin(client, SUPABASE_URL)) {
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", SUPABASE_KEY);
    http.addHeader("Authorization", String("Bearer ") + SUPABASE_KEY);
    http.addHeader("Prefer", "return=representation");

    String jsonPayload = "{\"code\":\"" + uid + "\",\"code_type\":\"RFID\",\"is_active\":true}";

    int httpCode = http.POST(jsonPayload);
    String responseBody = http.getString();

    Serial.print("[SUPABASE] HTTP Response Code: ");
    Serial.println(httpCode);
    Serial.print("[SUPABASE] Response Body: ");
    Serial.println(responseBody);

    if (httpCode == 201 || httpCode == 200 || httpCode == 204) {
      Serial.println("[SUPABASE] Success! RFID UID posted to AquaSync database.");
      digitalWrite(RED_LED_PIN, LOW);
      digitalWrite(GREEN_LED_PIN, HIGH);
      updateOLED("ACCESS GRANTED!", uid.c_str(), "Sent to System!");
      beep(100, 2); // Double success beep
    } else if (httpCode == 409) {
      Serial.println("[SUPABASE] Note: Card UID is already registered in system.");
      digitalWrite(RED_LED_PIN, HIGH);
      digitalWrite(GREEN_LED_PIN, LOW);
      updateOLED("CARD ALREADY EXIST", uid.c_str(), "Already Registered");
      beep(250, 1);
    } else if (httpCode == 401) {
      Serial.println("[SUPABASE ERROR 401] RLS Policy Blocking Public Insert!");
      Serial.println("[FIX] Run the RLS Policy SQL in Supabase SQL Editor.");
      digitalWrite(RED_LED_PIN, HIGH);
      digitalWrite(GREEN_LED_PIN, LOW);
      updateOLED("ERROR 401 (RLS)", "Run SQL Policy", "In Supabase Editor");
      beep(400, 2);
    } else {
      digitalWrite(RED_LED_PIN, HIGH);
      digitalWrite(GREEN_LED_PIN, LOW);
      updateOLED("SERVER ERROR!", String(httpCode).c_str(), "Try Again");
      beep(400, 1);
    }
    http.end();
  } else {
    Serial.println("[SUPABASE] Connection Error.");
    updateOLED("CONNECTION ERROR", "Check WiFi/Key");
    beep(500, 1);
  }

  delay(1500);
  digitalWrite(RED_LED_PIN, LOW);
  digitalWrite(GREEN_LED_PIN, HIGH);
  updateOLED("STATUS: READY", "Ready to scan card", "Tap RFID Card...");
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    digitalWrite(GREEN_LED_PIN, LOW);
    digitalWrite(RED_LED_PIN, HIGH);
    updateOLED("WIFI DISCONNECTED", "Reconnecting...");
    WiFi.disconnect();
    WiFi.reconnect();
    delay(2000);
    return;
  }

  if (!rfid.PICC_IsNewCardPresent()) return;
  if (!rfid.PICC_ReadCardSerial()) return;

  String uidString = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    if (rfid.uid.uidByte[i] < 0x10) uidString += "0";
    uidString += String(rfid.uid.uidByte[i], HEX);
    if (i < rfid.uid.size - 1) uidString += ":";
  }
  uidString.toUpperCase();

  if (uidString == lastScannedUID && (millis() - lastScanTime < DEBOUNCE_DELAY)) {
    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();
    return;
  }

  lastScannedUID = uidString;
  lastScanTime = millis();

  Serial.println("----------------------------------------------");
  Serial.print("[RFID SCANNED] UID: ");
  Serial.println(uidString);

  beep(120, 1);
  sendRfidToSupabase(uidString);

  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();
}
