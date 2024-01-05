package states;

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

typedef MenuData =
{
	backgroundColor:String,
	backgroundSpr:String,
	checkersEnabled:Bool,
	oneshotSongName:String,
	creditsType:String,
	randomMessage:Array<String>
}
class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = Info.version; // This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'options'
	];

	var magenta:FlxSprite;

	var menuJSON:MenuData;

	// menu stuff
	var bg:FlxSprite;
	var grid:FlxBackdrop;

	// editor stuff
	var tab_menu:FlxUITabMenu;
	var tab_group_menu:FlxUI;
	var tab_tabs = [{name: 'Main', label: 'Main Settings'}];
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];

	var menu_bgColor:FlxUIInputText;
	var menu_bgSpr:FlxUIInputText;
	var menu_creditType:FlxUIInputText;
	var oneshot_songName:FlxUIInputText;

	var check_oneshot:FlxUICheckBox;
	var check_checkers:FlxUICheckBox;

	var saveButton:FlxButton;
	var closeButton:FlxButton;

	var oneshot_songTitle:FlxText;

	// some variables stuff
	var creditsType:String = 'Bios';
	var oneshotMod:Bool = false;

	private static var _file:FileReference;

	var credits:FlxSprite;
	var mods:FlxSprite;
	var mainSide:FlxSprite;

	var menuItem:FlxSprite;
	var blackBg:FlxSprite;

	var random_text:FlxText;
	var random_background:FlxSprite;

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

		bg = new FlxSprite(-80).loadGraphic(Paths.image(menuJSON.backgroundSpr));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = CoolUtil.colorFromString(menuJSON.backgroundColor);
		add(bg);

		grid = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33000000, 0x0));
		grid.velocity.set(30, 30);
		grid.scale.set(1.3, 1.3);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		grid.visible = menuJSON.checkersEnabled;
		if (ClientPrefs.data.lowQuality) menuJSON.checkersEnabled = false;
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

		credits = new FlxSprite(935, 553).loadGraphic(Paths.image('mic-d-up/credits'));
		add(credits);

		mods = new FlxSprite(935, -121).loadGraphic(Paths.image('mic-d-up/mods'));
		add(mods);

		blackBg = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackBg.alpha = 0;
		blackBg.screenCenter();
		add(blackBg);

		if (ClientPrefs.data.menuEditor) {
			tab_menu = new FlxUITabMenu(null, tab_tabs, true);
			tab_menu.scrollFactor.set(0, 0);
			tab_menu.resize(300, 400);
			tab_menu.screenCenter(Y);
			tab_menu.visible = false;
			tab_menu.x += 20;
			add(tab_menu);
	
			tab_group_menu = new FlxUI(null, tab_menu);
			tab_group_menu.name = "Main";
	
			tab_menu.selected_tab_id = 'Main';
	
			saveButton = new FlxButton(0, 0, 'Save Changes', function(){
				convertFile(menuJSON);
			});
			saveButton.screenCenter(Y);
			saveButton.x += 40;
			saveButton.y += 172;
			saveButton.visible = false;
			add(saveButton);
	
			closeButton = new FlxButton(0, 0, 'Close', function() {
				saveButton.visible = false;
				closeButton.visible = false;
				tab_group_menu.visible = false;
				tab_menu.visible = false;
				FlxTween.tween(blackBg, {alpha: 0}, 0.1, {ease: FlxEase.quadInOut});
			});
			closeButton.screenCenter(Y);
			closeButton.x += 140;
			closeButton.y += 172;
			closeButton.visible = false;
			add(closeButton);
	
			menu_bgColor = new FlxUIInputText(0, 0, 200, '');
			menu_bgColor.screenCenter(Y);
			menu_bgColor.y -= 300;
			menu_bgColor.x += 20;
			menu_bgColor.scrollFactor.set(0, 0);
			blockPressWhileTypingOn.push(menu_bgColor);
	
			var menu_bgTitle:FlxText = new FlxText(menu_bgColor.x, menu_bgColor.y - 20, 0, "Background Color (hex)", 10);
			
			menu_bgSpr = new FlxUIInputText(0, 0, 200, '');
			menu_bgSpr.screenCenter(Y);
			menu_bgSpr.y -= 250;
			menu_bgSpr.x += 20;
			menu_bgSpr.scrollFactor.set(0, 0);
			blockPressWhileTypingOn.push(menu_bgSpr);
	
			var menu_sprTitle:FlxText = new FlxText(menu_bgSpr.x, menu_bgSpr.y - 20, 0, "Background Image", 10);
	
			menu_creditType = new FlxUIInputText(0, 0, 70, ''); 
			menu_creditType.screenCenter(Y);
			menu_creditType.y -= 200;
			menu_creditType.x += 20;
			menu_creditType.maxLength = 9;
			menu_creditType.scrollFactor.set(0, 0);
			blockPressWhileTypingOn.push(menu_creditType);
	
			var menu_credTitle:FlxText = new FlxText(menu_creditType.x, menu_creditType.y - 20, 0, "Credits Type", 10);
	
			check_oneshot = new FlxUICheckBox(0, 0, null, null, "Is Oneshot mod");
			check_oneshot.screenCenter(Y);
			check_oneshot.x += 120;
			check_oneshot.y -= 200; 
	
			oneshot_songName = new FlxUIInputText(0, 0, 200, '');
			oneshot_songName.screenCenter(Y);
			oneshot_songName.y -= 150;
			oneshot_songName.x += 20;
			blockPressWhileTypingOn.push(oneshot_songName);
	
			oneshot_songTitle = new FlxText(oneshot_songName.x, oneshot_songName.y - 20, 0, "Oneshot SongName", 10);
			var oneshot_desc = new FlxText(oneshot_songName.x, oneshot_songName.y + 23, 0, "Make sure to enable the Oneshot Mod option\nbefore writing something here.");
	
			check_checkers = new FlxUICheckBox(oneshot_desc.x, oneshot_songName.y + 59, null, null, 'Enable Checkers');

			tab_group_menu.add(menu_bgColor);
			tab_group_menu.add(menu_bgTitle);
			tab_group_menu.add(menu_bgSpr);
			tab_group_menu.add(menu_sprTitle);
			tab_group_menu.add(menu_creditType);
			tab_group_menu.add(menu_credTitle);
			tab_group_menu.add(check_oneshot);
			tab_group_menu.add(oneshot_songName);
			tab_group_menu.add(oneshot_songTitle);
			tab_group_menu.add(oneshot_desc);
			tab_group_menu.add(check_checkers);
	
			tab_menu.addGroup(tab_group_menu);
	
			loadEverything();
			
			var opentxt:FlxText = new FlxText(FlxG.width - 320, FlxG.height - 24, 0, 'Press TAB to open the menu editor.', 12);
			opentxt.scrollFactor.set();
			opentxt.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			add(opentxt);
		}

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
				random_text.text = menuJSON.randomMessage[0];
			case 1:
				random_text.text = menuJSON.randomMessage[1];
			case 2:
				random_text.text = menuJSON.randomMessage[2];
			case 3:
				random_text.text = menuJSON.randomMessage[3];	
			case 4:
				random_text.text = menuJSON.randomMessage[4];	
		}

		changeItem();

		super.create();
	}

	function loadEverything() 
	{
		menu_bgColor.text = menuJSON.backgroundColor;
		menu_bgSpr.text = menuJSON.backgroundSpr;
		menu_creditType.text = menuJSON.creditsType;
		oneshot_songName.text = menuJSON.oneshotSongName;
		check_oneshot.checked = oneshotMod;
		check_checkers.checked = menuJSON.checkersEnabled;
	}

	public static function convertFile(menuJSON:MenuData) {
		var data:String = haxe.Json.stringify(menuJSON, "\t");
		if (data.length > 0)
			{
				_file = new FileReference();
				_file.addEventListener(Event.COMPLETE, onSaveComplete);
				_file.addEventListener(Event.CANCEL, onSaveCancel);
				_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
				_file.save(data, "mainmenu" + ".json");
			}
	}

	private static function onSaveComplete(_):Void
		{
			_file.removeEventListener(Event.COMPLETE, onSaveComplete);
			_file.removeEventListener(Event.CANCEL, onSaveCancel);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file = null;
			FlxG.log.notice("Successfully saved file.");
		}
	
		private static function onSaveCancel(_):Void
		{
			_file.removeEventListener(Event.COMPLETE, onSaveComplete);
			_file.removeEventListener(Event.CANCEL, onSaveCancel);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file = null;
		}

		private static function onSaveError(_):Void
		{
			_file.removeEventListener(Event.COMPLETE, onSaveComplete);
			_file.removeEventListener(Event.CANCEL, onSaveCancel);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file = null;
			FlxG.log.error("Problem saving file");
		}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
	
		if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if(sender == menu_bgColor) {
				bg.color = CoolUtil.colorFromString(menu_bgColor.text.trim());
				menuJSON.backgroundColor = menu_bgColor.text.trim();
			}
			else if (sender == menu_bgSpr) {
				bg.loadGraphic(Paths.image(menu_bgSpr.text.trim()));
				menuJSON.backgroundSpr = menu_bgSpr.text.trim();
				bg.screenCenter();
			}
			else if (sender == menu_creditType) {
				creditsType = menu_creditType.text.trim();
				menuJSON.creditsType = menu_creditType.text.trim();
			}
			else if (sender == oneshot_songName) {
				menuJSON.oneshotSongName = oneshot_songName.text.trim();
			}
		}

		if (id == FlxUICheckBox.CLICK_EVENT)
		{
				var check:FlxUICheckBox = cast sender;
				var label = check.getLabel().text;
				switch (label)
				{
					case 'Is Oneshot mod':
						oneshotMod = check.checked;
					
					case 'Enable Checkers':
						grid.visible = check.checked;
				}
		}
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{

		if (ClientPrefs.data.menuEditor) {
			if (FlxG.keys.justPressed.TAB) {
				saveButton.visible = true;
				closeButton.visible = true;
				tab_group_menu.visible = true;
				tab_menu.visible = true;
				FlxTween.tween(blackBg, {alpha: 0.3}, 0.2, {ease: FlxEase.quadInOut});
			}
		}

		if (FlxG.mouse.overlaps(credits)) {
			if (ClientPrefs.data.lowQuality == false) credits.loadGraphic(Paths.image('mic-d-up/selected/credits-selected'));
			credits.alpha = 1;
			if (creditsType == 'Disabled') {
				if (ClientPrefs.data.lowQuality == false) credits.loadGraphic(Paths.image('mic-d-up/selected/disabled-creds-selected'));
				credits.alpha = 0.6;
			}
			FlxTween.tween(credits, {x: 935, y: 522}, 0.1, {ease: FlxEase.quadInOut});
			if (FlxG.mouse.justPressed) {
				switch (creditsType) {
					
					case 'Credits':
						MusicBeatState.switchState(new CreditsState());
					case 'Bios':
						MusicBeatState.switchState(new BiosMenuState());
					case 'Default':
						MusicBeatState.switchState(new BiosMenuState());
					case 'Disabled':
						FlxG.sound.play(Paths.sound('cancelMenu'));

				}
			}
		}
		else
		{
			credits.alpha = 1;
			credits.loadGraphic(Paths.image('mic-d-up/credits'));
			FlxTween.tween(credits, {x: 935, y: 553}, 0.1, {ease: FlxEase.quadInOut});
			if (creditsType == 'Disabled') { 
				credits.loadGraphic(Paths.image('mic-d-up/disabled-creds')); 
				credits.alpha = 0.6;
			}
		}

		if (FlxG.mouse.overlaps(mods))
			{
				if (ClientPrefs.data.lowQuality == false) mods.loadGraphic(Paths.image('mic-d-up/selected/mods-selected')); 
				FlxTween.tween(mods, {x: 935, y: -91}, 0.1, {ease: FlxEase.quadInOut});
	
				if (FlxG.mouse.justPressed)
				{
					FlxG.sound.play(Paths.sound('confirmMenu'));
					MusicBeatState.switchState(new ModsMenuState());
				}
			}
			else
			{
				mods.loadGraphic(Paths.image('mic-d-up/mods')); 
				FlxTween.tween(mods, {x: 935, y: -121}, 0.1, {ease: FlxEase.quadInOut});
			}

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				ClientPrefs.toggleVolumeKeys(false);
				FlxG.keys.enabled = false;
				blockInput = true;

				if(FlxG.keys.justPressed.ENTER) inputText.hasFocus = false;
				break;
			}
		}

		if (!blockInput) {
			ClientPrefs.toggleVolumeKeys(true);
			FlxG.keys.enabled = true;
			if(FlxG.keys.justPressed.ESCAPE) {
				MusicBeatState.switchState(new MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
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
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(flick:FlxFlicker)
					{
						switch (optionShit[curSelected])
						{
							case 'story_mode':
								if (check_oneshot.checked == true) 
								{
									var songLowercase:String = Paths.formatToSongPath(menuJSON.oneshotSongName);
									var poop:String = backend.Highscore.formatSongButBetter(songLowercase, 'hard');

									PlayState.SONG = Song.loadFromJson(poop, songLowercase);
									PlayState.isStoryMode = false;
									PlayState.storyDifficulty = 1;

									LoadingState.loadAndSwitchState(new PlayState());
								}
								else
								{
									MusicBeatState.switchState(new StoryMenuState());
								}
							case 'freeplay':
								MusicBeatState.switchState(new FreeplayState());

							#if MODS_ALLOWED
							case 'mods':
								MusicBeatState.switchState(new ModsMenuState());
							#end

							#if ACHIEVEMENTS_ALLOWED
							case 'awards':
								MusicBeatState.switchState(new AchievementsMenuState());
							#end

							case 'credits':
								MusicBeatState.switchState(new CreditsState());
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
						FlxTween.tween(menuItems.members[i], {x: -600}, 0.6, { ease: FlxEase.cubeIn,
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
		menuItems.members[curSelected].updateHitbox();
		menuItems.members[curSelected].screenCenter(X);
		menuItems.members[curSelected].x += -200;

		//if (ClientPrefs.data.lowQuality == false) FlxTween.tween(menuItems.members[curSelected].scale, {x: 1.1, y: 1.1}, 0.2, {ease: FlxEase.quadInOut});

		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.members[curSelected].animation.play('selected');
		menuItems.members[curSelected].centerOffsets();
		menuItems.members[curSelected].screenCenter(X);
		menuItems.members[curSelected].x += -200;

		//if (ClientPrefs.data.lowQuality == false) FlxTween.tween(menuItems.members[curSelected].scale, {x: 1.1, y: 1.1}, 0.2, {ease: FlxEase.quadInOut});
	}
}
