package states;

import flixel.input.FlxInput.FlxInputState;
import flixel.FlxSprite;
import flixel.FlxBasic;
import openfl.Lib;
import lime.app.Application;
import game.Conductor;
import utilities.PlayerSettings;
import game.Conductor.BPMChangeEvent;
import utilities.Controls;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;

class MusicBeatState extends FlxUIState
{
	public var lastBeat:Float = 0;
	public var lastStep:Float = 0;

	public var curStep:Int = 0;
	public var curBeat:Int = 0;
	private var controls(get, never):Controls;

	public static var windowNameSuffix:String = "";
	public static var windowNamePrefix:String = "Leather Engine";

	public static var fullscreenBind:String = "F11";

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override public function new()
	{
		#if polymod
		polymod.Polymod.clearCache();
		#end

		super();
	}

        #if android
	var _virtualpad:FlxVirtualPad;
	var _hitbox:FlxHitbox;
	var trackedinputsUI:Array<FlxActionInput> = [];
	var trackedinputsNOTES:Array<FlxActionInput> = [];
	#end
	#if android
	public function addVirtualPad(DPad:FlxDPadMode, Action:FlxActionMode) {
		_virtualpad = new FlxVirtualPad(DPad, Action);
		add(_virtualpad);
		controls.setVirtualPadUI(_virtualpad, DPad, Action);
		trackedinputsUI = controls.trackedinputsUI;
		controls.trackedinputsUI = [];
	}
	#end
		
	#if android
	public function removeVirtualPad() {
		controls.removeFlxInput(trackedinputsUI);
		remove(_virtualpad);
	}
	#end

	#if android
        public function addPadCamera() {
		var camcontrol = new flixel.FlxCamera();
		FlxG.cameras.add(camcontrol);
		camcontrol.bgColor.alpha = 0;
		_virtualpad.cameras = [camcontrol];
	}
	#end
	
	override function destroy() {
		#if android
		controls.removeFlxInput(trackedinputsUI);
		controls.removeFlxInput(trackedinputsNOTES);	
		#end
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		super.update(elapsed);

		if(FlxG.stage != null)
			FlxG.stage.frameRate = utilities.Options.getData("maxFPS");

		if(!utilities.Options.getData("antialiasing"))
		{
			forEachAlive(function(basic:FlxBasic) {
				if(Std.isOfType(basic, FlxSprite))
					Reflect.setProperty(basic, "antialiasing", false);
			}, true);
		}

		if(FlxG.keys.checkStatus(FlxKey.fromString(utilities.Options.getData("fullscreenBind", "binds")), FlxInputState.JUST_PRESSED))
			FlxG.fullscreen = !FlxG.fullscreen;

		Application.current.window.title = windowNamePrefix + windowNameSuffix;
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / Conductor.timeScale[1]);
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		
		for(i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		var dumb:TimeScaleChangeEvent = {
			stepTime: 0,
			songTime: 0,
			timeScale: [4,4]
		};

		var lastTimeChange:TimeScaleChangeEvent = dumb;

		for(i in 0...Conductor.timeScaleChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.timeScaleChangeMap[i].songTime)
				lastTimeChange = Conductor.timeScaleChangeMap[i];
		}

		if(lastTimeChange != dumb)
			Conductor.timeScale = lastTimeChange.timeScale;

		var multi:Float = 1;

		if(FlxG.state == PlayState.instance)
			multi = PlayState.songMultiplier;

		Conductor.recalculateStuff(multi);

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);

		updateBeat();
	}

	public function stepHit():Void
	{
		if (curStep % Conductor.timeScale[0] == 0)
			beatHit();
	}

	public function beatHit():Void { /* do literally nothing dumbass */ }
}
