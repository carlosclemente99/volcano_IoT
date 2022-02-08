/*
    ------ [802_03] - receive XBee packets --------

    Explanation: This program shows how to receive packets with
    XBee-802.15.4 modules.

    Copyright (C) 2016 Libelium Comunicaciones Distribuidas S.L.
    http://www.libelium.com

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Version:           3.0
    Design:            David Gascón
    Implementation:    Yuri Carmona
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

char *token, *aux;
unsigned char buffer_ts[300];
char buffer_aux[100];
char *tx_accX, *tx_accY, *tx_accZ, *tx_temp, *tx_hum,
     *tx_press, tx_bat[10] = "100";


float temp;
float humd;
float pres;

int x_acc;
int y_acc;
int z_acc;
uint8_t bat;
uint8_t error;
char filename[100];
uint8_t socket = SOCKET1;
uint16_t socket_handle = 0;
char HOST[]        = "mqtt.thingspeak.com"; //MQTT Broker
char REMOTE_PORT[] = "1883";  //MQTT
char LOCAL_PORT[]  = "3000";

char SENSORS_CHANNEL[] = "1644029";
char SENSORS_API_KEY[] = "2CSSVGPQ7AUXUP8L";

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

  // init XBee
  xbee802.ON();
  connectWifi();

}

void sendData(unsigned char* payload)
{
  memset( buffer_ts, 0, sizeof(buffer_ts) );
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
  topicString.cstring = (char *)"channels/1644029/publish/2CSSVGPQ7AUXUP8L";
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
       token = strtok(buffer_aux, "#"); //strtok MODIFIES THE STRING PASSED TO PARSE (string constant) !!!! So constant has to be new everytime (local variable)
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


/*void printSensorValues(char* temp, char* hum, char* pres, char* accX, char* accY, char* accZ, char* bat) {
  
}*/

void printSensorValues(void){
  USB.println("\n--------------GATEWAY VALUES---------------");
  USB.print("Battery Level: ");
  USB.print(PWR.getBatteryLevel(), DEC);
  USB.println(F(" %"));
  USB.print("Pressure: ");
  USB.printFloat(Events.getPressure(), 2);
  USB.println(F(" Pa"));
  USB.print("Temperature: ");
  USB.printFloat(Events.getTemperature(), 2);
  USB.println(F(" Celsius"));
  USB.print("Humidity: ");
  USB.printFloat(Events.getHumidity(), 1); 
  USB.println(F(" %"));  
  USB.println(F(" \t0X\t0Y\t0Z")); 
  USB.print(F(" ACC\t")); 
  USB.print(ACC.getX(), DEC);
  USB.print(F("\t")); 
  USB.print(ACC.getY(), DEC);
  USB.print(F("\t")); 
  USB.println(ACC.getZ(), DEC);
  USB.println("-----------------------------\n");
  USB.println("\n--------------EDGE NODE VALUES---------------");
  USB.printf( "Temperature =%s&Humidity=%s&Pressure=%s&Acc_X=%s&Acc_Y=%s&Acc_Z=%s&batLevel=%s",
             tx_temp, tx_hum, tx_press, tx_accX, tx_accY, tx_accZ, &tx_bat);
  USB.println("-----------------------------\n");
 }

void loop()
{
  // receive XBee packet (wait for 10 seconds)
  error = xbee802.receivePacketTimeout( 120000 );

  // check answer
  if ( error == 0 )
  {
    // Show data stored in '_payload' buffer indicated by '_length'
    USB.print(F("Data: "));
    USB.println( xbee802._payload, xbee802._length);
    // Show data stored in '_payload' buffer indicated by '_length'
    USB.print(F("Length: "));
    USB.println( xbee802._length, DEC);

    // #:#X:%d#Y:%d#Z:%d#T:%s#H:%s#P:%s#B:%d
    memset( buffer_aux, 0, sizeof(buffer_aux) ); // Reset buffer
    strcpy( buffer_aux, (const char*)xbee802._payload );
    unsigned char payload[300]; // Payload to be transmitted
    char* sensorValues[NUM_MEASURES];
    boolean alarmReceived = parseInput(buffer_aux, sensorValues); // Parse buffer_aux and set sensor values into array
    if (!alarmReceived) {
      buildPayload(sensorValues, payload);
      printSensorValues();
    } else {
      buildAlarmPayload(sensorValues[POS_ALARM], payload);
    }
    
    USB.printf("Payload to be sent: %s\n", payload);
    // ToDo: if current battery level is low, create an string with the format ##ALARM_BL#
    if (WIFI_PRO.isConnected()) // No error ocurred during connection
    {
      sendData(payload);
      if (atoi(sensorValues[POS_BAT]) <= LOW_BATTERY) {
        unsigned char alarmPayload[100];
        USB.println("Edge node battery is low, sending alert to ThingSpeak");
        buildAlarmPayload(ALARM_BAT, alarmPayload);
        USB.printf("Alarm payload %s\n", alarmPayload);
        sendData(alarmPayload);
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
