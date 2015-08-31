(
~numtrx = 8;
~recsynths = Array.newClear(~numtrx);
~playsynths = Array.newClear(~numtrx);
~ixbuf = Buffer.alloc(s, s.sampleRate*16.0, 1);
~trx = {Buffer.alloc(s, s.sampleRate * 16.0, 1)}!16;
~ixbus = Bus.audio(s);
~ixkbus = Bus.control(s);
~ebus = Bus.control(s);
~ixgr = Group.new();
~ingr = Group.after(~ixgr);
~ogr = Group.after(~ingr);


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

~proc = NetAddr("127.0.0.1", 12321);

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
)

~ix = Synth(\bufidx, [\buf, ~ixbuf, \bus, ~ixbus, \kbus, ~ixkbus], ~ixgr);

~numtrx.do{ |ix| ~recsynths[ix] = Synth(\bufrec, [\idxbus, ~ebus, \buf, ~trx[ix]], ~ingr) };
~numtrx.do{ |ix| ~playsynths[ix] = Synth(\bufpl, [\idxbus, ~ixbus, \buf, ~trx[ix]], ~ogr) };


~t1rec = Synth(\bufrec, [\idxbus, ~ixbus, \buf, ~trx[0]], ~ingr);
~t1rec.free;
~t1pl = Synth(\bufpl, [\idxbus, ~ixbus, \buf, ~trx[0]], ~ogr);


~t2rec = Synth(\bufrec, [\idxbus, ~ixbus, \buf, ~trx[1]], ~ingr);
~t2rec.free;
~t2pl = Synth(\bufpl, [\idxbus, ~ixbus, \buf, ~trx[1]], ~ogr);

s.meter

~ixkbus.get