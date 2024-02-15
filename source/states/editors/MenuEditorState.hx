package states.editors;

import backend.Song;
import flash.net.FileFilter;
import flixel.FlxObject;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.*;
import flixel.effects.FlxFlicker;
import flixel.ui.FlxButton;
import lime.app.Application;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import options.OptionsState;
import states.editors.MasterEditorMenu;
import tjson.TJSON as Json;

class MenuEditorState extends MusicBeatState
{
	var menuItems:FlxTypedGroup<FlxSprite>;

	// menu stuff
	var bg:FlxSprite;
	var grid:FlxBackdrop;

	// editor stuff
	var tab_menu:FlxUITabMenu;
	var tab_tabs = [
		{name: 'Main', label: 'Main Settings'}
	];
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];

	var tab_group_menu:FlxUI;
	var tab_group_custom:FlxUI;

	var menu_bgColor:FlxUIInputText;
	var menu_items:FlxUICheckBox;
	var menu_bgSpr:FlxUIInputText;
	var menu_creditType:FlxUIInputText;
	var oneshot_songName:FlxUIInputText;

	var check_oneshot:FlxUICheckBox;
	var check_checkers:FlxUICheckBox;
	var check_hideCreds:FlxUICheckBox;

	var saveButton:FlxButton;
	var closeButton:FlxButton;

	var oneshot_songTitle:FlxText;

	// some variables stuff
	var creditsType:String = 'Bios';

	public static var oneshotMod:Bool = false;

	var credits:FlxSprite;
	var mods:FlxSprite;
	var mainSide:FlxSprite;

	var menuItem:FlxSprite;
	var blackBg:FlxSprite;

	var random_text:FlxText;
	var random_background:FlxSprite;

	var mainMenu:MenuData;

	private static var _file:FileReference;

	var optionShit:Array<String> = ["story_mode", "freeplay", "options"];

	override function create()
	{
		mainMenu = Json.parse(Paths.getTextFromFile('moddingTools/mainmenu.json'));

		FlxG.mouse.visible = true;

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Editing the Main Menu...", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite(-80).loadGraphic(Paths.image(mainMenu.bgSpr));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = CoolUtil.colorFromString(mainMenu.bgColor);
		add(bg);

		grid = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33000000, 0x0));
		grid.velocity.set(30, 30);
		grid.scale.set(1.3, 1.3);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		grid.visible = mainMenu.checkersOn;
		if (ClientPrefs.data.lowQuality)
			mainMenu.checkersOn = false;
		add(grid);

		mainSide = new FlxSprite(0, 0).loadGraphic(Paths.image('mic-d-up/Main_Side'));
		add(mainSide);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		credits = new FlxSprite(935, 553).loadGraphic(Paths.image('mic-d-up/credits'));
		add(credits);

		mods = new FlxSprite(935, -121).loadGraphic(Paths.image('mic-d-up/mods'));
		add(mods);

		blackBg = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackBg.alpha = 0;
		blackBg.screenCenter();
		add(blackBg);

		tab_menu = new FlxUITabMenu(null, tab_tabs, true);
		tab_menu.scrollFactor.set(0, 0);
		tab_menu.resize(300, 450);
		tab_menu.screenCenter(Y);
		tab_menu.x += 20;
		add(tab_menu);

		tab_group_menu = new FlxUI(null, tab_menu);
		tab_group_menu.name = "Main";

		tab_menu.selected_tab_id = "Main";

		saveButton = new FlxButton(0, 0, 'Save Changes', function()
		{
			convertFile(mainMenu);
		});

		saveButton.screenCenter(Y);
		saveButton.x += 40;
		saveButton.y += 172;
		add(saveButton);

		var help = new FlxButton(0, 0, 'Help', function()
		{
			trace('hi');
		});
	
		help.screenCenter(Y);
		help.color = FlxColor.YELLOW;
		help.x += 145;
		help.y += 172;
		add(help);

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
		var oneshot_desc = new FlxText(oneshot_songName.x, oneshot_songName.y + 23, 0,
			"Make sure to enable the Oneshot Mod option\nbefore writing something here.");

		check_checkers = new FlxUICheckBox(oneshot_desc.x, oneshot_songName.y + 59, null, null, 'Enable Checkers');
		menu_items = new FlxUICheckBox(check_checkers.x, check_checkers.y + 59, null, null, 'Show Creds and Mods Arrows');

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
		tab_group_menu.add(menu_items);
		tab_menu.addGroup(tab_group_menu);

		credits.visible = !menu_items.checked;
		mods.visible = !menu_items.checked;

		loadEverything();

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

		random_text = new FlxText(0, 0, 1244, 'Hi, welcome to the menu editor!');
		random_text.setFormat('VCR OSD Mono', 29, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		random_text.screenCenter();
		random_text.y -= 339;
		random_text.visible = ClientPrefs.data.randomMessage;
		add(random_text);

		super.create();

		for (i in 0...optionShit.length)
			{
				var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
				menuItem = new FlxSprite(0, (i * 207) + offset);
				menuItem.antialiasing = ClientPrefs.data.antialiasing;
				menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
				menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
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
	}

	function loadEverything()
	{
		menu_bgColor.text = mainMenu.bgColor;
		menu_bgSpr.text = mainMenu.bgSpr;
		menu_creditType.text = mainMenu.creditsType;
		oneshot_songName.text = mainMenu.oneshotSong;
		check_oneshot.checked = oneshotMod;
		check_checkers.checked = mainMenu.checkersOn;
		menu_items.checked = mainMenu.arrowsOn;
	}

	public static function convertFile(menuJSON:MenuData)
	{
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

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == menu_bgColor)
			{
				bg.color = CoolUtil.colorFromString(menu_bgColor.text.trim());
				mainMenu.bgColor = menu_bgColor.text.trim();
			}
			else if (sender == menu_bgSpr)
			{
				bg.loadGraphic(Paths.image(menu_bgSpr.text.trim()));
				mainMenu.bgSpr = menu_bgSpr.text.trim();
				bg.screenCenter();
			}
			else if (sender == menu_creditType)
			{
				creditsType = menu_creditType.text.trim();
				mainMenu.creditsType = menu_creditType.text.trim();
			}
			else if (sender == oneshot_songName)
			{
				mainMenu.oneshotSong = oneshot_songName.text.trim();
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
				case 'Show Creds and Mods Arrows':
					mods.visible = check.checked;
					credits.visible = check.checked;
			}
		}
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (controls.BACK)
		{
			MusicBeatState.switchState(new MasterEditorMenu());
		}

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				ClientPrefs.toggleVolumeKeys(false);
				FlxG.keys.enabled = false;
				blockInput = true;

				if (FlxG.keys.justPressed.ENTER)
					inputText.hasFocus = false;
				break;
			}
		}

		if (!blockInput)
		{
			ClientPrefs.toggleVolumeKeys(true);
			FlxG.keys.enabled = true;
			if (FlxG.keys.justPressed.ESCAPE)
			{
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

		super.update(elapsed);
	}
}
