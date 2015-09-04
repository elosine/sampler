//play range
//hook up red buttons
//make performance
//finish this sequencer and draw a line under it
//clean up code
//make tutorial videos and assignments
//separate cursors
//play range
//change tempo


import oscP5.*;
import netP5.*;
import processing.serial.*;

Serial ino; 
int numbts = 8;
String serialmsg;

OscP5 osc;
NetAddress sc;
int h = 640;
int w = 1000;
int trht, trhf;
float cx=0;
int numtrx = 8;
int[] rectogs, playtogs;

int bufsize = 1000;
float[][] samparrays;

int totalbts = 16;
int btspermes = 4;
int totalmes=4;
float mesw, btw;


void setup() {
  size(w, h);

  String portName = Serial.list()[2];
  ino = new Serial(this, portName, 9600);

  OscProperties properties= new OscProperties();
  //properties.setRemoteAddress("127.0.0.1", 57120);  //osc send port (to sc)
  properties.setListeningPort(12321);               //osc receive port (from sc)/*
  properties.setDatagramSize(5136);  //5136 is the minimum 
  osc= new OscP5(this, properties);
  sc = new NetAddress("127.0.0.1", 57120);
  osc.plug(this, "ix", "/ix");

  trht = round(h/numtrx);
  trhf = round(trht/2);

  rectogs = new int[numtrx];
  for (int i=0; i<rectogs.length; i++) rectogs[i]=0;
  playtogs = new int[numtrx];
  for (int i=0; i<playtogs.length; i++) playtogs[i]=1;
  samparrays = new float[numtrx][bufsize];
  for (int i=0; i<samparrays.length; i++) {
    for (int j=0; j<samparrays[i].length; j++) samparrays[i][j]=0.0;
  } 

  btw = w/totalbts;
  mesw = btspermes*btw;
  

}

void draw() {
  background(255);
  
  //read serial port
  if ( ino.available() > 0) {
    serialmsg = ino.readString();
    String[] mtemp = split(serialmsg, ";");
    mtemp = shorten(mtemp); //because last semi-colon adds extra item
    for (int i=0; i<mtemp.length; i++) {
      String[]mtemp2 = split(mtemp[i], ":");
      //rec track 1 - button 0
      if( mtemp2[0].equals("bt0") ){
        rectogs[0] = ( rectogs[0]+int(mtemp2[1]) )%2;
   /**/ if (rectogs[0]==1) osc.send("/recon", new Object[]{0}, sc);
   /**/ else osc.send("/recoff", new Object[]{0}, sc);
      }
      //rec track 2 - button 1
      if( mtemp2[0].equals("bt1") ){
        rectogs[1] = ( rectogs[1]+int(mtemp2[1]) )%2;
   /**/ if (rectogs[1]==1) osc.send("/recon", new Object[]{1}, sc);
   /**/ else osc.send("/recoff", new Object[]{1}, sc);
      }
    }
  }

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

  //beat markers
  strokeWeight(1);
  ellipseMode(CENTER);
  fill(255);
  for (int j=0; j<numtrx; j++) {
    stroke(255);
    for (int i=0; i<totalmes; i++) line( mesw*i, (trht*j)+(trht*0.3333), mesw*i, (trht*j)+(trht*0.66667) );
    noStroke();
    for (int i=0; i<totalbts; i++) ellipse( btw*i, (trht*j)+trhf, 7, 7 );
  }

  //waveform display
  stroke(255, 153, 51);
  strokeWeight(1);
  for (int j=0; j<numtrx; j++) {
    for (int i=1; i<bufsize; i++) {
      line(i-1, ((trht*j)+trhf) + (samparrays[j][i-1] * trhf), i, ((trht*j)+trhf) + (samparrays[j][i] * trhf) );
    }
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
 /**/ if((frameCount%6)==0)osc.send("/wavfrm", new Object[]{i}, sc); 
    }
  }

  //Cursor
/**/ osc.send("/getidx", new Object[]{}, sc); //get current cursor location from sc
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
 /**/ if (rectogs[i]==1) osc.send("/recon", new Object[] {i}, sc);
 /**/ else osc.send("/recoff", new Object[] {i}, sc);
    }
    if ( mouseX>(w/2) && mouseY>(trht*i) && mouseY<((trht*i)+trht) ) {
      playtogs[i] = (playtogs[i]+1)%2;
 /**/ if (playtogs[i]==1) osc.send("/play", new Object[]{i}, sc);
 /**/ else osc.send("/pause", new Object[]{i}, sc);
    }
  }
}

void keyPressed(){
  if(key=='s'){
/**/osc.send("/stop", new Object[]{}, sc);
    for (int i=0; i<samparrays.length; i++) {
      for (int j=0; j<samparrays[i].length; j++) samparrays[i][j]=0.0;
    } 
  }
/**/if(key=='r')osc.send("/restart", new Object[]{}, sc);
}

void oscEvent(OscMessage msg) {
  //get waveform data and store in samparrays
  if ( msg.checkAddrPattern("/sbuf") ) {
    int trkn = msg.get(0).intValue();
    for (int i=0; i<bufsize; i++) {
      if (i>0) samparrays[trkn][i] = msg.get(i).floatValue();
    }
  }
}

