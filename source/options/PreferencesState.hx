package options;

class PreferencesState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Preferences Settings';
		rpcTitle = 'Preferences Settings Menu';

		var option:Option = new Option('Language:',
			"DISABLED UNTIL 0.7.3, SORRY!",
			'language',
			'string',
			['English']);
		addOption(option);

		var option:Option = new Option('Show Random Message',
			"if unchecked, hides the random messages of the mainmenu.",
			'randomMessage',
			'bool');
		addOption(option);

		super();
	}
}