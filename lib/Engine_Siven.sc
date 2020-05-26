//
// Engine_Sivn
//

Engine_Siven : CroneEngine {
	classvar <maxNumVoices;

  var <voiceDef;
  var <paramDefaults;

	var <ctlBus; // collection of control busses
	var <mixBus; // audio bus for mixing synth voices
	var <gr; // parent group for voice nodes
	var <voices; // collection of voice nodes

  *initClass {
    maxNumVoices = 16;
  }

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
    voiceDef = SynthDef(\siven, {
			arg out = 0, gate = 1, hz = 440, amp = 1.0, level = 0.2,
      // amp envelope
      ampAtk = 0.05, ampDec = 0.1, ampSus = 1.0, ampRel = 1.0, ampCurve = -1.0;

			var snd, ampEnv;

      snd = SinOsc.ar(hz);

      ampEnv = EnvGen.ar(Env.adsr(ampAtk, ampDec, ampSus, ampRel, 1.0, ampCurve),
        gate, levelScale: amp, doneAction: 2);

      snd = snd * ampEnv * level;
      Out.ar(out, [snd, snd]);
		});
    voiceDef.add;

    paramDefaults = Dictionary.with(
      \level -> -12.dbamp,
      \ampAtk -> 0.05, \ampDec -> 0.1, \ampSus -> 1.0, \ampRel -> 1.0, \ampCurve ->  -1.0,
		);

		context.server.sync;

    gr = ParGroup.new(context.xg);

    // setup control global controls
    ctlBus = Dictionary.new;
    voiceDef.allControlNames.do({ arg ctl;
      var name = ctl.name;
      if ((name != \gate) && (name != \hz) && (name != \amp) && (name != \out), {
        ctlBus.add(name -> Bus.control(context.server));
        ctlBus[name].set(paramDefaults[name]);
      });
    });

    ctlBus.postln;

    voices = Dictionary.new;

    //
    // commands
    //

    // start a new voice
		this.addCommand(\start, "iff", { arg msg;
      this.addVoice(msg[1], msg[2], msg[3], true);
		});


		// same as start, but don't map control busses, just copy their current values
		this.addCommand(\solo, "iff", { arg msg;
      this.addVoice(msg[1], msg[2], msg[3], false);
		});


		// stop a voice
		this.addCommand(\stop, "i", { arg msg;
			this.removeVoice(msg[1]);
		});

		// free all synths
		this.addCommand(\stopAll, "", {
			gr.set(\gate, 0);
			voices.clear;
		});

		// generate commands to set each control bus
		ctlBus.keys.do({ arg name;
			this.addCommand(name, "f", { arg msg; ctlBus[name].setSynchronous(msg[1]); });
		});
  }

	addVoice { arg id, hz, amp = 1.0, map = true;
		var params = List.with(\out, context.out_b.index, \hz, hz, \amp, amp);
		var numVoices = voices.size;

		if(voices[id].notNil, {
			voices[id].set(\gate, 1);
			voices[id].set(\hz, hz);
		}, {
			if(numVoices < maxNumVoices, {
				ctlBus.keys.do({ arg name;
					params.add(name);
					params.add(ctlBus[name].getSynchronous);
				});

				voices.add(id -> Synth.new(\siven, params, gr));
				NodeWatcher.register(voices[id]);
				voices[id].onFree({
					voices.removeAt(id);
				});

				if(map, {
					ctlBus.keys.do({ arg name;
						voices[id].map(name, ctlBus[name]);
					});
				});
			});
		});
	}

  removeVoice { arg id;
		if(true, {
			voices[id].set(\gate, 0);
		});
	}


  free {
		gr.free;
		ctlBus.do({ arg bus, i; bus.free; });
	}

}
