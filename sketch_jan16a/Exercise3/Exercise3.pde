
/*
    ------ Waspmote Pro Code Example --------

    Explanation: This is the basic Code for Waspmote Pro

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
*/

// Put your libraries here (#include ...)
#include <WaspSensorEvent_v30.h>
#include <WaspXBee802.h>
#include <WaspFrame.h>


char RX_ADDRESS[] = "0013A200416BE350";
char WASPMOTE_ID[] = "node_01";
//Global Variables
uint8_t status;
int batL;
int accX;
int accY;
int accZ;
char message[100];
float temp;
float humd;
float pres;
pirSensorClass pir(SOCKET_1);
uint8_t pirvalue = 0;
uint8_t error;

void setup()
{
  // Setup for Serial port over USB
  USB.ON();
  ACC.ON();
  ACC.setFF(); 
  // Powers RTC up, init I2C bus and read initial values
  RTC.ON(); 
  RTC.setTime("09:10:20:03:17:35:30");
  RTC.setAlarm1(0,0,0,30,RTC_OFFSET,RTC_ALM1_MODE5);
  //Turn on sensors board
  Events.ON();
  Events.attachInt();
  //Set up XBEE
  xbee802.ON();
  // store Waspmote identifier in EEPROM memory
  frame.setID( WASPMOTE_ID );
  pirvalue = pir.readPirSensor();
  USB.println();
  //Wait for PIR stabilization
  while (pirvalue == 1){
    USB.println(F("...wait for PIR stabilization"));
    delay(1000);
    pirvalue = pir.readPirSensor();    
  } 


}


void loop()
{
  
  //Check if interrupt is ACC
  if( intFlag & ACC_INT )
  {
    Utils.setLED(LED0, LED_ON);
    // clear interruption flag
    intFlag &= ~(ACC_INT);
    
    // print info
    // create new frame
    snprintf(message,sizeof(message),"#:#ALARM_FF:ALARM_FF");
     ///////////////////////////////////////////
    // 2. Send packet
    ///////////////////////////////////////////  
  
    // send XBee packet
    error = xbee802.send( RX_ADDRESS, message);   
    
    // check TX flag
    if( error == 0 )
    {
      USB.println(F("send ok"));
    }
    else 
    {
      USB.println(F("send error"));
    }
    
    Utils.setLED(LED0, LED_OFF);
    
  }
  
  //Check if interrupt is RTC
  if( intFlag & RTC_INT )
  {
    Utils.setLED(LED1, LED_ON); 
    // clear interruption flag
    intFlag &= ~(RTC_INT);
    USB.println(F("-------------------------"));
    USB.println(F("RTC INT Captured"));
    USB.println(F("-------------------------"));
    // create message payload
    temp = Events.getTemperature();  
    humd = Events.getHumidity();     
    pres = Events.getPressure(); 
        
    char tmp_str[10];
    dtostrf(temp, 2, 1, tmp_str);
    char hum_str[10];
    dtostrf(humd, 2, 1, hum_str);
    char pres_str[10];
    dtostrf(pres, 1, 1, pres_str);
    accX = ACC.getX();
    accY = ACC.getY();
    accZ = ACC.getZ();
    batL = PWR.getBatteryLevel();

    printSensorValues();
    
    snprintf(message,sizeof(message),"#:#X:%d#Y:%d#Z:%d#T:%s#H:%s#P:%s#B:%d",
         accX, accY, accY, tmp_str, hum_str, pres_str,PWR.getBatteryLevel());

    // Send packet
    
    error = xbee802.send( RX_ADDRESS, message);   
    // check TX flag
    if( error == 0 )
    {
      USB.println(F("send ok"));
    }
    else 
    {
      USB.println(F("send error"));
    }
    // turn OFF LEDs
    Utils.setLED(LED1, LED_OFF);
   
  }    

  if(intFlag & SENS_INT){
    
    Events.detachInt();   // Disable interruptions from the board
    Events.loadInt();     // Load the interruption flag  
    
    if (pir.getInt()){    // In case the interruption came from PIR
      USB.println(F("-----------------------------"));
      USB.println(F("Interruption from PIR"));
      USB.println(F("-----------------------------"));
      USB.println();
      snprintf(message,sizeof(message),"#:#ALARM_PIR:ALARM_PIR");
      error = xbee802.send( RX_ADDRESS, message);   
    
      // check TX flag
      if( error == 0 )
      {
        USB.println(F("send ok"));
      }
      else 
      {
        USB.println(F("send error"));
      }
      
           
    }

    pirvalue = pir.readPirSensor();
    USB.println();
    while (pirvalue == 1){
      USB.println(F("...wait for PIR stabilization"));
      delay(1000);
      pirvalue = pir.readPirSensor();    
    }   
    intFlag &= ~(SENS_INT);// Clean the interruption flag
    
    Events.attachInt(); // Enable interruptions from the board
  }
    

  
   
  //  Clear interruption pin   
  
  PWR.clearInterruptionPin();
   

 
}
void printSensorValues(void){
  USB.println("\n-----------------------------");
  USB.print("Battery Level: ");
  USB.printFloat(batL, 2);
  USB.println(F(" %"));
  USB.print("Pressure: ");
  USB.printFloat(pres, 2);
  USB.println(F(" Pa"));
  USB.print("Temperature: ");
  USB.printFloat(temp, 2);
  USB.println(F(" Celsius"));
  USB.print("Humidity: ");
  USB.printFloat(humd, 1); 
  USB.println(F(" %"));  
  USB.println(F(" \t0X\t0Y\t0Z")); 
  USB.print(F(" ACC\t")); 
  USB.print(accX, DEC);
  USB.print(F("\t")); 
  USB.print(accY, DEC);
  USB.print(F("\t")); 
  USB.println(accZ, DEC);
  USB.println("-----------------------------\n");
 }
  



