/// Generated file. Do not edit.
///
/// Original: assets/l10n
/// To regenerate, run: `dart run slang`
///
/// Locales: 2
/// Strings: 226 (113 per locale)
///
/// Built on 2025-09-15 at 13:39 UTC

// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang_flutter/slang_flutter.dart';
export 'package:slang_flutter/slang_flutter.dart';

const AppLocale _baseLocale = AppLocale.en;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.en) // set locale
/// - Locale locale = AppLocale.en.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.en) // locale check
enum AppLocale with BaseAppLocale<AppLocale, Strings> {
	en(languageCode: 'en', build: Strings.build),
	ja(languageCode: 'ja', build: _StringsJa.build);

	const AppLocale({required this.languageCode, this.scriptCode, this.countryCode, required this.build}); // ignore: unused_element

	@override final String languageCode;
	@override final String? scriptCode;
	@override final String? countryCode;
	@override final TranslationBuilder<AppLocale, Strings> build;

	/// Gets current instance managed by [LocaleSettings].
	Strings get translations => LocaleSettings.instance.translationMap[this]!;
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
/// Configurable via 'translate_var'.
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
Strings get t => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final t = Strings.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class TranslationProvider extends BaseTranslationProvider<AppLocale, Strings> {
	TranslationProvider({required super.child}) : super(settings: LocaleSettings.instance);

	static InheritedLocaleData<AppLocale, Strings> of(BuildContext context) => InheritedLocaleData.of<AppLocale, Strings>(context);
}

/// Method B shorthand via [BuildContext] extension method.
/// Configurable via 'translate_var'.
///
/// Usage (e.g. in a widget's build method):
/// context.t.someKey.anotherKey
extension BuildContextTranslationsExtension on BuildContext {
	Strings get t => TranslationProvider.of(this).translations;
}

/// Manages all translation instances and the current locale
class LocaleSettings extends BaseFlutterLocaleSettings<AppLocale, Strings> {
	LocaleSettings._() : super(utils: AppLocaleUtils.instance);

	static final instance = LocaleSettings._();

