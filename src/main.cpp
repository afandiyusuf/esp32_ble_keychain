#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer *pServer;
BLEService *pService;
BLECharacteristic *pCharacteristic;

bool advertising = false; // to flag that ble is need to be advertise again or not

bool soundPlaying = false; // to flag sound is playing or not

std::string bleCommand = ""; // command from onWrite is stored at this variable

// to get elapsed time from sound is played.
unsigned long startTime = millis();
unsigned long elapsedTime = millis();

class MyServerCallback : public BLEServerCallbacks

{
  void onDisconnect(BLEServer *pServer)
  {
    // flag that ble is stop advertise its bluetooth, so we can advertise it again.
    advertising = false;
  }
};

class MyCharacteristicCallback : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic, esp_ble_gatts_cb_param_t *param)
  {
    // save the command from onWrite to bleCommand
    startTime = millis();
    std::string value = pCharacteristic->getValue();
    bleCommand = value.c_str();
  }
};
// put function declarations here:
void startAdvertisingTask();

void setup()
{
  Serial.begin(115200);
  // define buzzer pinout
  pinMode(GPIO_NUM_16, OUTPUT);
  // initiate a sound

  // define your ble name at here
  BLEDevice::init("Keychain Yusuf");
  pServer = BLEDevice::createServer();
  pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE_NR);
  pCharacteristic->setCallbacks(new MyCharacteristicCallback());

  pService->start();
  pServer->setCallbacks(new MyServerCallback());
  startAdvertisingTask();
}

void loop()
{

  if (!advertising)
  {
    advertising = true;
    BLEDevice::startAdvertising();
  }
  else
  {
    if (bleCommand == "on")
    {
      Serial.println("Timer after last command");
      Serial.println(millis() - startTime);
      if (!soundPlaying)
      {
        tone(GPIO_NUM_16, 1000);
        soundPlaying = true;
      }
      // if the command is active more than 5 sec, auto turn off
      if (millis() - startTime > 5000)
      {
        bleCommand = "off";
        if (soundPlaying)
        {
          noTone(GPIO_NUM_16);
          soundPlaying = false;
        }
      }
    }
    else
    {
      if (soundPlaying)
      {
        noTone(GPIO_NUM_16);
        soundPlaying = false;
      }
    }
  }
}

void startAdvertisingTask()
{
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06); // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  advertising = true;
}