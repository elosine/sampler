//waveform display
//beat markers
//arduino
//change tempo
//loop single bars

import oscP5.*;
import netP5.*;

OscP5 osc;
NetAddress sc;
int h = 640;
int w = 1000;
int trht;
float cx=0;
int numtrx = 8;
int[] rectogs, playtogs;

int bufsize = 800;
float[] sampArray;

void setup() {
  size(w, h);
  OscProperties properties= new OscProperties();
  //properties.setRemoteAddress("127.0.0.1", 57120);  //osc send port (to sc)
  properties.setListeningPort(12321);               //osc receive port (from sc)/*
  properties.setDatagramSize(5136);  //5136 is the minimum 
  osc= new OscP5(this, properties);
  sc = new NetAddress("127.0.0.1", 57120);
  
  trht = round(h/numtrx);

  rectogs = new int[numtrx];
  for (int i=0; i<rectogs.length; i++) rectogs[i]=0;
  playtogs = new int[numtrx];
  for (int i=0; i<playtogs.length; i++) playtogs[i]=1;


  sampArray = new float[bufsize];
  for (int i=0; i<bufsize; i++) sampArray[i] = 0.0;

  sc = new NetAddress("127.0.0.1", 57120);
  osc.plug(this, "ix", "/ix");
}

void draw() {
  background(255);
  
  //track background
  noStroke();
  for (int i=0; i<ceil (numtrx/2); i++) {
    //t1
    fill(0);
    rect(0, trht*2*i, w, trht);
    //t2
    fill(25, 33, 47);
    rect(0, (trht*2*i)+trht, w, trht);
  }
  
  //waveform display
  for (int i=1; i<bufsize; i++) {
    stroke(255, 153, 51);
    strokeWeight(1);
    line(i-1, 400 - (sampArray[i-1] * 300), i, 400 - (sampArray[i] * 300) );
  }
  

  //record & play highlighting
  for (int i=0; i<numtrx; i++) {
    if (playtogs[i]==0) {
      fill(153, 225, 0, 40);
      rect(0, trht*i, w, trht);
    }
    if (rectogs[i]==1) {
      fill(255, 105, 180, 120);
      rect(0, trht*i, w, trht);
    }
  }

  //Cursor
  osc.send("/getidx", new Object[] {}, sc); //get current cursor location from sc
  strokeWeight(3);
  stroke(153, 255, 0);
  line(cx, 0, cx, h);
}

public void ix(float idx) {
  cx = idx*w;
}

void mousePressed() {
  //Record & play toggles
  for (int i=0; i<numtrx; i++) {
    if ( mouseX<(w/2) && mouseY>(trht*i) && mouseY<((trht*i)+trht) ) {
      rectogs[i] = (rectogs[i]+1)%2;
      if (rectogs[i]==1) osc.send("/recon", new Object[]{i}, sc);
      else osc.send("/recoff", new Object[]{i}, sc);
    }
    if ( mouseX>(w/2) && mouseY>(trht*i) && mouseY<((trht*i)+trht) ) {
      playtogs[i] = (playtogs[i]+1)%2;
      if(playtogs[i]==1) osc.send("/play", new Object[] {i}, sc);
      else osc.send("/pause", new Object[] {i}, sc);
    }
  }
}

void oscEvent(OscMessage msg) {
  if ( msg.checkAddrPattern("/sbuf") ) {

   for (int i=0; i<bufsize; i++) {
     println(msg.get(i).floatValue());
     sampArray[i] = msg.get(i).floatValue();
   }
  //  println(sampArray);
  }
}

