package states;

import backend.Song;
import flixel.*;
import flixel.text.FlxText;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

class ResultsScreen extends MusicBeatSubstate
{
	var songCleared:Alphabet;

	var scoreTxt:Alphabet;
	var missTxt:Alphabet;
	var noteTxt:Alphabet;
	var ratingTxt:Alphabet;

	var ratingContent:Alphabet;

	var pressEnter:FlxSprite;
	var bf:FlxSprite;

	var enterTimer:FlxTimer;

	var grid:FlxBackdrop;

	var campScore = PlayState.campaignScore;
	var campMisses = PlayState.campaignMisses;
	
	override function create()
	{
		enterTimer = new FlxTimer();

		FlxG.sound.playMusic(Paths.music('offsetSong'));

		var bg = new FlxSprite(0, 0).loadGraphic(Paths.image('menuDesat'));
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.color = FlxColor.fromRGB(PlayState.instance.dad.healthColorArray[0], PlayState.instance.dad.healthColorArray[1], PlayState.instance.dad.healthColorArray[2]);
		if (PlayState.instance.dad.healthColorArray[0] == 0 && PlayState.instance.dad.healthColorArray[1] == 0 && PlayState.instance.dad.healthColorArray[2] == 0)
		{
			bg.color = 0x292929; // doing this bc if you use tottaly black colors you cant see a shit lol
		}
		add(bg);

		grid = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33000000, 0x0));
		grid.velocity.set(30, 30);
		grid.scale.set(1.3, 1.3);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		var songname = PlayState.instance.songName;
		var diff = Difficulty.getString();

		var songName:Alphabet = new Alphabet(30, 70, "", false);
		songName.text = '${songname}'.toUpperCase();
		songName.scrollFactor.set();
		add(songName);

		songCleared = new Alphabet(30, 30, 'Song Completed!', true);
		songCleared.scrollFactor.set();
		add(songCleared);

		var score = PlayState.instance.songScore;
		var misses = PlayState.instance.songMisses;
		var hits = PlayState.instance.songHits;
		var rating = PlayState.instance.ratingFC;

		if (PlayState.isStoryMode)
		{
			songCleared.text = 'Week Completed!';
			songName.text = 'Week ' + '${PlayState.storyWeek}';
			if (PlayState.storyWeek == 0) // gotta make something to fix it if you delete 'tutorial week'
			{
				songName.text = 'Tutorial';
			}
		}

		scoreTxt = new Alphabet(30, songName.y + 217, 'Score: 0');
		scoreTxt.scrollFactor.set();
		add(scoreTxt);

		missTxt = new Alphabet(30, scoreTxt.y + 77, 'Misses: 0');
		missTxt.scrollFactor.set();
		add(missTxt);

		noteTxt = new Alphabet(30, missTxt.y + 77, 'Note Hits: 0');
		noteTxt.scrollFactor.set();
		add(noteTxt);

		ratingTxt = new Alphabet(30, noteTxt.y + 80, 'Rating: ');
		ratingTxt.scrollFactor.set();
		add(ratingTxt);

		ratingContent = new Alphabet(ratingTxt.x + 336, ratingTxt.y, '${rating}');
		ratingContent.scrollFactor.set();
		add(ratingContent);

		if (rating == 'FC')
		{
			ratingContent.color = FlxColor.GRAY;
		}
		else if (rating == '?' || rating == 'Clear')
		{
			ratingContent.color = FlxColor.GRAY;
		}
		else if (rating == 'SFC' || rating == 'GFC')
		{
			ratingContent.color = FlxColor.LIME;
		}
		else if (rating == 'SDCB')
		{
			ratingContent.color = FlxColor.GREEN;
		}

		pressEnter = new FlxSprite(673, 750);
		pressEnter.frames = Paths.getSparrowAtlas('resultsScreen/press_enter');
		pressEnter.animation.addByPrefix('idle', 'press enter', 24);
		pressEnter.animation.addByPrefix('pressed', 'enter pressed', 24);
		pressEnter.animation.play('idle');
		add(pressEnter);

		bf = new FlxSprite(817, 949);
		bf.frames = Paths.getSparrowAtlas('resultsScreen/bf');
		bf.animation.addByPrefix('bf_dance', 'BF idle dance', 24);
		bf.animation.addByPrefix('bf_fail', 'BF NOTE LEFT MISS', 24, false);
		bf.animation.addByPrefix('bf_hey', 'BF HEY!!', 24, false);
		bf.animation.play('bf_dance');
		add(bf);

		if (PlayState.isStoryMode) noteTxt.visible = false;

		FlxTween.tween(bf, {x: 817, y: 137}, 1.0, {ease: FlxEase.backOut, startDelay: 1.0, onComplete: function(t:FlxTween){
			if (score > 5500 && misses < 30)
			{
				bf.animation.play('bf_hey');
			}
			else if (score < 5500 && misses > 30)
			{
				bf.animation.play('bf_fail');
			}
		}});
		FlxTween.tween(pressEnter, {x: 673, y: 614}, 1.0, {ease: FlxEase.backOut, startDelay: 2.0});

		if (PlayState.isStoryMode)
		{
			FlxTween.num(0, ${campScore}, 3.0, {type: FlxTweenType.ONESHOT, ease: FlxEase.cubeIn}, updateScoreResult);
			FlxTween.num(0, ${campMisses}, 3.0, {type: FlxTweenType.ONESHOT, ease: FlxEase.cubeIn}, updateMissResult);
		}
		else
		{
			FlxTween.num(0, ${score}, 3.0, {type: FlxTweenType.ONESHOT, ease: FlxEase.cubeIn}, updateScoreResult);
			FlxTween.num(0, ${misses}, 3.0, {type: FlxTweenType.ONESHOT, ease: FlxEase.cubeIn}, updateMissResult);
			FlxTween.num(0, ${hits}, 3.0, {type: FlxTweenType.ONESHOT, ease: FlxEase.cubeIn}, updateNotehitResult);
		}

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.ACCEPT || controls.BACK)
		{
			pressEnter.animation.play('pressed');
			FlxG.sound.play(Paths.sound('confirmMenu'));
			enterTimer.start(1.0, changeStateShit, 1);
			FlxG.sound.music.stop();
		}
		
		super.update(elapsed);
	}

	function changeStateShit(t:FlxTimer)
	{
		if (PlayState.isStoryMode)
			{
				if (PlayState.storyPlaylist.length <= 0)
				{
					MusicBeatState.switchState(new StoryMenuState());
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				MusicBeatState.switchState(new FreeplayState());
			}
	}

	function updateNotehitResult(newValue:Float)
	{
		noteTxt.text = 'Note Hits: ' + Std.string(Std.int(newValue));
	}

	function updateMissResult(newValue:Float)
	{
		missTxt.text = 'Misses: ' + Std.string(Std.int(newValue));
	}

	function updateScoreResult(newValue:Float)
	{
		scoreTxt.text = 'Score: ' + Std.string(Std.int(newValue));
	}
}