/// Generated file. Do not edit.
///
/// Original: assets/l10n
/// To regenerate, run: `dart run slang`
///
/// Locales: 2
/// Strings: 214 (107 per locale)
///
/// Built on 2025-09-08 at 14:22 UTC

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
	late final _StringsUiEn ui = _StringsUiEn._(_root);
	late final _StringsCombatEn combat = _StringsCombatEn._(_root);
	late final _StringsDialogueEn dialogue = _StringsDialogueEn._(_root);
	late final _StringsItemsEn items = _StringsItemsEn._(_root);
	late final _StringsEnemiesEn enemies = _StringsEnemiesEn._(_root);
	late final _StringsMessagesEn messages = _StringsMessagesEn._(_root);
	late final _StringsDebugEn debug = _StringsDebugEn._(_root);
}

// Path: game
class _StringsGameEn {
	_StringsGameEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get title => 'Kiro Halloween Game';
	String get start => 'Start Game';
	String get pause => 'Pause';
	String get resume => 'Resume';
	String get quit => 'Quit';
	String get gameOver => 'Game Over';
	String get victory => 'Victory!';
}

// Path: ui
class _StringsUiEn {
	_StringsUiEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get health => 'Health';
	String get score => 'Score';
	String get level => 'Level';
	String get inventory => 'Inventory';
	String get back => 'Back';
	String get confirm => 'Confirm';
	String get cancel => 'Cancel';
}

// Path: combat
class _StringsCombatEn {
	_StringsCombatEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get attack => 'Attack';
	String get defend => 'Defend';
	String get run => 'Run';
	String get victory => 'You won!';
	String get defeat => 'You were defeated!';
	String get enemyDefeated => 'Enemy defeated!';
	String get takeDamage => 'You took {damage} damage';
	String get dealDamage => 'You dealt {damage} damage';
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
	String get skip => 'Skip';
	String get close => 'Close';
}

// Path: items
class _StringsItemsEn {
	_StringsItemsEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get candy => 'Candy';
	String get collected => 'Collected {item}!';
	String get useItem => 'Use Item';
	String get noItems => 'No items available';
}

// Path: enemies
class _StringsEnemiesEn {
	_StringsEnemiesEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get ghost => 'Ghost';
	String get skeleton => 'Skeleton';
	String get zombie => 'Zombie';
}

// Path: messages
class _StringsMessagesEn {
	_StringsMessagesEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get welcome => 'Welcome to Kiro Halloween Game!';
	String get gameStarted => 'Game started!';
	String get levelComplete => 'Level completed!';
	String get newLevel => 'Level {level}';
}

// Path: debug
class _StringsDebugEn {
	_StringsDebugEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get gameLoopInitialized => 'GameLoopManager: Initialized with player at {}';
	String get turnBasedSystemInitialized => 'GameLoopManager: Turn-based system initialized';
	String get turnBasedSystemStopped => 'GameLoopManager: Turn-based system stopped';
	String get combatEncountersProcessed => 'GameLoopManager: Processed {} combat encounters';
	String get combatResult => 'GameLoopManager: Combat result - {}';
	String get enemyDefeatedRemoved => 'GameLoopManager: Enemy {} defeated and removed';
	String get allyDefeated => 'GameLoopManager: Ally {} defeated';
	String get playerDefeatedEnemy => 'GameLoopManager: Player defeated enemy with directional attack';
	String get processingAdjacentCombat => 'GameLoopManager: Processing adjacent combat with {} enemies';
	String get enemyAttacksPlayer => 'GameLoopManager: {} attacks player for {} damage';
	String get playerDefeated => 'GameLoopManager: Player was defeated!';
	String get processingTurn => 'GameLoopManager: Processing turn after player move';
	String get turnCompleted => 'GameLoopManager: Turn completed';
	String get errorInTurnProcessing => 'GameLoopManager: Error in turn processing: {}';
	String get convertedEnemyToAlly => 'GameLoopManager: Converted enemy {} to ally';
}

