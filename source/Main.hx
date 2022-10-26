package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import haxe.Timer;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;

import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import lime.system.System;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 120; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var fps:FPSCounter;
	public static var base:Main;

	public static var path:String = System.applicationStorageDirectory;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		base = new Main();
		Lib.current.addChild(base);
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		SUtil.check();

		#if mobile
		gameWidth = 1280;
		gameHeight = 720;
		zoom = 1;
		#end

		#if !debug
		initialState = TitleState;
		#end

		FlxG.save.bind('funkin', 'ninjamuffin99');

		if (FlxG.save.data.FPS != null)
		{
			framerate = FlxG.save.data.FPS;
		}

		addChild(new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen));


		fps = new FPSCounter(10, 3, 0xFFFFFF);
		fps.visible = !FlxG.save.data.showFPS;
		addChild(fps);


		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
	}

	public static function clearCache()
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null)
			{
				Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}
		Assets.cache.clear("songs");
	}

}

class Saving extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	private var up:Bool = true;

	public function new(color:Int = 0xffff00)
	{
		super();

		this.x = 0;
		this.y = 10;

		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("VCR OSD Mono", 30, color);
		text = "Syncing...";
		this.alpha = 0;
		this.x = Lib.application.window.width - 200;
		width = 200;

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end
	}

	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		if (up)
		{
			alpha += 0.02;
			if (alpha >= 1)
				up = false;
		}
		else
		{
			alpha -= 0.02;
			if (alpha <= 0)
				up = true;
		}
		x = Lib.application.window.width - 200;
	}
	#if android
	function onCrash(e:UncaughtErrorEvent):Void
		{
			var errMsg:String = "";
			var path:String;
			var callStack:Array<StackItem> = CallStack.exceptionStack(true);
			var dateNow:String = Date.now().toString();
	
			
	
			path = SUtil.getPath() + "crash/" + "PsychEngine_" + dateNow + ".txt";
	
			for (stackItem in callStack)
			{
				switch (stackItem)
				{
					case FilePos(s, file, line, column):
						errMsg += file + " (line " + line + ")\n";
					default:
						Sys.println(stackItem);
				}
			}
	
			errMsg += "\nUncaught Error: " + e.error + "\nPlease report this error to the GitHub page: https://github.com/KaiqueAlt/Megamix-v3/\n\n> Crash Handler written by: sqirra-rng";
	
			if (!FileSystem.exists(SUtil.getPath() + "crash/"))
				FileSystem.createDirectory(SUtil.getPath() + "crash/");
	
			File.saveContent(path, errMsg + "\n");
	
			Sys.println(errMsg);
			Sys.println("Crash dump saved in " + Path.normalize(path));
	
			Application.current.window.alert(errMsg, "Error!");

			Sys.exit(1);
		}
		#end	
}
