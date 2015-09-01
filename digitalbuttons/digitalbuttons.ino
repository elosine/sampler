int numbts = 8;
int bts[8];
boolean bgates[8];

void setup() {
  Serial.begin(9600);
  for (int i = 0; i < numbts; i++) bts[i] = i + 2;
  for (int i = 0; i < numbts; i++) pinMode(bts[i], INPUT_PULLUP);
  for (int i = 0; i < numbts; i++) bgates[i] = false;
}

void loop() {
  for (int i = 0; i < numbts; i++) {
    if (!bgates[i]) {
      if (digitalRead(bts[i]) == LOW) {
        bgates[i] = true;
        Serial.print("bt" + String(i) + ":");
        Serial.print(1, DEC);
        Serial.print(";");
      }
    }
    if (bgates[i]) {
      if (digitalRead(bts[i]) == HIGH) {
        bgates[i] = false;
        Serial.print("bt" + String(i) + ":");
        Serial.print(0, DEC);
        Serial.print(";");
      }
    }
  }
//Serial.println();
  delay(5);
}