// Path: combat.enemyAttacks
class _StringsCombatEnemyAttacksEn {
	_StringsCombatEnemyAttacksEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	List<String> get withDamage => [
		'The {} gives Kiro an unexpected hug! It\'s surprisingly warm! ({} damage)',
		'A friendly {} bumps into Kiro playfully! ({} damage)',
		'The {} tries to high-five Kiro, but ghosts are tricky to touch! ({} damage)',
		'The {} attempts a tickle attack on the floating ghost! ({} damage)',
		'A curious {} pokes at Kiro\'s ghostly form! ({} damage)',
	];
	List<String> get withoutDamage => [
		'The {} waves at Kiro but misses the ghostly target! (0 damage)',
		'A confused {} swings at empty air where Kiro was floating! (0 damage)',
		'The {}\'s friendly gesture goes right through Kiro! (0 damage)',
	];
}

// Path: combat.playerAttacks
class _StringsCombatPlayerAttacksEn {
	_StringsCombatPlayerAttacksEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	List<String> get withDamage => [
		'Kiro gives a spooky BOO! The enemy runs away scared! ({} damage)',
		'Kiro\'s ghostly presence overwhelms the foe! They vanish in fright! ({} damage)',
		'A friendly ghostly hug makes the enemy too embarrassed to continue! ({} damage)',
		'Kiro\'s ethereal tickle attack is too much! The enemy giggles away! ({} damage)',
		'The enemy is so charmed by Kiro\'s ghostly dance, they leave peacefully! ({} damage)',
	];
	List<String> get withoutDamage => [
		'Kiro attempts a spooky scare, but the enemy just laughs! ({} damage)',
		'Kiro\'s ghostly boop is noticed but not very effective! ({} damage)',
		'The enemy feels a gentle ghostly breeze from Kiro\'s approach! ({} damage)',
		'Kiro\'s friendly ghost wave confuses the enemy slightly! ({} damage)',
	];
}

// Path: combat.messages
class _StringsCombatMessagesEn {
	_StringsCombatMessagesEn._(this._root);

	final Strings _root; // ignore: unused_field

	// Translations
	String get allyDefeatsEnemyStrike => '{ally} defeats {enemy} with a powerful strike!';
	String get allyEmergesVictorious => '{ally} emerges victorious against {enemy}!';
	String get allyOvercomes => '{ally} overcomes {enemy} in battle!';
	String get allyDefeatedBy => '{ally} is defeated by {enemy}.';
	String get enemyOvercomes => '{enemy} overcomes {ally} in combat.';
	String get allyFalls => '{ally} falls to {enemy}.';
	String get bothDefeatEachOther => '{ally} and {enemy} defeat each other!';
	String get bothFallInCombat => 'Both {ally} and {enemy} fall in combat!';
	String get bothDefeated => '{ally} and {enemy} are both defeated!';
	String get exchangeBlows => '{ally} and {enemy} exchange blows!';
	String get battleContinues => 'The battle between {ally} and {enemy} continues!';
	String get fightFiercely => '{ally} and {enemy} fight fiercely!';
	String get engagesInCombat => '{ally} engages {enemy} in combat!';
	String get movesToAttack => '{ally} moves to attack {enemy}!';
	String get confronts => '{ally} confronts {enemy}!';
	String get hasBeenDefeated => '{enemy} has been defeated!';
	String get fallsToGround => '{enemy} falls to the ground, defeated.';
	String get noLongerThreat => '{enemy} is no longer a threat.';
	String get entersCombat => '{ally} enters combat mode!';
	String get preparesForBattle => '{ally} prepares for battle!';
	String get readiesForCombat => '{ally} readies for combat!';
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
	String get allyDefeatedSatisfied => '{ally} has been defeated but feels satisfied with their service.';
	String get combatStarted => '{ally} engages {enemy} in combat!';
	String get combatConcluded => 'The combat has concluded.';
	String get allyVictory => 'Your ally emerges victorious!';
	String get enemyVictory => 'The enemy has defeated your ally.';
	String get combatDraw => 'The battle ends in a stalemate.';
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
	@override late final _StringsUiJa ui = _StringsUiJa._(_root);
	@override late final _StringsCombatJa combat = _StringsCombatJa._(_root);
	@override late final _StringsDialogueJa dialogue = _StringsDialogueJa._(_root);
	@override late final _StringsItemsJa items = _StringsItemsJa._(_root);
	@override late final _StringsEnemiesJa enemies = _StringsEnemiesJa._(_root);
	@override late final _StringsMessagesJa messages = _StringsMessagesJa._(_root);
	@override late final _StringsDebugJa debug = _StringsDebugJa._(_root);
}

