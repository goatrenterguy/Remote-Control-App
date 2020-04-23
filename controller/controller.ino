//All 
#include <bluefruit.h>

// OTA DFU service
BLEDfu bledfu;

// Uart over BLE service
BLEUart bleuart;

// Function prototypes for packetparser.cpp
uint8_t readPacket (BLEUart *ble_uart, uint16_t timeout);
float   parsefloat (uint8_t *buffer);
void    printHex   (const uint8_t * data, const uint32_t numBytes);

//Motor 1 declaration
const int motorPin1  = 2;  // Pin 2 of MC to Pin 14 of L293
const int motorPin2  = 3;  // Pin 3 to 10

//Motor 2 declaration
const int motorPin3  = 4; // Pin 4 to 7
const int motorPin4  = 7;  // Pin 7 to 2

// Packet buffer
extern uint8_t packetbuffer[];

void setup(void) {
  Serial.begin(115200);
  while ( !Serial ) delay(10);   // for nrf52840 with native usb

  Serial.println(F("RCV Controller"));
  Serial.println(F("-------------------------------------------"));

  Bluefruit.begin();
  Bluefruit.setTxPower(4);    // Check bluefruit.h for supported values
  Bluefruit.setName("E.7 Remote Control Car ");

  // To be consistent OTA DFU should be added first if it exists
  bledfu.begin();

  // Configure and start the BLE Uart service
  bleuart.begin();

  // Set up and start advertising
  startAdv();

  pinMode(LED_BUILTIN, OUTPUT);
  //Set pins as outputs (send that sweet sweet voltage)
  pinMode(motorPin1, OUTPUT); //Motor 1
  pinMode(motorPin2, OUTPUT);
  pinMode(motorPin3, OUTPUT); //Motor2
  pinMode(motorPin4, OUTPUT);
}

void startAdv(void) {
  // Advertising packet
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();

  // Include the BLE UART (AKA 'NUS') 128-bit UUID
  Bluefruit.Advertising.addService(bleuart);

  // Secondary Scan Response packet (optional)
  // Since there is no room for 'Name' in Advertising packet
  Bluefruit.ScanResponse.addName();
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 244);    // in unit of 0.625 ms
  Bluefruit.Advertising.setFastTimeout(30);      // number of seconds in fast mode
  Bluefruit.Advertising.start(0);                // 0 = Don't stop advertising after n seconds
}

/**************************************************************************/
/*!
    @brief  Constantly poll for new command or response data
*/
/**************************************************************************/
void loop(void) {
  // Wait for new data to arrive
  uint8_t len = readPacket(&bleuart, 500);
  if (len == 0) return;

  // Got a packet!
  //printHex(packetbuffer, len);

  // Buttons
  //packetbuffer[0] = ! (Denotes the begginng of a paccket)
  //packetbuffer[1] (Denotes the type of inofrmation ie. 'B' = button)
  //Packetbuffer[2] (Denotes which button is pressed)
  //Packetbuffer[3] (Denotes status of the button/toggle)
  if (packetbuffer[1] == 'B') {
    uint8_t buttnum = packetbuffer[2] - '0';
    boolean pressed = packetbuffer[3] - '0';
    if (buttnum == 1) {
      if (pressed) {
        Serial.print ("Button ");
        Serial.println(" pressed");
        digitalWrite(LED_BUILTIN, HIGH);
      } else {
        Serial.print ("Button ");
        Serial.println(" released");
        digitalWrite(LED_BUILTIN, LOW);
      }
      //Button 3 is forward
    } else if (buttnum == 3) {
      if (pressed) {
        Serial.print ("Button ");
        Serial.print(buttnum);
        Serial.println(" pressed");
        digitalWrite(motorPin1, HIGH); //Motor 1 is essentially on in one direction now
        digitalWrite(motorPin2, LOW);
        digitalWrite(motorPin3, LOW);
        digitalWrite(motorPin4, LOW);
      } else {
        Serial.print ("Button ");
        Serial.print(buttnum);
        Serial.println(" released");
        digitalWrite(motorPin1, LOW);
        digitalWrite(motorPin2, LOW);
        digitalWrite(motorPin3, LOW);
        digitalWrite(motorPin4, LOW);
      }
    } else if (buttnum == 4) {
      if (pressed) {
        Serial.print ("Button ");
        Serial.print(buttnum);
        Serial.println(" pressed");
        digitalWrite(motorPin1, LOW);
        digitalWrite(motorPin2, HIGH); //Motor 1 on in opposite direction
        digitalWrite(motorPin3, LOW);
        digitalWrite(motorPin4, LOW);
      } else {
        Serial.print ("Button "); Serial.print(buttnum);
        Serial.println(" released");
        digitalWrite(motorPin1, LOW);
        digitalWrite(motorPin2, LOW);
        digitalWrite(motorPin3, LOW);
        digitalWrite(motorPin4, LOW);
      }
    } else {
      Serial.print ("Button "); Serial.print(buttnum);
      if (pressed) {
        Serial.println(" pressed");
      } else {
        Serial.println(" released");
      }
    }
    //Takes input from the slider in app and controls the speed and direction of the steering motors
  } else if (packetbuffer[1] == 'S') {
    uint8_t buttnum = packetbuffer[2] - '0';
    boolean pressed = packetbuffer[3] - '0';
    if (buttnum < 5) {
      Serial.print("Slider left: ");
      Serial.print(buttnum);
      analogWrite(motorPin4, buttnum * 2.5);
    } else if (buttnum > 5) {
      Serial.print("Slider right: ");
      Serial.print(buttnum);
      analogWrite(motorPin3, buttnum * 2.5);

    } else {
      analogWrite(motorPin3, 0);
      analogWrite(motorPin4, 0);
    }
    //Takes input from sliders in app and changes speed and direction of motor
  } else if (packetbuffer[1] == 'M'){
    if (buttnum < 5) {
      Serial.print("Slider left: ");
      Serial.print(buttnum);
      analogWrite(motorPin2, buttnum * 2.5);
    } else if (buttnum > 5) {
      Serial.print("Slider right: ");
      Serial.print(buttnum);
      analogWrite(motorPin1, buttnum * 2.5);
    } else {
      analogWrite(motorPin1, 0);
      analogWrite(motorPin2, 0);
  }
}
