# yml_gtranslate

yml_gtranslate is a convenience gem to get your rails localization process going quickly. It uses the Google Translate service (no API required though).
It creates missing `*.yml` localization config files or updates the locale files with missing keys and translates those missing keys.


## Installation

Use rubygems for installation:

    $ gem install yml_gtranslate


or add this line to your application's Gemfile:

    gem 'yml_gtranslate', :git => 'git://github.com/zenchief/yml_gtranslate.git'


And then execute:

    $ bundle install



## Requirements

You need [sed](www.gnu.org/software/sed) and [curl](curl.haxx.se) on your system and in your $PATH. Curl is for getting data and sed is used for handling comment tokens before and after transaltion. 

## Usage

After installation use the command:


	$ yml_gt <from_lang> <to_lang> [directory]
goes thru all `*from_lang.yml` files in the `directory`  
the default dir is config/locales


Translates config/locales/*en.yml files to German

	$ yml_gt en de


Translates all sk.yml files in the _current directory_ to English (hence the dot)

	$ yml_gt sk en .
	
This is going to take your all your `config/locales/*en.yml` files and compare them with `config/locales/*de.yml` files.
(That is in case your locale files are divided, e.g. en.yml, devise.en.yml etc.). If the target file does not exist
it's going to create it and translate all string keys in the source file to German using Google Translate.
If the target file already exists it's gonna compare all the string keys in both source and target and translate only those missing in the target.

The translation adds a comment "#i18n-GT" after the translated key. This is to let you know, that this string was
generated by Google Translate and probably needs some fine tuning (coz let's face it, GT is seldom perfect in translations).

###Example 1.
Completing and sorting locale files:

**en.yml**
```ruby
en:
  oranges: "oranges"
  apples: "apples"
  cherries: "cherries"
```

**de.yml**
```ruby
de:
  oranges: "my awesome deutsch translation: Orangen"
```ruby

Command `yml_gt en de .` will result in `de.yml` being updated to:
```ruby
de: 
  apples: "Äpfel" #i18n-GT
  cherries: "Kirschen" #i18n-GT
  oranges: "my awesome deutsch translation: Orangen"
```


## Contributing

A: Shoot me an email and we'll talk it over

**or**

B:

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


