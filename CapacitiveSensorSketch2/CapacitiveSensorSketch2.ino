#include <CapacitiveSensor.h>

/*
 * CapitiveSense Library Demo Sketch
 * Paul Badger 2008
 * Uses a high value resistor e.g. 10M between send pin and receive pin
 * Resistor effects sensitivity, experiment with values, 50K - 50M. Larger resistor values yield larger sensor values.
 * Receive pin is the sensor pin - try different amounts of foil/metal on this pin
 */


CapacitiveSensor   cs_4_2 = CapacitiveSensor(4,2);        // 10M resistor between pins 4 & 2, pin 2 is sensor pin, add a wire and or foil if desired
//CapacitiveSensor   cs_4_6 = CapacitiveSensor(4,6);        // 10M resistor between pins 4 & 6, pin 6 is sensor pin, add a wire and or foil
//CapacitiveSensor   cs_4_8 = CapacitiveSensor(4,8);        // 10M resistor between pins 4 & 8, pin 8 is sensor pin, add a wire and or foil
//CapacitiveSensor   cs_4_10 = CapacitiveSensor(4,10);        // 10M resistor between pins 4 & 8, pin 8 is sensor pin, add a wire and or foil

boolean g1 = true;
boolean g2 = true;
boolean g3 = true;
boolean g4 = true;

void setup(){
  Serial.begin(9600);
}

void loop()                    
{
  long total1 =  cs_4_2.capacitiveSensor(30);
  // long total2 =  cs_4_6.capacitiveSensor(30);
  //  long total3 =  cs_4_8.capacitiveSensor(30);
  //  long total4 =  cs_4_10.capacitiveSensor(30);


  if (total1 > 500) {
    if(g1) {
      g1 = false;
      Serial.print("cs1:");
      Serial.print(total1, DEC);
      Serial.println(";");
    }
  }
  else if(total1<=500){
    g1=true;
  }

  /*
  if (total2 > 500) {
   if(g2) {
   g2 = false;
   Serial.print("cs2:");
   Serial.print(total2, DEC);
   Serial.println(";");
   }
   }
   else if(total2<=500){
   g2=true;
   }
   
   if (total3 > 500) {
   if(g3) {
   g3 = false;
   Serial.print("cs3:");
   Serial.print(total3, DEC);
   Serial.println(";");
   }
   }
   else if(total3<=500){
   g3=true;
   }
   
   if (total4 > 500) {
   if(g4) {
   g4 = false;
   Serial.print("cs4:");
   Serial.print(total4, DEC);
   Serial.println(";");
   }
   }
   else if(total4<=500){
   g4=true;
   }
   
   
   
   */

  delay(15);                             // arbitrary delay to limit data to serial port 
}


