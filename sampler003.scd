(
////VARIABLES////
~numtrx = 8;
~ixsynths = Array.newClear(~numtrx+1); //initialize new array to hold record index synths, ~numtrx+1 is so ~ixbufs[0] could be a master index
~recsynths = Array.newClear(~numtrx); //initialize new array to hold record synths
~playsynths = Array.newClear(~numtrx); //initialize new array to hold play synths
~ixbufs = {Buffer.alloc(s, s.sampleRate*16.0, 1)}!(~numtrx+1); //buffers to hold current index location, notice it is 16 seconds long, or 4 4_4 bars at bpm=60 (s.sampleRate*16.0);
~trx = {Buffer.alloc(s, s.sampleRate * 16.0, 1)}!~numtrx; //buffers to hold track audio
~ixbuses = {Bus.audio(s)}!(~numtrx+1); //audio rate busses to hold index location
~ixkbuses = {Bus.control(s)}!(~numtrx+1); //control rate busses to hold index location, for waveform display
~zerobus = Bus.audio(s); //zero value index bus to switch to for pause/stop
~ixgr = Group.new(); //ix group before all groups
~ingr = Group.after(~ixgr); //in group for incomming (rec) audio
~ogr = Group.after(~ingr); //out group for outgoing (play) audio
~proc = NetAddr("127.0.0.1", 12321); //net sender to processing

////SYNTHDEFS////
//synthdef to control the indexes
SynthDef(\bufidx,{
	arg buf, spd=1, bus, numbts=1.0, start=0.0, end=1.0, kbus;
	var indexer, indexnorm;
	//create an audio rate indexer using the Phasor object
	indexer = Phasor.ar(trig:0, rate:BufRateScale.kr(buf)*spd, start:start*BufFrames.kr(buf), end:end*BufFrames.kr(buf));
	//normalize the index
	indexnorm = indexer.linlin(0.0, BufFrames.kr(buf), 0.0, numbts);
	//send the index out to both a control and audio rate bus
	Out.ar(bus, indexer);
	Out.kr(kbus, indexnorm);
}).add;

SynthDef(\bufrec, {
	arg ich=0, idxbus, buf;
	var in, idx;
	idx = In.ar(idxbus);
	in = SoundIn.ar(ich);
	BufWr.ar(in, buf, idx);
}).add;

SynthDef(\bufpl, {
	arg idxbus, obs=0, buf;
	var idx, sig;
	idx = In.ar(idxbus);
	sig = BufRd.ar(1, buf, idx);
	Out.ar(obs, sig);
}).add;

////FUNCTIONS////
//Function to collect & send waveform display data
~waveform = { |buf trkn|
	var bufarray, sampsize, resamp, resampArray, ct;
	buf.loadToFloatArray( action:{
		arg array;
		var bufarray, sampsize, resamp, resampArray, ct;
		bufarray = array;
		//RESAMPLE TO MANAGEABLE SIZE
		sampsize = 975; //Make sure to change this if you change pixel width of sampler
		resamp = (bufarray.size/sampsize).round;
		resampArray = Array.newClear(sampsize+2); //This is the new resampled array
		ct = 0; //A counter for the resampled array
		//RESAMPLE THE BUFFER ARRAY AND PUT THE VALUES INTO A NEW ARRAY AS FLOATS
		bufarray.do{ |it, ix| if( ix%resamp == 0, {resampArray[ct]=it.asFloat; ct = ct+1} ) };
		//ADD TRACK NUMBER AND OSC ADDRESS
		resampArray = resampArray.insert(0, trkn.asInteger);
		resampArray = resampArray.insert(0, "/sbuf");
		//SEND TO PROCESSING
		~proc.sendBundle(0.0, resampArray);
	} );
};

////OSCDEFS////
//On Demand normalized index
OSCdef( \getidx,{ ~ixkbuses[0].get({arg val; ~proc.sendMsg("/ix", val)}) }, "/getidx");
OSCdef( \gettridx,{
	arg msg;
	var tr = msg[1].asInteger;
	~ixkbuses[tr+1].get({arg val; ~proc.sendMsg("/trix", tr, val.asFloat)}) ;
}, "/gettridx");

OSCdef( \setidx,{
	arg msg;
	var trnum, start, end;
	msg.postln;
	trnum = msg[1].asInteger;
	start = msg[2].asFloat;
	end = msg[3].asFloat;
	~ixsynths[trnum+1].set(\start,  start); //trnum+1because ix track 0 is master track
	~ixsynths[trnum+1].set(\end,  end);
	~playsynths[trnum].set(\idxbus, ~ixbuses[trnum+1]);
}, "/setidx");

//record and play
OSCdef(\recon, {
	arg msg;
	var tr;
	tr = msg[1].asInteger;
	~recsynths[tr].set(\idxbus, ~ixbuses[0]);
	"on: ".post; tr.postln;
}, "/recon");

OSCdef(\recoff, {
	arg msg;
	var tr;
	tr = msg[1].asInteger;
	~recsynths[tr].set(\idxbus, ~zerobus);
}, "/recoff");

OSCdef(\play, {
	arg msg;
	var tr, ixb;
	tr = msg[1].asInteger;
	ixb = msg[2].asInteger;
	~playsynths[tr].set(\idxbus, ~ixbuses[ixb]);
}, "/play");

OSCdef(\pause, {
	arg msg;
	var tr;
	tr = msg[1].asInteger;
	~playsynths[tr].set(\idxbus, ~zerobus);
}, "/pause");

OSCdef(\wavfrm, {
	arg msg;
	var tr = msg[1].asInteger;
	~waveform.value(~trx[tr], tr);
}, "/wavfrm");

OSCdef(\stop, {
	~numtrx.do{|ix| ~recsynths[ix].free; ~playsynths[ix].free; ~ixsynths[ix].free};
	~trx.do{|it| it.free};
	~trx = nil;
}, "/stop");

OSCdef(\restart, {
	~trx = {Buffer.alloc(s, s.sampleRate * 16.0, 1)}!16;
	~numtrx.do{ |ix|
		~ixsynths[ix] = Synth(\bufidx, [\buf, ~ixbufs[ix], \bus, ~ixbuses[ix], \kbus, ~ixkbuses[ix]], ~ixgr);
	~recsynths[ix] = Synth(\bufrec, [\idxbus, ~zerobus, \buf, ~trx[ix]], ~ingr);
	~playsynths[ix] = Synth(\bufpl, [\idxbus, ~ixbuses[0], \buf, ~trx[ix]], ~ogr)
	};
}, "/restart");
)

(
(~numtrx+1).do{ |ix| ~ixsynths[ix] = Synth(\bufidx, [\buf, ~ixbufs[ix], \bus, ~ixbuses[ix], \kbus, ~ixkbuses[ix]], ~ixgr) };
~numtrx.do{ |ix|
	~recsynths[ix] = Synth(\bufrec, [\idxbus, ~zerobus, \buf, ~trx[ix]], ~ingr);
	~playsynths[ix] = Synth(\bufpl, [\idxbus, ~ixbuses[0], \buf, ~trx[ix]], ~ogr)
};
)


new color for scrub
button for returning track to master cursor
envelope for record & playback loop points
fix ~zerobus for switching off/pausing
cursor speed/direction


