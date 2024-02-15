package states;

import states.editors.MenuEditorState;
import backend.Song;
import flixel.ui.FlxButton;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import tjson.TJSON as Json;
import openfl.net.FileReference;
import flash.net.FileFilter;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flixel.addons.ui.*;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = Info.version; // This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var optionShit:Array<String> = [
		"story_mode",
		"freeplay",
		"options"
	];

	var menuItems:FlxTypedGroup<FlxSprite>;

	var magenta:FlxSprite;

	// menu stuff
	var bg:FlxSprite;
	var grid:FlxBackdrop;

	private static var _file:FileReference;

	var credits:FlxSprite;
	var mods:FlxSprite;
	var mainSide:FlxSprite;

	var menuItem:FlxSprite;
	var blackBg:FlxSprite;

	var random_text:FlxText;
	var random_background:FlxSprite;

	public static var menuJSON:MenuData;

	override function create()
	{
		menuJSON = Json.parse(Paths.getTextFromFile('moddingTools/mainmenu.json'));
		FlxG.mouse.visible = true;

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite(-80).loadGraphic(Paths.image(menuJSON.bgSpr));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = CoolUtil.colorFromString(menuJSON.bgColor);
		add(bg);

		if (!menuJSON.bgFlick)
		{
			magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
			magenta.antialiasing = ClientPrefs.data.antialiasing;
			magenta.scrollFactor.set();
			magenta.setGraphicSize(Std.int(magenta.width * 1.175));
			magenta.updateHitbox();
			magenta.screenCenter();
			magenta.visible = false;
			magenta.color = CoolUtil.colorFromString(menuJSON.bgFlickColor);
			add(magenta);
		}

		grid = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33000000, 0x0));
		grid.velocity.set(30, 30);
		grid.scale.set(1.3, 1.3);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		grid.visible = menuJSON.checkersOn;
		if (ClientPrefs.data.lowQuality) menuJSON.checkersOn = false;
		add(grid);

		mainSide = new FlxSprite(0, 0).loadGraphic(Paths.image('mic-d-up/Main_Side'));
		add(mainSide);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			menuItem = new FlxSprite(0, (i * 207) + offset);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.updateHitbox();
			menuItem.screenCenter(X);
			menuItem.x += -200;
		}

		credits = new FlxSprite(935, 553).loadGraphic(Paths.image(menuJSON.creditsArrowPath));
		credits.visible = menuJSON.arrowsOn;
		add(credits);

		mods = new FlxSprite(935, -121).loadGraphic(Paths.image(menuJSON.modsArrowPath));
		mods.visible = menuJSON.arrowsOn;
		add(mods);

		blackBg = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackBg.alpha = 0;
		blackBg.screenCenter();
		add(blackBg);

		var projectVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Project Engine v" + Info.version, 12);
		projectVer.scrollFactor.set();
		projectVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(projectVer);

		var updateTxt:FlxText = new FlxText(12, FlxG.height - 44, 0, Info.update, 12);
		updateTxt.scrollFactor.set();
		updateTxt.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(updateTxt);

		random_background = new FlxSprite(-8, -4).makeGraphic(1504, 48, FlxColor.BLACK);
		random_background.visible = ClientPrefs.data.randomMessage;
		random_background.alpha = 0.5;
		add(random_background);
	
		random_text = new FlxText(0, 0, 1244, '');
		random_text.setFormat('VCR OSD Mono', 29, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		random_text.screenCenter();
		random_text.y -= 339;
		random_text.visible = ClientPrefs.data.randomMessage;
		add(random_text);

		switch (FlxG.random.int(0, 4)) {

			case 0:
				random_text.text = menuJSON.randomMessages[0];
			case 1:
				random_text.text = menuJSON.randomMessages[1];
			case 2:
				random_text.text = menuJSON.randomMessages[2];
			case 3:
				random_text.text = menuJSON.randomMessages[3];	
			case 4:
				random_text.text = menuJSON.randomMessages[4];	
		}

		changeItem();

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (menuJSON.arrowsOn) {
			if (FlxG.mouse.overlaps(credits)) {
				credits.alpha = 1;
				if (menuJSON.creditsType == 'Disabled') {
					credits.visible = false;
				}
				FlxTween.tween(credits, {x: 935, y: 522}, 0.1, {ease: FlxEase.quadInOut});
				if (FlxG.mouse.justPressed) {
						switch (menuJSON.creditsType) {
						
							case 'Credits':
								MusicBeatState.switchState(new CreditsState());
							case 'Bios':
								MusicBeatState.switchState(new BiosMenuState());
							default:
								MusicBeatState.switchState(new BiosMenuState());
						}
					}
			}
			else
			{
				credits.alpha = 1;
				credits.loadGraphic(Paths.image(menuJSON.creditsArrowPath));
				FlxTween.tween(credits, {x: 935, y: 553}, 0.1, {ease: FlxEase.quadInOut});
				if (menuJSON.creditsType == 'Disabled') { 
					credits.visible = false;
				}
			}
	
			if (FlxG.mouse.overlaps(mods))
				{
					FlxTween.tween(mods, {x: 935, y: -91}, 0.1, {ease: FlxEase.quadInOut});
		
					if (FlxG.mouse.justPressed)
					{
						MusicBeatState.switchState(new ModsMenuState());
						FlxG.sound.play(Paths.sound('confirmMenu'));
					}
				}
				else
				{
					mods.loadGraphic(Paths.image('mic-d-up/mods')); 
					FlxTween.tween(mods, {x: 935, y: -121}, 0.1, {ease: FlxEase.quadInOut});
				}
		}

		

		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

		if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				if (optionShit[curSelected] == "donate")
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;

					if (ClientPrefs.data.flashing)
						FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(flick:FlxFlicker)
					{
						switch (optionShit[curSelected])
						{
							case "story_mode":
								if (MenuEditorState.oneshotMod) 
								{
									var songLowercase:String = Paths.formatToSongPath(menuJSON.oneshotSong);
									var poop:String = backend.Highscore.formatSongButBetter(songLowercase);
	
									PlayState.SONG = Song.loadFromJson(poop, songLowercase);
									PlayState.isStoryMode = false;
									PlayState.storyDifficulty = 1;
	
									LoadingState.loadAndSwitchState(new PlayState());
								}
								else
								{
									MusicBeatState.switchState(new StoryMenuState());
								}
							case "freeplay":
								MusicBeatState.switchState(new FreeplayState());

							case 'options':
								MusicBeatState.switchState(new OptionsState());
								OptionsState.onPlayState = false;
								if (PlayState.SONG != null)
								{
									PlayState.SONG.arrowSkin = null;
									PlayState.SONG.splashSkin = null;
									PlayState.stageUI = 'normal';
								}
						}
					});

					for (i in 0...menuItems.members.length)
					{
						if (i == curSelected)
							continue;
						FlxTween.tween(FlxG.camera, {zoom: 10, angle: 0, alpha: 0}, 0.5, {ease: FlxEase.expoIn});
						FlxTween.tween(bg, {angle: 45}, 0.8, {ease: FlxEase.expoIn});
						FlxTween.tween(menuItems.members[i], {x: -600}, 0.6, { ease: FlxEase.backIn,
							onComplete: function(twn:FlxTween)
							{
								menuItems.members[i].kill();
							}
						});
					}
				}
			}
			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		menuItems.members[curSelected].animation.play('idle');
		menuItems.members[curSelected].screenCenter(X);
		menuItems.members[curSelected].x += -200;

		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.members[curSelected].animation.play('selected');
		menuItems.members[curSelected].screenCenter(X);
		menuItems.members[curSelected].x += -200;
	}
}