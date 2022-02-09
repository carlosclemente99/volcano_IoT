/*
    Gateway code

    GROUP 8
    Carlos Clemente Martín (carlos.clemente.martin@alumnos.upm.es)
    Paulo Seoane Davila (p.seoane@alumnos.upm.es@alumnos.upm.es)
*/

#include <WaspXBee802.h>
#include <WaspSensorEvent_v30.h>
#include <WaspWIFI_PRO.h>
#include <WaspFrame.h>

#include <Countdown.h>
#include <FP.h>
#include <MQTTFormat.h>
#include <MQTTLogging.h>
#include <MQTTPacket.h>
#include <MQTTPublish.h>
#include <MQTTSubscribe.h>
#include <MQTTUnsubscribe.h>

#define HOST              "mqtt.thingspeak.com" //MQTT Broker
#define REMOTE_PORT       "1883"  //MQTT
#define LOCAL_PORT        "3000"

#define SENSORS_TOPIC      "channels/1644029/publish/2CSSVGPQ7AUXUP8L"
#define GATEWAY_TOPIC      "channels/1650435/publish/O1WYCTPXZQVS8NWA"

// Battery is low if its level is lower or equal than LOW_BATTERY
#define LOW_BATTERY 20

// Sensor values received from the end node will be stored into an array.
// To avoid confussion with the positions, they are saved in constants
#define POS_ALARM    0
#define POS_TEMP     1
#define POS_HUM      2
#define POS_BAT      3
#define POS_PRES     4
#define POS_ACCX     5
#define POS_ACCY     6
#define POS_ACCZ     7
#define NUM_MEASURES 8

// Alarm codes
#define NO_ALARM     "-1"
#define ALARM_FF     "0"
#define ALARM_PIR    "1"
#define ALARM_BAT    "2"

uint8_t error;
uint8_t socket = SOCKET1;
uint16_t socket_handle = 0;

bool connectWifi()
{
  uint8_t status;
  //////////////////////////////////////////////////
  // 1. Switch ON
  //////////////////////////////////////////////////
  WIFI_PRO.softReset();
  WIFI_PRO.setESSID("iPhone de Paulo");
  WIFI_PRO.setPassword(WPA2, "bolundejo99");
  error = WIFI_PRO.ON(socket);

  if ( error == 0 )
  {
    USB.println(F("1. WiFi switched ON"));
  }
  else
  {
    USB.println(F("1. WiFi did not initialize correctly"));
    USB.println(error, DEC);
    return false;
  }
  // check connectivity
  status =  WIFI_PRO.isConnected();

  // check if module is connected
  if ( status == true )
  {
    USB.print(F("2. WiFi is connected OK"));
    USB.print(F(" Time(ms):"));

    // get IP address
    error = WIFI_PRO.getIP();

    if (error == 0) // No error ocurred while getting IP
    {
      USB.print(F("IP address: "));
      USB.println( WIFI_PRO._ip );
    }
    else
    {
      USB.println(F("getIP error"));
      return false;
    }
  }
  else
  {
    USB.print(F("2. WiFi is connected ERROR"));
    USB.print(F(" Time(ms):"));
    return false;
  }
  return true;
}

void setup()
{
  // init USB port
  USB.ON();

  USB.println(F("Init RTC"));
  RTC.ON();
  //Turn on sensors board
  Events.ON();
  Events.attachInt();
  ACC.ON();

 // init XBee;
  xbee802.ON();
  connectWifi();

}

