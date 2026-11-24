// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get accountGoogleFailed =>
      'Google ile giriş bu telefonda çalışmadı. Tekrar dene ya da aşağıdan e-postayla devam et.';

  @override
  String get accountAppleFailed =>
      'Apple ile giriş bu telefonda çalışmadı. Ayarlar\'da Apple Hesabına giriş yaptığından emin ol ya da aşağıdan e-postayla devam et.';

  @override
  String get accountExistsNoLocal =>
      'Bu e-postayla zaten bir hesabın var. Giriş yap, bu telefon o hesapta kayıtlı yıldızları yüklesin.';

  @override
  String accountExistsWithLocal(int solved) {
    String _temp0 = intl.Intl.pluralLogic(
      solved,
      locale: localeName,
      other:
          'Bu e-postayla zaten bir hesabın var. Bu telefonda o hesapta olmayan $solved çözülmüş seviye var ve ikisi birleştirilemez — giriş yaparsan bunların yerini o hesaptakiler alır.',
    );
    return '$_temp0';
  }

  @override
  String get accountEmailInUse =>
      'Bu e-postayla zaten bir hesap var. Bunun yerine giriş yapmayı dene.';

  @override
  String get accountEmailMalformed => 'Bu bir e-posta adresine benzemiyor.';

  @override
  String get accountPasswordWeak =>
      'Bu şifre çok kolay tahmin edilir. Daha uzun bir şifre dene.';

  @override
  String get accountWrongPassword => 'E-posta ve şifre eşleşmiyor.';

  @override
  String get accountTooManyAttempts =>
      'Çok fazla deneme. Birkaç dakika bekleyip tekrar dene.';

  @override
  String get accountNeedsRecentLogin => 'Lütfen önce yeniden giriş yap.';

  @override
  String get accountMethodNotEnabled =>
      'E-postayla giriş şu an kullanılamıyor. “Google ile devam et” seçeneğini dene.';

  @override
  String get accountSessionUnavailable =>
      'Giriş yapıldı ama ilerlemen henüz sunucuya kaydedilmedi. Bağlantı gelince eşitlenecek.';

  @override
  String get accountUnavailable =>
      'Sunucuya ulaşılamadı. İlerlemen bu cihazda hâlâ güvende.';

  @override
  String get accountUseThatAccount => 'O hesabı kullan';

  @override
  String get accountExistingTitle => 'Zaten bir hesabın var';

  @override
  String get accountExistingBodyEmpty =>
      'Bu telefon o hesapta kayıtlı yıldızları yükleyecek.';

  @override
  String accountExistingBodyLocal(int cleared) {
    String _temp0 = intl.Intl.pluralLogic(
      cleared,
      locale: localeName,
      other:
          'Bu telefonda o hesapta olmayan $cleared çözülmüş seviye var. Birleştirilemedikleri için yerlerini o hesaptakiler alacak.',
    );
    return '$_temp0';
  }

  @override
  String get accountSignIn => 'Giriş yap';

  @override
  String get accountSignInCancelled =>
      'Giriş iptal edildi. Hiçbir şey değişmedi.';

  @override
  String get accountSignedInToast =>
      'Giriş yapıldı. Yıldızların artık yeni telefonuna da seninle gelir.';

  @override
  String get accountResetNeedsEmail =>
      'Önce e-postanı gir, sonra “Şifreni mi unuttun?” bağlantısına dokun.';

  @override
  String get accountResetSent =>
      'Bu e-postaya ait bir hesap varsa sıfırlama bağlantısı yolda.';

  @override
  String get accountYourAccount => 'Hesabın';

  @override
  String accountRankValue(int rank) {
    return '#$rank';
  }

  @override
  String accountStreakValue(int days) {
    return '${days}g';
  }

  @override
  String get accountCardTravels =>
      'Bu kart hesabınla birlikte gelir; yeni bir telefonda kaldığın yerden devam edersin.';

  @override
  String get accountYourNameHeader => 'Adın';

  @override
  String get accountChangeName => 'Adını değiştir';

  @override
  String get accountChangeNameDetail => 'Sıralamalarda nasıl görünürsün';

  @override
  String get accountShowOnBoards => 'Beni sıralamalarda göster';

  @override
  String get accountShowOnBoardsDetail =>
      'Kapalıysa adın ve sıran gizlenir. Yıldızlar yine sayılır.';

  @override
  String get accountYourPlayHeader => 'Oyunun';

  @override
  String get accountStatistics => 'İstatistikler';

  @override
  String get accountStatisticsDetail =>
      'Sürelerin, etkinliğin ve tüm seviyeler';

  @override
  String get accountSessionHeader => 'Oturum';

  @override
  String get accountDeleteHint =>
      'Hesabını silmek için Ayarlar → Tehlikeli bölge\'ye git.';

  @override
  String get accountVisibilityFailed =>
      'Sunucuya ulaşılamadı, hiçbir şey değişmedi.';

  @override
  String get accountSignOutTitle => 'Çıkış yapılsın mı?';

  @override
  String get accountSignOutBody =>
      'İlerlemen bu telefonda kalır. Başka bir yerde devam etmek için istediğin zaman tekrar giriş yapabilirsin.';

  @override
  String get accountStaySignedIn => 'Oturumu açık tut';

  @override
  String get accountSignOut => 'Çıkış yap';

  @override
  String get accountSignOutDetail => 'İlerlemen bu telefonda kalır';

  @override
  String get accountSaveTitle => 'İlerlemeni kaydet';

  @override
  String get accountSaveIntro =>
      'Yıldızların, serin ve sıralama adın hesabınla birlikte gelir; yeni bir telefonda kaldığın yerden başlarsın.';

  @override
  String get accountContinueApple => 'Apple ile Devam Et';

  @override
  String get accountContinueGoogle => 'Google ile devam et';

  @override
  String get accountOr => 'VEYA';

  @override
  String get accountEmailLabel => 'E-posta';

  @override
  String get accountEmailEmpty => 'E-postanı gir.';

  @override
  String get accountPasswordLabel => 'Şifre';

  @override
  String get accountPasswordHelper => 'En az 8 karakter';

  @override
  String get accountPasswordEmpty => 'Bir şifre gir.';

  @override
  String get accountPasswordShort => 'En az 8 karakter.';

  @override
  String get accountShowPassword => 'Şifreyi göster';

  @override
  String get accountHidePassword => 'Şifreyi gizle';

  @override
  String get accountCreate => 'Hesap oluştur';

  @override
  String get accountSwitchToSignIn => 'Hesabın var mı? Giriş yap';

  @override
  String get accountSwitchToSignInSemantic => 'Bunun yerine giriş yap';

  @override
  String get accountSwitchToCreate => 'Hesabın yok mu? Oluştur';

  @override
  String get accountSwitchToCreateSemantic => 'Bunun yerine hesap oluştur';

  @override
  String get accountForgotPassword => 'Şifreni mi unuttun?';

  @override
  String get accountForgotPasswordSemantic => 'Şifreni sıfırla';

  @override
  String get accountNaming => 'Adın veriliyor…';

  @override
  String get accountSignedInLabel => 'Giriş yapıldı';

  @override
  String accountPouringSince(String month, int year) {
    return 'BAŞLANGIÇ: $month $year';
  }

  @override
  String get accountPlayerCardTag => 'OYUNCU KARTI';

  @override
  String get accountStatSolved => 'ÇÖZÜLEN';

  @override
  String get accountStatStars => 'YILDIZ';

  @override
  String get accountStatStreak => 'SERİ';

  @override
  String get accountStatRank => 'SIRA';

  @override
  String accountStarsValue(int stars) {
    return '$stars★';
  }

  @override
  String get accountSyncing => 'Eşitleniyor…';

  @override
  String get accountSyncingDetail => 'İlerleme hesabına kaydediliyor';

  @override
  String get accountWaitingToSync => 'Eşitleme bekleniyor';

  @override
  String get accountWaitingOffline => 'İnternete bağlanınca kaydedilir';

  @override
  String get accountWaitingPending => 'Son seviyelerin sırada';

  @override
  String get accountSyncedDetail => 'İlerleme hesabına kaydedildi';

  @override
  String get accountSynced => 'Eşitlendi';

  @override
  String get accountSyncedJustNow => 'Az önce eşitlendi';

  @override
  String accountSyncedMinutesAgo(int minutes) {
    return '$minutes dk önce eşitlendi';
  }

  @override
  String accountSyncedHoursAgo(int hours) {
    return '$hours sa önce eşitlendi';
  }

  @override
  String accountSyncedDaysAgo(int days) {
    return '$days g önce eşitlendi';
  }

  @override
  String get accountCrestSignedIn => 'Hesabın';

  @override
  String get accountCrestGuest => 'Misafir olarak oynuyorsun';

  @override
  String get accountRenameRefused => 'Bu ad kabul edilmedi.';

  @override
  String get accountRenameOffline =>
      'Sunucuya ulaşılamadı. Biraz sonra tekrar dene.';

  @override
  String get ranksTitle => 'Sıralama';

  @override
  String get ranksTabToday => 'Bugün';

  @override
  String get ranksTabCampaign => 'Kampanya';

  @override
  String get ranksLoading => 'Sıralama getiriliyor…';

  @override
  String get ranksEmptyDailyTitle =>
      'Bugünün bulmacasını henüz kimse bitirmedi';

  @override
  String get ranksEmptyDailyDetail => 'İlk sen ol.';

  @override
  String get ranksEmptyCampaignTitle => 'Henüz sıralamada oyuncu yok';

  @override
  String get ranksEmptyCampaignDetail => 'Burada yıldızlar belirler.';

  @override
  String get ranksYourSpot => 'Senin yerin';

  @override
  String ranksPlayerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu sıralamada $countString oyuncu',
    );
    return '$_temp0';
  }

  @override
  String ranksMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hamle',
    );
    return '$_temp0';
  }

  @override
  String ranksStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yıldız',
    );
    return '$_temp0';
  }

  @override
  String ranksLevels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seviye',
    );
    return '$_temp0';
  }

  @override
  String ranksInTime(String time) {
    return '$time sürede';
  }

  @override
  String get ranksOpenSpot => 'Boş yer';

  @override
  String ranksNameYou(String name) {
    return '$name (sen)';
  }

  @override
  String ranksPlaceOpen(int place) {
    return '$place. sıra, boş';
  }

  @override
  String ranksPlaceSemantic(int rank, String name, String score) {
    return '$rank. sıra, $name, $score';
  }

  @override
  String ranksScoreWithTieBreak(String score, String tieBreak) {
    return '$score, $tieBreak';
  }

  @override
  String get ranksOffTitle => 'Bu sürümde sıralamalar kapalı';

  @override
  String get ranksOffDetail => 'Kampanya bundan etkilenmez.';

  @override
  String get ranksLoadFailed => 'Sıralama yüklenemedi';

  @override
  String get ranksOffline =>
      'Çevrimdışı görünüyorsun. Tüm seviyeler bağlantı olmadan da oynanır.';

  @override
  String get ranksTimeout => 'Sunucunun yanıtı çok uzun sürdü.';

  @override
  String get ranksServerError =>
      'Bizim tarafta bir sorun çıktı. İlerlemen güvende.';

  @override
  String get ranksHiddenTitle => 'Gizlisin';

  @override
  String get ranksHiddenDetail =>
      'Yıldızların ve serin yine sayılır — sadece burada görünmezsin. Ayarı Ayarlar\'da bulabilirsin.';

  @override
  String get statsTitle => 'İstatistiklerin';

  @override
  String get statsTabOverview => 'Genel';

  @override
  String get statsTabLevels => 'Seviyeler';

  @override
  String get statsTabBadges => 'Rozetler';

  @override
  String get statsPaceOnPar => 'tam par';

  @override
  String statsPaceUnder(int percent) {
    return '%$percent altında';
  }

  @override
  String statsPaceOver(int percent) {
    return '%$percent üstünde';
  }

  @override
  String get statsEmptyTitle => 'Henüz gösterilecek bir şey yok';

  @override
  String get statsEmptyBody =>
      'Bir seviye çöz, burası dolsun: par\'a göre sürelerin, en iyi çözümlerin ve oynadığın günler.';

  @override
  String get statsBackToLevels => 'Seviyelere dön';

  @override
  String get statsLevelsSolved => 'çözülen seviye';

  @override
  String get statsStars => 'yıldız';

  @override
  String get statsPoints => 'puan';

  @override
  String get statsPlayed => 'oyun süresi';

  @override
  String get statsNowOn => 'şu an';

  @override
  String get statsBestSolveMoves => 'en iyi çözümlerdeki hamle';

  @override
  String get statsAgainstClock => 'ZAMANA KARŞI';

  @override
  String get statsNoTimes =>
      'Henüz kayıtlı süre yok. Saat gelmeden önce bitirdiğin seviyelerin süresi yok — birini yeniden oyna, sayım başlasın.';

  @override
  String get statsFastest => 'En hızlı';

  @override
  String get statsLongest => 'En uzun';

  @override
  String get statsAvgPace => 'Ort. tempo';

  @override
  String statsClockValue(String time, int level) {
    return '$time · S$level';
  }

  @override
  String statsUntimed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Çözdüğün seviyelerden $count tanesi saatten önce bitirildi ve kayıtlı süresi yok.',
    );
    return '$_temp0';
  }

  @override
  String statsUnderParSemantic(int under, int total) {
    return '$total süreli seviyeden $under tanesi par altında';
  }

  @override
  String get statsUnderParTag => 'PAR ALTI';

  @override
  String get statsLast30Days => 'SON 30 GÜN';

  @override
  String statsStreakChip(int count) {
    return '$count günlük seri';
  }

  @override
  String get statsNoStreak => 'seri yok';

  @override
  String statsDaysPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün oynandı',
    );
    return '$_temp0';
  }

  @override
  String statsLevelsFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seviye bitti',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en iyi $count gün',
    );
    return '$_temp0';
  }

  @override
  String get statsToday => 'Bugün';

  @override
  String statsMonthShort(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'jan': 'Oca',
      'feb': 'Şub',
      'mar': 'Mar',
      'apr': 'Nis',
      'may': 'May',
      'jun': 'Haz',
      'jul': 'Tem',
      'aug': 'Ağu',
      'sep': 'Eyl',
      'oct': 'Eki',
      'nov': 'Kas',
      'dec': 'Ara',
      'other': '$month',
    });
    return '$_temp0';
  }

  @override
  String statsMonthDay(String month, int day) {
    return '$day $month';
  }

  @override
  String statsBarLevels(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$day · $count seviye',
    );
    return '$_temp0';
  }

  @override
  String statsBarNoPlay(String day) {
    return '$day · oynanmadı';
  }

  @override
  String get statsWorldAhead => 'sırada';

  @override
  String get statsWorldNoTimes => 'süre yok';

  @override
  String statsWorldPoints(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString puan';
  }

  @override
  String statsWorldSolvedSemantic(String name, int cleared, int total) {
    return '$name: $total seviyeden $cleared tanesi çözüldü';
  }

  @override
  String statsWorldPaceSemantic(String pace) {
    return 'tempo $pace';
  }

  @override
  String statsWorldPointsSemantic(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString puan';
  }

  @override
  String get statsColLevel => 'SEV';

  @override
  String get statsColStars => 'YILDIZ';

  @override
  String get statsColMoves => 'HAMLE';

  @override
  String get statsColTime => 'SÜRE';

  @override
  String get statsColPoints => 'PUAN';

  @override
  String statsMovesBestPossible(int moves, int best) {
    return '$moves hamle, en iyisi $best';
  }

  @override
  String statsMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hamle',
    );
    return '$_temp0';
  }

  @override
  String badgeUnlockedCount(int earned, int total) {
    return '$earned / $total açıldı';
  }

  @override
  String get badgeUnlocked => 'Açıldı';

  @override
  String get badgeNotYet => 'Henüz değil';

  @override
  String badgeProgress(int shown, int target) {
    return '$shown / $target';
  }

  @override
  String badgeSemantic(String title, String description, String status) {
    return '$title: $description $status';
  }

  @override
  String get badgeFirstPourTitle => 'İlk döküş';

  @override
  String get badgeFirstPourDesc => 'İlk seviyeni bitir.';

  @override
  String get badgePar10Title => 'Tam par';

  @override
  String get badgePar10Desc => '10 seviyeyi tam par ile bitir.';

  @override
  String get badgePar50Title => 'Par ustası';

  @override
  String get badgePar50Desc => '50 seviyeyi tam par ile bitir.';

  @override
  String get badgeCleanClearTitle => 'Geri almak yok';

  @override
  String get badgeCleanClearDesc => 'Bir seviyeyi geri almadan bitir.';

  @override
  String get badgeSpeedyTitle => 'Hızlı döküş';

  @override
  String get badgeSpeedyDesc => 'Bir seviyeyi 30 saniyenin altında bitir.';

  @override
  String get badgeLevels100Title => 'Yüzbaşı';

  @override
  String get badgeLevels100Desc => '100 seviye bitir.';

  @override
  String get badgeStars300Title => 'Yıldız avcısı';

  @override
  String get badgeStars300Desc => '300 yıldız topla.';

  @override
  String get badgeWorldPerfectTitle => 'Kusursuz dünya';

  @override
  String get badgeWorldPerfectDesc =>
      'Bir dünyadaki her seviyede üç yıldız al.';

  @override
  String get badgeStreak7Title => 'Döküş haftası';

  @override
  String get badgeStreak7Desc => '7 günlük Günün Bulmacası serisine ulaş.';

  @override
  String get badgeStreak30Title => 'Döküş ayı';

  @override
  String get badgeStreak30Desc => '30 günlük Günün Bulmacası serisine ulaş.';

  @override
  String get badgeChests5Title => 'Hazine avcısı';

  @override
  String get badgeChests5Desc => '5 yıldız sandığı aç.';

  @override
  String get badgeHard5Title => 'Sert ceviz';

  @override
  String get badgeHard5Desc => '5 ZOR seviye bitir.';

  @override
  String get badgeEventFullTitle => 'Tam hafta';

  @override
  String get badgeEventFullDesc =>
      'Haftalık bir etkinliğin yedi bulmacasının hepsini bitir.';

  @override
  String get badgeZen25Title => 'Zen bahçesi';

  @override
  String get badgeZen25Desc => 'Zen modunda 25 bulmaca bitir.';

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonBack => 'Geri';

  @override
  String get commonOk => 'Tamam';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonRetry => 'Tekrar dene';

  @override
  String get commonNotNow => 'Şimdi değil';

  @override
  String commonLevelN(int level) {
    return 'Seviye $level';
  }

  @override
  String get hubAccountYours => 'Hesabın';

  @override
  String get hubAccountSave => 'İlerlemeni kaydet';

  @override
  String get hubPlayerFallback => 'Oyuncu';

  @override
  String get hubSettings => 'Ayarlar';

  @override
  String get hubTagline => 'DÖK · DİZ · RAHATLA';

  @override
  String hubStatChipSemantic(String value, String label) {
    return '$value $label. İstatistikler';
  }

  @override
  String get hubStatSolved => 'çözülen';

  @override
  String get hubStatStars => 'yıldız';

  @override
  String get hubStatStreak => 'seri';

  @override
  String hubStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün',
    );
    return '$_temp0';
  }

  @override
  String hubRankNumber(int rank) {
    return '#$rank';
  }

  @override
  String hubEventSemantic(int cleared, int total) {
    return 'Haftalık etkinlik, $total bulmacadan $cleared';
  }

  @override
  String hubEventProgress(int cleared, int total, String timeLeft) {
    return '$cleared/$total · $timeLeft';
  }

  @override
  String hubEventProgressRanked(
    int cleared,
    int total,
    int rank,
    String timeLeft,
  ) {
    return '$cleared/$total · #$rank · $timeLeft';
  }

  @override
  String get hubZen => 'Zen';

  @override
  String get hubZenSemantic => 'Zen modu';

  @override
  String hubZenLockedSemantic(int level) {
    return 'Zen modu $level. seviyede açılır';
  }

  @override
  String get hubZenOpen => 'Sonsuz, saatsiz';

  @override
  String hubZenLocked(int level, int remaining) {
    return 'Seviye $level · $remaining kaldı';
  }

  @override
  String get hubDockJourney => 'Yolculuk';

  @override
  String get hubDockRankings => 'Sıralama';

  @override
  String get hubDockStats => 'İstatistik';

  @override
  String get hubTip =>
      'Harika! Yolculuk tüm seviyeleri gösterir ve her gün oynayacak yeni bir Günün Bulmacası var.';

  @override
  String hubHeroWorld(int world) {
    return 'Dünya $world';
  }

  @override
  String hubHeroWorldBand(int world, String band) {
    return 'Dünya $world · $band';
  }

  @override
  String hubHeroPar(int par) {
    return 'par $par';
  }

  @override
  String get hubPlay => 'OYNA';

  @override
  String hubPlaySemantic(int level) {
    return 'Oyna: Seviye $level';
  }

  @override
  String get hubMoreUpdateTitle => 'Yeni seviyeler için güncelle';

  @override
  String get hubMoreUpdateBody =>
      'Yeni bir dünya çıktı ve en son Pourfect gerekiyor. Dökmeye devam etmek için oyunu güncelle.';

  @override
  String get hubMoreDownloadingTitle => 'Yeni seviyeler yolda';

  @override
  String get hubMoreDownloadingBody =>
      'Sonraki dünya iniyor. Yalnızca bir dakikanı alır.';

  @override
  String get hubMoreAllDoneTitle => 'Hepsini döktün!';

  @override
  String get hubMoreOfflineBody =>
      'İnternete bağlan, yeni seviyeler arka planda insin. Bu arada Günün Bulmacası seni bekliyor.';

  @override
  String get hubMoreOnlineBody =>
      'Çevrimiçi olduğunda yeni seviyeler arka planda iner. Bu arada Günün Bulmacası seni bekliyor.';

  @override
  String get hubMoreCheckAgain => 'Tekrar kontrol et';

  @override
  String hubAchievementOne(String title) {
    return 'Başarım açıldı: $title';
  }

  @override
  String hubAchievementMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count başarım açıldı!',
    );
    return '$_temp0';
  }

  @override
  String get hubUpdateReady => 'Bir güncelleme yüklenmeye hazır.';

  @override
  String get hubUpdateRestart => 'Yeniden başlat';

  @override
  String hubSpanSeconds(int seconds) {
    return '$seconds sn';
  }

  @override
  String hubSpanMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String hubSpanMinutesSeconds(int minutes, int seconds) {
    return '$minutes dk $seconds sn';
  }

  @override
  String hubSpanHours(int hours) {
    return '$hours sa';
  }

  @override
  String hubSpanHoursMinutes(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String get hubParOn => 'tam par';

  @override
  String hubParUnder(int percent) {
    return 'par\'ın %$percent altında';
  }

  @override
  String hubParOver(int percent) {
    return 'par\'ın %$percent üstünde';
  }

  @override
  String get dailyTitle => 'Günün Bulmacası';

  @override
  String get dailyCardSemantic => 'Bugünün bulmacası';

  @override
  String get dailyCardUnavailable => 'bugünün bulmacasına ulaşılamıyor';

  @override
  String get dailyCardSolved => 'çözüldü';

  @override
  String dailyCardNextIn(String time) {
    return 'yenisi $time sonra';
  }

  @override
  String dailyCardEndsIn(String time) {
    return 'kalan $time';
  }

  @override
  String dailyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count günlük seri',
    );
    return '$_temp0';
  }

  @override
  String dailyStreakMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count günlük seri!',
    );
    return '$_temp0';
  }

  @override
  String get dailyRankSemantic => 'Sıralama';

  @override
  String dailyRankSemanticRanked(int rank) {
    return 'Sıralama, $rank. sıra';
  }

  @override
  String get dailyRankSticker => 'SIRA';

  @override
  String get dailyLeaveLost =>
      'Günün Bulmacası\'ndaki hamlelerin kaydedilmeyecek. Bugün istediğin zaman yeniden başlayabilirsin.';

  @override
  String get dailySubmitRefused => 'Sunucu bu sonucu kabul etmedi.';

  @override
  String get dailySubmitFailed =>
      'Çözüldü — ama sonuç gönderilemedi. Daha sonra tekrar dene.';

  @override
  String get dailyHudLabel => 'Günün';

  @override
  String get dailyHudValue => 'Bulmacası';

  @override
  String get dailyDeadEndRestart =>
      'Buradan bitirmenin yolu yok. Başka bir yol denemek için baştan başla.';

  @override
  String dailyDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Buradan bitirmenin yolu yok. Yola dönmek için $count hamle geri al.',
    );
    return '$_temp0';
  }

  @override
  String get dailyActionRestart => 'Baştan';

  @override
  String dailyActionUndo(int count) {
    return '$count geri al';
  }

  @override
  String get dailyNoHint => 'Bu durum için ipucu yok.';

  @override
  String get dailyLoadingTitle => 'Bugünün bulmacası yükleniyor';

  @override
  String get dailyOffTitle => 'Bu sürümde günlük bulmacalar kapalı';

  @override
  String get dailyOffDetail =>
      'Kampanya bundan etkilenmez — tüm seviyeler bu cihazda.';

  @override
  String get dailyNoBoardTitle => 'Bugün bulmaca yok';

  @override
  String get dailyNoBoardDetail =>
      'Bugünün bulmacası sunucudan gelir ve sunucuya ulaşılamadı. Kampanyanın buna ihtiyacı yok.';

  @override
  String get dailyLoaderCaption => 'Bugünün bulmacası dökülüyor…';

  @override
  String get dailyBackToLevels => 'Seviyelere dön';

  @override
  String dailyWeekSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün',
    );
    return 'Serin: $_temp0. Aç';
  }

  @override
  String dailyDaySemantic(String weekday, String state) {
    return '$weekday, $state';
  }

  @override
  String get dailyDayFrozen => 'kaçırıldı, dondurmayla korundu';

  @override
  String get dailyDayPlayedToday => 'bugün oynandı';

  @override
  String get dailyDayPlayed => 'oynandı';

  @override
  String get dailyDayToday => 'bugün, henüz oynanmadı';

  @override
  String get dailyDayMissed => 'oynanmadı';

  @override
  String get dailyDayFuture => 'henüz gelmedi';

  @override
  String get dailyOutcomeBest => 'Yeni rekor';

  @override
  String get dailyOutcomeSolved => 'Çözüldü';

  @override
  String get dailyFigureMoves => 'hamle';

  @override
  String get dailyFigureStreak => 'seri';

  @override
  String get dailyUnranked => 'sırasız';

  @override
  String dailyOfPlayers(int count) {
    return '$count kişiden';
  }

  @override
  String get dailyReminderOn => 'Yarın akşam bir hatırlatma alacaksın.';

  @override
  String get dailyRemindMe => 'Yarın hatırlat';

  @override
  String get dailyDone => 'TAMAM';

  @override
  String get dailyFreezeVideoUnfinished => 'Dondurma yok — video bitmedi.';

  @override
  String get dailyFreezeNoVideo => 'Şu an video yok.';

  @override
  String get dailyFreezeError => 'Bir sorun çıktı. Daha sonra tekrar dene.';

  @override
  String get dailyFreezeAdded => 'Dondurma eklendi. Kaçırılan bir gün korunur.';

  @override
  String get dailyFreezeNoRoom => 'Bugün başka dondurmaya yer yok.';

  @override
  String get dailyFreezeLoadingVideo => 'Video yükleniyor…';

  @override
  String get dailyFreezeWatch => 'Dondurma için video izle';

  @override
  String get dailyFreezesFull =>
      'Dondurmalar dolu. Her biri kaçırdığın bir günü korur.';

  @override
  String get dailyFreezeTomorrow =>
      'Günde bir videodan bir dondurma. Yarın yine gel.';

  @override
  String get dailyStreakTitle => 'Serin';

  @override
  String get dailyStreakNone => 'Henüz seri yok';

  @override
  String get dailyStreakStart =>
      'Bir seri başlatmak için bugün Günün Bulmacası\'nı oyna.';

  @override
  String dailyStreakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En iyi: $count gün',
    );
    return '$_temp0';
  }

  @override
  String dailyFreezesSemantic(int count, int max) {
    return '$max seri dondurmadan $count tane';
  }

  @override
  String get dailyFreezesTitle => 'Seri dondurmaları';

  @override
  String get dailyFreezesEach => 'Her biri kaçırılan bir günü korur.';

  @override
  String dailyFreezeWeekly(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Her pazartesi bir tane ücretsiz; sıradaki $days gün sonra.',
      one: 'Her pazartesi bir tane ücretsiz; sıradaki yarın.',
    );
    return '$_temp0';
  }

  @override
  String get dailyCalendarPrevious => 'Önceki ay';

  @override
  String get dailyCalendarNext => 'Sonraki ay';

  @override
  String dailyCalendarCellSemantic(String date, String state) {
    return '$date, $state';
  }

  @override
  String get dailyCalendarPlayed => 'oynandı';

  @override
  String get dailyCalendarFrozen => 'donduruldu';

  @override
  String get dailyCalendarFuture => 'gelecek';

  @override
  String get dailyLegendPlayed => 'Oynandı';

  @override
  String get dailyLegendFrozen => 'Donduruldu';

  @override
  String get dailyLegendToday => 'Bugün';

  @override
  String get eventTitle => 'Haftalık etkinlik';

  @override
  String get eventUnreachable => 'Bu haftanın etkinliğine şu an ulaşılamıyor.';

  @override
  String get eventEnded => 'bitti';

  @override
  String eventEndsIn(String timeLeft) {
    return 'kalan $timeLeft';
  }

  @override
  String eventTimeLeftDaysHours(int days, int hours) {
    return '${days}g ${hours}sa';
  }

  @override
  String eventTimeLeftHours(int hours) {
    return '${hours}sa';
  }

  @override
  String eventTimeLeftMinutes(int minutes) {
    return '${minutes}dk';
  }

  @override
  String eventSummary(int cleared, int total, String endsIn) {
    return '$total bulmacadan $cleared · $endsIn';
  }

  @override
  String get eventFigurePoints => 'puan';

  @override
  String eventRankOf(int count) {
    return '$count kişiden';
  }

  @override
  String get eventRankPlay => 'sıralanmak için bir bulmaca oyna';

  @override
  String get eventRankSetName => 'sıralanmak için bir ad belirle';

  @override
  String eventTileSemanticDone(int slot, int stars, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars yıldız',
    );
    return 'Bulmaca $slot, $_temp0, $points puan';
  }

  @override
  String eventTileSemanticNew(int slot) {
    return 'Bulmaca $slot, oynanmadı';
  }

  @override
  String eventTilePoints(int points) {
    return '$points p';
  }

  @override
  String get eventStandingsTitle => 'Bu haftanın sıralaması';

  @override
  String get eventStandingsEmpty => 'Henüz sıralamada kimse yok. İlk sen ol.';

  @override
  String eventStandingsCleared(int cleared) {
    return ' · $cleared/7';
  }

  @override
  String get eventSubmitRefused =>
      'Sunucu bu sonucu almadı — etkinlik bitmiş olabilir.';

  @override
  String get eventSubmitFailed =>
      'Çözüldü — ama sonuç gönderilemedi. Tekrar dene.';

  @override
  String eventDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Buradan bitirmenin yolu yok. $count hamle geri al.',
    );
    return '$_temp0';
  }

  @override
  String get eventNoHint => 'Şu an bu durum için ipucu yok.';

  @override
  String get eventHudLabel => 'Bulmaca';

  @override
  String eventHudBand(String event, String endsIn) {
    return '$event · $endsIn';
  }

  @override
  String get eventSending => 'Gönderiliyor…';

  @override
  String eventResult(int points, int total) {
    return '$points puan · bu hafta $total';
  }

  @override
  String eventResultRanked(int points, int total, int rank) {
    return '$points puan · bu hafta $total · #$rank';
  }

  @override
  String get journeyTitle => 'Yolculuk';

  @override
  String journeyStarsSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yıldız',
    );
    return '$_temp0';
  }

  @override
  String journeyWorldCardSemantic(
    int world,
    int worlds,
    String name,
    int solved,
    int total,
  ) {
    return 'Dünya $world/$worlds, $name, $total seviyeden $solved çözüldü';
  }

  @override
  String journeyWorldOf(int world, int worlds) {
    return 'DÜNYA $world/$worlds';
  }

  @override
  String journeyRibbonSemantic(int world, String name, int solved, int total) {
    return 'Dünya $world, $name, $total seviyeden $solved çözüldü. Oraya kaydır';
  }

  @override
  String journeyRibbonLabel(int world, String name) {
    return 'DÜNYA $world · $name';
  }

  @override
  String get journeyYouPin => 'SEN';

  @override
  String journeyBandCaps(int world, int count) {
    return 'DÜNYA $world · $count';
  }

  @override
  String get journeyBandFirstPours => 'İlk Adımlar';

  @override
  String get journeyBandFindingRhythm => 'Ritmi Yakala';

  @override
  String get journeyBandDeepWater => 'Derin Sular';

  @override
  String get journeyBandMastery => 'Ustalık';

  @override
  String get notifSoftAskTitle => 'Hatırlatalım mı?';

  @override
  String get notifSoftAskBody =>
      'Günün Bulmacası çıktığında ya da sıradaki seviyen seni beklerken haber veririz. Günde en fazla iki kez; Ayarlar\'dan istediğin zaman kapatabilirsin.';

  @override
  String get notifSoftAskBodyDenied =>
      'Pourfect için bildirimler kapalı. Günün Bulmacası çıktığında ya da yeni bir dünya geldiğinde haber almak için telefon ayarlarından aç. Günde en fazla iki kez.';

  @override
  String get notifSoftAskOpenSettings => 'Ayarları aç';

  @override
  String get notifSoftAskYes => 'Evet, lütfen';

  @override
  String get notifChannelName => 'Hatırlatmalar';

  @override
  String get notifChannelDescription =>
      'Günün Bulmacası, sıradaki seviyen ve yeni dünyalar. Günde en fazla iki kez.';

  @override
  String get playHudLevel => 'Seviye';

  @override
  String playHudTitle(String label, String value) {
    return '$label $value';
  }

  @override
  String get playHudHard => 'ZOR ×1,5';

  @override
  String get playHudHardLabel => 'Zor seviye, bir buçuk kat puan';

  @override
  String get playHudMoves => 'HAMLE';

  @override
  String playHudMovesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hamle',
    );
    return '$_temp0';
  }

  @override
  String playParLeftFor3Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '3 yıldız için $count hamle kaldı',
    );
    return '$_temp0';
  }

  @override
  String get playParSpent => 'Par bitti · bundan sonra 2 yıldız';

  @override
  String playParLeftFor2Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '2 yıldız için $count hamle kaldı',
    );
    return '$_temp0';
  }

  @override
  String get playParOneStarFromHere => 'Bundan sonra 1 yıldız · her bitiriş';

  @override
  String get playParAnyFinish => 'Her bitiriş 1 yıldız kazandırır';

  @override
  String playParMeterLabel(int stars, int used, int par, String words) {
    return '$stars yıldız temposu, par $par hamleden $used kullanıldı. $words';
  }

  @override
  String playHudBusyLabel(String label) {
    return '$label, çalışıyor. İptal için dokun';
  }

  @override
  String get playHudUndo => 'Geri al';

  @override
  String get playHudHint => 'İpucu';

  @override
  String get playHudRestart => 'Baştan';

  @override
  String get playExtraTubeLabel => 'Ek tüp için video izle';

  @override
  String get playExtraTubeChip => '+ Tüp';

  @override
  String playStarsOfTotal(int earned, int total) {
    return '$total yıldızdan $earned';
  }

  @override
  String get playDismiss => 'Kapat';

  @override
  String get playLeaveTitleSoSoon => 'Bu kadar erken mi?';

  @override
  String get playLeaveTitleMissYou => 'Toplar seni özleyecek';

  @override
  String get playLeaveTitleAbandon => 'Dökmeyi bırakıyor musun?';

  @override
  String get playLeaveTitleMidPour => 'Dökerken mi gidiyorsun?';

  @override
  String get playLeaveBody =>
      'Bu bulmacadaki hamlelerin ve süren kaydedilmeyecek.';

  @override
  String get playLeaveKeepPouring => 'Dökmeye devam';

  @override
  String get playLeaveConfirm => 'Çık';

  @override
  String get playTutorialSkipLabel => 'Eğitimi geç';

  @override
  String get playTutorialSkip => 'Geç';

  @override
  String playTipBubbleLabel(String text) {
    return '$text. Kapat';
  }

  @override
  String get playTipPar =>
      'Üç yıldız için par içinde bitir. Çubuk ne kadarını kullandığını gösterir.';

  @override
  String get playTipTallTubes =>
      'Daha uzun tüpler! Artık her biri beş top alıyor.';

  @override
  String get playTipHint =>
      'Takıldın mı? İpucu sana iyi bir sonraki hamleyi gösterir.';

  @override
  String get playTipUndo =>
      'Par\'ı geçtin mi? Geri almak ücretsiz — istediğin kadar geri dön.';

  @override
  String get playGuideSorted => 'Tamam! Şimdi her tüpü tek renk yap.';

  @override
  String get playGuideDrop =>
      'Şimdi gidecekleri yere dokun: aynı rengin üstüne ya da boş bir tüpe.';

  @override
  String get playGuideWrongTube =>
      'Bunun yerine o topları almak için elin gösterdiği tüpe dokun.';

  @override
  String get playGuideFirstTap => 'Üstteki topları almak için bir tüpe dokun.';

  @override
  String get playGuideFirstPour => 'İşte bir döküş! Devam et.';

  @override
  String get playGuideKeepGoing => 'Devam et: her tüpe tek renk.';

  @override
  String playCoachHolding(int count) {
    return 'Elinde $count top · zıplayan bir tüpe bırak';
  }

  @override
  String get playExtraTubeAdTitle => 'Ek tüp için video izler misin?';

  @override
  String get playExtraTubeAdBody =>
      'Bu seviye için bir boş tüp daha. Ek tüple bitirilen seviye en fazla iki yıldız kazandırır.';

  @override
  String get playExtraTubeNotFinished => 'Tüp yok — video bitmedi.';

  @override
  String get playExtraTubeSaved => 'Saklandı — sonraki tüpün ücretsiz.';

  @override
  String get playNoVideo => 'Şu an video yok.';

  @override
  String get playRewardFailed => 'Bir sorun çıktı. Hiçbir şey harcanmadı.';

  @override
  String get playHintShowing => 'İpucun ekranda: parlayan tüpe dök.';

  @override
  String get playHintNoneNothingUsed =>
      'Bu durum için ipucu yok. Hiçbir şey harcanmadı.';

  @override
  String get playHintNotFinished => 'İpucu yok — video bitmedi.';

  @override
  String get playHintVideoSaved => 'Videon sonraki ipucu için saklandı.';

  @override
  String get playHintNoneVideoSaved =>
      'Bu durum için ipucu yok — videon sonraki için saklandı.';

  @override
  String get playHintNone => 'Bu durum için ipucu yok.';

  @override
  String get playHintHere => 'İşte ipucun — parlayan tüpe dök.';

  @override
  String get playDeadEndRestart =>
      'Buradan bitirmenin yolu yok. Başka bir yol denemek için baştan başla.';

  @override
  String get playDeadEndRestartTube =>
      'Buradan bitirmenin yolu yok. Başka bir yol denemek için baştan başla. Ya da yedek tüp için + Tüp\'e dokun.';

  @override
  String playDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Buradan bitirmenin yolu yok. Yola dönmek için $count hamle geri al.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoTube(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Buradan bitirmenin yolu yok. Yola dönmek için $count hamle geri al. Ya da yedek tüp için + Tüp\'e dokun.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoAction(int count) {
    return '$count geri al';
  }

  @override
  String get playHintAdTitle => 'İpucu için video izler misin?';

  @override
  String playHintAdFreeLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ücretsiz ipucun kaldı.',
    );
    return '$_temp0';
  }

  @override
  String get playHintAdNoneLeft =>
      'Ücretsiz ipuçların bitti. Kısa bir video bir tane daha kazandırır.';

  @override
  String get playWatch => 'İzle';

  @override
  String get playLoadFailed => 'Seviyeler yüklenemedi';

  @override
  String get playTubeSorted => 'TAMAM!';

  @override
  String get playWinTitlePerfect => 'Mükemmel\nDöküş!';

  @override
  String get playWinTitleNice => 'Güzel\nDöküş!';

  @override
  String get playWinTitlePoured => 'Döktün!';

  @override
  String get playWinLastPour => 'Son döküş…';

  @override
  String playWinMovesPar(int count, int par) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count HAMLE · PAR $par',
    );
    return '$_temp0';
  }

  @override
  String playWinLevelBand(int level, String band) {
    return 'Seviye $level · $band';
  }

  @override
  String get playWinNewBest => 'YENİ REKOR!';

  @override
  String playWinMovesChip(int par) {
    return 'hamle · par $par';
  }

  @override
  String get playWinUntimed => 'süresiz';

  @override
  String get playWinFastest => 'en hızlısı!';

  @override
  String get playWinTime => 'süre';

  @override
  String get playWinUnderPar => 'PAR ALTI!';

  @override
  String get playWinPoints => 'puan';

  @override
  String playWinWorldBand(int world, String band) {
    return 'DÜNYA $world · $band';
  }

  @override
  String get playWinTryAssisted =>
      'Üç yıldız için ek tüp kullanmadan bitirmelisin.';

  @override
  String playWinTryShort(int par, int took, int short) {
    String _temp0 = intl.Intl.pluralLogic(
      short,
      locale: localeName,
      other: 'Par $par, sen $took hamle yaptın. 3★\'a $short hamle uzaktasın.',
      one: 'Par $par, sen $took hamle yaptın. 3★\'a bir hamle uzaktasın.',
    );
    return '$_temp0';
  }

  @override
  String playWinTryInReach(int par) {
    return 'Par $par. Üç yıldız çok yakın.';
  }

  @override
  String get playWinTryButton => '3★ İÇİN DENE';

  @override
  String get playWinTryButtonLabel => 'Üç yıldız için bu seviyeyi yeniden oyna';

  @override
  String get playWinReplayLabel => 'Bu seviyeyi yeniden oyna';

  @override
  String get playWinHomeLabel => 'Ana ekrana dön';

  @override
  String get playWinNextLevel => 'SONRAKİ SEVİYE';

  @override
  String get playWinBackToLevels => 'SEVİYELERE DÖN';

  @override
  String playChestNextAtLabel(int stars) {
    return 'Sonraki yıldız sandığı $stars yıldızda';
  }

  @override
  String get playChestOpenLabel => 'Yıldız sandığını aç';

  @override
  String get playChestReady => 'Bir yıldız sandığı hazır!';

  @override
  String playChestNextAt(int stars) {
    return 'Sonraki sandık: $stars ★';
  }

  @override
  String get playChestOpen => 'AÇ';

  @override
  String get playChestDoubleFailed => 'Bu sefer ikiye katlanamadı.';

  @override
  String get playChestDoubleNotFinished => 'Katlanmadı — video bitmedi.';

  @override
  String get playChestOpening => 'Açılıyor…';

  @override
  String playChestTitle(int index) {
    return 'Yıldız sandığı $index';
  }

  @override
  String get playChestNotYetTitle => 'Az kaldı';

  @override
  String get playChestAlreadyOpenTitle => 'Zaten açık';

  @override
  String get playChestFailedTitle => 'Açılamadı';

  @override
  String get playChestNotYetNote =>
      'En yeni yıldızların hâlâ sunucuya gidiyor. Biraz sonra tekrar dene.';

  @override
  String get playChestAlreadyOpenNote => 'Bu sandık başka bir cihazda açıldı.';

  @override
  String get playChestFailedNote => 'Bağlantını kontrol edip tekrar dene.';

  @override
  String playChestRewardCount(int count) {
    return '+$count';
  }

  @override
  String playChestHintsCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ipucu',
    );
    return '$_temp0';
  }

  @override
  String playChestTubesCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ek tüp',
    );
    return '$_temp0';
  }

  @override
  String playChestUnlocked(String name) {
    return 'Açıldı: $name';
  }

  @override
  String playChestBallSkinName(String skin) {
    return '$skin top görünümü';
  }

  @override
  String playChestTubeThemeName(String theme) {
    return '$theme tüpler';
  }

  @override
  String get playChestNewLook => 'yeni bir görünüm';

  @override
  String get playChestSavedNote =>
      'İhtiyacın olduğunda kullanmak için saklandı. İpucu ve + Tüp önce bunları kullanır.';

  @override
  String get playChestLoadingVideo => 'Video yükleniyor…';

  @override
  String get playChestDouble => 'Videoyla ikiye katla';

  @override
  String get playChestCollect => 'Topla';

  @override
  String playClockLabel(String time) {
    return 'Süre $time';
  }

  @override
  String playClockDetailLabel(
    String time,
    String par,
    String sign,
    int percent,
  ) {
    String _temp0 = intl.Intl.selectLogic(sign, {
      'plus': 'artı',
      'other': 'eksi',
    });
    return 'Süre $time, par $par, $_temp0 yüzde $percent puan';
  }

  @override
  String playClockBonusChip(String sign, int percent) {
    return '$sign%$percent puan';
  }

  @override
  String get playLoading => 'Yükleniyor';

  @override
  String get playWorking => 'Çalışıyor';

  @override
  String get playZenTitle => 'Zen';

  @override
  String get playZenIntro =>
      'Sonsuz bulmacalar. Saat yok, yıldız yok, sıralama yok — sadece dök.';

  @override
  String get playZenPaceCalm => 'Sakin';

  @override
  String get playZenPaceSteady => 'Dengeli';

  @override
  String get playZenPaceDeep => 'Derin';

  @override
  String playZenPaceColors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count renk',
    );
    return '$_temp0';
  }

  @override
  String playZenPaceLabel(String pace, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$pace, $count renk',
    );
    return '$_temp0';
  }

  @override
  String playZenBandPoured(String pace, int count) {
    return '$pace · $count döküldü';
  }

  @override
  String playZenPoured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Döktün! Şimdiye kadar $count.',
      one: 'Döktün!',
    );
    return '$_temp0';
  }

  @override
  String get playZenNext => 'İLERİ';

  @override
  String get playZenLeaveBody =>
      'Bu bulmacanın hamleleri kaydedilmeyecek. Döküş sayın kalır.';

  @override
  String get playZenDeadEnd =>
      'Buradan bitirmenin yolu yok. Geri al ya da baştan başla.';

  @override
  String get playZenNoHint => 'Şu an bu durum için ipucu yok.';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsSectionFeel => 'Hissiyat';

  @override
  String get settingsSectionVisibility => 'Görünürlük';

  @override
  String get settingsSectionLeaderboard => 'Sıralama';

  @override
  String get settingsSectionNotifications => 'Bildirimler';

  @override
  String get settingsSectionSupport => 'Destek';

  @override
  String get settingsSectionAccount => 'Hesap ve hakkında';

  @override
  String get settingsSectionDanger => 'Tehlikeli bölge';

  @override
  String get settingsSoundTitle => 'Ses efektleri';

  @override
  String get settingsSoundDetail => 'Dökme, düğmeler ve ödüller';

  @override
  String get settingsSoundVolume => 'Efekt ses düzeyi';

  @override
  String get settingsMusicTitle => 'Müzik';

  @override
  String get settingsMusicDetail => 'Asla kendi müziğinin üstüne çalmaz';

  @override
  String get settingsMusicVolume => 'Müzik ses düzeyi';

  @override
  String get settingsHapticsTitle => 'Titreşim';

  @override
  String get settingsHapticsDetail => 'Her top yerine oturunca hafif bir tık';

  @override
  String get settingsSmoothMotionTitle => 'Akıcı hareket';

  @override
  String get settingsSmoothMotionAuto => 'Otomatik';

  @override
  String get settingsSmoothMotion60 => '60 Hz';

  @override
  String get settingsSmoothMotionMax => 'Maks';

  @override
  String get settingsMotionUnknown =>
      'Otomatik, telefon yetişirse ekranın en yüksek hızını kullanır';

  @override
  String settingsMotionFixed(String max) {
    return 'Bu ekran yalnızca $max Hz\'de çalışır';
  }

  @override
  String settingsMotionBatterySaver(String current) {
    return 'Pil Tasarrufu onu $current Hz\'de tutuyor';
  }

  @override
  String settingsMotionAutoStuttered(String current, String max) {
    return '$current Hz\'de çalışıyor · bu telefon $max Hz\'de takıldı';
  }

  @override
  String settingsMotionAuto(String current) {
    return '$current Hz\'de çalışıyor · takılırsa 60 Hz\'e düşer';
  }

  @override
  String settingsMotionPinnedByPhone(String current) {
    return 'Telefonunun ekran ayarı onu $current Hz\'de tutuyor';
  }

  @override
  String settingsMotionStandard(String current, String max) {
    return '$current Hz\'de çalışıyor · bu ekran $max Hz\'e kadar çıkabilir';
  }

  @override
  String settingsMotionMax(String current) {
    return '$current Hz\'de çalışıyor, bu ekranın en yüksek hızı';
  }

  @override
  String get settingsBoldSymbolsTitle => 'Kalın semboller';

  @override
  String get settingsBoldSymbolsDetail =>
      'Renk körlüğü için daha belirgin şekiller';

  @override
  String get settingsRenameTitle => 'Adını değiştir';

  @override
  String get settingsRenameDetail => 'Sıralamalarda nasıl görünürsün';

  @override
  String get settingsShowOnBoardsTitle => 'Beni sıralamalarda göster';

  @override
  String get settingsShowOnBoardsDetail =>
      'Kapalıysa adın ve sıran gizlenir. Yıldızlar yine sayılır.';

  @override
  String get settingsHowToPlayTitle => 'Nasıl oynanır';

  @override
  String get settingsHowToPlayDetail => 'Rehberli ilk seviyeyi yeniden oyna';

  @override
  String get settingsQuestionsTitle => 'Sorular';

  @override
  String get settingsQuestionsDetail => 'Yıldızlar, ipuçları, saat ve dahası';

  @override
  String get settingsRateTitle => 'Pourfect\'i puanla';

  @override
  String get settingsRateDetail => 'Diğer oyunculara ne düşündüğünü anlat';

  @override
  String get settingsCollectionTitle => 'Koleksiyon';

  @override
  String get settingsCollectionDetail => 'Top görünümleri ve tüp temaları';

  @override
  String get settingsRestoreTitle => 'Satın alımları geri yükle';

  @override
  String get settingsRestoreDetail => 'Reklamları Kaldır veya Görünüm paketi';

  @override
  String get settingsRestoreDone => 'Varsa satın alımlar geri yüklendi.';

  @override
  String get settingsRemoveAdsTitle => 'Reklamları kaldır';

  @override
  String get settingsRemoveAdsDetail =>
      'Seviyeler arasında reklam yok. İpucu videoları kalır.';

  @override
  String get settingsAdsRemoved => 'Reklamlar kaldırıldı — teşekkürler';

  @override
  String get settingsPurchaseThanks =>
      'Teşekkürler. Seviyeler arası reklamlar kapandı.';

  @override
  String get settingsPurchaseAlreadyOwned =>
      'Zaten satın alındı — reklamlar kapalı.';

  @override
  String get settingsPurchasePending =>
      'Ödeme bekliyor. Onaylanınca reklamlar kapanacak.';

  @override
  String get settingsStoreUnavailable =>
      'Mağaza şu an bu cihazda kullanılamıyor.';

  @override
  String get settingsPurchaseFailed =>
      'Satın alma gerçekleşmedi. Ücret alınmadı.';

  @override
  String get settingsStoreOpenFailed => 'Mağaza açılamadı.';

  @override
  String get settingsBrowserOpenFailed => 'Tarayıcı açılamadı.';

  @override
  String get settingsSignedIn => 'Giriş yapıldı';

  @override
  String get settingsSignedInDetail => 'İlerlemen seninle gelir';

  @override
  String get settingsSaveProgressTitle => 'İlerlemeni kaydet';

  @override
  String get settingsSaveProgressDetail =>
      'Telefon değiştirsen de yıldızların kalsın';

  @override
  String get settingsPrivacyPolicy => 'Gizlilik politikası';

  @override
  String get settingsTermsAndLicenses => 'Koşullar ve lisanslar';

  @override
  String get settingsTermsOfUse => 'Kullanım koşulları';

  @override
  String get settingsRefundPolicy => 'İade politikası';

  @override
  String get settingsOpenSourceLicenses => 'Açık kaynak lisansları';

  @override
  String get settingsAdPrivacyTitle => 'Reklam gizliliği seçenekleri';

  @override
  String get settingsAdPrivacyDetail =>
      'Reklamlar için verdiğin izinleri değiştir';

  @override
  String get settingsResetRowTitle => 'İlerlemeyi sıfırla';

  @override
  String get settingsResetRowDetail =>
      'Tüm yıldızları sil ve 1. seviyeden başla';

  @override
  String get settingsResetTitle => 'İlerleme sıfırlansın mı?';

  @override
  String get settingsResetNothing => 'Henüz sıfırlanacak bir şey yok.';

  @override
  String settingsResetBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bu, çözülmüş $count seviyedeki tüm yıldızları ve en iyi skorları siler, 1. seviyeden sonrasını yeniden kilitler. Geri alınamaz.',
    );
    return '$_temp0';
  }

  @override
  String get settingsKeepIt => 'Kalsın';

  @override
  String get settingsResetConfirm => 'Her şeyi sil';

  @override
  String get settingsResetDone => 'İlerleme sıfırlandı.';

  @override
  String get settingsSignOutTitle => 'Çıkış yapılsın mı?';

  @override
  String get settingsSignOutBody =>
      'İlerlemen bu telefonda kalır. Başka bir yerde devam etmek için istediğin zaman tekrar giriş yapabilirsin.';

  @override
  String get settingsSignOutStay => 'Oturumu açık tut';

  @override
  String get settingsSignOutConfirm => 'Çıkış yap';

  @override
  String get settingsServerUnreachable =>
      'Sunucuya ulaşılamadı, hiçbir şey değişmedi.';

  @override
  String get settingsDeleteRowTitle => 'Hesabı sil';

  @override
  String get settingsDeleteRowDetail => 'Hesabını ve ona bağlı her şeyi kaldır';

  @override
  String get settingsDeleteTitle => 'Hesabın silinsin mi?';

  @override
  String get settingsDeleteBody =>
      'Bu işlem hesabını, yıldızlarını, serini ve sıralama kaydını bu telefondan ve sunucumuzdan kaldırır. Geri alınamaz.\n\nReklamları Kaldır etkilenmez — onu satın aldığın mağaza hesabına aittir ve tekrar oynarsan geri yüklenir.';

  @override
  String get settingsDeleteConfirm => 'Her şeyi sil';

  @override
  String get settingsDeleteServerRefused =>
      'Sunucuya ulaşılamadı. Hiçbir şey silinmedi — internete bağlanınca tekrar dene.';

  @override
  String get settingsDeleteNotAuthenticated =>
      'Sen olduğun doğrulanamadı. Yeniden giriş yap, sonra hesabını sil — henüz hiçbir şey silinmedi.';

  @override
  String settingsFooterVersion(String version) {
    return 'Pourfect $version';
  }

  @override
  String settingsFooterVersionBoards(int count, String version) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Pourfect $version · çözülebilirliği kanıtlanmış $count bulmacayla yapıldı',
    );
    return '$_temp0';
  }

  @override
  String get settingsNamingYou => 'Adın veriliyor…';

  @override
  String get settingsYourName => 'Adın';

  @override
  String get settingsGuest => 'Misafir olarak oynuyorsun';

  @override
  String get settingsStatSolved => 'ÇÖZÜLEN';

  @override
  String get settingsStatStars => 'YILDIZ';

  @override
  String get settingsNotifyTurnOnTitle => 'Bildirimleri aç';

  @override
  String get settingsNotifyDeniedDetail =>
      'Telefon ayarlarında kapalı. Açmak için dokun.';

  @override
  String get settingsNotifyNotYetDetail =>
      'Pourfect henüz bildirim gönderemiyor';

  @override
  String get settingsRemindersTitle => 'Günün Bulmacası hatırlatmaları';

  @override
  String get settingsRemindersDetail =>
      'Sabah ve akşam, günde en fazla iki kez';

  @override
  String get settingsNewsTitle => 'Oyun haberleri';

  @override
  String get settingsNewsDetail => 'Yeni dünyalar ve duyurular';

  @override
  String settingsToggleOn(String title) {
    return '$title, açık';
  }

  @override
  String settingsToggleOff(String title) {
    return '$title, kapalı';
  }

  @override
  String get settingsFaqSectionPlaying => 'Oynanış';

  @override
  String get settingsFaqSectionStuck => 'Takıldın mı?';

  @override
  String get settingsFaqSectionProgress => 'İlerlemen';

  @override
  String get settingsFaqSectionAds => 'Reklam ve ses';

  @override
  String get settingsFaqHowToPlayQ => 'Nasıl oynanır?';

  @override
  String get settingsFaqHowToPlayA =>
      'Bir tüpe dokunup üstteki topları al, sonra başka bir tüpe dokunup içine dök. Toplar yalnızca aynı rengin üstüne ya da boş bir tüpe düşer. Her tüpü tek renge ayırınca seviye biter. Ayarlar → Nasıl oynanır, rehberli ilk seviyeyi yeniden oynatır.';

  @override
  String get settingsFaqStarsQ => 'Yıldızlar ne anlama geliyor?';

  @override
  String get settingsFaqStarsA =>
      'Yıldızlar yalnızca hamleleri sayar. Par veya daha az hamleyle bitirirsen üç, par\'ın bir buçuk katı içinde bitirirsen iki yıldız alırsın; her bitiriş bir yıldız kazandırır. Par, seviyenin çözülebileceği en az hamle sayısıdır.';

  @override
  String get settingsFaqClockQ => 'Saat bana yıldız kaybettirir mi?';

  @override
  String get settingsFaqClockA =>
      'Asla. Süre yalnızca puanını değiştirir. Süre par\'ını geçip bonus puan kazan ya da istediğin kadar zaman ayır, tüm yıldızlarını koru.';

  @override
  String get settingsFaqSolvableQ => 'Her seviye çözülebilir mi?';

  @override
  String get settingsFaqSolvableA =>
      'Evet. Her bulmaca yayınlanmadan önce çözüldü ve par bu çözümden gelir, yani her zaman ulaşılabilir.';

  @override
  String get settingsFaqDailyQ => 'Günün Bulmacası nedir?';

  @override
  String get settingsFaqDailyA =>
      'Her gün kendi sıralamasıyla yeni bir bulmaca. İnternet bağlantısı gerekir. Kampanya seviyeleri için gerekmez.';

  @override
  String get settingsFaqUndoQ => 'Geri alma sınırlı mı?';

  @override
  String get settingsFaqUndoA =>
      'Hayır. Geri alma her seviyede ücretsiz ve sınırsız.';

  @override
  String get settingsFaqHintsQ => 'İpuçları nasıl çalışır?';

  @override
  String settingsFaqHintsA(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'İlk $count ipucun ücretsiz. Sonrasında kısa bir video bir ipucu kazandırır. İpucu bulunamazsa video yine bir sonrakine sayılır.',
      one: 'İlk ipucun ücretsiz. Sonrasında kısa bir video bir ipucu kazandırır. İpucu bulunamazsa video yine bir sonrakine sayılır.',
    );
    return '$_temp0';
  }

  @override
  String get settingsFaqTubeQ => '+ Tüp düğmesi nedir?';

  @override
  String get settingsFaqTubeA =>
      'Hamlelerin par\'a ulaştığında ya da bir ipucu bitirmenin yolu olmadığını gösterdiğinde, video izleyerek boş bir ek tüp alabilirsin; her denemede en fazla iki tane. Geri alma onu götürmez. Ek tüple bitirilen seviye en fazla iki yıldız kazandırır.';

  @override
  String get settingsFaqHardQ => 'ZOR seviyeler nedir?';

  @override
  String get settingsFaqHardA =>
      'Her on seviyenin en zorunda kırmızı bir ZOR rozeti olur. Diğer seviyeler gibi oynanır ve bir buçuk kat puan değerindedir.';

  @override
  String get settingsFaqChestsQ => 'Yıldız sandıkları nedir?';

  @override
  String get settingsFaqChestsA =>
      'Her 30 yıldız Yolculuk\'ta bir sandık açar: iki ipucu ve bir ek tüp, ihtiyacın olduğunda kullanmak için saklanır. Her üçüncü sandık ayrıca bir top görünümü açar.';

  @override
  String get settingsFaqFreezeQ => 'Seri dondurma nedir?';

  @override
  String get settingsFaqFreezeA =>
      'Günün Bulmacası\'nı bir gün kaçırırsan bir dondurma o günü korur ve serin devam eder. Her pazartesi bir tane ücretsiz alırsın, günde bir tane de videoyla kazanabilirsin; en fazla iki tane tutabilirsin.';

  @override
  String get settingsFaqAccountQ => 'Hesaba ihtiyacım var mı?';

  @override
  String get settingsFaqAccountA =>
      'Hayır. Misafir olarak oynarsın ve ilerlemen bu telefonda kaydedilir. Giriş yaparsan yeni bir telefona geçtiğinde yıldızların kalır.';

  @override
  String get settingsFaqOfflineQ => 'Çevrimdışı oynayabilir miyim?';

  @override
  String get settingsFaqOfflineA =>
      'Evet, kampanyanın tamamını. Günün Bulmacası ve sıralamalar bağlantı ister; ilerlemen internete bağlanınca eşitlenir.';

  @override
  String get settingsFaqNameQ => 'Sıralama adımı nasıl değiştiririm?';

  @override
  String get settingsFaqNameA =>
      'Ayarlar → Adını değiştir. Orada kendini sıralamalardan da gizleyebilirsin; yıldızların yine sayılır.';

  @override
  String get settingsFaqRemoveAdsQ => 'Reklamları kaldır ne işe yarar?';

  @override
  String get settingsFaqRemoveAdsA =>
      'Seviyeler arasındaki reklamları kapatır. İpucu ve tüp videoları kalır, çünkü onları yalnızca sen istediğinde görürsün.';

  @override
  String get settingsFaqReinstallQ =>
      'Yeniden yükledim. Reklamları kaldır nereye gitti?';

  @override
  String get settingsFaqReinstallA =>
      'Satın aldığın mağaza hesabına aittir ve genelde kendiliğinden geri gelir. Gelmezse Ayarlar → Satın alımları geri yükle\'ye dokun.';

  @override
  String get settingsFaqMusicQ => 'Oyun müziğimi durdurur mu?';

  @override
  String get settingsFaqMusicA =>
      'Hayır. Pourfect seslerini müziğin ya da podcast\'inle birlikte çalar. Ses ve titreşim Ayarlar\'dan kapatılabilir.';

  @override
  String get settingsLegalTitle => 'Dökmeden önce';

  @override
  String get settingsLegalIntro =>
      'Pourfect ücretsizdir, çevrimdışı çalışır ve hesap gerektirmez. Lütfen önce bunları okuyup kabul et.';

  @override
  String settingsLegalAcceptTerms(String document) {
    return '$document metnini kabul ediyorum';
  }

  @override
  String settingsLegalReadPrivacy(String document) {
    return '$document metnini okudum';
  }

  @override
  String settingsLegalAlsoCovers(String document, String version) {
    return 'Kabul etmen $document metnimizi de (sürüm $version) kapsar.';
  }

  @override
  String get settingsLegalPrivacyPolicy => 'Gizlilik Politikası';

  @override
  String get settingsLegalTermsOfService => 'Hizmet Koşulları';

  @override
  String get settingsLegalRefundPolicy => 'İade Politikası';

  @override
  String settingsLegalReadDocument(String document) {
    return '$document metnini oku';
  }

  @override
  String get settingsLegalAccept => 'HADİ DÖKELİM!';

  @override
  String get settingsLegalReadAgain =>
      'Bunları istediğin zaman Ayarlar\'da yeniden okuyabilirsin.';

  @override
  String get settingsLegalLoadFailed =>
      'Bu belge bu cihazda yüklenemedi.\n\nKabul etmeden önce legal.pranta.dev adresinden okuyabilirsin.';

  @override
  String get settingsUpdateTitle => 'Yeni Pourfect hazır';

  @override
  String get settingsUpdateBody =>
      'Google Play güncellemeyi indirecek ve bitince oyunu yeniden açacak. Yıldızların güvende.';

  @override
  String get settingsUpdateMandatoryTitle => 'Güncelleme zamanı';

  @override
  String get settingsUpdateMandatoryBody =>
      'Pourfect\'in bu sürümü artık desteklenmiyor. Google Play güncellemeyi indirip oyunu yeniden açacak. Yıldızların güvende.';

  @override
  String get settingsUpdateNow => 'Şimdi güncelle';

  @override
  String get settingsRenameHello => 'MERHABA';

  @override
  String get settingsRenameMyNameIs => 'BENİM ADIM';

  @override
  String get settingsRenameHint => 'Diğer oyuncular bunu sıralamalarda görür';

  @override
  String get settingsRenameSave => 'KAYDET';

  @override
  String settingsCollectionUnlockWith(String how) {
    return 'Açmak için: $how.';
  }

  @override
  String get settingsCollectionChangeFailed =>
      'Şu an değiştirilemedi. Daha sonra tekrar dene.';

  @override
  String get settingsPackThanks => 'Teşekkürler! Paket birazdan açılıyor.';

  @override
  String get settingsPackAlreadyOwned => 'Zaten senin. Şimdi geri yükleniyor.';

  @override
  String get settingsPackPending =>
      'Ödeme bekliyor. Onaylanınca paket açılacak.';

  @override
  String get settingsCollectionOffline =>
      'Koleksiyonunu görmek için internete bağlan.';

  @override
  String get settingsCollectionBallSkins => 'Top görünümleri';

  @override
  String get settingsCollectionTubeThemes => 'Tüp temaları';

  @override
  String settingsCollectionPreview(String skin, String theme) {
    return '$skin toplar · $theme tüpler';
  }

  @override
  String settingsCollectionItemWorn(String name) {
    return '$name, seçili';
  }

  @override
  String settingsCollectionItemTapToWear(String name) {
    return '$name, seçmek için dokun';
  }

  @override
  String settingsCollectionItemLocked(String name, String how) {
    return '$name, kilitli: $how';
  }

  @override
  String get settingsCollectionWearing => 'Seçili';

  @override
  String get settingsCollectionTapToWear => 'Seçmek için dokun';

  @override
  String settingsUnlockChest(int number) {
    return 'Yıldız sandığı $number';
  }

  @override
  String settingsUnlockStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days günlük seri',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnlockFree => 'Ücretsiz';

  @override
  String get settingsSkinPack => 'Görünüm paketi';

  @override
  String get settingsSkinPackDetail =>
      'Mermer, İnci ve Dama toplar; Ahşap ve Leylak tüpler.';

  @override
  String get settingsOwned => 'ALINDI';

  @override
  String get settingsSoon => 'Yakında';

  @override
  String get settingsSkinClassic => 'Klasik';

  @override
  String get settingsSkinGlossy => 'Parlak';

  @override
  String get settingsSkinStriped => 'Şeker çizgili';

  @override
  String get settingsSkinGlow => 'Işıltı';

  @override
  String get settingsSkinSpeckled => 'Konfeti';

  @override
  String get settingsSkinMarble => 'Mermer';

  @override
  String get settingsSkinPearl => 'İnci';

  @override
  String get settingsSkinChecker => 'Dama';

  @override
  String get settingsTubeToy => 'Oyuncak';

  @override
  String get settingsTubeFrost => 'Buzlu';

  @override
  String get settingsTubeWood => 'Ahşap';

  @override
  String get settingsTubeLilac => 'Leylak';
}
