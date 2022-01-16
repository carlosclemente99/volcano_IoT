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

float temp;
float humd;
float pres;
float value;
uint8_t status;
int x_acc;
int y_acc;
int z_acc;
int battery_level;

void setup() 
{
  // Turn on the USB and print a start message
  USB.ON();
  USB.println(F("Start program"));
  ACC.ON();
  
  
}



void loop() 
{
  
  ///////////////////////////////////////
  // 1. Read  Values
  ///////////////////////////////////////
  // Turn on the sensor board
  Events.ON();
  //Temperature
  temp = Events.getTemperature();
  //Humidity
  humd = Events.getHumidity();
  //Pressure
  pres = Events.getPressure();
  //Accelerometer
  status = ACC.check();
  x_acc = ACC.getX();
  y_acc = ACC.getY();
  z_acc = ACC.getZ();
  //Battery Level
  battery_level = PWR.getBatteryLevel();
  ///////////////////////////////////////
  // 2. Print  Values
  ///////////////////////////////////////
  USB.println("-----------------------------");
  USB.print("Temperature: ");
  USB.printFloat(temp, 2);
  USB.println(F(" Celsius"));
  USB.print("Humidity: ");
  USB.printFloat(humd, 1); 
  USB.println(F(" %")); 
  USB.print("Pressure: ");
  USB.printFloat(pres, 2); 
  USB.println(F(" Pa")); 
  USB.print(F("Battery Level: "));
  USB.print(battery_level,DEC);
  USB.print(F(" %"));
  USB.print(F("\nCheck acc status: 0x")); 
  USB.println(status, HEX);
  USB.println(F("\n \t0X\t0Y\t0Z")); 
  USB.print(F(" ACC\t")); 
  USB.print(x_acc, DEC);
  USB.print(F("\t")); 
  USB.print(y_acc, DEC);
  USB.print(F("\t")); 
  USB.println(z_acc, DEC);
  USB.println("-----------------------------");  

  // Every 3 seconds
  delay(3000);

}
