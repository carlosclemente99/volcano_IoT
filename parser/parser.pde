/*
 *  ------   [UT_07] - Formatted messages   -------- 
 *
 *  Explanation: This example shows how to use the snprintf function
 *  in order to create formatted strings from variable values. The 
 *  variables types can be integer types, characters, strings, etc.
 *  Conversions are introduced with the character '%'. Possible 
 *  options can follow the '%':
 *    %c 	character
 *    %d 	signed integers
 *    %i 	signed integers
 *    %o 	octal
 *    %s 	a string of characters
 *    %u 	unsigned integer
 *    %x 	unsigned hexadecimal, with lowercase letters
 *    %X 	unsigned hexadecimal, with uppercase letters 
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
 *  Design:            David Gascon 
 *  Implementation:    Yuri Carmona
 */

// define buffer to store the message
char message[100];

// define several variable types to be 
// included within a formatted message
char character = 'A';
int  integer = -123;
char string[]="This_is_a_string";
unsigned long ulong = 10000000;
float float_val = 123.456789;


void setup() 
{ 
  USB.ON();
  
  
  /////////////////////////////////////////////////
  // 1. Include Character  
  /////////////////////////////////////////////////
 
  
  
}



void loop() 
{
  
  char *payload = "<=>†#24417C32C8913E94#node_01#0#BAT:95#ACC:364;-115;941#H2S:9531";
  char subPay[4];
  char batLevel[2];
  char accValueX[4];
  char accValueY[4];
  char accValueZ[4];
  int size = 72;
  memcpy(subPay,&payload[34],3);
  subPay[3]='\0';
  USB.println(subPay);
  if (strcmp(subPay,"BAT")== 0){
    int i = 34;
    char tag[3];
    memcpy(tag,&payload[i],3);
    tag[3]='\0';
    USB.println(tag);
    i = 38;
    while (&payload[i] != "#"){
      memcpy(batLevel,&payload[i],1);
      USB.println(&payload[i]);
      i = i+1;
    }
    USB.println(batLevel);
    memcpy(tag,&payload[i],3);
    tag[3]='\0';
    if (strcmp(tag,"ACC")== 0){
      while(&payload[i] != "#"){
        while( &payload[i] != ";"){
          memcpy(accValueX,&payload[i+1],1);
          i = i+1;
        }
        USB.println(accValueX);
        while( &payload[i+1] != ";"){
          memcpy(accValueY,&payload[i+1],1);
          i = i+1;
        }
        USB.println(accValueX);
        i = i+1;
        memcpy(accValueZ,&payload[i+1],1);
        USB.println(accValueX);
        
        }
        
        
      }
      
      
    }
    
    
     delay(5000);
 
}






