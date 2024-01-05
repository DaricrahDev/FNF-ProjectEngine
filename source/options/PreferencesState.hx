package options;

class PreferencesState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Preferences Settings';
		rpcTitle = 'Preferences Settings Menu';

		var option:Option = new Option('Language:',
			"DISABLED",
			'language',
			'string',
			['English']);
		addOption(option);

		var option:Option = new Option('Enable Menu Editor',
			"Should the Menu Editor be enabled?",
			'menuEditor',
			'bool');
		addOption(option);

		var option:Option = new Option('Show Random Message',
			"if unchecked, hides the random messages of the mainmenu.",
			'randomMessage',
			'bool');
		addOption(option);

		var option:Option = new Option('More Options Soon...',
			"More options coming soon on v0.7.3!",
			'none',
			'string',
			['']);
		addOption(option);

		super();
	}
}