// Path: game
class _StringsGameJa extends _StringsGameEn {
	_StringsGameJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'キロ ハロウィン ゲーム';
	@override String get start => 'ゲーム開始';
	@override String get pause => '一時停止';
	@override String get resume => '再開';
	@override String get quit => '終了';
	@override String get gameOver => 'ゲームオーバー';
	@override String get victory => '勝利！';
}

// Path: ui
class _StringsUiJa extends _StringsUiEn {
	_StringsUiJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get health => '体力';
	@override String get score => 'スコア';
	@override String get level => 'レベル';
	@override String get inventory => 'アイテム';
	@override String get back => '戻る';
	@override String get confirm => '確認';
	@override String get cancel => 'キャンセル';
}

// Path: combat
class _StringsCombatJa extends _StringsCombatEn {
	_StringsCombatJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get attack => '攻撃';
	@override String get defend => '防御';
	@override String get run => '逃げる';
	@override String get victory => '勝利しました！';
	@override String get defeat => '敗北しました！';
	@override String get enemyDefeated => '敵を倒しました！';
	@override String get takeDamage => '{damage}のダメージを受けました';
	@override String get dealDamage => '{damage}のダメージを与えました';
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
	@override String get skip => 'スキップ';
	@override String get close => '閉じる';
}

// Path: items
class _StringsItemsJa extends _StringsItemsEn {
	_StringsItemsJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get candy => 'キャンディ';
	@override String get collected => '{item}を入手しました！';
	@override String get useItem => 'アイテム使用';
	@override String get noItems => 'アイテムがありません';
}

// Path: enemies
class _StringsEnemiesJa extends _StringsEnemiesEn {
	_StringsEnemiesJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get ghost => 'ゴースト';
	@override String get skeleton => 'スケルトン';
	@override String get zombie => 'ゾンビ';
}

// Path: messages
class _StringsMessagesJa extends _StringsMessagesEn {
	_StringsMessagesJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get welcome => 'キロ ハロウィン ゲームへようこそ！';
	@override String get gameStarted => 'ゲームが開始されました！';
	@override String get levelComplete => 'レベルクリア！';
	@override String get newLevel => 'レベル {level}';
}

// Path: debug
class _StringsDebugJa extends _StringsDebugEn {
	_StringsDebugJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get gameLoopInitialized => 'GameLoopManager: プレイヤーを{}で初期化しました';
	@override String get turnBasedSystemInitialized => 'GameLoopManager: ターンベースシステムが初期化されました';
	@override String get turnBasedSystemStopped => 'GameLoopManager: ターンベースシステムが停止されました';
	@override String get combatEncountersProcessed => 'GameLoopManager: {}の戦闘遭遇を処理しました';
	@override String get combatResult => 'GameLoopManager: 戦闘結果 - {}';
	@override String get enemyDefeatedRemoved => 'GameLoopManager: エネミー{}が倒され削除されました';
	@override String get allyDefeated => 'GameLoopManager: アライ{}が倒されました';
	@override String get playerDefeatedEnemy => 'GameLoopManager: プレイヤーが方向攻撃でエネミーを倒しました';
	@override String get processingAdjacentCombat => 'GameLoopManager: {}体のエネミーとの隣接戦闘を処理中';
	@override String get enemyAttacksPlayer => 'GameLoopManager: {}がプレイヤーに{}ダメージを与えました';
	@override String get playerDefeated => 'GameLoopManager: プレイヤーが倒されました！';
	@override String get processingTurn => 'GameLoopManager: プレイヤー移動後のターンを処理中';
	@override String get turnCompleted => 'GameLoopManager: ターン完了';
	@override String get errorInTurnProcessing => 'GameLoopManager: ターン処理でエラー: {}';
	@override String get convertedEnemyToAlly => 'GameLoopManager: エネミー{}をアライに変換しました';
}

// Path: combat.enemyAttacks
class _StringsCombatEnemyAttacksJa extends _StringsCombatEnemyAttacksEn {
	_StringsCombatEnemyAttacksJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override List<String> get withDamage => [
		'{}がキロに意外なハグをしました！驚くほど温かいです！（{}ダメージ）',
		'フレンドリーな{}がキロに遊び半分でぶつかってきました！（{}ダメージ）',
		'{}がキロとハイタッチしようとしましたが、幽霊に触るのは難しいようです！（{}ダメージ）',
		'{}が浮いている幽霊にくすぐり攻撃を試みました！（{}ダメージ）',
		'好奇心旺盛な{}がキロの幽霊の形を突いてきました！（{}ダメージ）',
	];
	@override List<String> get withoutDamage => [
		'{}がキロに手を振りましたが、幽霊のターゲットを外しました！（0ダメージ）',
		'困惑した{}がキロが浮いていた空中を振り回しました！（0ダメージ）',
		'{}のフレンドリーなジェスチャーがキロを素通りしました！（0ダメージ）',
	];
}

