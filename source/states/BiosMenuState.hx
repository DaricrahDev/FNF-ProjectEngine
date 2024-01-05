package states;

import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxBackdrop;
import flixel.*;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;
import tjson.TJSON as Json;
#if sys
import sys.FileSystem;
#end
import flixel.addons.ui.FlxInputText;

typedef BiosMenuJSON =
{
	people:Array<String>,
	descriptions:Array<String>,
	links:Array<String>,
	badgeImages:Array<String>,
	imageLinks:Array<String>,
	badgeText:Array<String>,
	backgroundSprite:String,
	backgroundColor:Array<String>
}
class BiosMenuState extends MusicBeatState {
	
	var bg:FlxSprite;
	var background:FlxSprite;
    var imageSprite:FlxSprite;

    var imagePath:Array<String>;
    var charDesc:Array<String>;
    var charName:Array<String>;
	var linkOpen:Array<String>;
	var badgeimg:Array<String>;
	var badgeText:Array<String>;
	var peopleLinks:Array<String>;

	var curSelected:Int = -1;
	var currentIndex:Int = 0;

    var descriptionText:FlxText;
    var characterName:FlxText;

	var gradient:FlxSprite;

	var badgeImg:FlxSprite;
	var badgetextx:FlxText;

	var biosJSON:BiosMenuJSON;

	override function create() {
		
		biosJSON = Json.parse(Paths.getTextFromFile('moddingTools/biosmenu.json'));

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		FlxG.mouse.visible = true;

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Bios Menu", null);
		#end
	
		background = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        background.setGraphicSize(Std.int(background.width * 1.2));
        background.screenCenter();
		background.color = CoolUtil.colorFromString(biosJSON.backgroundColor[currentIndex]);
        add(background);

		// i took this from psych's engine code lol
		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33000000, 0x0));
		grid.velocity.set(30, 30);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);
	
		imageSprite = new FlxSprite(55, 99).loadGraphic(Paths.image(biosJSON.imageLinks[currentIndex]));
		imageSprite.setGraphicSize(518, 544);
		add(imageSprite);

		badgeImg = new FlxSprite(1086, 451).loadGraphic(Paths.image(biosJSON.badgeImages[currentIndex]));
		add(badgeImg);

		badgetextx = new FlxText(1069, 628, 197, biosJSON.badgeText[currentIndex]);
		badgetextx.setFormat('VCR OSD Mono', 22, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(badgetextx);

		characterName = new FlxText(630, 94, 622, biosJSON.people[currentIndex]);
        characterName.setFormat(Paths.font("vcr.ttf"), 96, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		characterName.antialiasing = true;
		characterName.borderSize = 4;
        add(characterName);

		descriptionText = new FlxText(630, 247, 601, biosJSON.descriptions[currentIndex]);
        descriptionText.setFormat(Paths.font("vcr.ttf"), 34, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descriptionText.antialiasing = true;
		descriptionText.borderSize = 2.5;
        add(descriptionText);

		var arrows = new FlxSprite(218, 30).loadGraphic(Paths.image('bios/assets/biosThing'));
		add(arrows);

		super.create();
	}

	override function update(elapsed:Float) {

		if (controls.ACCEPT) {
			CoolUtil.browserLoad(biosJSON.links[currentIndex]);
		}

		if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W) 
			{
				currentIndex--;
				if (currentIndex < 0)
				{
					currentIndex = biosJSON.imageLinks.length - 1;
				}
				remove(imageSprite);
				imageSprite = new FlxSprite(55, 99).loadGraphic(Paths.image(biosJSON.imageLinks[currentIndex]));
				add(imageSprite);
				FlxTween.tween(imageSprite, {x: 55, y: 101}, 0.1, {ease: FlxEase.quadInOut});
				remove(badgeImg);
				badgeImg = new FlxSprite(1086, 451).loadGraphic(Paths.image(biosJSON.badgeImages[currentIndex]));
				add(badgeImg);
				descriptionText.text = biosJSON.descriptions[currentIndex];
				characterName.text = biosJSON.people[currentIndex];
				badgetextx.text = biosJSON.badgeText[currentIndex];
				background.color = CoolUtil.colorFromString(biosJSON.backgroundColor[currentIndex]);
				FlxG.sound.play(Paths.sound('scrollMenu'));  
	
			}
			else if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S)
			{
				currentIndex++;
				if (currentIndex >= biosJSON.imageLinks.length)
				{
					currentIndex = 0;
				}
				remove(imageSprite);
				imageSprite = new FlxSprite(55, 99).loadGraphic(Paths.image(biosJSON.imageLinks[currentIndex]));
				add(imageSprite);
				FlxTween.tween(imageSprite, {x: 55, y: 101}, 0.1, {ease: FlxEase.quadInOut});
				remove(badgeImg);
				badgeImg = new FlxSprite(1086, 451).loadGraphic(Paths.image(biosJSON.badgeImages[currentIndex]));
				add(badgeImg);
				descriptionText.text = biosJSON.descriptions[currentIndex];
				characterName.text = biosJSON.people[currentIndex];  
				badgetextx.text = biosJSON.badgeText[currentIndex];
				background.color = CoolUtil.colorFromString(biosJSON.backgroundColor[currentIndex]);
				FlxG.sound.play(Paths.sound('scrollMenu'));	
			}
			if (controls.BACK)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					MusicBeatState.switchState(new MainMenuState());
				}
		
		super.update(elapsed);
}	}