void sendData(unsigned char* payload, char* topic)
{
  unsigned char buffer_ts[300];
  strcpy( (char *)buffer_ts, (char *)payload);
  /// Publish MQTT
  error = WIFI_PRO.setTCPclient( HOST, REMOTE_PORT, LOCAL_PORT);
   // check response
  if (error == 0)
  {
    // get socket handle (from 0 to 9)
    socket_handle = WIFI_PRO._socket_handle;

    USB.print(F("3.1. Open TCP socket OK in handle: "));
    USB.println(socket_handle, DEC);
  }
  else
  {
    USB.println(F("3.1. Error calling 'setTCPclient' function"));
    WIFI_PRO.printErrorCode();
  }
  MQTTPacket_connectData data = MQTTPacket_connectData_initializer;
  MQTTString topicString = MQTTString_initializer;
  int buflen = sizeof(buffer_ts);

  // options
  data.clientID.cstring = (char*)"mt1";
  data.keepAliveInterval = 30;
  data.cleansession = 1;
  int len = MQTTSerialize_connect(buffer_ts, buflen, &data); /* 1 */

  // Topic and message
  topicString.cstring = topic;
  int payloadlen = strlen((const char*)payload);

  len += MQTTSerialize_publish(buffer_ts + len, buflen - len, 0, 0, 0, 0, topicString, payload, payloadlen); /* 2 */

  len += MQTTSerialize_disconnect(buffer_ts + len, buflen - len); /* 3 */


  ////////////////////////////////////////////////
  // 3.2. send data
  ////////////////////////////////////////////////
  error = WIFI_PRO.send( socket_handle, buffer_ts, len);

  // check response
  if (error == 0)
  {
    USB.println(F("3.2. Send data OK"));
  }
  else
  {
    USB.println(F("3.2. Error calling 'send' function"));
    WIFI_PRO.printErrorCode();
  }
   WIFI_PRO.closeSocket();
}

// Tokenizes a string with the format ##X:-6#Y:-90#Z:1042#T:25.5#H:44.4#P:1883.5#B:98
// Stores values into array. Returns true if array contains alarm code, false if it contains sensor values
boolean parseInput(char* input_buffer, char* values[]) {
    char *token, *aux;
    token = strtok(input_buffer, "#"); //strtok MODIFIES THE STRING PASSED TO PARSE (string constant) !!!! So constant has to be new everytime (local variable)
    // loop through the string to extract all other tokens
    boolean alarmReceived = false;
    USB.println(token);
    while ( token != NULL ) {
      token = strtok(NULL, ":");
      if ( !strcmp("X", token) ) {
        token = strtok(NULL, "#");
        values[POS_ACCX] = token;
      }
      else if ( !strcmp("Y", token) ) {
        token = strtok(NULL, "#");
        values[POS_ACCY] = token;
      }
      else if ( !strcmp("Z", token) ) {
        token = strtok(NULL, "#");
        values[POS_ACCZ] = token;
      }
      else if ( !strcmp("T", token) ) {
        token = strtok(NULL, "#");
        values[POS_TEMP] = token;
      }
      else if ( !strcmp("H", token) ) {
        token = strtok(NULL, "#");
        values[POS_HUM] = token;
      }
      else if ( !strcmp("P", token) ) {
        token = strtok(NULL, "#");
        values[POS_PRES] = token;
      }
      else if ( !strcmp("B", token) ) {
        token = strtok(NULL, "#");
        values[POS_BAT] = token;
      }
      else if ( !strcmp("ALARM_FF", token) ) {
        token = strtok(NULL, "#");
        values[POS_ALARM] = ALARM_FF;
        alarmReceived = true;
      }
      else if ( !strcmp("ALARM_PIR", token) ) {
        token = strtok(NULL, "#");
        values[POS_ALARM] = ALARM_PIR;
        alarmReceived = true;
      }
    }
    return alarmReceived;
}

void buildPayload(char* values[], unsigned char* payload) {
    snprintf(
      (char *)payload, 
       300, 
      "field1=%s&field2=%s&field3=%s&field4=%s&field5=%s&field6=%s&field7=%s",
       values[POS_TEMP], 
       values[POS_HUM],
       values[POS_PRES],
       values[POS_ACCX], 
       values[POS_ACCY], 
       values[POS_ACCZ], 
       values[POS_BAT]
    );
}

void buildAlarmPayload(char* alarmCode, unsigned char* payload) {
  snprintf(
    (char*)payload,
    100,
    "field8=%s",
    alarmCode
  );
}

