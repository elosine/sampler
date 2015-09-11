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
int x0 = 25;
int trht, trhf;
float cx=0;
float[]tcx;
int numtrx = 8;
int[] rectogs, playtogs, rangex1, rangex2, ranger, trcsr;

int bufsize;
float[][] samparrays;

int totalbts = 16;
int btspermes = 4;
int totalmes=4;
float mesw, btw, trw;

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
  osc.plug(this, "trix", "/trix");
   
  trw = w-x0;
  bufsize = int(trw);
  btw = trw/totalbts;
  mesw = btspermes*btw;
  trht = round(h/numtrx);

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
  trcsr = new int[numtrx];
  for (int i=0; i<trcsr.length; i++) trcsr[i]=0;
  tcx = new float[numtrx];
  for (int i=0; i<tcx.length; i++) tcx[i]=0.0;

  samparrays = new float[numtrx][bufsize];
  for (int i=0; i<samparrays.length; i++) {
    for (int j=0; j<samparrays[i].length; j++) samparrays[i][j]=0.0;
  }
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
          if (rectogs[0]==1) recon(0);
          else recoff(0);
        }
        //rec track 2 - button 1
        if ( mtemp2[0].equals("bt1") ) {
          rectogs[1] = ( rectogs[1]+int(mtemp2[1]) )%2;
          if (rectogs[1]==1) recon(1);
          else recoff(1);
        }
        //rec track 3 - button 2
        if ( mtemp2[0].equals("bt2") ) {
          rectogs[2] = ( rectogs[2]+int(mtemp2[1]) )%2;
          if (rectogs[2]==1) recon(2);
          else recoff(2);
        }
        //rec track 4 - button 3
        if ( mtemp2[0].equals("bt3") ) {
          rectogs[3] = ( rectogs[3]+int(mtemp2[1]) )%2;
          if (rectogs[3]==1) recon(3);
          else recoff(3);
        }
        //play/pause track 0 - button 5
        if ( mtemp2[0].equals("bt4") ) {
          playtogs[0] = ( playtogs[0]+int(mtemp2[1]) )%2;
          if (playtogs[0]==1) play(0);
          else pause(0);
        }
        //play/pause track 1 - button 6
        if ( mtemp2[0].equals("bt5") ) {
          playtogs[1] = ( playtogs[1]+int(mtemp2[1]) )%2;
          if (playtogs[1]==1) play(1);
          else pause(1);
        }
        //play/pause track 2 - button 7
        if ( mtemp2[0].equals("bt6") ) {
          playtogs[2] = ( playtogs[2]+int(mtemp2[1]) )%2;
          if (playtogs[2]==1) play(2);
          else pause(2);
        }
        //play/pause track 3 - button 8
        if ( mtemp2[0].equals("bt7") ) {
          playtogs[3] = ( playtogs[3]+int(mtemp2[1]) )%2;
          if (playtogs[3]==1) play(3);
          else pause(3);
        }
      }
    }
  }
  
  //button area
  noStroke();
  fill(120);
  rect(0, 0, x0, height);

  //track background
  noStroke();
  for (int i=0; i<ceil (numtrx/2); i++) {
    //t1
    fill(0);
    rect(x0, trht*2*i, w, trht);
    //t2
    fill(25, 33, 47);
    rect(x0, (trht*2*i)+trht, w, trht);
  }

  //beat markers
  strokeWeight(1);
  ellipseMode(CENTER);
  fill(255);
  for (int j=0; j<numtrx; j++) {
    stroke(255);
    for (int i=0; i<totalmes; i++) line( (mesw*i)+x0, (trht*j)+(trht*0.3333), (mesw*i)+x0, (trht*j)+(trht*0.66667) );
    noStroke();
    for (int i=0; i<totalbts; i++) ellipse( (btw*i)+x0, (trht*j)+(trht/2), 7, 7 );
  }

  //waveform display
  stroke(255, 153, 51);
  strokeWeight(1);
  for (int j=0; j<numtrx; j++) {
    for (int i=1; i<bufsize; i++) {
      line( (i-1)+x0, ((trht*j)+(trht/2)) + (samparrays[j][i-1] * (trht/2)), i+x0, ((trht*j)+(trht/2)) + (samparrays[j][i] * (trht/2)) );
    }
  }

  //record & play highlighting
  for (int i=0; i<numtrx; i++) {
    if (playtogs[i]==0) {
      fill(153, 225, 0, 40);
      rect(x0, trht*i, w, trht);
    }
    if (rectogs[i]==1) {
      fill(255, 105, 180, 120);
      rect(x0, trht*i, w, trht);
      /**/ if((frameCount%6)==0)osc.send("/wavfrm", new Object[]{i}, sc);
    }
  }  

  //Ranger
  for (int i=0; i<numtrx; i++) {
    if (ranger[i]==1) {
      noStroke();
      fill(255, 0, 255, 100);
      rect(rangex1[i], trht*i, rangex2[i]-rangex1[i], trht);
    }
  }

  //record & play & reset cursor buttons
  for (int i=0; i<numtrx; i++) {
    if (whichtrack()==i) {
      if (mouseX<x0) {
        noStroke();
        //record
        fill(255, 0, 0);
        strokeWeight(3);
        stroke(120);
        rect(0, (i*trht), 20, 20);
        //play
        fill(0, 255, 0);
        rect(0, (i*trht)+20, 20, 20);
        //reset cursor
        fill(0, 0, 255);
        rect(0, (i*trht)+40, 20, 20);
      }
    }
  }

  //Cursor
  /**/ osc.send("/getidx", new Object[]{}, sc); //get current cursor location from sc
  strokeWeight(3);
  stroke(153, 255, 0);
  line(cx, 0, cx, h);

  //Track Cursors
  for (int i=0; i<numtrx; i++) {
    if (trcsr[i]==1) {
      /**/ osc.send("/gettridx", new Object[]{i}, sc); //get current cursor location from sc
      strokeWeight(3);
      stroke(0, 153, 255);
      line( tcx[i], trht*i, tcx[i], trht*(i+1) );
    }
  }
}

