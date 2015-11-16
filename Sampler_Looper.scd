(
s.waitForBoot{
	fork{
		var numsamps = 8;
		var maxsamplength = 16.0;
		var masteridxbuf = Buffer.alloc(s, s.sampleRate*maxsamplength, 1);
		var masteridxAbus = Bus.audio(s);
		var masteridxKbus = Bus.control(s);
		var masteridxnode = 9999;
		var idxbufs = {Buffer.alloc(s, s.sampleRate*maxsamplength, 1)}!numsamps; //buffers to hold sample index
		var sampbufs = {Buffer.alloc(s, s.sampleRate * maxsamplength, 1)}!numsamps; //buffers to hold sample audio
		var idxAbusses = {Bus.audio(s)}!numsamps; //audio rate busses to hold index location
		var idxKbusses = {Bus.control(s)}!numsamps; //control rate busses to hold index location, for waveform display
		var iIdxnode = 3000;  // initial node for index synths
		var irecnode = 4000;  // initial node for index synths
		var iplaynode = 5000;  // initial node for index synths
		var recstartidxval = 0!numsamps;
		var recendidxval = 1.0!numsamps;
		var idxgr = Group.new(); //index group before all groups
		var recgr = Group.after(idxgr); //in group for incomming (rec) audio
		var playgr = Group.after(recgr); //out group for outgoing (play) audio
		var proc = NetAddr("127.0.0.1", 12321); //net sender to processing
		////SYNTHDEFS///////////////////////////////////////////////////////////////////////////////////
		SynthDef(\bufidx,{
			arg buf, spd=1, bus, start=0.0, end=1.0, kbus;
			var indexer, indexnorm;
			//create an audio rate indexer using the Phasor object
			indexer = Phasor.ar(trig:0, rate:BufRateScale.kr(buf)*spd, start:start*BufFrames.kr(buf), end:end*BufFrames.kr(buf));
			//normalize the index
			indexnorm = indexer.linlin(0.0, BufFrames.kr(buf), 0.0, 1.0);
			//send the index out to both a control and audio rate bus
			Out.ar(bus, indexer);
			Out.kr(kbus, indexnorm);
		}).add;
		SynthDef(\bufrec, {
			arg ich=0, idxbus, buf, gate=1;
			var in, idx, env;
			env = EnvGen.ar(Env.asr(releaseTime:0.01, curve:0),gate, doneAction:2);
			idx = In.ar(idxbus);
			in = SoundIn.ar(ich);
			BufWr.ar(in*env, buf, idx);
		}).add;
		SynthDef(\bufpl, {
			arg idxbus, obs=0, buf, gate=1;
			var idx, sig, env;
			env = EnvGen.ar(Env.asr(releaseTime:0.01, curve:0),gate, doneAction:2);
			idx = In.ar(idxbus);
			sig = BufRd.ar(1, buf, idx);
			Out.ar(obs, sig*env);
		}).add;
		//// OSCdefs //////////////////////////////////////////////////////////////////////////////////////
		OSCdef(\rec, { |msg|
			var sampnum = msg[1].asInteger; //which bank
			var state = msg[2].asInteger; //1 or 0 record on or off
			var ch = msg[3].asInteger; //which channel to record from
			var recnode = irecnode+sampnum; //node for record synth
			var idxnode = iIdxnode+sampnum; //node of idx synth
			msg.postln;
			if(sampnum<numsamps,{ //is the sampnum less than the allocated num samples
				if(state==1, { //if state1, record
					//Make a new record synth - synthdefname, node number, , addaction (0=head of group)group, args
					s.sendMsg(\s_new, \bufrec, recnode, 0, recgr.nodeID, \ich, ch, \idxbus, masteridxAbus.index, \buf, sampbufs[sampnum].bufnum);
					//Query index bus for current value and store in recstartidxval
					recstartidxval[sampnum] = masteridxKbus.getSynchronous.asFloat;
					}, { // end if state = 1, begin else (state=0), stop recording
						recendidxval[sampnum] = masteridxKbus.getSynchronous.asFloat+(0.01/maxsamplength);
						s.sendMsg(\n_set, recnode, \gate, 0); //set gate of recording synth to 0, doneAction:2 will auto kill synth
						s.sendMsg(\n_set, iIdxnode+sampnum, \start, recstartidxval[sampnum], \end, masteridxKbus.getSynchronous.asFloat+(0.01/maxsamplength) /*to accomodate release of record envelope*/); //send start & end times of of index for new recording
				}); // end else if state != 1 (state=0 or off)
			})//end if sampnum<numsamps
		}, "/rec");

		OSCdef(\play, { |msg|
			var sampnum = msg[1].asInteger; //which bank
			var state = msg[2].asInteger; //1 or 0 play on or off
			var ch = msg[3].asInteger; //which channel to play out
			var playnode = iplaynode+sampnum; //node for bufplay synth
			var idxnode = iIdxnode+sampnum; //node of idx synth
			if(sampnum<numsamps,{ //is the sampnum less than the allocated num samples
				if(state==1, { //if state1, play
					//Make a new play synth - synthdefname, node number, , addaction (0=head of group)group, args
					s.sendMsg(\s_new, \bufpl, playnode, 0, playgr.nodeID, \obs, ch, \idxbus, idxAbusses[sampnum].index, \buf, sampbufs[sampnum].bufnum);
					}, { // end if state = 1, begin else (state=0), stop playing
						s.sendMsg(\n_set, playnode, \gate, 0); //set gate of bufplay synth to 0, doneAction:2 will auto kill synth
				}); // end else if state != 1 (state=0 or off)
			})//end if sampnum<numsamps
		}, "/play");

		OSCdef( \getidx,{|msg|
			var sampnum = msg[1].asInteger;
			var idxval = idxKbusses[sampnum].getSynchronous.asFloat;
			var start = recstartidxval[sampnum];
			var end = recendidxval[sampnum];
			if(end<start, {end=end+1.0; if(idxval<start, {idxval = idxval+1.0})}); //if end is < start then count from start to 1+end
			idxval = idxval.linlin(start, end, 0.0, 1.0);
			proc.sendMsg("/ix", sampnum, idxval)
		}, "/getidx");

		0.1.wait;

		//// Create A Master Index
		s.sendMsg(\s_new, \bufidx, masteridxnode, 0, idxgr.nodeID, \buf, masteridxbuf.bufnum, \bus, masteridxAbus.index, \kbus, masteridxKbus.index);
		//// Create & Start Index Synths for each sample
		numsamps.do{|ix| s.sendMsg(\s_new, \bufidx, iIdxnode+ix, 0, idxgr.nodeID, \buf, idxbufs[ix].bufnum, \bus, idxAbusses[ix].index, \kbus, idxKbusses[ix].index)};

	} //end fork
}// end s.waitForBoot
)
s.queryAllNodes
n = NetAddr("127.0.0.1", 57120);
n.sendMsg("/rec", 0, 1, 0);
n.sendMsg("/rec", 0, 0, 0);
n.sendMsg("/play", 0, 1, 0);
n.sendMsg("/play", 0, 0, 0);

/*
Make contact mic trigger for samples
Make effect processing presets for samps w/granulator



*/

1.0.linlin(0.8, 0.2, 0.0, 1.0);