/*  
 *  ------ [802_03] - receive XBee packets -------- 
 *  
 *  Explanation: This program shows how to receive packets with 
 *  XBee-802.15.4 modules.
 *  
 *  Copyright (C) 2016 Libelium Comunicaciones Distribuidas S.L. 
 *  http://www.libelium.com 
 *  
 *  This program is free software: you can redistribute it and/or modify 
 *  it under the terms of the GNU General Public License as published by 
 *  the Free Software Foundation, either version 3 of the License, or 
 *  (at your option) any later version. 
 *  
 *  This program is distributed in the hope that it will be useful, 
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of 
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 *  GNU General Public License for more details. 
 *  
 *  You should have received a copy of the GNU General Public License 
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>. 
 *  
 *  Version:           3.0
 *  Design:            David Gascón 
 *  Implementation:    Yuri Carmona
 */
 
#include <WaspXBee802.h>
#include <WaspSensorEvent_v30.h>

char *token, *aux;
char buffer_ts[100], buffer_aux[100]; 
char *tx_accX, *tx_accY, *tx_accZ,*tx_temp, *tx_hum,
     *tx_press, tx_bat[10]="100";


float temp;
float humd;
float pres;

int x_acc;
int y_acc;
int z_acc;
uint8_t bat;
// define variable
uint8_t error;
char filename[100];
pirSensorClass pir(SOCKET_1);


void setup()
{  
  // init USB port
  USB.ON();
  
  USB.println(F("Init RTC"));
  RTC.ON(); 
  RTC.setTime("09:10:20:03:17:35:30");
  RTC.setAlarm1(0,0,0,30,RTC_OFFSET,RTC_ALM1_MODE5);
  //Turn on sensors board
  Events.ON();
  Events.attachInt();

  // init XBee 
  xbee802.ON();

}


void loop()
{ 
  // receive XBee packet (wait for 10 seconds)
  error = xbee802.receivePacketTimeout( 10000 );

  // check answer  
  if( error == 0 ) 
  {
    // Show data stored in '_payload' buffer indicated by '_length'
    USB.print(F("Data: "));  
    USB.println( xbee802._payload, xbee802._length);
    // Show data stored in '_payload' buffer indicated by '_length'
    USB.print(F("Length: "));  
    USB.println( xbee802._length,DEC);
    //char * payload = (char *)xbee802._payload;

    
    // #:#X:%d#Y:%d#Z:%d#T:%s#H:%s#P:%s#B:%d
    memset( buffer_aux, 0, sizeof(buffer_aux) );
    memset( buffer_ts, 0, sizeof(buffer_ts) );
    strcpy( buffer_aux, (const char*)xbee802._payload );
    
    token = strtok(buffer_aux, "#"); //strtok MODIFIES THE STRING PASSED TO PARSE (string constant) !!!! So constant has to be new everytime (local variable)
   // loop through the string to extract all other tokens
   USB.println(token);
   while( token != NULL ) {
      token = strtok(NULL, ":");
      USB.println(token);
      //##X:-6#Y:-90#Z:1042#T:25.5#H:44.4#P:1883.5#B:98
      if ( !strcmp("X", token) ){ token = strtok(NULL, "#"); tx_accX = token;}
      else if ( !strcmp("Y", token) ){ token = strtok(NULL, "#"); tx_accY = token;}
      else if ( !strcmp("Z", token) ){ token = strtok(NULL, "#"); tx_accZ = token;}
      else if ( !strcmp("T", token) ){ token = strtok(NULL, "#"); tx_temp = token;}
      else if ( !strcmp("H", token) ){ token = strtok(NULL, "#"); tx_hum = token;}
      else if ( !strcmp("P", token) ){ token = strtok(NULL, "#"); tx_press = token;}
      else if ( !strcmp("B", token) ){ token = strtok(NULL, "#"); strcpy( tx_bat, (const char*)token ); }
      else if ( !strcmp("ALARM_PD", token) ){ break; }
      else if ( !strcmp("ALARM_FF", token) ){ break; }

   }//end while
   snprintf( buffer_ts, sizeof(buffer_ts),  
      "temp=%s \n hum=%s \n pres=%s \n accX=%s \n accY=%s \n accZ=%s \n batL=%s \n",  
       tx_temp,tx_hum,tx_press,tx_accX,tx_accY,tx_accZ,&tx_bat    );

   USB.println(buffer_ts);

    
  }
  else
  {
    // Print error message:
    /*
     * '7' : Buffer full. Not enough memory space
     * '6' : Error escaping character within payload bytes
     * '5' : Error escaping character in checksum byte
     * '4' : Checksum is not correct	  
     * '3' : Checksum byte is not available	
     * '2' : Frame Type is not valid
     * '1' : Timeout when receiving answer   
    */
    USB.print(F("Error receiving a packet:"));
    USB.println(error,DEC);     
  }

   
  

  
} 
