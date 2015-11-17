(
s.waitForBoot{
	fork{
		var numsamps = 8;
		var maxsamplength = 16.0;
		var idxbufs = {Buffer.alloc(s, s.sampleRate*maxsamplength, 1)}!numsamps; //buffers to hold sample index
		var sampbufs = {Buffer.alloc(s, s.sampleRate * maxsamplength, 1)}!numsamps; //buffers to hold sample audio
		var idxAbusses = {Bus.audio(s)}!numsamps; //audio rate busses to hold index location
		var idxKbusses = {Bus.control(s)}!numsamps; //control rate busses to hold index location, for waveform display
		var iIdxnode = 3000;  // initial node for index synths
		var irecnode = 4000;  // initial node for index synths
		var iplaynode = 5000;  // initial node for index synths
		var recendidxval = 1.0!numsamps;
		var idxgr = Group.new(); //index group before all groups
		var recgr = Group.after(idxgr); //in group for incomming (rec) audio
		var playgr = Group.after(recgr); //out group for outgoing (play) audio
		var proc = NetAddr("127.0.0.1", 12321); //net sender to processing
		var waveformFunc;
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
			env = EnvGen.ar(Env.asr(releaseTime:0.08, curve:0),gate, doneAction:2);
			idx = In.ar(idxbus);
			in = SoundIn.ar(ich);
			BufWr.ar(in*env, buf, idx);
		}).add;
		SynthDef(\bufpl, {
			arg idxbus, obs=0, buf, gate=1;
			var idx, sig, env;
			env = EnvGen.ar(Env.asr(releaseTime:0.08, curve:0),gate, doneAction:2);
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
			var playnode = iplaynode+sampnum; //node for bufplay synth
			if(sampnum<numsamps,{ //is the sampnum less than the allocated num samples
				if(state==1, { //if state1, record
					//Stop any playback
					s.sendMsg(\n_set, playnode, \gate, 0);
					//Make a new index synth, kill old index synth
					s.sendMsg(\n_free, idxnode);
					s.sendMsg(\s_new, \bufidx, idxnode, 0, idxgr.nodeID, \buf, idxbufs[sampnum].bufnum, \bus, idxAbusses[sampnum].index, \kbus, idxKbusses[sampnum].index, \start, 0.0);
					//Make a new record synth - synthdefname, node number, , addaction (0=head of group)group, args
					s.sendMsg(\s_new, \bufrec, recnode, 0, recgr.nodeID, \ich, ch, \idxbus, idxAbusses[sampnum].index, \buf, sampbufs[sampnum].bufnum);
					}, { // end if state = 1, begin else (state=0), stop recording
						s.sendMsg(\n_set, recnode, \gate, 0); //set gate of recording synth to 0, doneAction:2 will auto kill synth
						s.sendMsg(\n_set, idxnode, \end, idxKbusses[sampnum].getSynchronous.asFloat); //set index end time to the time you end the recording
						recendidxval[sampnum] = idxKbusses[sampnum].getSynchronous.asFloat+ (0.08/maxsamplength); //store end time
						waveformFunc.value(sampnum);
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
			var end = recendidxval[sampnum];
			idxval = idxval.linlin(0.0, end, 0.0, 1.0);
			proc.sendMsg("/ix", sampnum, idxval)
		}, "/getidx");


		//Function to collect & send waveform display data
		waveformFunc = { |sampnum|
			var buf = sampbufs[sampnum];
			var count = recendidxval[sampnum]*(maxsamplength*44100.0);
			buf.loadToFloatArray(0, count, action:{
				arg array;
				var bufarray, sampsize, resamp, resampArray, ct;
				bufarray = array;
				//RESAMPLE TO MANAGEABLE SIZE
				sampsize = 200; //Make sure to change this if you change pixel width of sampler
				resamp = (bufarray.size/sampsize).round;
				resampArray = Array.newClear(sampsize+2); //This is the new resampled array
				ct = 0; //A counter for the resampled array
				//RESAMPLE THE BUFFER ARRAY AND PUT THE VALUES INTO A NEW ARRAY AS FLOATS
				bufarray.do{ |it, ix| if( ix%resamp == 0, {resampArray[ct]=it.asFloat; ct = ct+1} ) };
				//ADD TRACK NUMBER AND OSC ADDRESS
				resampArray = resampArray.insert(0, sampnum.asInteger);
				resampArray = resampArray.insert(0, "/sbuf");
				//SEND TO PROCESSING
				proc.sendBundle(0.0, resampArray);
			} );
		};
	} //end fork
}// end s.waitForBoot
)
s.queryAllNodes
s.meter
n = NetAddr("127.0.0.1", 57120);
n.sendMsg("/rec", 0, 1, 0);
n.sendMsg("/rec", 0, 0, 0);
n.sendMsg("/play", 0, 1, 0);
n.sendMsg("/play", 0, 0, 0);
n.sendMsg("/rec", 6, 1, 0);
n.sendMsg("/rec", 6, 0, 0);
n.sendMsg("/play", 6, 1, 0);
n.sendMsg("/play", 6, 0, 0);

/*
Make contact mic trigger for samples
Make effect processing presets for samps w/granulator


*/
