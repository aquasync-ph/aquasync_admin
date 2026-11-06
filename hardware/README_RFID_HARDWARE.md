# AquaSync RFID Hardware & Software Setup Guide

This guide provides the complete setup for integrating **Physical RFID Loyalty Cards** into the **AquaSync** platform across Admin, Cashier, User, and Driver applications.

---

## 1. Hardware Requirements

- **Microcontroller**: ESP8266 (NodeMCU v2/v3 or Wemos D1 Mini) **OR** ESP32 Dev Board
- **RFID Reader Module**: MFRC522 (13.56 MHz RFID / NFC Reader)
- **RFID Cards / Tags**: 13.56 MHz Mifare S50 / IC Cards / Keychains
- **Buzzer**: 5V Active Buzzer (Audio Feedback)
- **Status LED**: 3mm or 5mm Green LED + 220Ω Resistor
- **Jumper Wires & Breadboard**

---

## 2. Hardware Wiring Diagram

> **WARNING**: The MFRC522 module **requires 3.3V power**. Connecting it to 5V will permanently damage the module.

| MFRC522 Pin | ESP8266 (NodeMCU) | ESP32 Pin | Description |
| :--- | :--- | :--- | :--- |
| **3.3V** | 3.3V | 3.3V | **3.3V Power** |
| **GND** | GND | GND | Ground |
| **RST** | D0 (GPIO 16) | GPIO 22 | Reset Pin |
| **IRQ** | *N/C* | *N/C* | Not Connected |
| **MISO** | D6 (GPIO 12) | GPIO 19 | SPI MISO |
| **MOSI** | D7 (GPIO 13) | GPIO 23 | SPI MOSI |
| **SCK** | D5 (GPIO 14) | GPIO 18 | SPI Clock |
| **SDA (SS)** | D8 (GPIO 15) | GPIO 5 | SPI Chip Select |
| **Buzzer (+)**| D1 (GPIO 5) | GPIO 4 | Audio Beep Signal |
| **Green LED** | D2 (GPIO 4) | GPIO 2 | Connection / Scan LED |

---

## 3. Arduino IDE Flashing Steps

1. **Install Arduino IDE** (v2.x or v1.8.x).
2. **Add ESP Board Support**:
   - Go to `File > Preferences` and add to Additional Boards Manager URLs:
     - ESP8266: `http://arduino.esp8266.com/stable/package_esp8266com_index.json`
     - ESP32: `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
   - Go to `Tools > Board > Boards Manager`, search for `esp8266` or `esp32` and click **Install**.
3. **Install Required Libraries**:
   - Go to `Tools > Manage Libraries...`
   - Search for **MFRC522** (by github.com/miguelbalboa/rfid) and click **Install**.
   - Search for **ArduinoJson** (by Benoit Blanchon) and click **Install**.
4. **Open Code**:
   - Open `hardware/aquasync_rfid_hardware.ino` in Arduino IDE.
5. **Update Credentials**:
   - Replace `WIFI_SSID` and `WIFI_PASSWORD` with your Wi-Fi details.
   - Replace `SUPABASE_URL` with: `https://YOUR_PROJECT_ID.supabase.co/rest/v1/rfid_qr_records`
   - Replace `SUPABASE_KEY` with your Supabase Anon API Key.
6. **Upload**:
   - Connect your ESP board via USB.
   - Select the correct Port under `Tools > Port`.
   - Click **Upload** (Ctrl + U).

---

## 4. End-to-End System Workflow

### A. Admin Card Registration
1. Tap a new blank physical RFID card on the MFRC522 scanner.
2. The hardware beeps and posts the UID to Supabase (`rfid_qr_records`).
3. In **AquaSync Admin**, open **Loyalty & RFID**.
4. The card automatically appears in the **Live Scanned RFID Inventory** section!
5. Click **Assign** to link the RFID UID to a specific customer profile.

### B. Cashier POS Counter Purchase
1. Customer taps their Loyalty RFID Card on the scanner at the store POS counter.
2. The Cashier app looks up `rfid_qr_records` for `code = scanned_uid`.
3. Instantly loads customer profile, reward history, and applies loyalty discounts automatically!

### C. User Mobile App
1. Customers open their AquaSync app profile to view their active **Loyalty RFID Card Badge** and status.
2. Can choose to redeem loyalty discounts during checkout.

### D. Driver Delivery Verification
1. Driver taps customer's card or enters the RFID UID upon arrival.
2. Verifies identity and confirms delivery completion.