void printSensorValues(char* sensorValues[]) {
  USB.printf("Battery level: %s\n", sensorValues[POS_BAT]);
  USB.printf("Temperature: %s Celsius\n", sensorValues[POS_TEMP]);
  USB.printf("Pressure: %s Pa\n", sensorValues[POS_PRES]);
  USB.printf("Humidity: %s\n", sensorValues[POS_HUM]);
  USB.printf("X Axis acceleration: %s\n", sensorValues[POS_ACCX]);
  USB.printf("Y Axis acceleration: %s\n", sensorValues[POS_ACCY]);
  USB.printf("Z Axis acceleration: %s\n", sensorValues[POS_ACCZ]);
  USB.println("---------");
}

void receiveAndPublishEndNodeValues() {
  char buffer_in[100];
  unsigned char payload[300]; // Payload to be transmitted
  char* sensorValues[NUM_MEASURES];
  // receive XBee packet (wait for 12 seconds)
  error = xbee802.receivePacketTimeout( 120000 );

  // check answer
  if ( error == 0 )
  {
    // Show data stored in '_payload' buffer indicated by '_length'
    USB.print(F("Data: "));
    USB.println(xbee802._payload, xbee802._length);

    // #:#X:%d#Y:%d#Z:%d#T:%s#H:%s#P:%s#B:%d
    strcpy(buffer_in, (const char*)xbee802._payload);

    boolean alarmReceived = parseInput(buffer_in, sensorValues); // Parse buffer_aux and set sensor values into array
    if (!alarmReceived) {
      buildPayload(sensorValues, payload);
      USB.println("END NODE SENSOR VALUES:");
      printSensorValues(sensorValues);
    } else {
      buildAlarmPayload(sensorValues[POS_ALARM], payload);
    }
    
    USB.printf("Payload to be sent: %s\n", payload);
    if (WIFI_PRO.isConnected()) // No error ocurred during connection
    {
      sendData(payload, SENSORS_TOPIC);
      // If an alarm was received, sensorVales[POS_BAT] will be set to 0
      if (!alarmReceived && atoi(sensorValues[POS_BAT]) <= LOW_BATTERY) {
        unsigned char alarmPayload[100];
        USB.println("Edge node battery is low, sending alert to ThingSpeak");
        buildAlarmPayload(ALARM_BAT, alarmPayload);
        sendData(alarmPayload, SENSORS_TOPIC);
      }
      
    } else {
      printf("Wifi is not connected");
    }
  }
  else
  {
    // Print error message:
    /*
       '7' : Buffer full. Not enough memory space
       '6' : Error escaping character within payload bytes
       '5' : Error escaping character in checksum byte
       '4' : Checksum is not correct
       '3' : Checksum byte is not available
       '2' : Frame Type is not valid
       '1' : Timeout when receiving answer
    */
    USB.print(F("Error receiving a packet:"));
    USB.println(error, DEC);
  }
}

void gatherAndPublishCurrentValues() {
  // Current gateway sensor values
  char* currentValues[NUM_MEASURES];
  unsigned char payload[300];
  char currentTemp[10];
  char currentHum[10];
  char currentPres[10];
  char currentAccX[10];
  char currentAccY[10];
  char currentAccZ[10];
  char currentBat[10];
  
  dtostrf(Events.getTemperature(), 2, 1, currentTemp);
  currentValues[POS_TEMP] = currentTemp;
  dtostrf(Events.getHumidity(), 2, 1, currentHum);
  currentValues[POS_HUM] = currentHum;
  dtostrf(Events.getPressure(), 1, 1, currentPres);
  currentValues[POS_PRES] = currentPres;
  snprintf(currentAccX, 10, "%d", ACC.getX());
  currentValues[POS_ACCX] = currentAccX;
  snprintf(currentAccY, 10, "%d", ACC.getY());
  currentValues[POS_ACCY] = currentAccY;
  snprintf(currentAccZ, 10, "%d", ACC.getZ());
  currentValues[POS_ACCZ] = currentAccZ;
  snprintf(currentBat, 10, "%d", PWR.getBatteryLevel());
  currentValues[POS_BAT] = currentBat;
  USB.println("CURRENT GATEWAY SENSOR VALUES");
  printSensorValues(currentValues);

  buildPayload(currentValues, payload);
  sendData(payload, GATEWAY_TOPIC);
}

void loop()
{
  receiveAndPublishEndNodeValues();
  gatherAndPublishCurrentValues();
}
















