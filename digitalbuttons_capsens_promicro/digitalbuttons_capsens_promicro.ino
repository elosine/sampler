  #include <CapacitiveSensor.h>

//Buttons
int numbts = 10;
int bts[] = {2, 3, 4, 5, 6, 7, 8, 9, 10, 16};
boolean bgates[10];
//Capacitive Sensors
int numcps = 2;
//CapacitiveSensor cps[] = {CapacitiveSensor(21, 14), CapacitiveSensor(21, 15), CapacitiveSensor(21, 18), CapacitiveSensor(21, 19), CapacitiveSensor(21, 20)};
CapacitiveSensor cps[] = {CapacitiveSensor(21, 14), CapacitiveSensor(21, 15)};
//CapacitiveSensor cps[] = {CapacitiveSensor(21, 14)};
boolean cpsgates[2];
long cpsval[2];
void setup() {
  Serial.begin(9600);
  for (int i = 0; i < numbts; i++) pinMode(bts[i], INPUT_PULLUP);
  for (int i = 0; i < numbts; i++) bgates[i] = false;
  for (int i = 0; i < numcps; i++) cpsgates[i] = true;
}

void loop() {
  //buttons
  for (int i = 0; i < numbts; i++) {
    if (!bgates[i]) {
      if (digitalRead(bts[i]) == LOW) {
        bgates[i] = true;
        Serial.print("bt" + String(i) + ":");
        Serial.println(1, DEC);
      }
    }
    if (bgates[i]) {
      if (digitalRead(bts[i]) == HIGH) {
        bgates[i] = false;
        Serial.print("bt" + String(i) + ":");
        Serial.println(0, DEC);
      }
    }
  }
  //Capacitive Sensors
 //long val = cps[0].capacitiveSensor(30);
 // Serial.println(val);
  for (int i = 0; i < numcps; i++) {
    cpsval[i] = cps[i].capacitiveSensor(30);
    if (cpsval[i] >= 5000) {
      if (cpsgates[i]) {
        cpsgates[i] = false;
        Serial.print("cs" + String(i) + ":");
        Serial.println(1, DEC);
      }
    }
    else if (cpsval[i] < 500) {
      if (!cpsgates[i]) {
        cpsgates[i] = true;
        Serial.print("cs" + String(i) + ":");
        Serial.println(0, DEC);
      }
    }
  }

  delay(15);
}