// Path: combat.playerAttacks
class _StringsCombatPlayerAttacksJa extends _StringsCombatPlayerAttacksEn {
	_StringsCombatPlayerAttacksJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override List<String> get withDamage => [
		'キロが怖い「ブー！」を放ちます！敵は怖がって逃げてしまいました！（{}ダメージ）',
		'キロの幽霊の存在感が敵を圧倒しました！敵は恐怖で消え去りました！（{}ダメージ）',
		'フレンドリーな幽霊のハグで敵は恥ずかしくて戦えません！（{}ダメージ）',
		'キロのエーテルなくすぐり攻撃がたまりません！敵は笑いながら去りました！（{}ダメージ）',
		'敵はキロの幽霊ダンスに魅了され、平和的に立ち去りました！（{}ダメージ）',
	];
	@override List<String> get withoutDamage => [
		'キロは怖がらせようとしましたが、敵は笑うだけでした！（{}ダメージ）',
		'キロの幽霊タッチは気づかれましたが、あまり効果的ではありませんでした！（{}ダメージ）',
		'敵はキロのアプローチから優しい幽霊の風を感じました！（{}ダメージ）',
		'キロのフレンドリーな幽霊の手振りが敵を少し混乱させました！（{}ダメージ）',
	];
}

// Path: combat.messages
class _StringsCombatMessagesJa extends _StringsCombatMessagesEn {
	_StringsCombatMessagesJa._(_StringsJa root) : this._root = root, super._(root);

	@override final _StringsJa _root; // ignore: unused_field

