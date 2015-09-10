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
float[]tcx;
int numtrx = 8;
int[] rectogs, playtogs, rangex1, rangex2, ranger;

int bufsize = 1000;
float[][] samparrays;

int totalbts = 16;
int btspermes = 4;
int totalmes=4;
float mesw, btw;

boolean serialon = false;


void setup() {
  size(w, h);

  if (serialon) {
    String portName = Serial.list()[2];
    ino = new Serial(this, portName, 9600);
  }

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
  rangex1 = new int[numtrx];
  for (int i=0; i<rangex1.length; i++) rangex1[i]=0;
  rangex2 = new int[numtrx];
  for (int i=0; i<rangex2.length; i++) rangex2[i]=width;
  ranger = new int[numtrx];
  for (int i=0; i<ranger.length; i++) ranger[i]=0;
  tcx = new float[numtrx];
  for (int i=0; i<tcx.length; i++) tcx[i]=0.0;
  
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
  if (serialon) {
    if ( ino.available() > 0) {
      serialmsg = ino.readString();
      String[] mtemp = split(serialmsg, ";");
      mtemp = shorten(mtemp); //because last semi-colon adds extra item
      for (int i=0; i<mtemp.length; i++) {
        String[]mtemp2 = split(mtemp[i], ":");
        //rec track 1 - button 0
        if ( mtemp2[0].equals("bt0") ) {
          rectogs[0] = ( rectogs[0]+int(mtemp2[1]) )%2;
              /**/ if (rectogs[0]==1) osc.send("/recon", new Object[]{0}, sc);
             /**/ else osc.send("/recoff", new Object[]{0}, sc);
        }
        //rec track 2 - button 1
        if ( mtemp2[0].equals("bt1") ) {
          rectogs[1] = ( rectogs[1]+int(mtemp2[1]) )%2;
              /**/ if (rectogs[1]==1) osc.send("/recon", new Object[]{1}, sc);
              /**/ else osc.send("/recoff", new Object[]{1}, sc);
        }
        //rec track 3 - button 2
        if ( mtemp2[0].equals("bt2") ) {
          rectogs[2] = ( rectogs[2]+int(mtemp2[1]) )%2;
              /**/ if (rectogs[2]==1) osc.send("/recon", new Object[]{2}, sc);
              /**/ else osc.send("/recoff", new Object[]{2}, sc);
        }
        //rec track 4 - button 3
        if ( mtemp2[0].equals("bt3") ) {
          rectogs[3] = ( rectogs[3]+int(mtemp2[1]) )%2;
              /**/ if (rectogs[3]==1) osc.send("/recon", new Object[]{3}, sc);
             /**/ else osc.send("/recoff", new Object[]{3}, sc);
        }
        //play/pause track 0 - button 5
        if ( mtemp2[0].equals("bt4") ) {
          playtogs[0] = ( playtogs[0]+int(mtemp2[1]) )%2;
             /**/ if (playtogs[0]==1) osc.send("/play", new Object[]{0}, sc);
             /**/ else osc.send("/pause", new Object[]{0}, sc);
        }
        //play/pause track 1 - button 6
        if ( mtemp2[0].equals("bt5") ) {
          playtogs[1] = ( playtogs[1]+int(mtemp2[1]) )%2;
             /**/ if (playtogs[1]==1) osc.send("/play", new Object[]{1}, sc);
             /**/ else osc.send("/pause", new Object[]{1}, sc);
        }
        //play/pause track 2 - button 7
        if ( mtemp2[0].equals("bt6") ) {
          playtogs[2] = ( playtogs[2]+int(mtemp2[1]) )%2;
              /**/ if (playtogs[2]==1) osc.send("/play", new Object[]{2}, sc);
              /**/ else osc.send("/pause", new Object[]{2}, sc);
        }
        //play/pause track 3 - button 8
        if ( mtemp2[0].equals("bt7") ) {
          playtogs[3] = ( playtogs[3]+int(mtemp2[1]) )%2;
              /**/ if (playtogs[3]==1) osc.send("/play", new Object[]{3}, sc);
              /**/ else osc.send("/pause", new Object[]{3}, sc);
        }
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

  //Ranger
  for (int i=0; i<numtrx; i++) {
    if (ranger[i]==1) {
      noStroke();
      fill(255, 128, 0, 100);
      rect(rangex1[i], trht*i, rangex2[i]-rangex1[i], trht);
    }
  }

  //record & play buttons
  for (int i=0; i<numtrx; i++) {
    if (whichtrack()==i) {
      if (mouseX<25) {
        noStroke();
        fill(255, 0, 0);
        rect(0, i*trht, 20, 20);
        fill(0, 255, 0);
        rect(0, ((i+1)*trht)-20, 20, 20);
      }
    }
  }

  //Cursor
  /**/ osc.send("/getidx", new Object[]{}, sc); //get current cursor location from sc
  strokeWeight(3);
  stroke(153, 255, 0);
  line(cx, 0, cx, h);
}

//Receives master index location
public void ix(float idx) {
  cx = idx*w;
}

//Receives track index location
public void trix(int tr, float idx) {
  tcx[tr] = idx*w;
}

void mousePressed() {
  //Record & play toggles
  for (int i=0; i<numtrx; i++) {
    if ( whichtrack()==i && mouseX<=20 && mouseY>(trht*i) && mouseY<((trht*i)+20) ) {
      rectogs[i] = (rectogs[i]+1)%2;
       /**/ if (rectogs[i]==1) osc.send("/recon", new Object[] {i}, sc);
       /**/ else osc.send("/recoff", new Object[] {i}, sc);
    }
    if ( whichtrack()==i && mouseX<=20 && mouseY>(trht*(i+1))-20 && mouseY<(trht*(i+1)) ) {
      playtogs[i] = (playtogs[i]+1)%2;
       /**/ if (playtogs[i]==1) osc.send("/play", new Object[]{i}, sc);
       /**/ else osc.send("/pause", new Object[]{i}, sc);
    }
    //for ranger (not touching the record or play buttons
    if ( mouseX<21 ) {
      if ( mouseY>((trht*i) + 20) && mouseY<((trht*(i+1)) - 20) ) {
        ranger[i] = 1;
        rangex1[i] = mouseX;
        rangex2[i] = mouseX;
      }
    } else if ( mouseY>(trht*i) && mouseY<(trht*(i+1)) ) {
      ranger[i] = 1;
      rangex1[i] = mouseX;
      rangex2[i] = mouseX;
    }
  }
}

void mouseDragged() {
  //for ranger (not touching the record or play buttons
  for (int i=0; i<numtrx; i++) {

    if ( mouseX<21 ) {
      if ( mouseY>((trht*i) + 20) && mouseY<((trht*(i+1)) - 20) ) {
        rangex2[i] = mouseX;
      }
    } else if ( mouseY>(trht*i) && mouseY<(trht*(i+1)) ) {
      rangex2[i] = mouseX;
    }
  }
}

void mouseReleased(){
  
}

void keyPressed() {
  if (key=='s') {
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

int whichtrack() {
  int trk=0;
  for (int i=0; i<numtrx; i++) {
    if ( mouseY>(trht*i) && mouseY<((trht*i)+trht) ) trk = i;
  }
  return trk;
}

