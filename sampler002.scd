(
~numtrx = 8;
~recsynths = Array.newClear(~numtrx);
~playsynths = Array.newClear(~numtrx);
~ixbuf = Buffer.alloc(s, s.sampleRate*16.0, 1);
~trx = {Buffer.alloc(s, s.sampleRate * 16.0, 1)}!~numtrx;
~ixbus = Bus.audio(s);
~ixkbus = Bus.control(s);
~ebus = Bus.control(s);
~ixgr = Group.new();
~ingr = Group.after(~ixgr);
~ogr = Group.after(~ingr);
~proc = NetAddr("127.0.0.1", 12321);


//Function to collect & send waveform display data
~waveform = { |buf trkn|
	var bufarray, sampsize, resamp, resampArray, ct;
	buf.loadToFloatArray( action:{
		arg array;
		var bufarray, sampsize, resamp, resampArray, ct;
		bufarray = array;
		//RESAMPLE TO MANAGEABLE SIZE
		sampsize = 1000;
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

SynthDef(\bufidx,{
	arg buf, spd=1, bus, numbts=1.0, start=0.0, end=1.0, kbus;
	var indexer, indexnorm;
	indexer = Phasor.ar(trig:0, rate:BufRateScale.kr(buf)*spd, start:start*BufFrames.kr(buf), end:end*BufFrames.kr(buf));
	indexnorm = indexer.linlin(0.0, BufFrames.kr(buf), 0.0, numbts);
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


//On Demand normalized index
OSCdef( \getidx,{
	arg msg, time, addr, recvPort;
	~ixkbus.get({arg val; ~proc.sendMsg("/ix", val)});
}, "/getidx");

OSCdef(\recixval, {|msg| msg[1]}, "/ix");

//record and play
OSCdef(\recon, {
	arg msg;
	var tr;
	tr = msg[1].asInteger;
	~recsynths[tr].set(\idxbus, ~ixbus);
	"on".post; tr.postln;
}, "/recon");

OSCdef(\recoff, {
	arg msg;
	var tr;
	tr = msg[1].asInteger;
	~recsynths[tr].set(\idxbus, ~obus);
}, "/recoff");

OSCdef(\play, {
	arg msg;
	var tr;
	tr = msg[1].asInteger;
	~playsynths[tr].set(\idxbus, ~ixbus);
}, "/play");

OSCdef(\pause, {
	arg msg;
	var tr;
	tr = msg[1].asInteger;
	~playsynths[tr].set(\idxbus, ~obus);
}, "/pause");

OSCdef(\wavfrm, {
	arg msg;
	var tr = msg[1].asInteger;
	~waveform.value(~trx[tr], tr);
}, "/wavfrm");

OSCdef(\stop, {
	~ix.free;
	~numtrx.do{|ix| ~recsynths[ix].free; ~playsynths[ix].free};
	~trx.do{|it| it.free};
	~trx = nil;
}, "/stop");

OSCdef(\restart, {
	~trx = {Buffer.alloc(s, s.sampleRate * 16.0, 1)}!16;
	~ix = Synth(\bufidx, [\buf, ~ixbuf, \bus, ~ixbus, \kbus, ~ixkbus], ~ixgr);
	~numtrx.do{ |ix|
		~recsynths[ix] = Synth(\bufrec, [\idxbus, ~ebus, \buf, ~trx[ix]], ~ingr);
		//~playsynths[ix] = Synth(\bufpl, [\idxbus, ~ixbus, \buf, ~trx[ix], \obs, 0], ~ogr)
		~playsynths[ix] = Synth(\bufpl, [\idxbus, ~ixbus, \buf, ~trx[ix], \obs, 1], ~ogr)
	};
}, "/restart");
)

(
~ix = Synth(\bufidx, [\buf, ~ixbuf, \bus, ~ixbus, \kbus, ~ixkbus], ~ixgr);
~numtrx.do{ |ix|
	~recsynths[ix] = Synth(\bufrec, [\idxbus, ~ebus, \buf, ~trx[ix]], ~ingr);
	~playsynths[ix] = Synth(\bufpl, [\idxbus, ~ixbus, \buf, ~trx[ix]], ~ogr)
};
)




