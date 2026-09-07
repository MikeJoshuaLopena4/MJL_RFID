#include <ETH.h>
#include <WiFi.h>
#include <SPI.h>
#include <MFRC522.h>
#include <ArduinoOTA.h>
#include <WiFiClient.h>
#include <WiFiServer.h>

// Hardware Config
#define ETH_PHY_ADDR    1
#define ETH_POWER_PIN   16
#define ETH_MDC_PIN     23
#define ETH_MDIO_PIN    18
#define ETH_PHY_TYPE    ETH_PHY_LAN8720
#define ETH_CLK_MODE    ETH_CLOCK_GPIO17_OUT

#define LED_POWER       2    // White power on
#define LED_NET         12   // Green Got IP Ethernet
#define BUZZER_PIN      4

#define RFID_SS         14
#define RFID_RST        17
#define RFID_SCK        15
#define RFID_MOSI       32
#define RFID_MISO       33

MFRC522 mfrc522(RFID_SS, RFID_RST);

char macStr[20] = "";
IPAddress ethIP;
String lastUID = "";

// TCP Client Setup
WiFiClient client;   
IPAddress serverIP(10, 1, 15, 161); // your server IP
const uint16_t serverPort = 3000;   // custom TCP port

// Telnet logs
WiFiServer telnetServer(23);
WiFiClient telnetClient;

// OTA AP
const char *apSSID = "ESP32_OTA";
const char *apPASS = "12345678";

// logs for telnet (FIRMWARExLAN)
void logPrint(String msg) {
  Serial.print(msg);
  if (telnetClient && telnetClient.connected()) {
    telnetClient.print(msg);
  }
}
void logPrintln(String msg) {
  Serial.println(msg);
  if (telnetClient && telnetClient.connected()) {
    telnetClient.println(msg);
  }
}