	// static aliases (checkout base methods for documentation)
	static AppLocale get currentLocale => instance.currentLocale;
	static Stream<AppLocale> getLocaleStream() => instance.getLocaleStream();
	static AppLocale setLocale(AppLocale locale, {bool? listenToDeviceLocale = false}) => instance.setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale setLocaleRaw(String rawLocale, {bool? listenToDeviceLocale = false}) => instance.setLocaleRaw(rawLocale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale useDeviceLocale() => instance.useDeviceLocale();
	@Deprecated('Use [AppLocaleUtils.supportedLocales]') static List<Locale> get supportedLocales => instance.supportedLocales;
	@Deprecated('Use [AppLocaleUtils.supportedLocalesRaw]') static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
	static void setPluralResolver({String? language, AppLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolver(
		language: language,
		locale: locale,
		cardinalResolver: cardinalResolver,
		ordinalResolver: ordinalResolver,
	);
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, Strings> {
	AppLocaleUtils._() : super(baseLocale: _baseLocale, locales: AppLocale.values);

	static final instance = AppLocaleUtils._();

	// static aliases (checkout base methods for documentation)
	static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
	static AppLocale parseLocaleParts({required String languageCode, String? scriptCode, String? countryCode}) => instance.parseLocaleParts(languageCode: languageCode, scriptCode: scriptCode, countryCode: countryCode);
	static AppLocale findDeviceLocale() => instance.findDeviceLocale();
	static List<Locale> get supportedLocales => instance.supportedLocales;
	static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}

// translations

// Path: <root>
class Strings implements BaseTranslations<AppLocale, Strings> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Strings.of(context);
	static Strings of(BuildContext context) => InheritedLocaleData.of<AppLocale, Strings>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Strings.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Strings> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Strings _root = this; // ignore: unused_field

	// Translations
	late final _StringsGameEn game = _StringsGameEn._(_root);
	late final _StringsStoryEn story = _StringsStoryEn._(_root);
	late final _StringsUiEn ui = _StringsUiEn._(_root);
	late final _StringsCombatEn combat = _StringsCombatEn._(_root);
	late final _StringsDialogueEn dialogue = _StringsDialogueEn._(_root);
	late final _StringsItemsEn items = _StringsItemsEn._(_root);
	late final _StringsCandyCollectionEn candyCollection = _StringsCandyCollectionEn._(_root);
	late final _StringsCandyTypesEn candyTypes = _StringsCandyTypesEn._(_root);
	late final _StringsGiftUIEn giftUI = _StringsGiftUIEn._(_root);
}

// Path: game
class _StringsGameEn {
	_StringsGameEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get title => 'Kiro Halloween Game';
}

// Path: story
class _StringsStoryEn {
	_StringsStoryEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get title => 'Kiro\'s Story';
	String get text => 'Kiro, a ghost troubled by not being scary enough, had set his goal to frighten the Vampire Master.\n\nHowever, tonight is Halloween night. Children are coming to seek candy...\n\nCan Kiro collect candy, make friends, and ultimately achieve victory over the Vampire Master?';
	String get startAdventure => '🚀 Start Adventure';
	String get tapToSkip => 'Tap to skip';
}

// Path: ui
class _StringsUiEn {
	_StringsUiEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get inventory => 'Inventory';
}

// Path: combat
class _StringsCombatEn {
	_StringsCombatEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	late final _StringsCombatBossAbilitiesEn bossAbilities = _StringsCombatBossAbilitiesEn._(_root);
	late final _StringsCombatEnemyAttacksEn enemyAttacks = _StringsCombatEnemyAttacksEn._(_root);
	late final _StringsCombatPlayerAttacksEn playerAttacks = _StringsCombatPlayerAttacksEn._(_root);
	late final _StringsCombatMessagesEn messages = _StringsCombatMessagesEn._(_root);
}

// Path: dialogue
class _StringsDialogueEn {
	_StringsDialogueEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get continueButton => 'Continue';
}

// Path: items
class _StringsItemsEn {
	_StringsItemsEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get eat => 'Eat';
	String get give => 'Give';
	String get noCandies => 'No candies in inventory';
	String get activeEffects => 'Active Effects';
	String get turns => 'turns';
	String get helpText => 'Tap an item for options. Press I to close.';
	String get inventoryFull => 'Inventory Full!';
	String get healthBoost => '+{value} Health';
	String get maxHealthIncrease => '+{value} Max Health';
	String get speedBoost => 'Speed Boost!';
	String get allyPower => 'Ally Power!';
	String get specialPower => 'Special Power!';
	String get statBoost => 'Stat Boost!';
}

// Path: candyCollection
class _StringsCandyCollectionEn {
	_StringsCandyCollectionEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	List<String> get messages => [
		'Kiro finds a {name}! {description}',
		'A glowing {name} catches Kiro\'s attention. Sweet supernatural treat!',
		'Kiro discovers a magical {name} that sparkles with otherworldly flavor.',
		'The {name} makes Kiro glow brighter with ghostly happiness.',
		'Kiro picked up {name}! Looks delicious!',
	];
	String get inventoryFullMessage => 'Kiro\'s inventory is full! Can\'t pick up more candy.';
}

// Path: candyTypes
class _StringsCandyTypesEn {
	_StringsCandyTypesEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	late final _StringsCandyTypesCandyBarEn candyBar = _StringsCandyTypesCandyBarEn._(_root);
	late final _StringsCandyTypesChocolateEn chocolate = _StringsCandyTypesChocolateEn._(_root);
	late final _StringsCandyTypesCookieEn cookie = _StringsCandyTypesCookieEn._(_root);
	late final _StringsCandyTypesCupcakeEn cupcake = _StringsCandyTypesCupcakeEn._(_root);
	late final _StringsCandyTypesDonutEn donut = _StringsCandyTypesDonutEn._(_root);
	late final _StringsCandyTypesIceCreamEn iceCream = _StringsCandyTypesIceCreamEn._(_root);
	late final _StringsCandyTypesLollipopEn lollipop = _StringsCandyTypesLollipopEn._(_root);
	late final _StringsCandyTypesPopsicleEn popsicle = _StringsCandyTypesPopsicleEn._(_root);
	late final _StringsCandyTypesGingerbreadEn gingerbread = _StringsCandyTypesGingerbreadEn._(_root);
	late final _StringsCandyTypesMuffinEn muffin = _StringsCandyTypesMuffinEn._(_root);
}

// Path: giftUI
class _StringsGiftUIEn {
	_StringsGiftUIEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get giveCandy => 'Give Candy to {enemyName}';
	String get chooseCandyTitle => 'Choose candy to give:';
	String get cancel => 'Cancel';
	String get giveGift => 'Give Gift';
	String get health => 'Health';
}

// Path: combat.bossAbilities
class _StringsCombatBossAbilitiesEn {
	_StringsCombatBossAbilitiesEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get charge => 'The Boss laughs loudly! The ground trembles!';
	String get areaAttack => 'The Boss sneezes! Shockwaves spread everywhere!';
	String get regeneration => 'The Boss eats a blood orange! {healAmount} health restored!';
	String get summonMinions => 'The Boss calls lost children! New threats emerge!';
}

// Path: combat.enemyAttacks
class _StringsCombatEnemyAttacksEn {
	_StringsCombatEnemyAttacksEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	List<String> get withDamage => [
		'The {} gives Kiro an unexpected hug! It\'s surprisingly warm! ({} damage)',
		'The {} tries to surprise Kiro! Boo! ({} damage)',
		'The {} tries to high-five Kiro, but ghosts are tricky to touch! ({} damage)',
		'The {} attempts a tickle attack on Kiro! ({} damage)',
		'A curious {} tries to lift Kiro\'s ghostly sheet! ({} damage)',
		'Kiro tries to scare the {} but just gets laughed at! ({} damage)',
		'Kiro is frightened by the {} asking for candy! ({} damage)',
	];
	List<String> get withoutDamage => [
		'The {} tries to hug Kiro but he turns transparent at the last second! (0 damage)',
		'The {} tries to surprise Kiro but it wasn\'t scary at all! (0 damage)',
		'The {} misses completely! (0 damage)',
	];
}

// Path: combat.playerAttacks
class _StringsCombatPlayerAttacksEn {
	_StringsCombatPlayerAttacksEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	List<String> get withDamage => [
		'Kiro gives a scary BOO! Enemy is frightened! ({} damage)',
		'Kiro\'s ghostly appeal! Enemy is trembling with fear! ({} damage)',
		'Kiro\'s friendly hug makes Enemy too embarrassed to fight! ({} damage)',
		'Kiro\'s ethereal tickle attack is irresistible! Enemy is laughing loudly! ({} damage)',
		'Enemy is charmed by Kiro\'s ghostly dance! ({} damage)',
	];
	List<String> get withoutDamage => [
		'Kiro tries to scare but Enemy just laughs! ({} damage)',
		'Kiro\'s ghost touch is noticed but not very effective! ({} damage)',
		'Enemy feels a gentle ghostly breeze from Kiro\'s approach! ({} damage)',
		'Kiro\'s gentle BOO confuses Enemy slightly! ({} damage)',
	];
}

// Path: combat.messages
class _StringsCombatMessagesEn {
	_StringsCombatMessagesEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get allyDefeatsEnemyStrike => '{ally}\'s powerful hug makes {enemy} no longer a threat!';
	String get allyEmergesVictorious => '{ally} satisfies {enemy}!';
	String get allyOvercomes => '{ally} wins the arm wrestling match against {enemy}!';
	String get allyDefeatedBy => '{ally} is satisfied by {enemy} and returns home!';
	String get enemyOvercomes => '{enemy} wins the dance battle against {ally}!';
	String get allyFalls => '{ally} is satisfied by {enemy}!';
	String get bothDefeatEachOther => '{ally} and {enemy} are satisfied and go home together!';
	String get bothFallInCombat => '{ally} and {enemy} become friends and go home together!';
	String get bothDefeated => '{ally} and {enemy} acknowledge each other!';
	String get exchangeBlows => 'Intense beatbox battle between {ally} and {enemy}!';
	String get battleContinues => 'The dance battle between {ally} and {enemy} continues!';
	String get fightFiercely => 'Intense joke battle between {ally} and {enemy}!';
	String get engagesInCombat => '{ally} starts a dance battle with {enemy}!';
	String get movesToAttack => '{ally} moves to play with {enemy}!';
	String get confronts => '{ally} confronts {enemy}!';
	String get hasBeenDefeated => '{enemy} is satisfied and goes home!';
	String get fallsToGround => '{enemy} is tired from laughing and lies down.';
	String get noLongerThreat => '{enemy} is no longer a threat.';
	String get entersCombat => '{ally} enters enjoy mode!';
	String get preparesForBattle => '{ally} prepares to play!';
	String get readiesForCombat => '{ally} gets ready to play!';
	String get returnsToFollowing => '{ally} returns to following you.';
	String get comesBack => '{ally} comes back to your side.';
	String get resumesFollowing => '{ally} resumes following.';
	String get looksSatisfied => '{ally} looks satisfied and wanders away.';
	String get seemsContent => '{ally} seems content and departs.';
	String get appearsFullfilled => '{ally} appears fulfilled and leaves.';
	String get looksContent => '{ally} looks more content.';
	String get seemsPleased => '{ally} seems pleased with the situation.';
	String get appearsHappier => '{ally} appears happier.';
	String get looksLessSatisfied => '{ally} looks less satisfied.';
	String get seemsTroubled => '{ally} seems troubled.';
	String get appearsUnhappy => '{ally} appears unhappy.';
	String get allyDefeatedSatisfied => '{ally} has gone home but feels satisfied with their service.';
	String get combatStarted => '{ally} starts a rap battle with {enemy}!';
	String get combatConcluded => 'The dance battle has concluded.';
	String get allyVictory => 'Your ally emerges victorious!';
	String get enemyVictory => 'The enemy has defeated your ally.';
	String get combatDraw => 'The dance ends in a tie.';
}

// Path: candyTypes.candyBar
class _StringsCandyTypesCandyBarEn {
	_StringsCandyTypesCandyBarEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get name => 'Candy Bar';
	String get description => 'A sweet candy bar that restores 20 health points';
}

// Path: candyTypes.chocolate
class _StringsCandyTypesChocolateEn {
	_StringsCandyTypesChocolateEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get name => 'Chocolate';
	String get description => 'Rich chocolate that permanently increases max health by 10';
}

// Path: candyTypes.cookie
class _StringsCandyTypesCookieEn {
	_StringsCandyTypesCookieEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get name => 'Cookie';
	String get description => 'A crispy cookie that restores 18 health points';
}

// Path: candyTypes.cupcake
class _StringsCandyTypesCupcakeEn {
	_StringsCandyTypesCupcakeEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get name => 'Cupcake';
	String get description => 'A delicious cupcake that boosts ally combat strength for 20 turns';
}

// Path: candyTypes.donut
class _StringsCandyTypesDonutEn {
	_StringsCandyTypesDonutEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get name => 'Donut';
	String get description => 'A glazed donut that restores 15 health points';
}

// Path: candyTypes.iceCream
class _StringsCandyTypesIceCreamEn {
	_StringsCandyTypesIceCreamEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get name => 'Ice Cream';
	String get description => 'Cool ice cream that freezes nearby enemies for 10 turns';
}

// Path: candyTypes.lollipop
class _StringsCandyTypesLollipopEn {
	_StringsCandyTypesLollipopEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get name => 'Lollipop';
	String get description => 'A colorful lollipop that restores 22 health points';
}

// Path: candyTypes.popsicle
class _StringsCandyTypesPopsicleEn {
	_StringsCandyTypesPopsicleEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get name => 'Popsicle';
	String get description => 'A refreshing popsicle that restores 12 health points';
}

// Path: candyTypes.gingerbread
class _StringsCandyTypesGingerbreadEn {
	_StringsCandyTypesGingerbreadEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get name => 'Gingerbread';
	String get description => 'Magical gingerbread that allows seeing through walls for 15 turns';
}

// Path: candyTypes.muffin
class _StringsCandyTypesMuffinEn {
	_StringsCandyTypesMuffinEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get name => 'Muffin';
	String get description => 'A hearty muffin that restores 25 health points';
}

// Path: <root>
class _StringsJa extends Strings {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsJa.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja>.
	@override final TranslationMetadata<AppLocale, Strings> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	@override late final _StringsJa _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsGameJa game = _StringsGameJa._(_root);
	@override late final _StringsStoryJa story = _StringsStoryJa._(_root);
	@override late final _StringsUiJa ui = _StringsUiJa._(_root);
	@override late final _StringsCombatJa combat = _StringsCombatJa._(_root);
	@override late final _StringsDialogueJa dialogue = _StringsDialogueJa._(_root);
	@override late final _StringsItemsJa items = _StringsItemsJa._(_root);
	@override late final _StringsCandyCollectionJa candyCollection = _StringsCandyCollectionJa._(_root);
	@override late final _StringsCandyTypesJa candyTypes = _StringsCandyTypesJa._(_root);
	@override late final _StringsGiftUIJa giftUI = _StringsGiftUIJa._(_root);
}

// Path: game
class _StringsGameJa extends _StringsGameEn {
	_StringsGameJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'キロ ハロウィン ゲーム';
}

// Path: story
class _StringsStoryJa extends _StringsStoryEn {
	_StringsStoryJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kiro\'s Story';
	@override String get text => '自分が怖くないことに悩んでいたおばけのKiroは、ヴァンパイアマスターを怖がらせることを目標にしていた。\n\nしかし、今日はハロウィンの夜。子供達がお菓子を求めてやってくる…\n\n果たしてKiroは、お菓子を集め、仲間を作り、最終的にヴァンパイアマスターに勝利できるのか？';
	@override String get startAdventure => '🚀 冒険を始める';
	@override String get tapToSkip => 'タップでスキップ';
}

// Path: ui
class _StringsUiJa extends _StringsUiEn {
	_StringsUiJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get inventory => 'アイテム';
}

// Path: combat
class _StringsCombatJa extends _StringsCombatEn {
	_StringsCombatJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override late final _StringsCombatBossAbilitiesJa bossAbilities = _StringsCombatBossAbilitiesJa._(_root);
	@override late final _StringsCombatEnemyAttacksJa enemyAttacks = _StringsCombatEnemyAttacksJa._(_root);
	@override late final _StringsCombatPlayerAttacksJa playerAttacks = _StringsCombatPlayerAttacksJa._(_root);
	@override late final _StringsCombatMessagesJa messages = _StringsCombatMessagesJa._(_root);
}

// Path: dialogue
class _StringsDialogueJa extends _StringsDialogueEn {
	_StringsDialogueJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get continueButton => '続ける';
}

// Path: items
class _StringsItemsJa extends _StringsItemsEn {
	_StringsItemsJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get eat => '食べる';
	@override String get give => 'あげる';
	@override String get noCandies => 'インベントリにキャンディがありません';
	@override String get activeEffects => '有効な効果';
	@override String get turns => 'ターン';
	@override String get helpText => 'アイテムをタップしてオプションを表示。Iキーで閉じます。';
	@override String get inventoryFull => 'インベントリがいっぱいです！';
	@override String get healthBoost => '+{value} 体力';
	@override String get maxHealthIncrease => '+{value} 最大体力';
	@override String get speedBoost => 'スピードアップ！';
	@override String get allyPower => '仲間の力！';
	@override String get specialPower => '特殊能力！';
	@override String get statBoost => 'ステータスアップ！';
}

// Path: candyCollection
class _StringsCandyCollectionJa extends _StringsCandyCollectionEn {
	_StringsCandyCollectionJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override List<String> get messages => [
		'キロが{name}を見つけました！{description}',
		'光る{name}がキロの注意を引きました。甘い超自然的な御馳走です！',
		'キロが異世界の味でキラキラ光る魔法の{name}を発見しました。',
		'{name}でキロが幽霊の幸せでより明るく光ります。',
		'キロが{name}を拾いました！美味しそうです！',
	];
	@override String get inventoryFullMessage => 'キロのインベントリがいっぱいです！これ以上キャンディを拾えません。';
}

// Path: candyTypes
class _StringsCandyTypesJa extends _StringsCandyTypesEn {
	_StringsCandyTypesJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override late final _StringsCandyTypesCandyBarJa candyBar = _StringsCandyTypesCandyBarJa._(_root);
	@override late final _StringsCandyTypesChocolateJa chocolate = _StringsCandyTypesChocolateJa._(_root);
	@override late final _StringsCandyTypesCookieJa cookie = _StringsCandyTypesCookieJa._(_root);
	@override late final _StringsCandyTypesCupcakeJa cupcake = _StringsCandyTypesCupcakeJa._(_root);
	@override late final _StringsCandyTypesDonutJa donut = _StringsCandyTypesDonutJa._(_root);
	@override late final _StringsCandyTypesIceCreamJa iceCream = _StringsCandyTypesIceCreamJa._(_root);
	@override late final _StringsCandyTypesLollipopJa lollipop = _StringsCandyTypesLollipopJa._(_root);
	@override late final _StringsCandyTypesPopsicleJa popsicle = _StringsCandyTypesPopsicleJa._(_root);
	@override late final _StringsCandyTypesGingerbreadJa gingerbread = _StringsCandyTypesGingerbreadJa._(_root);
	@override late final _StringsCandyTypesMuffinJa muffin = _StringsCandyTypesMuffinJa._(_root);
}

// Path: giftUI
class _StringsGiftUIJa extends _StringsGiftUIEn {
	_StringsGiftUIJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get giveCandy => '{enemyName}にキャンディをあげる';
	@override String get chooseCandyTitle => 'あげるキャンディを選んでください：';
	@override String get cancel => 'キャンセル';
	@override String get giveGift => 'プレゼントする';
	@override String get health => '体力';
}

// Path: combat.bossAbilities
class _StringsCombatBossAbilitiesJa extends _StringsCombatBossAbilitiesEn {
	_StringsCombatBossAbilitiesJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get charge => 'ボスが大声で笑った！ 大地が震える！';
	@override String get areaAttack => 'ボスがくしゃみをした！ 広範囲に衝撃が走る！';
	@override String get regeneration => 'ボスがブラッドオレンジを食べた！ {healAmount}の体力が復活！';
	@override String get summonMinions => 'ボスが迷子の子供を呼び寄せた！ 新たな脅威が現れる！';
}

// Path: combat.enemyAttacks
class _StringsCombatEnemyAttacksJa extends _StringsCombatEnemyAttacksEn {
	_StringsCombatEnemyAttacksJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override List<String> get withDamage => [
		'{}がキロにハグをしました！驚くほど温かいです！（{}ダメージ）',
		'{}がキロを驚かせようとしました！バアー！（{}ダメージ）',
		'{}がキロとハイタッチしようとしましたが、幽霊に触るのは難しいようです！（{}ダメージ）',
		'{}がキロにくすぐり攻撃を試みました！（{}ダメージ）',
		'好奇心旺盛な{}がキロの布をめくろうとしました！（{}ダメージ）',
		'キロは{}を驚かせようとしましたが、笑われるだけでした！（{}ダメージ）',
		'キロはお菓子をねだる{}に恐怖しました！（{}ダメージ）',
	];
	@override List<String> get withoutDamage => [
		'{}がキロにハグしようとしましたが、すんでのところで透明化しました！（0ダメージ）',
		'{}がキロを驚かせようとしましたが、全然怖くなかったです！（0ダメージ）',
		'{}の！（0ダメージ）',
	];
}

// Path: combat.playerAttacks
class _StringsCombatPlayerAttacksJa extends _StringsCombatPlayerAttacksEn {
	_StringsCombatPlayerAttacksJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override List<String> get withDamage => [
		'キロが怖い「バアー！」を放ちます！Enemyは怖がりました！（{}ダメージ）',
		'キロの幽霊アピール！Enemyは恐怖で震えています！（{}ダメージ）',
		'キロのフレンドリーなハグでEnemyは恥ずかしくて戦えません！（{}ダメージ）',
		'キロのエーテルなくすぐり攻撃がたまりません！Enemyは大笑いしています！（{}ダメージ）',
		'Enemyはキロの幽霊ダンスに魅了されています！（{}ダメージ）',
	];
	@override List<String> get withoutDamage => [
		'キロは怖がらせようとしましたが、Enemyは笑うだけでした！（{}ダメージ）',
		'キロのお化けタッチは気づかれてしまい、あまり効果的ではありませんでした！（{}ダメージ）',
		'Enemyはキロのアプローチから優しい幽霊の風を感じました！（{}ダメージ）',
		'キロの優しい「バアー！」はEnemyを少し混乱させました！（{}ダメージ）',
	];
}

// Path: combat.messages
class _StringsCombatMessagesJa extends _StringsCombatMessagesEn {
	_StringsCombatMessagesJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get allyDefeatsEnemyStrike => '{ally}の強力なハグで{enemy}はもはや脅威ではありません！';
	@override String get allyEmergesVictorious => '{ally}が{enemy}を満足させました！';
	@override String get allyOvercomes => '{ally}が{enemy}との腕相撲で勝ちました！';
	@override String get allyDefeatedBy => '{ally}が{enemy}によって満足させられ帰りました！';
	@override String get enemyOvercomes => '{enemy}が{ally}とのダンス勝負に勝ちました！';
	@override String get allyFalls => '{ally}が{enemy}に満足させられました！';
	@override String get bothDefeatEachOther => '{ally}と{enemy}は満足して一緒に帰りました！';
	@override String get bothFallInCombat => '{ally}と{enemy}が友達になり一緒に帰りました！';
	@override String get bothDefeated => '{ally}と{enemy}はお互いを認め合いました！';
	@override String get exchangeBlows => '{ally}と{enemy}の激しいビートボックスバトル！';
	@override String get battleContinues => '{ally}と{enemy}とのダンス対決は続いています！';
	@override String get fightFiercely => '{ally}と{enemy}との激しいジョークバトル！';
	@override String get engagesInCombat => '{ally}が{enemy}とダンスバトルを開始しました！';
	@override String get movesToAttack => '{ally}が{enemy}と遊ぶために動きました！';
	@override String get confronts => '{ally}が{enemy}に立ち向かいます！';
	@override String get hasBeenDefeated => '{enemy}が満足して帰りました！';
	@override String get fallsToGround => '{enemy}が笑い疲れて、横になりました。';
	@override String get noLongerThreat => '{enemy}はもはや脅威ではありません。';
	@override String get entersCombat => '{ally}がエンジョイモードに入りました！';
	@override String get preparesForBattle => '{ally}が遊びの準備をしています！';
	@override String get readiesForCombat => '{ally}が遊びに備えています！';
	@override String get returnsToFollowing => '{ally}があなたに従うために戻ってきました。';
	@override String get comesBack => '{ally}があなたの元に戻ってきました。';
	@override String get resumesFollowing => '{ally}が従うことを再開しました。';
	@override String get looksSatisfied => '{ally}が満足そうに見えて去っていきました。';
	@override String get seemsContent => '{ally}が満足そうに見えて立ち去りました。';
	@override String get appearsFullfilled => '{ally}が充実した様子で去っていきました。';
	@override String get looksContent => '{ally}がより満足そうに見えます。';
	@override String get seemsPleased => '{ally}が状況に満足しているようです。';
	@override String get appearsHappier => '{ally}がより幸せそうに見えます。';
	@override String get looksLessSatisfied => '{ally}があまり満足していないようです。';
	@override String get seemsTroubled => '{ally}が困っているようです。';
	@override String get appearsUnhappy => '{ally}が不満そうに見えます。';
	@override String get allyDefeatedSatisfied => '{ally}が帰りましたが、奉仕に満足しています。';
	@override String get combatStarted => '{ally}が{enemy}とラップバトルを開始しました！';
	@override String get combatConcluded => 'ダンスバトルが終了しました。';
	@override String get allyVictory => 'あなたの味方が勝利しました！';
	@override String get enemyVictory => 'Enemyがあなたの味方を倒しました。';
	@override String get combatDraw => 'ダンスは互角で終わりました。';
}

// Path: candyTypes.candyBar
class _StringsCandyTypesCandyBarJa extends _StringsCandyTypesCandyBarEn {
	_StringsCandyTypesCandyBarJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get name => 'キャンディバー';
	@override String get description => '20ポイントの体力を回復する甘いキャンディバー';
}

// Path: candyTypes.chocolate
class _StringsCandyTypesChocolateJa extends _StringsCandyTypesChocolateEn {
	_StringsCandyTypesChocolateJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get name => 'チョコレート';
	@override String get description => '最大体力を永久に10ポイント増加させるリッチなチョコレート';
}

// Path: candyTypes.cookie
class _StringsCandyTypesCookieJa extends _StringsCandyTypesCookieEn {
	_StringsCandyTypesCookieJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get name => 'クッキー';
	@override String get description => '18ポイントの体力を回復するサクサククッキー';
}

// Path: candyTypes.cupcake
class _StringsCandyTypesCupcakeJa extends _StringsCandyTypesCupcakeEn {
	_StringsCandyTypesCupcakeJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get name => 'カップケーキ';
	@override String get description => '20ターンの間仲間の戦闘力を向上させる美味しいカップケーキ';
}

// Path: candyTypes.donut
class _StringsCandyTypesDonutJa extends _StringsCandyTypesDonutEn {
	_StringsCandyTypesDonutJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get name => 'ドーナツ';
	@override String get description => '15ポイントの体力を回復するグレーズドーナツ';
}

// Path: candyTypes.iceCream
class _StringsCandyTypesIceCreamJa extends _StringsCandyTypesIceCreamEn {
	_StringsCandyTypesIceCreamJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get name => 'アイスクリーム';
	@override String get description => '10ターンの間近くの敵を凍らせる冷たいアイスクリーム';
}

// Path: candyTypes.lollipop
class _StringsCandyTypesLollipopJa extends _StringsCandyTypesLollipopEn {
	_StringsCandyTypesLollipopJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get name => 'ロリポップ';
	@override String get description => '22ポイントの体力を回復するカラフルなロリポップ';
}

// Path: candyTypes.popsicle
class _StringsCandyTypesPopsicleJa extends _StringsCandyTypesPopsicleEn {
	_StringsCandyTypesPopsicleJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get name => 'アイスキャンディ';
	@override String get description => '12ポイントの体力を回復する爐しいアイスキャンディ';
}

// Path: candyTypes.gingerbread
class _StringsCandyTypesGingerbreadJa extends _StringsCandyTypesGingerbreadEn {
	_StringsCandyTypesGingerbreadJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get name => 'ジンジャーブレッド';
	@override String get description => '15ターンの間壁を透して見ることができる魔法のジンジャーブレッド';
}

// Path: candyTypes.muffin
class _StringsCandyTypesMuffinJa extends _StringsCandyTypesMuffinEn {
	_StringsCandyTypesMuffinJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get name => 'マフィン';
	@override String get description => '25ポイントの体力を回復するボリュームあるマフィン';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Strings {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'game.title': return 'Kiro Halloween Game';
			case 'story.title': return 'Kiro\'s Story';
			case 'story.text': return 'Kiro, a ghost troubled by not being scary enough, had set his goal to frighten the Vampire Master.\n\nHowever, tonight is Halloween night. Children are coming to seek candy...\n\nCan Kiro collect candy, make friends, and ultimately achieve victory over the Vampire Master?';
			case 'story.startAdventure': return '🚀 Start Adventure';
			case 'story.tapToSkip': return 'Tap to skip';
			case 'ui.inventory': return 'Inventory';
			case 'combat.bossAbilities.charge': return 'The Boss laughs loudly! The ground trembles!';
			case 'combat.bossAbilities.areaAttack': return 'The Boss sneezes! Shockwaves spread everywhere!';
			case 'combat.bossAbilities.regeneration': return 'The Boss eats a blood orange! {healAmount} health restored!';
			case 'combat.bossAbilities.summonMinions': return 'The Boss calls lost children! New threats emerge!';
			case 'combat.enemyAttacks.withDamage.0': return 'The {} gives Kiro an unexpected hug! It\'s surprisingly warm! ({} damage)';
			case 'combat.enemyAttacks.withDamage.1': return 'The {} tries to surprise Kiro! Boo! ({} damage)';
			case 'combat.enemyAttacks.withDamage.2': return 'The {} tries to high-five Kiro, but ghosts are tricky to touch! ({} damage)';
			case 'combat.enemyAttacks.withDamage.3': return 'The {} attempts a tickle attack on Kiro! ({} damage)';
			case 'combat.enemyAttacks.withDamage.4': return 'A curious {} tries to lift Kiro\'s ghostly sheet! ({} damage)';
			case 'combat.enemyAttacks.withDamage.5': return 'Kiro tries to scare the {} but just gets laughed at! ({} damage)';
			case 'combat.enemyAttacks.withDamage.6': return 'Kiro is frightened by the {} asking for candy! ({} damage)';
			case 'combat.enemyAttacks.withoutDamage.0': return 'The {} tries to hug Kiro but he turns transparent at the last second! (0 damage)';
			case 'combat.enemyAttacks.withoutDamage.1': return 'The {} tries to surprise Kiro but it wasn\'t scary at all! (0 damage)';
			case 'combat.enemyAttacks.withoutDamage.2': return 'The {} misses completely! (0 damage)';
			case 'combat.playerAttacks.withDamage.0': return 'Kiro gives a scary BOO! Enemy is frightened! ({} damage)';
			case 'combat.playerAttacks.withDamage.1': return 'Kiro\'s ghostly appeal! Enemy is trembling with fear! ({} damage)';
			case 'combat.playerAttacks.withDamage.2': return 'Kiro\'s friendly hug makes Enemy too embarrassed to fight! ({} damage)';
			case 'combat.playerAttacks.withDamage.3': return 'Kiro\'s ethereal tickle attack is irresistible! Enemy is laughing loudly! ({} damage)';
			case 'combat.playerAttacks.withDamage.4': return 'Enemy is charmed by Kiro\'s ghostly dance! ({} damage)';
			case 'combat.playerAttacks.withoutDamage.0': return 'Kiro tries to scare but Enemy just laughs! ({} damage)';
			case 'combat.playerAttacks.withoutDamage.1': return 'Kiro\'s ghost touch is noticed but not very effective! ({} damage)';
			case 'combat.playerAttacks.withoutDamage.2': return 'Enemy feels a gentle ghostly breeze from Kiro\'s approach! ({} damage)';
			case 'combat.playerAttacks.withoutDamage.3': return 'Kiro\'s gentle BOO confuses Enemy slightly! ({} damage)';
			case 'combat.messages.allyDefeatsEnemyStrike': return '{ally}\'s powerful hug makes {enemy} no longer a threat!';
			case 'combat.messages.allyEmergesVictorious': return '{ally} satisfies {enemy}!';
			case 'combat.messages.allyOvercomes': return '{ally} wins the arm wrestling match against {enemy}!';
			case 'combat.messages.allyDefeatedBy': return '{ally} is satisfied by {enemy} and returns home!';
			case 'combat.messages.enemyOvercomes': return '{enemy} wins the dance battle against {ally}!';
			case 'combat.messages.allyFalls': return '{ally} is satisfied by {enemy}!';
			case 'combat.messages.bothDefeatEachOther': return '{ally} and {enemy} are satisfied and go home together!';
			case 'combat.messages.bothFallInCombat': return '{ally} and {enemy} become friends and go home together!';
			case 'combat.messages.bothDefeated': return '{ally} and {enemy} acknowledge each other!';
			case 'combat.messages.exchangeBlows': return 'Intense beatbox battle between {ally} and {enemy}!';
			case 'combat.messages.battleContinues': return 'The dance battle between {ally} and {enemy} continues!';
			case 'combat.messages.fightFiercely': return 'Intense joke battle between {ally} and {enemy}!';
			case 'combat.messages.engagesInCombat': return '{ally} starts a dance battle with {enemy}!';
			case 'combat.messages.movesToAttack': return '{ally} moves to play with {enemy}!';
			case 'combat.messages.confronts': return '{ally} confronts {enemy}!';
			case 'combat.messages.hasBeenDefeated': return '{enemy} is satisfied and goes home!';
			case 'combat.messages.fallsToGround': return '{enemy} is tired from laughing and lies down.';
			case 'combat.messages.noLongerThreat': return '{enemy} is no longer a threat.';
			case 'combat.messages.entersCombat': return '{ally} enters enjoy mode!';
			case 'combat.messages.preparesForBattle': return '{ally} prepares to play!';
			case 'combat.messages.readiesForCombat': return '{ally} gets ready to play!';
			case 'combat.messages.returnsToFollowing': return '{ally} returns to following you.';
			case 'combat.messages.comesBack': return '{ally} comes back to your side.';
			case 'combat.messages.resumesFollowing': return '{ally} resumes following.';
			case 'combat.messages.looksSatisfied': return '{ally} looks satisfied and wanders away.';
			case 'combat.messages.seemsContent': return '{ally} seems content and departs.';
			case 'combat.messages.appearsFullfilled': return '{ally} appears fulfilled and leaves.';
			case 'combat.messages.looksContent': return '{ally} looks more content.';
			case 'combat.messages.seemsPleased': return '{ally} seems pleased with the situation.';
			case 'combat.messages.appearsHappier': return '{ally} appears happier.';
			case 'combat.messages.looksLessSatisfied': return '{ally} looks less satisfied.';
			case 'combat.messages.seemsTroubled': return '{ally} seems troubled.';
			case 'combat.messages.appearsUnhappy': return '{ally} appears unhappy.';
			case 'combat.messages.allyDefeatedSatisfied': return '{ally} has gone home but feels satisfied with their service.';
			case 'combat.messages.combatStarted': return '{ally} starts a rap battle with {enemy}!';
			case 'combat.messages.combatConcluded': return 'The dance battle has concluded.';
			case 'combat.messages.allyVictory': return 'Your ally emerges victorious!';
			case 'combat.messages.enemyVictory': return 'The enemy has defeated your ally.';
			case 'combat.messages.combatDraw': return 'The dance ends in a tie.';
			case 'dialogue.continueButton': return 'Continue';
			case 'items.eat': return 'Eat';
			case 'items.give': return 'Give';
			case 'items.noCandies': return 'No candies in inventory';
			case 'items.activeEffects': return 'Active Effects';
			case 'items.turns': return 'turns';
			case 'items.helpText': return 'Tap an item for options. Press I to close.';
			case 'items.inventoryFull': return 'Inventory Full!';
			case 'items.healthBoost': return '+{value} Health';
			case 'items.maxHealthIncrease': return '+{value} Max Health';
			case 'items.speedBoost': return 'Speed Boost!';
			case 'items.allyPower': return 'Ally Power!';
			case 'items.specialPower': return 'Special Power!';
			case 'items.statBoost': return 'Stat Boost!';
			case 'candyCollection.messages.0': return 'Kiro finds a {name}! {description}';
			case 'candyCollection.messages.1': return 'A glowing {name} catches Kiro\'s attention. Sweet supernatural treat!';
			case 'candyCollection.messages.2': return 'Kiro discovers a magical {name} that sparkles with otherworldly flavor.';
			case 'candyCollection.messages.3': return 'The {name} makes Kiro glow brighter with ghostly happiness.';
			case 'candyCollection.messages.4': return 'Kiro picked up {name}! Looks delicious!';
			case 'candyCollection.inventoryFullMessage': return 'Kiro\'s inventory is full! Can\'t pick up more candy.';
			case 'candyTypes.candyBar.name': return 'Candy Bar';
			case 'candyTypes.candyBar.description': return 'A sweet candy bar that restores 20 health points';
			case 'candyTypes.chocolate.name': return 'Chocolate';
			case 'candyTypes.chocolate.description': return 'Rich chocolate that permanently increases max health by 10';
			case 'candyTypes.cookie.name': return 'Cookie';
			case 'candyTypes.cookie.description': return 'A crispy cookie that restores 18 health points';
			case 'candyTypes.cupcake.name': return 'Cupcake';
			case 'candyTypes.cupcake.description': return 'A delicious cupcake that boosts ally combat strength for 20 turns';
			case 'candyTypes.donut.name': return 'Donut';
			case 'candyTypes.donut.description': return 'A glazed donut that restores 15 health points';
			case 'candyTypes.iceCream.name': return 'Ice Cream';
			case 'candyTypes.iceCream.description': return 'Cool ice cream that freezes nearby enemies for 10 turns';
			case 'candyTypes.lollipop.name': return 'Lollipop';
			case 'candyTypes.lollipop.description': return 'A colorful lollipop that restores 22 health points';
			case 'candyTypes.popsicle.name': return 'Popsicle';
			case 'candyTypes.popsicle.description': return 'A refreshing popsicle that restores 12 health points';
			case 'candyTypes.gingerbread.name': return 'Gingerbread';
			case 'candyTypes.gingerbread.description': return 'Magical gingerbread that allows seeing through walls for 15 turns';
			case 'candyTypes.muffin.name': return 'Muffin';
			case 'candyTypes.muffin.description': return 'A hearty muffin that restores 25 health points';
			case 'giftUI.giveCandy': return 'Give Candy to {enemyName}';
			case 'giftUI.chooseCandyTitle': return 'Choose candy to give:';
			case 'giftUI.cancel': return 'Cancel';
			case 'giftUI.giveGift': return 'Give Gift';
			case 'giftUI.health': return 'Health';
			default: return null;
		}
	}
}

extension on _StringsJa {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'game.title': return 'キロ ハロウィン ゲーム';
			case 'story.title': return 'Kiro\'s Story';
			case 'story.text': return '自分が怖くないことに悩んでいたおばけのKiroは、ヴァンパイアマスターを怖がらせることを目標にしていた。\n\nしかし、今日はハロウィンの夜。子供達がお菓子を求めてやってくる…\n\n果たしてKiroは、お菓子を集め、仲間を作り、最終的にヴァンパイアマスターに勝利できるのか？';
			case 'story.startAdventure': return '🚀 冒険を始める';
			case 'story.tapToSkip': return 'タップでスキップ';
			case 'ui.inventory': return 'アイテム';
			case 'combat.bossAbilities.charge': return 'ボスが大声で笑った！ 大地が震える！';
			case 'combat.bossAbilities.areaAttack': return 'ボスがくしゃみをした！ 広範囲に衝撃が走る！';
			case 'combat.bossAbilities.regeneration': return 'ボスがブラッドオレンジを食べた！ {healAmount}の体力が復活！';
			case 'combat.bossAbilities.summonMinions': return 'ボスが迷子の子供を呼び寄せた！ 新たな脅威が現れる！';
			case 'combat.enemyAttacks.withDamage.0': return '{}がキロにハグをしました！驚くほど温かいです！（{}ダメージ）';
			case 'combat.enemyAttacks.withDamage.1': return '{}がキロを驚かせようとしました！バアー！（{}ダメージ）';
			case 'combat.enemyAttacks.withDamage.2': return '{}がキロとハイタッチしようとしましたが、幽霊に触るのは難しいようです！（{}ダメージ）';
			case 'combat.enemyAttacks.withDamage.3': return '{}がキロにくすぐり攻撃を試みました！（{}ダメージ）';
			case 'combat.enemyAttacks.withDamage.4': return '好奇心旺盛な{}がキロの布をめくろうとしました！（{}ダメージ）';
			case 'combat.enemyAttacks.withDamage.5': return 'キロは{}を驚かせようとしましたが、笑われるだけでした！（{}ダメージ）';
			case 'combat.enemyAttacks.withDamage.6': return 'キロはお菓子をねだる{}に恐怖しました！（{}ダメージ）';
			case 'combat.enemyAttacks.withoutDamage.0': return '{}がキロにハグしようとしましたが、すんでのところで透明化しました！（0ダメージ）';
			case 'combat.enemyAttacks.withoutDamage.1': return '{}がキロを驚かせようとしましたが、全然怖くなかったです！（0ダメージ）';
			case 'combat.enemyAttacks.withoutDamage.2': return '{}の！（0ダメージ）';
			case 'combat.playerAttacks.withDamage.0': return 'キロが怖い「バアー！」を放ちます！Enemyは怖がりました！（{}ダメージ）';
			case 'combat.playerAttacks.withDamage.1': return 'キロの幽霊アピール！Enemyは恐怖で震えています！（{}ダメージ）';
			case 'combat.playerAttacks.withDamage.2': return 'キロのフレンドリーなハグでEnemyは恥ずかしくて戦えません！（{}ダメージ）';
			case 'combat.playerAttacks.withDamage.3': return 'キロのエーテルなくすぐり攻撃がたまりません！Enemyは大笑いしています！（{}ダメージ）';
			case 'combat.playerAttacks.withDamage.4': return 'Enemyはキロの幽霊ダンスに魅了されています！（{}ダメージ）';
			case 'combat.playerAttacks.withoutDamage.0': return 'キロは怖がらせようとしましたが、Enemyは笑うだけでした！（{}ダメージ）';
			case 'combat.playerAttacks.withoutDamage.1': return 'キロのお化けタッチは気づかれてしまい、あまり効果的ではありませんでした！（{}ダメージ）';
			case 'combat.playerAttacks.withoutDamage.2': return 'Enemyはキロのアプローチから優しい幽霊の風を感じました！（{}ダメージ）';
			case 'combat.playerAttacks.withoutDamage.3': return 'キロの優しい「バアー！」はEnemyを少し混乱させました！（{}ダメージ）';
			case 'combat.messages.allyDefeatsEnemyStrike': return '{ally}の強力なハグで{enemy}はもはや脅威ではありません！';
			case 'combat.messages.allyEmergesVictorious': return '{ally}が{enemy}を満足させました！';
			case 'combat.messages.allyOvercomes': return '{ally}が{enemy}との腕相撲で勝ちました！';
			case 'combat.messages.allyDefeatedBy': return '{ally}が{enemy}によって満足させられ帰りました！';
			case 'combat.messages.enemyOvercomes': return '{enemy}が{ally}とのダンス勝負に勝ちました！';
			case 'combat.messages.allyFalls': return '{ally}が{enemy}に満足させられました！';
			case 'combat.messages.bothDefeatEachOther': return '{ally}と{enemy}は満足して一緒に帰りました！';
			case 'combat.messages.bothFallInCombat': return '{ally}と{enemy}が友達になり一緒に帰りました！';
			case 'combat.messages.bothDefeated': return '{ally}と{enemy}はお互いを認め合いました！';
			case 'combat.messages.exchangeBlows': return '{ally}と{enemy}の激しいビートボックスバトル！';
			case 'combat.messages.battleContinues': return '{ally}と{enemy}とのダンス対決は続いています！';
			case 'combat.messages.fightFiercely': return '{ally}と{enemy}との激しいジョークバトル！';
			case 'combat.messages.engagesInCombat': return '{ally}が{enemy}とダンスバトルを開始しました！';
			case 'combat.messages.movesToAttack': return '{ally}が{enemy}と遊ぶために動きました！';
			case 'combat.messages.confronts': return '{ally}が{enemy}に立ち向かいます！';
			case 'combat.messages.hasBeenDefeated': return '{enemy}が満足して帰りました！';
			case 'combat.messages.fallsToGround': return '{enemy}が笑い疲れて、横になりました。';
			case 'combat.messages.noLongerThreat': return '{enemy}はもはや脅威ではありません。';
			case 'combat.messages.entersCombat': return '{ally}がエンジョイモードに入りました！';
			case 'combat.messages.preparesForBattle': return '{ally}が遊びの準備をしています！';
			case 'combat.messages.readiesForCombat': return '{ally}が遊びに備えています！';
			case 'combat.messages.returnsToFollowing': return '{ally}があなたに従うために戻ってきました。';
			case 'combat.messages.comesBack': return '{ally}があなたの元に戻ってきました。';
			case 'combat.messages.resumesFollowing': return '{ally}が従うことを再開しました。';
			case 'combat.messages.looksSatisfied': return '{ally}が満足そうに見えて去っていきました。';
			case 'combat.messages.seemsContent': return '{ally}が満足そうに見えて立ち去りました。';
			case 'combat.messages.appearsFullfilled': return '{ally}が充実した様子で去っていきました。';
			case 'combat.messages.looksContent': return '{ally}がより満足そうに見えます。';
			case 'combat.messages.seemsPleased': return '{ally}が状況に満足しているようです。';
			case 'combat.messages.appearsHappier': return '{ally}がより幸せそうに見えます。';
			case 'combat.messages.looksLessSatisfied': return '{ally}があまり満足していないようです。';
			case 'combat.messages.seemsTroubled': return '{ally}が困っているようです。';
			case 'combat.messages.appearsUnhappy': return '{ally}が不満そうに見えます。';
			case 'combat.messages.allyDefeatedSatisfied': return '{ally}が帰りましたが、奉仕に満足しています。';
			case 'combat.messages.combatStarted': return '{ally}が{enemy}とラップバトルを開始しました！';
			case 'combat.messages.combatConcluded': return 'ダンスバトルが終了しました。';
			case 'combat.messages.allyVictory': return 'あなたの味方が勝利しました！';
			case 'combat.messages.enemyVictory': return 'Enemyがあなたの味方を倒しました。';
			case 'combat.messages.combatDraw': return 'ダンスは互角で終わりました。';
			case 'dialogue.continueButton': return '続ける';
			case 'items.eat': return '食べる';
			case 'items.give': return 'あげる';
			case 'items.noCandies': return 'インベントリにキャンディがありません';
			case 'items.activeEffects': return '有効な効果';
			case 'items.turns': return 'ターン';
			case 'items.helpText': return 'アイテムをタップしてオプションを表示。Iキーで閉じます。';
			case 'items.inventoryFull': return 'インベントリがいっぱいです！';
			case 'items.healthBoost': return '+{value} 体力';
			case 'items.maxHealthIncrease': return '+{value} 最大体力';
			case 'items.speedBoost': return 'スピードアップ！';
			case 'items.allyPower': return '仲間の力！';
			case 'items.specialPower': return '特殊能力！';
			case 'items.statBoost': return 'ステータスアップ！';
			case 'candyCollection.messages.0': return 'キロが{name}を見つけました！{description}';
			case 'candyCollection.messages.1': return '光る{name}がキロの注意を引きました。甘い超自然的な御馳走です！';
			case 'candyCollection.messages.2': return 'キロが異世界の味でキラキラ光る魔法の{name}を発見しました。';
			case 'candyCollection.messages.3': return '{name}でキロが幽霊の幸せでより明るく光ります。';
			case 'candyCollection.messages.4': return 'キロが{name}を拾いました！美味しそうです！';
			case 'candyCollection.inventoryFullMessage': return 'キロのインベントリがいっぱいです！これ以上キャンディを拾えません。';
			case 'candyTypes.candyBar.name': return 'キャンディバー';
			case 'candyTypes.candyBar.description': return '20ポイントの体力を回復する甘いキャンディバー';
			case 'candyTypes.chocolate.name': return 'チョコレート';
			case 'candyTypes.chocolate.description': return '最大体力を永久に10ポイント増加させるリッチなチョコレート';
			case 'candyTypes.cookie.name': return 'クッキー';
			case 'candyTypes.cookie.description': return '18ポイントの体力を回復するサクサククッキー';
			case 'candyTypes.cupcake.name': return 'カップケーキ';
			case 'candyTypes.cupcake.description': return '20ターンの間仲間の戦闘力を向上させる美味しいカップケーキ';
			case 'candyTypes.donut.name': return 'ドーナツ';
			case 'candyTypes.donut.description': return '15ポイントの体力を回復するグレーズドーナツ';
			case 'candyTypes.iceCream.name': return 'アイスクリーム';
			case 'candyTypes.iceCream.description': return '10ターンの間近くの敵を凍らせる冷たいアイスクリーム';
			case 'candyTypes.lollipop.name': return 'ロリポップ';
			case 'candyTypes.lollipop.description': return '22ポイントの体力を回復するカラフルなロリポップ';
			case 'candyTypes.popsicle.name': return 'アイスキャンディ';
			case 'candyTypes.popsicle.description': return '12ポイントの体力を回復する爐しいアイスキャンディ';
			case 'candyTypes.gingerbread.name': return 'ジンジャーブレッド';
			case 'candyTypes.gingerbread.description': return '15ターンの間壁を透して見ることができる魔法のジンジャーブレッド';
			case 'candyTypes.muffin.name': return 'マフィン';
			case 'candyTypes.muffin.description': return '25ポイントの体力を回復するボリュームあるマフィン';
			case 'giftUI.giveCandy': return '{enemyName}にキャンディをあげる';
			case 'giftUI.chooseCandyTitle': return 'あげるキャンディを選んでください：';
			case 'giftUI.cancel': return 'キャンセル';
			case 'giftUI.giveGift': return 'プレゼントする';
			case 'giftUI.health': return '体力';
			default: return null;
		}
	}
}
