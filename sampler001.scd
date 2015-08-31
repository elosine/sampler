(
~b = Buffer.alloc(s, s.sampleRate * 16.0, 1);
~trx = {Buffer.alloc(s, s.sampleRate * 16.0, 1)}!16;
~ixbus = Bus.audio(s);
~ixgr = Group.new();
~ingr = Group.after(~ixgr);
~ogr = Group.after(~ingr);

SynthDef(\bufidx,{
	arg buf, spd=1, bus, numbts=16.0, start=0.0, end=1.0;
	var indexer, indexnorm;
	indexer = Phasor.ar(trig:0, rate:BufRateScale.kr(buf)*spd, start:start*BufFrames.kr(buf), end:end*BufFrames.kr(buf));
	indexnorm = indexer.linlin(0.0, BufFrames.kr(buf), 0.0, numbts);
	Out.ar(bus, indexer);
}).add;

SynthDef(\bufrec, {
	arg ich=0, idxbus, buf;
	var in, idx;
	idx = In.ar(idxbus).poll;
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
)

~ix = Synth(\bufidx, [\buf, ~b, \bus, ~ixbus], ~ixgr);

~t1rec = Synth(\bufrec, [\idxbus, ~ixbus, \buf, ~b], ~ingr);
~t1rec.free;
~t1pl = Synth(\bufpl, [\idxbus, ~ixbus, \buf, ~b], ~ogr);

s.meter