// Ethernet events
void WiFiEvent(WiFiEvent_t event) {
  switch (event) {
    case ARDUINO_EVENT_ETH_GOT_IP:
      ethIP = ETH.localIP();
      logPrint("ETH Connected. IP: ");
      logPrintln(ethIP.toString());
      digitalWrite(LED_NET, HIGH);

      uint8_t mac[6];
      ETH.macAddress(mac);
      snprintf(macStr, sizeof(macStr), "%02X:%02X:%02X:%02X:%02X:%02X",
               mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
      logPrint("MAC Address: ");
      logPrintln(macStr);
      break;

    case ARDUINO_EVENT_ETH_DISCONNECTED:
      logPrintln("ETH Disconnected");
      digitalWrite(LED_NET, LOW);
      break;
  }
}

// --- Send UID to Server via raw TCP ---
bool sendUIDNotif(String uidStr) {
  uidStr.trim();

  // trip spaces in UID
  uidStr.replace(" ", "");

  //  Prepare MAC (last 3 octets, no colons)
  String macProcessed = String(macStr);
  macProcessed.replace(":", "");               // remove colons
  macProcessed = macProcessed.substring(6);    // last 3 octets (6 hex chars)

  if (client.connect(serverIP, serverPort)) {
    // Send "mac,rfid;\n"
    client.print(macProcessed);
    client.print(",");
    client.print(uidStr);
    client.print(";");   // terminate with semicolon + newline
    client.flush();

    logPrint("Sent to server: ");
    logPrintln(macProcessed + "," + uidStr + ";");

    
    unsigned long startTime = millis();
    while (millis() - startTime < 2000) { // 2s timeout
      if (client.available()) {
        char c = client.read();
        if (c == '\n') {
          logPrintln(" ACK received from server");
          client.stop();
          beep(300);   
          return true;
        }
      }
      ArduinoOTA.handle(); // keep OTA responsive while waiting
    }

    logPrintln(" No ACK from server (timeout)");
    client.stop();
    return false;

  } else {
    logPrintln(" TCP connection failed on port 3000");
    return false;
  }
}

// buzzer
void beep(int duration) {
  digitalWrite(BUZZER_PIN, LOW);
  delay(duration);
  ArduinoOTA.handle();
  digitalWrite(BUZZER_PIN, HIGH);
}

// OTA setup
void setupOTA() {
  ArduinoOTA.setHostname("RFID-OTA-Device");
  ArduinoOTA.setPassword("rfidota"); // passwd

  ArduinoOTA
    .onStart([]() { logPrintln("OTA Update Start"); })
    .onEnd([]() { logPrintln("OTA Update End"); })
    .onProgress([](unsigned int progress, unsigned int total) {
      char buf[50];
      sprintf(buf, "Progress: %u%%", (progress / (total / 100)));
      logPrintln(buf);
    })
    .onError([](ota_error_t error) {
      char buf[40];
      sprintf(buf, "OTA Error[%u]", error);
      logPrintln(buf);
    });

  ArduinoOTA.begin();
  logPrintln("OTA Ready - Connect to ESP32 AP and upload firmware.");
}

// setup
void setup() {
  Serial.begin(115200);

  pinMode(LED_POWER, OUTPUT);
  pinMode(LED_NET, OUTPUT);
  pinMode(BUZZER_PIN, INPUT_PULLDOWN);
  delay(100);
  pinMode(BUZZER_PIN, OUTPUT);

  digitalWrite(LED_POWER, HIGH);
  digitalWrite(LED_NET, LOW);
  digitalWrite(BUZZER_PIN, HIGH);

  digitalWrite(LED_NET, HIGH);
  delay(300);
  ArduinoOTA.handle();
  digitalWrite(LED_NET, LOW);
  delay(200);
  ArduinoOTA.handle();

  // RFID
  SPI.begin(RFID_SCK, RFID_MISO, RFID_MOSI);
  mfrc522.PCD_Init();
  logPrintln("RFID Reader Initialized");

  // Ethernet
  WiFi.onEvent(WiFiEvent);
  ETH.begin(ETH_PHY_TYPE, ETH_PHY_ADDR, ETH_MDC_PIN, ETH_MDIO_PIN, ETH_POWER_PIN, ETH_CLK_MODE);

  // WiFi-OTA
  WiFi.mode(WIFI_AP);
  WiFi.softAP(apSSID, apPASS);
  logPrint("OTA AP Started. SSID: ");
  logPrintln(apSSID);
  logPrint("AP IP: ");
  logPrintln(WiFi.softAPIP().toString());

  // OTA
  setupOTA();

  // Telnet server
  telnetServer.begin();
  telnetServer.setNoDelay(true);
  logPrintln("Telnet Server started on port 23");
}

void loop() {
  ArduinoOTA.handle();

  // Telnet client
  if (telnetServer.hasClient()) {
    if (!telnetClient || !telnetClient.connected()) {
      telnetClient = telnetServer.available();
      logPrintln("Telnet client connected");
    } else {
      telnetServer.available().stop(); // reject extra
    }
  }

  //  Check if telnet client sent something
  if (telnetClient && telnetClient.connected() && telnetClient.available()) {
    String cmd = telnetClient.readStringUntil('\n');
    cmd.trim();

    if (cmd == "1") {
      // Return ESP32 Ethernet IP
      telnetClient.println("ESP32 IP: " + ethIP.toString());
      Serial.println("Telnet requested IP, sent: " + ethIP.toString());
    } 
    else if (cmd == "2") {
      // Return ESP32 MAC address
      telnetClient.println("ESP32 MAC: " + String(macStr));
      Serial.println("Telnet requested MAC, sent: " + String(macStr));
    } 
    else {
      telnetClient.println("Unknown command: " + cmd);
    }
  }


  if (!mfrc522.PICC_IsNewCardPresent()) {
    delay(50);
    ArduinoOTA.handle();
    return;
  }

  if (mfrc522.PICC_ReadCardSerial()) {
    String uidStr = "";
    for (byte i = 0; i < mfrc522.uid.size; i++) {
      if (mfrc522.uid.uidByte[i] < 0x10) uidStr += "0";
      uidStr += String(mfrc522.uid.uidByte[i], HEX);
      uidStr += " ";
      ArduinoOTA.handle();
    }
    uidStr.trim();

    if (uidStr != lastUID || lastUID == "") {
      logPrint("Card UID: ");
      logPrintln(uidStr);

      bool sentOK = sendUIDNotif(uidStr);
      if (sentOK) {
        lastUID = uidStr;
      } else {
        lastUID = "";
      }
    }
    mfrc522.PICC_HaltA();
  }

  delay(100);
  ArduinoOTA.handle();
}