	// Translations
	@override String get allyDefeatsEnemyStrike => '{ally}が強力な一撃で{enemy}を倒しました！';
	@override String get allyEmergesVictorious => '{ally}が{enemy}との戦いで勝利しました！';
	@override String get allyOvercomes => '{ally}が戦闘で{enemy}を克服しました！';
	@override String get allyDefeatedBy => '{ally}が{enemy}によって倒されました。';
	@override String get enemyOvercomes => '{enemy}が戦闘で{ally}を打ち負かしました。';
	@override String get allyFalls => '{ally}が{enemy}に倒れました。';
	@override String get bothDefeatEachOther => '{ally}と{enemy}が互いを倒しました！';
	@override String get bothFallInCombat => '{ally}と{enemy}が共に戦闘で倒れました！';
	@override String get bothDefeated => '{ally}と{enemy}が両方とも倒されました！';
	@override String get exchangeBlows => '{ally}と{enemy}が打ち合いを繰り広げています！';
	@override String get battleContinues => '{ally}と{enemy}の戦いが続いています！';
	@override String get fightFiercely => '{ally}と{enemy}が激しく戦っています！';
	@override String get engagesInCombat => '{ally}が{enemy}と戦闘を開始しました！';
	@override String get movesToAttack => '{ally}が{enemy}を攻撃するために動きました！';
	@override String get confronts => '{ally}が{enemy}に立ち向かいます！';
	@override String get hasBeenDefeated => '{enemy}が倒されました！';
	@override String get fallsToGround => '{enemy}が地面に倒れ、敗北しました。';
	@override String get noLongerThreat => '{enemy}はもはや脅威ではありません。';
	@override String get entersCombat => '{ally}が戦闘モードに入りました！';
	@override String get preparesForBattle => '{ally}が戦闘の準備をしています！';
	@override String get readiesForCombat => '{ally}が戦闘に備えています！';
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
	@override String get allyDefeatedSatisfied => '{ally}が倒されましたが、奉仕に満足しています。';
	@override String get combatStarted => '{ally}が{enemy}と戦闘を開始しました！';
	@override String get combatConcluded => '戦闘が終了しました。';
	@override String get allyVictory => 'あなたの味方が勝利しました！';
	@override String get enemyVictory => '敵があなたの味方を倒しました。';
	@override String get combatDraw => '戦闘は互角で終わりました。';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Strings {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'game.title': return 'Kiro Halloween Game';
			case 'game.start': return 'Start Game';
			case 'game.pause': return 'Pause';
			case 'game.resume': return 'Resume';
			case 'game.quit': return 'Quit';
			case 'game.gameOver': return 'Game Over';
			case 'game.victory': return 'Victory!';
			case 'ui.health': return 'Health';
			case 'ui.score': return 'Score';
			case 'ui.level': return 'Level';
			case 'ui.inventory': return 'Inventory';
			case 'ui.back': return 'Back';
			case 'ui.confirm': return 'Confirm';
			case 'ui.cancel': return 'Cancel';
			case 'combat.attack': return 'Attack';
			case 'combat.defend': return 'Defend';
			case 'combat.run': return 'Run';
			case 'combat.victory': return 'You won!';
			case 'combat.defeat': return 'You were defeated!';
			case 'combat.enemyDefeated': return 'Enemy defeated!';
			case 'combat.takeDamage': return 'You took {damage} damage';
			case 'combat.dealDamage': return 'You dealt {damage} damage';
			case 'combat.enemyAttacks.withDamage.0': return 'The {} gives Kiro an unexpected hug! It\'s surprisingly warm! ({} damage)';
			case 'combat.enemyAttacks.withDamage.1': return 'A friendly {} bumps into Kiro playfully! ({} damage)';
			case 'combat.enemyAttacks.withDamage.2': return 'The {} tries to high-five Kiro, but ghosts are tricky to touch! ({} damage)';
			case 'combat.enemyAttacks.withDamage.3': return 'The {} attempts a tickle attack on the floating ghost! ({} damage)';
			case 'combat.enemyAttacks.withDamage.4': return 'A curious {} pokes at Kiro\'s ghostly form! ({} damage)';
			case 'combat.enemyAttacks.withoutDamage.0': return 'The {} waves at Kiro but misses the ghostly target! (0 damage)';
			case 'combat.enemyAttacks.withoutDamage.1': return 'A confused {} swings at empty air where Kiro was floating! (0 damage)';
			case 'combat.enemyAttacks.withoutDamage.2': return 'The {}\'s friendly gesture goes right through Kiro! (0 damage)';
			case 'combat.playerAttacks.withDamage.0': return 'Kiro gives a spooky BOO! The enemy runs away scared! ({} damage)';
			case 'combat.playerAttacks.withDamage.1': return 'Kiro\'s ghostly presence overwhelms the foe! They vanish in fright! ({} damage)';
			case 'combat.playerAttacks.withDamage.2': return 'A friendly ghostly hug makes the enemy too embarrassed to continue! ({} damage)';
			case 'combat.playerAttacks.withDamage.3': return 'Kiro\'s ethereal tickle attack is too much! The enemy giggles away! ({} damage)';
			case 'combat.playerAttacks.withDamage.4': return 'The enemy is so charmed by Kiro\'s ghostly dance, they leave peacefully! ({} damage)';
			case 'combat.playerAttacks.withoutDamage.0': return 'Kiro attempts a spooky scare, but the enemy just laughs! ({} damage)';
			case 'combat.playerAttacks.withoutDamage.1': return 'Kiro\'s ghostly boop is noticed but not very effective! ({} damage)';
			case 'combat.playerAttacks.withoutDamage.2': return 'The enemy feels a gentle ghostly breeze from Kiro\'s approach! ({} damage)';
			case 'combat.playerAttacks.withoutDamage.3': return 'Kiro\'s friendly ghost wave confuses the enemy slightly! ({} damage)';
			case 'combat.messages.allyDefeatsEnemyStrike': return '{ally} defeats {enemy} with a powerful strike!';
			case 'combat.messages.allyEmergesVictorious': return '{ally} emerges victorious against {enemy}!';
			case 'combat.messages.allyOvercomes': return '{ally} overcomes {enemy} in battle!';
			case 'combat.messages.allyDefeatedBy': return '{ally} is defeated by {enemy}.';
			case 'combat.messages.enemyOvercomes': return '{enemy} overcomes {ally} in combat.';
			case 'combat.messages.allyFalls': return '{ally} falls to {enemy}.';
			case 'combat.messages.bothDefeatEachOther': return '{ally} and {enemy} defeat each other!';
			case 'combat.messages.bothFallInCombat': return 'Both {ally} and {enemy} fall in combat!';
			case 'combat.messages.bothDefeated': return '{ally} and {enemy} are both defeated!';
			case 'combat.messages.exchangeBlows': return '{ally} and {enemy} exchange blows!';
			case 'combat.messages.battleContinues': return 'The battle between {ally} and {enemy} continues!';
			case 'combat.messages.fightFiercely': return '{ally} and {enemy} fight fiercely!';
			case 'combat.messages.engagesInCombat': return '{ally} engages {enemy} in combat!';
			case 'combat.messages.movesToAttack': return '{ally} moves to attack {enemy}!';
			case 'combat.messages.confronts': return '{ally} confronts {enemy}!';
			case 'combat.messages.hasBeenDefeated': return '{enemy} has been defeated!';
			case 'combat.messages.fallsToGround': return '{enemy} falls to the ground, defeated.';
			case 'combat.messages.noLongerThreat': return '{enemy} is no longer a threat.';
			case 'combat.messages.entersCombat': return '{ally} enters combat mode!';
			case 'combat.messages.preparesForBattle': return '{ally} prepares for battle!';
			case 'combat.messages.readiesForCombat': return '{ally} readies for combat!';
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
			case 'combat.messages.allyDefeatedSatisfied': return '{ally} has been defeated but feels satisfied with their service.';
			case 'combat.messages.combatStarted': return '{ally} engages {enemy} in combat!';
			case 'combat.messages.combatConcluded': return 'The combat has concluded.';
			case 'combat.messages.allyVictory': return 'Your ally emerges victorious!';
			case 'combat.messages.enemyVictory': return 'The enemy has defeated your ally.';
			case 'combat.messages.combatDraw': return 'The battle ends in a stalemate.';
			case 'dialogue.continueButton': return 'Continue';
			case 'dialogue.skip': return 'Skip';
			case 'dialogue.close': return 'Close';
			case 'items.candy': return 'Candy';
			case 'items.collected': return 'Collected {item}!';
			case 'items.useItem': return 'Use Item';
			case 'items.noItems': return 'No items available';
			case 'enemies.ghost': return 'Ghost';
			case 'enemies.skeleton': return 'Skeleton';
			case 'enemies.zombie': return 'Zombie';
			case 'messages.welcome': return 'Welcome to Kiro Halloween Game!';
			case 'messages.gameStarted': return 'Game started!';
			case 'messages.levelComplete': return 'Level completed!';
			case 'messages.newLevel': return 'Level {level}';
			case 'debug.gameLoopInitialized': return 'GameLoopManager: Initialized with player at {}';
			case 'debug.turnBasedSystemInitialized': return 'GameLoopManager: Turn-based system initialized';
			case 'debug.turnBasedSystemStopped': return 'GameLoopManager: Turn-based system stopped';
			case 'debug.combatEncountersProcessed': return 'GameLoopManager: Processed {} combat encounters';
			case 'debug.combatResult': return 'GameLoopManager: Combat result - {}';
			case 'debug.enemyDefeatedRemoved': return 'GameLoopManager: Enemy {} defeated and removed';
			case 'debug.allyDefeated': return 'GameLoopManager: Ally {} defeated';
			case 'debug.playerDefeatedEnemy': return 'GameLoopManager: Player defeated enemy with directional attack';
			case 'debug.processingAdjacentCombat': return 'GameLoopManager: Processing adjacent combat with {} enemies';
			case 'debug.enemyAttacksPlayer': return 'GameLoopManager: {} attacks player for {} damage';
			case 'debug.playerDefeated': return 'GameLoopManager: Player was defeated!';
			case 'debug.processingTurn': return 'GameLoopManager: Processing turn after player move';
			case 'debug.turnCompleted': return 'GameLoopManager: Turn completed';
			case 'debug.errorInTurnProcessing': return 'GameLoopManager: Error in turn processing: {}';
			case 'debug.convertedEnemyToAlly': return 'GameLoopManager: Converted enemy {} to ally';
			default: return null;
		}
	}
}