void mousePressed() {
  //Record & play toggles
  for (int i=0; i<numtrx; i++) {
    //record
    if ( whichtrack()==i && mouseX<=20 && mouseY>(trht*i) && mouseY<((trht*i)+20) ) {
      rectogs[i] = (rectogs[i]+1)%2;
      if (rectogs[i]==1) recon(i);
      else recoff(i);
    }
    //play
    if ( whichtrack()==i && mouseX<=20 && mouseY>(trht*i)+20 && mouseY<(trht*i)+40 ) {
      playtogs[i] = (playtogs[i]+1)%2;
      if (playtogs[i]==1) play(i);
      else pause(i);
    }
    //Button to go back to main cursor
    if ( whichtrack()==i && mouseX<=20 && mouseY>(trht*i)+40 && mouseY<(trht*i)+60 ) {
      ranger[i] = 0;
      trcsr[i] = 0;
      /**/osc.send("/setidx", new Object[]{ -1, 0, 1, 1 }, sc);
    }
    if ( mouseX>=x0 && mouseY>(trht*i) && mouseY<(trht*(i+1)) ) {
        ranger[i] = 1;
        rangex1[i] = mouseX;
        rangex2[i] = mouseX;
      }
  }
}

void mouseDragged() {
  //for ranger (not touching the record or play buttons
  for (int i=0; i<numtrx; i++) {
    if ( mouseX>=x0 && mouseY>(trht*i) && mouseY<(trht*(i+1)) ) {
        rangex2[i] = mouseX;
      }
  }
}

void mouseReleased() {
  //for ranger (not touching the record or play buttons
  for (int i=0; i<numtrx; i++) {
    if ( mouseX>=x0 && mouseY>(trht*i) && mouseY<(trht*(i+1)) ) {
        if ( whichtrack()==i ) {
          float rx1 = norm(rangex1[i], x0, width);
          float rx2 = norm(rangex2[i], x0, width);
          trcsr[i] = 1;
          /**/osc.send("/setidx", new Object[]{ i, rx1, rx2, 1 }, sc);
        }
      }
  }
}

void keyPressed() {
  if (key=='s') {
    /**/osc.send("/stop", new Object[]{}, sc);
    for (int i=0; i<samparrays.length; i++) {
      for (int j=0; j<samparrays[i].length; j++) samparrays[i][j]=0.0;
    }
    for (int i=0; i<numtrx; i++){
      trcsr[i]=0;
      ranger[i]=0;
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


//Receives master index location
public void ix(float idx) {
  cx = (idx*trw) + x0;
}

//Receives track index location
public void trix(int tr, float idx) {
  tcx[tr] = (idx*trw) + x0;
}

//play
public void play(int tr) {
  int ixtr;
  if (trcsr[tr]==1) ixtr=tr+1;
  else ixtr=0;
  /**/osc.send("/play", new Object[]{ tr, ixtr }, sc);
}

//pause
public void pause(int tr) {
  /**/osc.send("/pause", new Object[]{tr}, sc);
}

//rec on
public void recon(int tr) {
  /**/osc.send("/recon", new Object[]{tr}, sc);
}

//rec off
public void recoff(int tr) {
  /**/osc.send("/recoff", new Object[]{tr}, sc);
}