extension on _StringsJa {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'game.title': return 'キロ ハロウィン ゲーム';
			case 'game.start': return 'ゲーム開始';
			case 'game.pause': return '一時停止';
			case 'game.resume': return '再開';
			case 'game.quit': return '終了';
			case 'game.gameOver': return 'ゲームオーバー';
			case 'game.victory': return '勝利！';
			case 'ui.health': return '体力';
			case 'ui.score': return 'スコア';
			case 'ui.level': return 'レベル';
			case 'ui.inventory': return 'アイテム';
			case 'ui.back': return '戻る';
			case 'ui.confirm': return '確認';
			case 'ui.cancel': return 'キャンセル';
			case 'combat.attack': return '攻撃';
			case 'combat.defend': return '防御';
			case 'combat.run': return '逃げる';
			case 'combat.victory': return '勝利しました！';
			case 'combat.defeat': return '敗北しました！';
			case 'combat.enemyDefeated': return '敵を倒しました！';
			case 'combat.takeDamage': return '{damage}のダメージを受けました';
			case 'combat.dealDamage': return '{damage}のダメージを与えました';
			case 'combat.enemyAttacks.withDamage.0': return '{}がキロに意外なハグをしました！驚くほど温かいです！（{}ダメージ）';
			case 'combat.enemyAttacks.withDamage.1': return 'フレンドリーな{}がキロに遊び半分でぶつかってきました！（{}ダメージ）';
			case 'combat.enemyAttacks.withDamage.2': return '{}がキロとハイタッチしようとしましたが、幽霊に触るのは難しいようです！（{}ダメージ）';
			case 'combat.enemyAttacks.withDamage.3': return '{}が浮いている幽霊にくすぐり攻撃を試みました！（{}ダメージ）';
			case 'combat.enemyAttacks.withDamage.4': return '好奇心旺盛な{}がキロの幽霊の形を突いてきました！（{}ダメージ）';
			case 'combat.enemyAttacks.withoutDamage.0': return '{}がキロに手を振りましたが、幽霊のターゲットを外しました！（0ダメージ）';
			case 'combat.enemyAttacks.withoutDamage.1': return '困惑した{}がキロが浮いていた空中を振り回しました！（0ダメージ）';
			case 'combat.enemyAttacks.withoutDamage.2': return '{}のフレンドリーなジェスチャーがキロを素通りしました！（0ダメージ）';
			case 'combat.playerAttacks.withDamage.0': return 'キロが怖い「ブー！」を放ちます！敵は怖がって逃げてしまいました！（{}ダメージ）';
			case 'combat.playerAttacks.withDamage.1': return 'キロの幽霊の存在感が敵を圧倒しました！敵は恐怖で消え去りました！（{}ダメージ）';
			case 'combat.playerAttacks.withDamage.2': return 'フレンドリーな幽霊のハグで敵は恥ずかしくて戦えません！（{}ダメージ）';
			case 'combat.playerAttacks.withDamage.3': return 'キロのエーテルなくすぐり攻撃がたまりません！敵は笑いながら去りました！（{}ダメージ）';
			case 'combat.playerAttacks.withDamage.4': return '敵はキロの幽霊ダンスに魅了され、平和的に立ち去りました！（{}ダメージ）';
			case 'combat.playerAttacks.withoutDamage.0': return 'キロは怖がらせようとしましたが、敵は笑うだけでした！（{}ダメージ）';
			case 'combat.playerAttacks.withoutDamage.1': return 'キロの幽霊タッチは気づかれましたが、あまり効果的ではありませんでした！（{}ダメージ）';
			case 'combat.playerAttacks.withoutDamage.2': return '敵はキロのアプローチから優しい幽霊の風を感じました！（{}ダメージ）';
			case 'combat.playerAttacks.withoutDamage.3': return 'キロのフレンドリーな幽霊の手振りが敵を少し混乱させました！（{}ダメージ）';
			case 'combat.messages.allyDefeatsEnemyStrike': return '{ally}が強力な一撃で{enemy}を倒しました！';
			case 'combat.messages.allyEmergesVictorious': return '{ally}が{enemy}との戦いで勝利しました！';
			case 'combat.messages.allyOvercomes': return '{ally}が戦闘で{enemy}を克服しました！';
			case 'combat.messages.allyDefeatedBy': return '{ally}が{enemy}によって倒されました。';
			case 'combat.messages.enemyOvercomes': return '{enemy}が戦闘で{ally}を打ち負かしました。';
			case 'combat.messages.allyFalls': return '{ally}が{enemy}に倒れました。';
			case 'combat.messages.bothDefeatEachOther': return '{ally}と{enemy}が互いを倒しました！';
			case 'combat.messages.bothFallInCombat': return '{ally}と{enemy}が共に戦闘で倒れました！';
			case 'combat.messages.bothDefeated': return '{ally}と{enemy}が両方とも倒されました！';
			case 'combat.messages.exchangeBlows': return '{ally}と{enemy}が打ち合いを繰り広げています！';
			case 'combat.messages.battleContinues': return '{ally}と{enemy}の戦いが続いています！';
			case 'combat.messages.fightFiercely': return '{ally}と{enemy}が激しく戦っています！';
			case 'combat.messages.engagesInCombat': return '{ally}が{enemy}と戦闘を開始しました！';
			case 'combat.messages.movesToAttack': return '{ally}が{enemy}を攻撃するために動きました！';
			case 'combat.messages.confronts': return '{ally}が{enemy}に立ち向かいます！';
			case 'combat.messages.hasBeenDefeated': return '{enemy}が倒されました！';
			case 'combat.messages.fallsToGround': return '{enemy}が地面に倒れ、敗北しました。';
			case 'combat.messages.noLongerThreat': return '{enemy}はもはや脅威ではありません。';
			case 'combat.messages.entersCombat': return '{ally}が戦闘モードに入りました！';
			case 'combat.messages.preparesForBattle': return '{ally}が戦闘の準備をしています！';
			case 'combat.messages.readiesForCombat': return '{ally}が戦闘に備えています！';
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
			case 'combat.messages.allyDefeatedSatisfied': return '{ally}が倒されましたが、奉仕に満足しています。';
			case 'combat.messages.combatStarted': return '{ally}が{enemy}と戦闘を開始しました！';
			case 'combat.messages.combatConcluded': return '戦闘が終了しました。';
			case 'combat.messages.allyVictory': return 'あなたの味方が勝利しました！';
			case 'combat.messages.enemyVictory': return '敵があなたの味方を倒しました。';
			case 'combat.messages.combatDraw': return '戦闘は互角で終わりました。';
			case 'dialogue.continueButton': return '続ける';
			case 'dialogue.skip': return 'スキップ';
			case 'dialogue.close': return '閉じる';
			case 'items.candy': return 'キャンディ';
			case 'items.collected': return '{item}を入手しました！';
			case 'items.useItem': return 'アイテム使用';
			case 'items.noItems': return 'アイテムがありません';
			case 'enemies.ghost': return 'ゴースト';
			case 'enemies.skeleton': return 'スケルトン';
			case 'enemies.zombie': return 'ゾンビ';
			case 'messages.welcome': return 'キロ ハロウィン ゲームへようこそ！';
			case 'messages.gameStarted': return 'ゲームが開始されました！';
			case 'messages.levelComplete': return 'レベルクリア！';
			case 'messages.newLevel': return 'レベル {level}';
			case 'debug.gameLoopInitialized': return 'GameLoopManager: プレイヤーを{}で初期化しました';
			case 'debug.turnBasedSystemInitialized': return 'GameLoopManager: ターンベースシステムが初期化されました';
			case 'debug.turnBasedSystemStopped': return 'GameLoopManager: ターンベースシステムが停止されました';
			case 'debug.combatEncountersProcessed': return 'GameLoopManager: {}の戦闘遭遇を処理しました';
			case 'debug.combatResult': return 'GameLoopManager: 戦闘結果 - {}';
			case 'debug.enemyDefeatedRemoved': return 'GameLoopManager: エネミー{}が倒され削除されました';
			case 'debug.allyDefeated': return 'GameLoopManager: アライ{}が倒されました';
			case 'debug.playerDefeatedEnemy': return 'GameLoopManager: プレイヤーが方向攻撃でエネミーを倒しました';
			case 'debug.processingAdjacentCombat': return 'GameLoopManager: {}体のエネミーとの隣接戦闘を処理中';
			case 'debug.enemyAttacksPlayer': return 'GameLoopManager: {}がプレイヤーに{}ダメージを与えました';
			case 'debug.playerDefeated': return 'GameLoopManager: プレイヤーが倒されました！';
			case 'debug.processingTurn': return 'GameLoopManager: プレイヤー移動後のターンを処理中';
			case 'debug.turnCompleted': return 'GameLoopManager: ターン完了';
			case 'debug.errorInTurnProcessing': return 'GameLoopManager: ターン処理でエラー: {}';
			case 'debug.convertedEnemyToAlly': return 'GameLoopManager: エネミー{}をアライに変換しました';
			default: return null;
		}
	}
}
