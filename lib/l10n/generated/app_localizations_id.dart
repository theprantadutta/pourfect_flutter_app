// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get accountGoogleFailed =>
      'Login Google tidak berhasil di ponsel ini. Coba lagi, atau pakai email di bawah.';

  @override
  String get accountAppleFailed =>
      'Login Apple tidak berhasil di ponsel ini. Pastikan kamu sudah masuk ke Akun Apple di Pengaturan, atau pakai email di bawah.';

  @override
  String get accountExistsNoLocal =>
      'Kamu sudah punya akun dengan email itu. Masuk ke akun itu, dan ponsel ini akan memuat bintang yang tersimpan di sana.';

  @override
  String accountExistsWithLocal(int solved) {
    String _temp0 = intl.Intl.pluralLogic(
      solved,
      locale: localeName,
      other:
          'Kamu sudah punya akun dengan email itu. Ponsel ini punya $solved level selesai yang tidak ada di akun itu, dan keduanya tidak bisa digabung — masuk akan menggantinya dengan isi akun itu.',
    );
    return '$_temp0';
  }

  @override
  String get accountEmailInUse =>
      'Sudah ada akun dengan email itu. Coba masuk saja.';

  @override
  String get accountEmailMalformed => 'Sepertinya itu bukan alamat email.';

  @override
  String get accountPasswordWeak =>
      'Sandi itu terlalu mudah ditebak. Coba yang lebih panjang.';

  @override
  String get accountWrongPassword => 'Email dan sandi itu tidak cocok.';

  @override
  String get accountTooManyAttempts =>
      'Terlalu banyak percobaan. Tunggu beberapa menit, lalu coba lagi.';

  @override
  String get accountNeedsRecentLogin => 'Silakan masuk lagi dulu.';

  @override
  String get accountMethodNotEnabled =>
      'Login dengan email sedang tidak tersedia. Coba Lanjutkan dengan Google.';

  @override
  String get accountSessionUnavailable =>
      'Sudah masuk, tapi progresmu belum tersimpan di server. Progres akan disinkronkan saat koneksi kembali.';

  @override
  String get accountUnavailable =>
      'Tidak bisa terhubung ke server. Progresmu tetap aman di perangkat ini.';

  @override
  String get accountUseThatAccount => 'Pakai akun itu';

  @override
  String get accountExistingTitle => 'Kamu sudah punya akun';

  @override
  String get accountExistingBodyEmpty =>
      'Ponsel ini akan memuat bintang yang sudah tersimpan di akun itu.';

  @override
  String accountExistingBodyLocal(int cleared) {
    String _temp0 = intl.Intl.pluralLogic(
      cleared,
      locale: localeName,
      other:
          'Ponsel ini punya $cleared level selesai yang tidak ada di akun itu. Keduanya tidak bisa digabung, jadi level itu akan diganti dengan isi akun tersebut.',
    );
    return '$_temp0';
  }

  @override
  String get accountSignIn => 'Masuk';

  @override
  String get accountSignInCancelled =>
      'Login dibatalkan. Tidak ada yang berubah.';

  @override
  String get accountSignedInToast =>
      'Berhasil masuk. Bintangmu kini ikut pindah ke ponsel baru.';

  @override
  String get accountResetNeedsEmail =>
      'Masukkan email dulu, lalu ketuk Lupa sandi?';

  @override
  String get accountResetSent =>
      'Jika email itu punya akun, link reset sedang dikirim.';

  @override
  String get accountYourAccount => 'Akunmu';

  @override
  String accountRankValue(int rank) {
    return '#$rank';
  }

  @override
  String accountStreakValue(int days) {
    return '${days}h';
  }

  @override
  String get accountCardTravels =>
      'Kartu ini ikut akunmu, jadi di ponsel baru kamu lanjut dari posisi terakhir.';

  @override
  String get accountYourNameHeader => 'Namamu';

  @override
  String get accountChangeName => 'Ganti namamu';

  @override
  String get accountChangeNameDetail => 'Namamu di papan peringkat';

  @override
  String get accountShowOnBoards => 'Tampilkan aku di peringkat';

  @override
  String get accountShowOnBoardsDetail =>
      'Jika mati, nama dan peringkatmu disembunyikan. Bintang tetap dihitung.';

  @override
  String get accountYourPlayHeader => 'Permainanmu';

  @override
  String get accountStatistics => 'Statistik';

  @override
  String get accountStatisticsDetail => 'Waktu, aktivitas, dan semua levelmu';

  @override
  String get accountSessionHeader => 'Sesi';

  @override
  String get accountDeleteHint =>
      'Untuk menghapus akun, buka Setelan → Zona bahaya.';

  @override
  String get accountVisibilityFailed =>
      'Tidak bisa terhubung ke server, jadi tidak ada yang berubah.';

  @override
  String get accountSignOutTitle => 'Keluar?';

  @override
  String get accountSignOutBody =>
      'Progresmu tetap ada di ponsel ini. Kamu bisa masuk lagi kapan saja untuk melanjutkannya di tempat lain.';

  @override
  String get accountStaySignedIn => 'Tetap masuk';

  @override
  String get accountSignOut => 'Keluar';

  @override
  String get accountSignOutDetail => 'Progresmu tetap ada di ponsel ini';

  @override
  String get accountSaveTitle => 'Simpan progresmu';

  @override
  String get accountSaveIntro =>
      'Bintang, runtunan, dan nama peringkatmu ikut akunmu, jadi di ponsel baru kamu lanjut dari posisi terakhir.';

  @override
  String get accountContinueApple => 'Lanjutkan dengan Apple';

  @override
  String get accountContinueGoogle => 'Lanjutkan dengan Google';

  @override
  String get accountOr => 'ATAU';

  @override
  String get accountEmailLabel => 'Email';

  @override
  String get accountEmailEmpty => 'Masukkan email.';

  @override
  String get accountPasswordLabel => 'Sandi';

  @override
  String get accountPasswordHelper => 'Minimal 8 karakter';

  @override
  String get accountPasswordEmpty => 'Masukkan sandi.';

  @override
  String get accountPasswordShort => 'Minimal 8 karakter.';

  @override
  String get accountShowPassword => 'Tampilkan sandi';

  @override
  String get accountHidePassword => 'Sembunyikan sandi';

  @override
  String get accountCreate => 'Buat akun';

  @override
  String get accountSwitchToSignIn => 'Sudah punya akun? Masuk';

  @override
  String get accountSwitchToSignInSemantic => 'Masuk saja';

  @override
  String get accountSwitchToCreate => 'Belum punya akun? Buat sekarang';

  @override
  String get accountSwitchToCreateSemantic => 'Buat akun saja';

  @override
  String get accountForgotPassword => 'Lupa sandi?';

  @override
  String get accountForgotPasswordSemantic => 'Reset sandi';

  @override
  String get accountNaming => 'Memberi nama…';

  @override
  String get accountSignedInLabel => 'Sudah masuk';

  @override
  String accountPouringSince(String month, int year) {
    return 'MENUANG SEJAK $month $year';
  }

  @override
  String get accountPlayerCardTag => 'KARTU PEMAIN';

  @override
  String get accountStatSolved => 'SELESAI';

  @override
  String get accountStatStars => 'BINTANG';

  @override
  String get accountStatStreak => 'RUNTUNAN';

  @override
  String get accountStatRank => 'PERINGKAT';

  @override
  String accountStarsValue(int stars) {
    return '$stars★';
  }

  @override
  String get accountSyncing => 'Menyinkronkan…';

  @override
  String get accountSyncingDetail => 'Menyimpan progres ke akunmu';

  @override
  String get accountWaitingToSync => 'Menunggu sinkronisasi';

  @override
  String get accountWaitingOffline => 'Tersimpan saat kamu online lagi';

  @override
  String get accountWaitingPending => 'Level terbarumu dikirim berikutnya';

  @override
  String get accountSyncedDetail => 'Progres tersimpan di akunmu';

  @override
  String get accountSynced => 'Tersinkron';

  @override
  String get accountSyncedJustNow => 'Baru saja tersinkron';

  @override
  String accountSyncedMinutesAgo(int minutes) {
    return 'Tersinkron $minutes mnt lalu';
  }

  @override
  String accountSyncedHoursAgo(int hours) {
    return 'Tersinkron $hours jam lalu';
  }

  @override
  String accountSyncedDaysAgo(int days) {
    return 'Tersinkron $days hr lalu';
  }

  @override
  String get accountCrestSignedIn => 'Akunmu';

  @override
  String get accountCrestGuest => 'Bermain sebagai tamu';

  @override
  String get accountRenameRefused => 'Nama itu tidak diterima.';

  @override
  String get accountRenameOffline =>
      'Tidak bisa terhubung ke server. Coba lagi sebentar lagi.';

  @override
  String get ranksTitle => 'Peringkat';

  @override
  String get ranksTabToday => 'Hari ini';

  @override
  String get ranksTabCampaign => 'Kampanye';

  @override
  String get ranksLoading => 'Memuat papan peringkat…';

  @override
  String get ranksEmptyDailyTitle =>
      'Belum ada yang menyelesaikan papan hari ini';

  @override
  String get ranksEmptyDailyDetail => 'Jadilah yang pertama.';

  @override
  String get ranksEmptyCampaignTitle => 'Belum ada pemain berperingkat';

  @override
  String get ranksEmptyCampaignDetail => 'Bintang yang menentukan di sini.';

  @override
  String get ranksYourSpot => 'Posisimu';

  @override
  String ranksPlayerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString pemain di papan ini',
    );
    return '$_temp0';
  }

  @override
  String ranksMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count langkah',
    );
    return '$_temp0';
  }

  @override
  String ranksStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bintang',
    );
    return '$_temp0';
  }

  @override
  String ranksLevels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count level',
    );
    return '$_temp0';
  }

  @override
  String ranksInTime(String time) {
    return 'dalam $time';
  }

  @override
  String get ranksOpenSpot => 'Masih kosong';

  @override
  String ranksNameYou(String name) {
    return '$name (kamu)';
  }

  @override
  String ranksPlaceOpen(int place) {
    return 'Posisi $place, kosong';
  }

  @override
  String ranksPlaceSemantic(int rank, String name, String score) {
    return 'Posisi $rank, $name, $score';
  }

  @override
  String ranksScoreWithTieBreak(String score, String tieBreak) {
    return '$score, $tieBreak';
  }

  @override
  String get ranksOffTitle => 'Papan peringkat nonaktif di versi ini';

  @override
  String get ranksOffDetail => 'Kampanye tidak terpengaruh.';

  @override
  String get ranksLoadFailed => 'Papan tidak bisa dimuat';

  @override
  String get ranksOffline =>
      'Sepertinya kamu offline. Semua level tetap bisa dimainkan tanpa koneksi.';

  @override
  String get ranksTimeout => 'Server terlalu lama menjawab.';

  @override
  String get ranksServerError => 'Ada masalah di pihak kami. Progresmu aman.';

  @override
  String get ranksHiddenTitle => 'Kamu disembunyikan';

  @override
  String get ranksHiddenDetail =>
      'Bintang dan runtunanmu tetap dihitung — kamu hanya tidak tampil di sini. Tombolnya ada di Setelan.';

  @override
  String get statsTitle => 'Statistikmu';

  @override
  String get statsTabOverview => 'Ringkasan';

  @override
  String get statsTabLevels => 'Level';

  @override
  String get statsTabBadges => 'Lencana';

  @override
  String get statsPaceOnPar => 'pas par';

  @override
  String statsPaceUnder(int percent) {
    return '$percent% di bawah';
  }

  @override
  String statsPaceOver(int percent) {
    return '$percent% di atas';
  }

  @override
  String get statsEmptyTitle => 'Belum ada yang ditampilkan';

  @override
  String get statsEmptyBody =>
      'Selesaikan satu level dan halaman ini akan terisi: waktumu dibanding par, solusi terbaikmu, dan hari-hari kamu bermain.';

  @override
  String get statsBackToLevels => 'Kembali ke level';

  @override
  String get statsLevelsSolved => 'level selesai';

  @override
  String get statsStars => 'bintang';

  @override
  String get statsPoints => 'poin';

  @override
  String get statsPlayed => 'dimainkan';

  @override
  String get statsNowOn => 'saat ini';

  @override
  String get statsBestSolveMoves => 'langkah di solusi terbaik';

  @override
  String get statsAgainstClock => 'MELAWAN WAKTU';

  @override
  String get statsNoTimes =>
      'Belum ada catatan waktu. Level yang kamu selesaikan sebelum ada jam tidak punya waktu — mainkan ulang satu dan waktunya mulai dihitung.';

  @override
  String get statsFastest => 'Tercepat';

  @override
  String get statsLongest => 'Terlama';

  @override
  String get statsAvgPace => 'Rata-rata';

  @override
  String statsClockValue(String time, int level) {
    return '$time · L$level';
  }

  @override
  String statsUntimed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count level selesaimu diselesaikan sebelum ada jam dan tidak punya catatan waktu.',
    );
    return '$_temp0';
  }

  @override
  String statsUnderParSemantic(int under, int total) {
    return '$under dari $total level berwaktu di bawah par';
  }

  @override
  String get statsUnderParTag => 'DI BAWAH PAR';

  @override
  String get statsLast30Days => '30 HARI TERAKHIR';

  @override
  String statsStreakChip(int count) {
    return '$count hari beruntun';
  }

  @override
  String get statsNoStreak => 'tanpa runtunan';

  @override
  String statsDaysPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari bermain',
    );
    return '$_temp0';
  }

  @override
  String statsLevelsFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count level selesai',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'terbaik $count hari',
    );
    return '$_temp0';
  }

  @override
  String get statsToday => 'Hari ini';

  @override
  String statsMonthShort(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'jan': 'Jan',
      'feb': 'Feb',
      'mar': 'Mar',
      'apr': 'Apr',
      'may': 'Mei',
      'jun': 'Jun',
      'jul': 'Jul',
      'aug': 'Agu',
      'sep': 'Sep',
      'oct': 'Okt',
      'nov': 'Nov',
      'dec': 'Des',
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
      other: '$day · $count level',
    );
    return '$_temp0';
  }

  @override
  String statsBarNoPlay(String day) {
    return '$day · tidak main';
  }

  @override
  String get statsWorldAhead => 'belum';

  @override
  String get statsWorldNoTimes => 'tanpa waktu';

  @override
  String statsWorldPoints(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString poin';
  }

  @override
  String statsWorldSolvedSemantic(String name, int cleared, int total) {
    return '$name: $cleared dari $total selesai';
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

    return '$pointsString poin';
  }

  @override
  String get statsColLevel => 'LVL';

  @override
  String get statsColStars => 'BTG';

  @override
  String get statsColMoves => 'LANGKAH';

  @override
  String get statsColTime => 'WAKTU';

  @override
  String get statsColPoints => 'POIN';

  @override
  String statsMovesBestPossible(int moves, int best) {
    return '$moves langkah, terbaik yang mungkin $best';
  }

  @override
  String statsMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count langkah',
    );
    return '$_temp0';
  }

  @override
  String badgeUnlockedCount(int earned, int total) {
    return '$earned dari $total terbuka';
  }

  @override
  String get badgeUnlocked => 'Terbuka';

  @override
  String get badgeNotYet => 'Belum';

  @override
  String badgeProgress(int shown, int target) {
    return '$shown dari $target';
  }

  @override
  String badgeSemantic(String title, String description, String status) {
    return '$title: $description $status';
  }

  @override
  String get badgeFirstPourTitle => 'Tuangan pertama';

  @override
  String get badgeFirstPourDesc => 'Selesaikan level pertamamu.';

  @override
  String get badgePar10Title => 'Pas par';

  @override
  String get badgePar10Desc => 'Selesaikan 10 level tepat di par.';

  @override
  String get badgePar50Title => 'Ahli par';

  @override
  String get badgePar50Desc => 'Selesaikan 50 level tepat di par.';

  @override
  String get badgeCleanClearTitle => 'Tanpa mundur';

  @override
  String get badgeCleanClearDesc => 'Selesaikan satu level tanpa urungkan.';

  @override
  String get badgeSpeedyTitle => 'Tuang kilat';

  @override
  String get badgeSpeedyDesc =>
      'Selesaikan satu level dalam kurang dari 30 detik.';

  @override
  String get badgeLevels100Title => 'Seratus level';

  @override
  String get badgeLevels100Desc => 'Selesaikan 100 level.';

  @override
  String get badgeStars300Title => 'Pemburu bintang';

  @override
  String get badgeStars300Desc => 'Kumpulkan 300 bintang.';

  @override
  String get badgeWorldPerfectTitle => 'Dunia sempurna';

  @override
  String get badgeWorldPerfectDesc =>
      'Raih tiga bintang di semua level satu dunia.';

  @override
  String get badgeStreak7Title => 'Seminggu menuang';

  @override
  String get badgeStreak7Desc => 'Capai runtunan 7 hari di Tantangan Harian.';

  @override
  String get badgeStreak30Title => 'Sebulan menuang';

  @override
  String get badgeStreak30Desc => 'Capai runtunan 30 hari di Tantangan Harian.';

  @override
  String get badgeChests5Title => 'Pemburu harta';

  @override
  String get badgeChests5Desc => 'Buka 5 peti bintang.';

  @override
  String get badgeHard5Title => 'Pantang mundur';

  @override
  String get badgeHard5Desc => 'Selesaikan 5 level SULIT.';

  @override
  String get badgeEventFullTitle => 'Seminggu penuh';

  @override
  String get badgeEventFullDesc =>
      'Selesaikan ketujuh papan di satu event mingguan.';

  @override
  String get badgeZen25Title => 'Taman Zen';

  @override
  String get badgeZen25Desc => 'Selesaikan 25 papan di mode Zen.';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonBack => 'Kembali';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get commonNotNow => 'Nanti saja';

  @override
  String commonLevelN(int level) {
    return 'Level $level';
  }

  @override
  String get hubAccountYours => 'Akunmu';

  @override
  String get hubAccountSave => 'Simpan progresmu';

  @override
  String get hubPlayerFallback => 'Pemain';

  @override
  String get hubSettings => 'Setelan';

  @override
  String get hubTagline => 'TUANG · SUSUN · SANTAI';

  @override
  String hubStatChipSemantic(String value, String label) {
    return '$value $label. Statistik';
  }

  @override
  String get hubStatSolved => 'selesai';

  @override
  String get hubStatStars => 'bintang';

  @override
  String get hubStatStreak => 'runtunan';

  @override
  String hubStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari',
    );
    return '$_temp0';
  }

  @override
  String hubRankNumber(int rank) {
    return '#$rank';
  }

  @override
  String hubEventSemantic(int cleared, int total) {
    return 'Event mingguan, $cleared dari $total papan';
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
  String get hubZenSemantic => 'Mode Zen';

  @override
  String hubZenLockedSemantic(int level) {
    return 'Mode Zen terbuka di level $level';
  }

  @override
  String get hubZenOpen => 'Tanpa akhir, tanpa jam';

  @override
  String hubZenLocked(int level, int remaining) {
    return 'Level $level · $remaining lagi';
  }

  @override
  String get hubDockJourney => 'Perjalanan';

  @override
  String get hubDockRankings => 'Peringkat';

  @override
  String get hubDockStats => 'Statistik';

  @override
  String get hubTip =>
      'Mantap! Perjalanan memuat semua level, dan ada Tantangan Harian baru setiap hari.';

  @override
  String hubHeroWorld(int world) {
    return 'Dunia $world';
  }

  @override
  String hubHeroWorldBand(int world, String band) {
    return 'Dunia $world · $band';
  }

  @override
  String hubHeroPar(int par) {
    return 'par $par';
  }

  @override
  String get hubPlay => 'MAIN';

  @override
  String hubPlaySemantic(int level) {
    return 'Main level $level';
  }

  @override
  String get hubMoreUpdateTitle => 'Perbarui untuk level baru';

  @override
  String get hubMoreUpdateBody =>
      'Dunia baru sudah rilis, dan butuh Pourfect versi terbaru. Perbarui game untuk terus menuang.';

  @override
  String get hubMoreDownloadingTitle => 'Level baru segera datang';

  @override
  String get hubMoreDownloadingBody =>
      'Dunia berikutnya sedang diunduh. Cuma sebentar.';

  @override
  String get hubMoreAllDoneTitle => 'Semua sudah kamu tuang!';

  @override
  String get hubMoreOfflineBody =>
      'Sambungkan ke internet, dan level baru akan diunduh di latar belakang. Sambil menunggu, Tantangan Harian hari ini sudah siap.';

  @override
  String get hubMoreOnlineBody =>
      'Level baru diunduh di latar belakang setiap kali kamu online. Sambil menunggu, Tantangan Harian hari ini sudah siap.';

  @override
  String get hubMoreCheckAgain => 'Cek lagi';

  @override
  String hubAchievementOne(String title) {
    return 'Pencapaian terbuka: $title';
  }

  @override
  String hubAchievementMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pencapaian terbuka!',
    );
    return '$_temp0';
  }

  @override
  String get hubUpdateReady => 'Pembaruan siap dipasang.';

  @override
  String get hubUpdateRestart => 'Mulai ulang';

  @override
  String hubSpanSeconds(int seconds) {
    return '${seconds}d';
  }

  @override
  String hubSpanMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String hubSpanMinutesSeconds(int minutes, int seconds) {
    return '${minutes}m ${seconds}d';
  }

  @override
  String hubSpanHours(int hours) {
    return '${hours}j';
  }

  @override
  String hubSpanHoursMinutes(int hours, int minutes) {
    return '${hours}j ${minutes}m';
  }

  @override
  String get hubParOn => 'pas par';

  @override
  String hubParUnder(int percent) {
    return '$percent% di bawah par';
  }

  @override
  String hubParOver(int percent) {
    return '$percent% di atas par';
  }

  @override
  String get dailyTitle => 'Tantangan Harian';

  @override
  String get dailyCardSemantic => 'Tantangan hari ini';

  @override
  String get dailyCardUnavailable => 'papan hari ini tak bisa dimuat';

  @override
  String get dailyCardSolved => 'selesai';

  @override
  String dailyCardNextIn(String time) {
    return 'berikutnya $time';
  }

  @override
  String dailyCardEndsIn(String time) {
    return 'sisa $time';
  }

  @override
  String dailyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari beruntun',
    );
    return '$_temp0';
  }

  @override
  String dailyStreakMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari beruntun!',
    );
    return '$_temp0';
  }

  @override
  String get dailyRankSemantic => 'Papan peringkat';

  @override
  String dailyRankSemanticRanked(int rank) {
    return 'Papan peringkat, posisi $rank';
  }

  @override
  String get dailyRankSticker => 'RANK';

  @override
  String get dailyLeaveLost =>
      'Langkahmu di Tantangan Harian hari ini tidak akan disimpan. Kamu bisa mulai lagi kapan saja hari ini.';

  @override
  String get dailySubmitRefused => 'Server tidak menerima hasil itu.';

  @override
  String get dailySubmitFailed =>
      'Selesai — tapi hasilnya tidak bisa dikirim. Coba lagi nanti.';

  @override
  String get dailyHudLabel => 'Tantangan';

  @override
  String get dailyHudValue => 'Harian';

  @override
  String get dailyDeadEndRestart =>
      'Tidak ada jalan selesai dari sini. Ulangi untuk mencoba jalur lain.';

  @override
  String dailyDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tidak ada jalan selesai dari sini. Urungkan $count langkah untuk kembali ke jalur.',
    );
    return '$_temp0';
  }

  @override
  String get dailyActionRestart => 'Ulangi';

  @override
  String dailyActionUndo(int count) {
    return 'Urungkan $count';
  }

  @override
  String get dailyNoHint => 'Tidak ada petunjuk untuk posisi ini.';

  @override
  String get dailyLoadingTitle => 'Memuat papan hari ini';

  @override
  String get dailyOffTitle => 'Tantangan harian nonaktif di versi ini';

  @override
  String get dailyOffDetail =>
      'Kampanye tidak terpengaruh — semua level ada di perangkat ini.';

  @override
  String get dailyNoBoardTitle => 'Tidak ada papan hari ini';

  @override
  String get dailyNoBoardDetail =>
      'Tantangan hari ini datang dari server, dan server tidak bisa dijangkau. Kampanye tidak membutuhkannya.';

  @override
  String get dailyLoaderCaption => 'Menuang papan hari ini…';

  @override
  String get dailyBackToLevels => 'Kembali ke level';

  @override
  String dailyWeekSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari',
    );
    return 'Runtunanmu: $_temp0. Buka';
  }

  @override
  String dailyDaySemantic(String weekday, String state) {
    return '$weekday, $state';
  }

  @override
  String get dailyDayFrozen => 'terlewat, dilindungi pelindung';

  @override
  String get dailyDayPlayedToday => 'dimainkan hari ini';

  @override
  String get dailyDayPlayed => 'dimainkan';

  @override
  String get dailyDayToday => 'hari ini, belum dimainkan';

  @override
  String get dailyDayMissed => 'tidak dimainkan';

  @override
  String get dailyDayFuture => 'belum tiba';

  @override
  String get dailyOutcomeBest => 'Rekor baru';

  @override
  String get dailyOutcomeSolved => 'Selesai';

  @override
  String get dailyFigureMoves => 'langkah';

  @override
  String get dailyFigureStreak => 'runtunan';

  @override
  String get dailyUnranked => 'tanpa peringkat';

  @override
  String dailyOfPlayers(int count) {
    return 'dari $count';
  }

  @override
  String get dailyReminderOn => 'Kamu akan dapat satu pengingat besok malam.';

  @override
  String get dailyRemindMe => 'Ingatkan aku besok';

  @override
  String get dailyDone => 'SELESAI';

  @override
  String get dailyFreezeVideoUnfinished =>
      'Tidak dapat pelindung — videonya tidak ditonton sampai habis.';

  @override
  String get dailyFreezeNoVideo => 'Tidak ada video untuk saat ini.';

  @override
  String get dailyFreezeError => 'Ada yang salah. Coba lagi nanti.';

  @override
  String get dailyFreezeAdded =>
      'Pelindung ditambahkan. Satu hari terlewat kini aman.';

  @override
  String get dailyFreezeNoRoom =>
      'Tidak bisa menambah pelindung lagi hari ini.';

  @override
  String get dailyFreezeLoadingVideo => 'Memuat video…';

  @override
  String get dailyFreezeWatch => 'Tonton video untuk pelindung';

  @override
  String get dailyFreezesFull =>
      'Pelindung penuh. Masing-masing melindungi satu hari yang terlewat.';

  @override
  String get dailyFreezeTomorrow =>
      'Satu pelindung dari video per hari. Kembali besok.';

  @override
  String get dailyStreakTitle => 'Runtunanmu';

  @override
  String get dailyStreakNone => 'Belum ada runtunan';

  @override
  String get dailyStreakStart =>
      'Mainkan Tantangan Harian hari ini untuk memulainya.';

  @override
  String dailyStreakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Terbaik: $count hari',
    );
    return '$_temp0';
  }

  @override
  String dailyFreezesSemantic(int count, int max) {
    return '$count dari $max pelindung runtunan';
  }

  @override
  String get dailyFreezesTitle => 'Pelindung runtunan';

  @override
  String get dailyFreezesEach => 'Masing-masing melindungi satu hari terlewat.';

  @override
  String dailyFreezeWeekly(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Gratis satu setiap Senin, $days hari lagi.',
      one: 'Gratis satu setiap Senin, besok.',
    );
    return '$_temp0';
  }

  @override
  String get dailyCalendarPrevious => 'Bulan sebelumnya';

  @override
  String get dailyCalendarNext => 'Bulan berikutnya';

  @override
  String dailyCalendarCellSemantic(String date, String state) {
    return '$date, $state';
  }

  @override
  String get dailyCalendarPlayed => 'dimainkan';

  @override
  String get dailyCalendarFrozen => 'dilindungi';

  @override
  String get dailyCalendarFuture => 'akan datang';

  @override
  String get dailyLegendPlayed => 'Dimainkan';

  @override
  String get dailyLegendFrozen => 'Dilindungi';

  @override
  String get dailyLegendToday => 'Hari ini';

  @override
  String get eventTitle => 'Event mingguan';

  @override
  String get eventUnreachable => 'Event minggu ini sedang tidak bisa dimuat.';

  @override
  String get eventEnded => 'berakhir';

  @override
  String eventEndsIn(String timeLeft) {
    return 'berakhir $timeLeft lagi';
  }

  @override
  String eventTimeLeftDaysHours(int days, int hours) {
    return '${days}h ${hours}j';
  }

  @override
  String eventTimeLeftHours(int hours) {
    return '${hours}j';
  }

  @override
  String eventTimeLeftMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String eventSummary(int cleared, int total, String endsIn) {
    return '$cleared dari $total papan · $endsIn';
  }

  @override
  String get eventFigurePoints => 'poin';

  @override
  String eventRankOf(int count) {
    return 'dari $count';
  }

  @override
  String get eventRankPlay => 'main satu papan untuk masuk peringkat';

  @override
  String get eventRankSetName => 'pasang nama untuk masuk peringkat';

  @override
  String eventTileSemanticDone(int slot, int stars, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars bintang',
    );
    return 'Papan $slot, $_temp0, $points poin';
  }

  @override
  String eventTileSemanticNew(int slot) {
    return 'Papan $slot, belum dimainkan';
  }

  @override
  String eventTilePoints(int points) {
    return '$points poin';
  }

  @override
  String get eventStandingsTitle => 'Peringkat minggu ini';

  @override
  String get eventStandingsEmpty =>
      'Belum ada siapa pun di papan. Jadilah yang pertama.';

  @override
  String eventStandingsCleared(int cleared) {
    return ' · $cleared/7';
  }

  @override
  String get eventSubmitRefused =>
      'Server tidak menerima hasil itu — mungkin event sudah berakhir.';

  @override
  String get eventSubmitFailed =>
      'Selesai — tapi hasilnya tidak bisa dikirim. Coba lagi.';

  @override
  String eventDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tidak ada jalan selesai dari sini. Urungkan $count langkah.',
    );
    return '$_temp0';
  }

  @override
  String get eventNoHint => 'Belum ada petunjuk untuk posisi ini.';

  @override
  String get eventHudLabel => 'Papan';

  @override
  String eventHudBand(String event, String endsIn) {
    return '$event · $endsIn';
  }

  @override
  String get eventSending => 'Mengirim…';

  @override
  String eventResult(int points, int total) {
    return '$points poin · $total minggu ini';
  }

  @override
  String eventResultRanked(int points, int total, int rank) {
    return '$points poin · $total minggu ini · #$rank';
  }

  @override
  String get journeyTitle => 'Perjalanan';

  @override
  String journeyStarsSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bintang',
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
    return 'Dunia $world dari $worlds, $name, $solved dari $total selesai';
  }

  @override
  String journeyWorldOf(int world, int worlds) {
    return 'DUNIA $world DARI $worlds';
  }

  @override
  String journeyRibbonSemantic(int world, String name, int solved, int total) {
    return 'Dunia $world, $name, $solved dari $total selesai. Gulir ke sana';
  }

  @override
  String journeyRibbonLabel(int world, String name) {
    return 'DUNIA $world · $name';
  }

  @override
  String get journeyYouPin => 'KAMU';

  @override
  String journeyBandCaps(int world, int count) {
    return 'DUNIA $world · $count';
  }

  @override
  String get journeyBandFirstPours => 'Langkah Pertama';

  @override
  String get journeyBandFindingRhythm => 'Menemukan Ritme';

  @override
  String get journeyBandDeepWater => 'Perairan Dalam';

  @override
  String get journeyBandMastery => 'Mahir';

  @override
  String get notifSoftAskTitle => 'Mau diingatkan?';

  @override
  String get notifSoftAskBody =>
      'Kabar singkat saat Tantangan Harian hari ini sudah ada, atau level berikutnya menunggu. Paling banyak dua kali sehari, dan bisa kamu matikan kapan saja di Setelan.';

  @override
  String get notifSoftAskBodyDenied =>
      'Notifikasi untuk Pourfect sedang mati. Nyalakan di setelan ponselmu agar dapat kabar saat Tantangan Harian sudah ada atau dunia baru tiba. Paling banyak dua kali sehari.';

  @override
  String get notifSoftAskOpenSettings => 'Buka setelan';

  @override
  String get notifSoftAskYes => 'Boleh';

  @override
  String get notifChannelName => 'Pengingat';

  @override
  String get notifChannelDescription =>
      'Tantangan Harian, level berikutnya, dan dunia baru. Paling banyak dua kali sehari.';

  @override
  String get playHudLevel => 'Level';

  @override
  String playHudTitle(String label, String value) {
    return '$label $value';
  }

  @override
  String get playHudHard => 'SULIT ×1.5';

  @override
  String get playHudHardLabel => 'Level sulit, poin satu setengah kali lipat';

  @override
  String get playHudMoves => 'LANGKAH';

  @override
  String playHudMovesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count langkah',
    );
    return '$_temp0';
  }

  @override
  String playParLeftFor3Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sisa $count langkah untuk 3 bintang',
    );
    return '$_temp0';
  }

  @override
  String get playParSpent => 'Par habis · 2 bintang dari sini';

  @override
  String playParLeftFor2Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sisa $count langkah untuk 2 bintang',
    );
    return '$_temp0';
  }

  @override
  String get playParOneStarFromHere => '1 bintang dari sini · asal selesai';

  @override
  String get playParAnyFinish => 'Asal selesai dapat 1 bintang';

  @override
  String playParMeterLabel(int stars, int used, int par, String words) {
    return 'Tempo $stars bintang, $used dari par $par langkah. $words';
  }

  @override
  String playHudBusyLabel(String label) {
    return '$label, sedang diproses. Ketuk untuk batal';
  }

  @override
  String get playHudUndo => 'Urungkan';

  @override
  String get playHudHint => 'Petunjuk';

  @override
  String get playHudRestart => 'Ulangi';

  @override
  String get playExtraTubeLabel => 'Tonton video untuk tabung tambahan';

  @override
  String get playExtraTubeChip => '+ Tabung';

  @override
  String playStarsOfTotal(int earned, int total) {
    return '$earned dari $total bintang';
  }

  @override
  String get playDismiss => 'Tutup';

  @override
  String get playLeaveTitleSoSoon => 'Kok buru-buru?';

  @override
  String get playLeaveTitleMissYou => 'Bolanya bakal kangen kamu';

  @override
  String get playLeaveTitleAbandon => 'Tinggalkan tuanganmu?';

  @override
  String get playLeaveTitleMidPour => 'Pergi di tengah tuangan?';

  @override
  String get playLeaveBody =>
      'Langkah dan waktumu di papan ini tidak akan disimpan.';

  @override
  String get playLeaveKeepPouring => 'Lanjut menuang';

  @override
  String get playLeaveConfirm => 'Keluar';

  @override
  String get playTutorialSkipLabel => 'Lewati tutorial';

  @override
  String get playTutorialSkip => 'Lewati';

  @override
  String playTipBubbleLabel(String text) {
    return '$text. Tutup';
  }

  @override
  String get playTipPar =>
      'Selesaikan dalam par untuk tiga bintang. Bilah menunjukkan berapa yang sudah kamu pakai.';

  @override
  String get playTipTallTubes =>
      'Tabung lebih tinggi! Sekarang tiap tabung muat lima bola.';

  @override
  String get playTipHint =>
      'Buntu? Petunjuk menunjukkan langkah berikutnya yang bagus.';

  @override
  String get playTipUndo =>
      'Lewat par? Urungkan gratis — mundur sejauh yang kamu mau.';

  @override
  String get playGuideSorted =>
      'Tersusun! Sekarang buat tiap tabung satu warna.';

  @override
  String get playGuideDrop =>
      'Sekarang ketuk tujuannya: di atas warna yang sama, atau tabung kosong.';

  @override
  String get playGuideWrongTube =>
      'Ketuk tabung yang ditunjuk tangan untuk mengambil bola itu.';

  @override
  String get playGuideFirstTap =>
      'Ketuk tabung untuk mengambil bola paling atas.';

  @override
  String get playGuideFirstPour => 'Itu satu tuangan! Lanjutkan.';

  @override
  String get playGuideKeepGoing => 'Lanjutkan: satu warna per tabung.';

  @override
  String playCoachHolding(int count) {
    return 'Memegang $count · taruh di tabung yang memantul';
  }

  @override
  String get playExtraTubeAdTitle => 'Tonton video untuk tabung tambahan?';

  @override
  String get playExtraTubeAdBody =>
      'Satu tabung kosong lagi untuk level ini. Level yang selesai dengan tabung tambahan dapat paling banyak dua bintang.';

  @override
  String get playExtraTubeNotFinished =>
      'Tidak dapat tabung — videonya tidak ditonton sampai habis.';

  @override
  String get playExtraTubeSaved => 'Tersimpan — tabung berikutnya gratis.';

  @override
  String get playNoVideo => 'Tidak ada video untuk saat ini.';

  @override
  String get playRewardFailed => 'Ada yang salah. Tidak ada yang terpakai.';

  @override
  String get playHintShowing =>
      'Petunjukmu sedang tampil: tuang ke tabung yang menyala.';

  @override
  String get playHintNoneNothingUsed =>
      'Tidak ada petunjuk untuk posisi ini. Tidak ada yang terpakai.';

  @override
  String get playHintNotFinished =>
      'Tidak dapat petunjuk — videonya tidak ditonton sampai habis.';

  @override
  String get playHintVideoSaved =>
      'Videomu disimpan untuk petunjuk berikutnya.';

  @override
  String get playHintNoneVideoSaved =>
      'Tidak ada petunjuk untuk posisi ini — videomu disimpan untuk petunjuk berikutnya.';

  @override
  String get playHintNone => 'Tidak ada petunjuk untuk posisi ini.';

  @override
  String get playHintHere => 'Ini petunjukmu — tuang ke tabung yang menyala.';

  @override
  String get playDeadEndRestart =>
      'Tidak ada jalan selesai dari sini. Ulangi untuk mencoba jalur lain.';

  @override
  String get playDeadEndRestartTube =>
      'Tidak ada jalan selesai dari sini. Ulangi untuk mencoba jalur lain. Atau ketuk + Tabung untuk tabung cadangan.';

  @override
  String playDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tidak ada jalan selesai dari sini. Urungkan $count langkah untuk kembali ke jalur.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoTube(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tidak ada jalan selesai dari sini. Urungkan $count langkah untuk kembali ke jalur. Atau ketuk + Tabung untuk tabung cadangan.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoAction(int count) {
    return 'Urungkan $count';
  }

  @override
  String get playHintAdTitle => 'Tonton video untuk petunjuk?';

  @override
  String playHintAdFreeLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sisa $count petunjuk gratis.',
    );
    return '$_temp0';
  }

  @override
  String get playHintAdNoneLeft =>
      'Petunjuk gratismu sudah habis. Satu video singkat memberi satu lagi.';

  @override
  String get playWatch => 'Tonton';

  @override
  String get playLoadFailed => 'Level tidak bisa dimuat';

  @override
  String get playTubeSorted => 'BERES!';

  @override
  String get playWinTitlePerfect => 'Tuangan\nSempurna!';

  @override
  String get playWinTitleNice => 'Tuangan\nMantap!';

  @override
  String get playWinTitlePoured => 'Tertuang!';

  @override
  String get playWinLastPour => 'Tuangan terakhir…';

  @override
  String playWinMovesPar(int count, int par) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count LANGKAH · PAR $par',
    );
    return '$_temp0';
  }

  @override
  String playWinLevelBand(int level, String band) {
    return 'Level $level · $band';
  }

  @override
  String get playWinNewBest => 'REKOR BARU!';

  @override
  String playWinMovesChip(int par) {
    return 'langkah · par $par';
  }

  @override
  String get playWinUntimed => 'tanpa waktu';

  @override
  String get playWinFastest => 'tercepat!';

  @override
  String get playWinTime => 'waktu';

  @override
  String get playWinUnderPar => 'DI BAWAH PAR!';

  @override
  String get playWinPoints => 'poin';

  @override
  String playWinWorldBand(int world, String band) {
    return 'DUNIA $world · $band';
  }

  @override
  String get playWinTryAssisted =>
      'Tiga bintang butuh penyelesaian tanpa tabung tambahan.';

  @override
  String playWinTryShort(int par, int took, int short) {
    String _temp0 = intl.Intl.pluralLogic(
      short,
      locale: localeName,
      other: 'Par $par, kamu $took. $short langkah lagi ke 3★.',
      one: 'Par $par, kamu $took. Satu langkah lagi ke 3★.',
    );
    return '$_temp0';
  }

  @override
  String playWinTryInReach(int par) {
    return 'Par $par. Tiga bintang sudah dekat.';
  }

  @override
  String get playWinTryButton => 'COBA 3★';

  @override
  String get playWinTryButtonLabel =>
      'Mainkan ulang level ini untuk tiga bintang';

  @override
  String get playWinReplayLabel => 'Mainkan ulang level ini';

  @override
  String get playWinHomeLabel => 'Kembali ke layar utama';

  @override
  String get playWinNextLevel => 'LEVEL BERIKUTNYA';

  @override
  String get playWinBackToLevels => 'KEMBALI KE LEVEL';

  @override
  String playChestNextAtLabel(int stars) {
    return 'Peti bintang berikutnya di $stars bintang';
  }

  @override
  String get playChestOpenLabel => 'Buka peti bintang';

  @override
  String get playChestReady => 'Peti bintang siap dibuka!';

  @override
  String playChestNextAt(int stars) {
    return 'Peti berikutnya di $stars ★';
  }

  @override
  String get playChestOpen => 'BUKA';

  @override
  String get playChestDoubleFailed => 'Kali ini tidak bisa digandakan.';

  @override
  String get playChestDoubleNotFinished =>
      'Tidak digandakan — videonya tidak ditonton sampai habis.';

  @override
  String get playChestOpening => 'Membuka…';

  @override
  String playChestTitle(int index) {
    return 'Peti bintang $index';
  }

  @override
  String get playChestNotYetTitle => 'Sedikit lagi';

  @override
  String get playChestAlreadyOpenTitle => 'Sudah dibuka';

  @override
  String get playChestFailedTitle => 'Tidak bisa dibuka';

  @override
  String get playChestNotYetNote =>
      'Bintang terbarumu masih dalam perjalanan ke server. Coba lagi sebentar lagi.';

  @override
  String get playChestAlreadyOpenNote =>
      'Peti ini sudah dibuka di perangkat lain.';

  @override
  String get playChestFailedNote => 'Periksa koneksimu dan coba lagi.';

  @override
  String playChestRewardCount(int count) {
    return '+$count';
  }

  @override
  String playChestHintsCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'petunjuk',
    );
    return '$_temp0';
  }

  @override
  String playChestTubesCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tabung ekstra',
    );
    return '$_temp0';
  }

  @override
  String playChestUnlocked(String name) {
    return 'Terbuka: $name';
  }

  @override
  String playChestBallSkinName(String skin) {
    return 'Skin bola $skin';
  }

  @override
  String playChestTubeThemeName(String theme) {
    return 'Tabung $theme';
  }

  @override
  String get playChestNewLook => 'tampilan baru';

  @override
  String get playChestSavedNote =>
      'Disimpan untuk saat kamu butuh. Petunjuk dan + Tabung memakai ini lebih dulu.';

  @override
  String get playChestLoadingVideo => 'Memuat video…';

  @override
  String get playChestDouble => 'Gandakan dengan video';

  @override
  String get playChestCollect => 'Ambil';

  @override
  String playClockLabel(String time) {
    return 'Waktu $time';
  }

  @override
  String playClockDetailLabel(
    String time,
    String par,
    String sign,
    int percent,
  ) {
    String _temp0 = intl.Intl.selectLogic(sign, {
      'plus': 'plus',
      'other': 'minus',
    });
    return 'Waktu $time dari par $par, $_temp0 $percent persen poin';
  }

  @override
  String playClockBonusChip(String sign, int percent) {
    return '$sign$percent% poin';
  }

  @override
  String get playLoading => 'Memuat';

  @override
  String get playWorking => 'Memproses';

  @override
  String get playZenTitle => 'Zen';

  @override
  String get playZenIntro =>
      'Papan tanpa akhir. Tanpa jam, tanpa bintang, tanpa peringkat — tuang saja.';

  @override
  String get playZenPaceCalm => 'Tenang';

  @override
  String get playZenPaceSteady => 'Stabil';

  @override
  String get playZenPaceDeep => 'Dalam';

  @override
  String playZenPaceColors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warna',
    );
    return '$_temp0';
  }

  @override
  String playZenPaceLabel(String pace, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$pace, $count warna',
    );
    return '$_temp0';
  }

  @override
  String playZenBandPoured(String pace, int count) {
    return '$pace · $count tertuang';
  }

  @override
  String playZenPoured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tertuang! Sudah $count.',
      one: 'Tertuang!',
    );
    return '$_temp0';
  }

  @override
  String get playZenNext => 'LANJUT';

  @override
  String get playZenLeaveBody =>
      'Langkah di papan ini tidak akan disimpan. Jumlah tuanganmu tetap.';

  @override
  String get playZenDeadEnd =>
      'Tidak ada jalan selesai dari sini. Urungkan atau ulangi.';

  @override
  String get playZenNoHint => 'Belum ada petunjuk untuk posisi ini.';

  @override
  String get settingsTitle => 'Setelan';

  @override
  String get settingsSectionFeel => 'Nuansa';

  @override
  String get settingsSectionVisibility => 'Visibilitas';

  @override
  String get settingsSectionLeaderboard => 'Peringkat';

  @override
  String get settingsSectionNotifications => 'Notifikasi';

  @override
  String get settingsSectionSupport => 'Bantuan';

  @override
  String get settingsSectionAccount => 'Akun & info';

  @override
  String get settingsSectionDanger => 'Zona bahaya';

  @override
  String get settingsSoundTitle => 'Efek suara';

  @override
  String get settingsSoundDetail => 'Tuangan, tombol, dan hadiah';

  @override
  String get settingsSoundVolume => 'Volume efek';

  @override
  String get settingsMusicTitle => 'Musik';

  @override
  String get settingsMusicDetail => 'Tidak pernah menimpa musikmu sendiri';

  @override
  String get settingsMusicVolume => 'Volume musik';

  @override
  String get settingsHapticsTitle => 'Getaran';

  @override
  String get settingsHapticsDetail => 'Getar halus tiap bola mendarat';

  @override
  String get settingsSmoothMotionTitle => 'Gerakan mulus';

  @override
  String get settingsSmoothMotionAuto => 'Otomatis';

  @override
  String get settingsSmoothMotion60 => '60 Hz';

  @override
  String get settingsSmoothMotionMax => 'Maks';

  @override
  String get settingsMotionUnknown =>
      'Otomatis memakai kecepatan tertinggi layar jika ponsel ini sanggup';

  @override
  String settingsMotionFixed(String max) {
    return 'Layar ini hanya berjalan di $max Hz';
  }

  @override
  String settingsMotionBatterySaver(String current) {
    return 'Penghemat Baterai menahannya di $current Hz';
  }

  @override
  String settingsMotionAutoStuttered(String current, String max) {
    return 'Berjalan di $current Hz · ponsel ini tersendat di $max Hz';
  }

  @override
  String settingsMotionAuto(String current) {
    return 'Berjalan di $current Hz · turun ke 60 Hz jika tersendat';
  }

  @override
  String settingsMotionPinnedByPhone(String current) {
    return 'Setelan layar ponselmu menahannya di $current Hz';
  }

  @override
  String settingsMotionStandard(String current, String max) {
    return 'Berjalan di $current Hz · layar ini sanggup $max Hz';
  }

  @override
  String settingsMotionMax(String current) {
    return 'Berjalan di $current Hz, tercepat untuk layar ini';
  }

  @override
  String get settingsBoldSymbolsTitle => 'Simbol tebal';

  @override
  String get settingsBoldSymbolsDetail => 'Bentuk lebih tegas untuk buta warna';

  @override
  String get settingsRenameTitle => 'Ganti namamu';

  @override
  String get settingsRenameDetail => 'Namamu di papan peringkat';

  @override
  String get settingsShowOnBoardsTitle => 'Tampilkan aku di peringkat';

  @override
  String get settingsShowOnBoardsDetail =>
      'Jika mati, nama dan peringkatmu disembunyikan. Bintang tetap dihitung.';

  @override
  String get settingsHowToPlayTitle => 'Cara bermain';

  @override
  String get settingsHowToPlayDetail => 'Ulangi level pertama yang dipandu';

  @override
  String get settingsQuestionsTitle => 'Pertanyaan';

  @override
  String get settingsQuestionsDetail => 'Bintang, petunjuk, jam, dan lainnya';

  @override
  String get settingsRateTitle => 'Beri nilai Pourfect';

  @override
  String get settingsRateDetail => 'Ceritakan pendapatmu ke pemain lain';

  @override
  String get settingsCollectionTitle => 'Koleksi';

  @override
  String get settingsCollectionDetail => 'Skin bola dan tema tabung';

  @override
  String get settingsRestoreTitle => 'Pulihkan pembelian';

  @override
  String get settingsRestoreDetail => 'Hapus Iklan atau Paket Skin';

  @override
  String get settingsRestoreDone => 'Pembelian dipulihkan, jika ada.';

  @override
  String get settingsRemoveAdsTitle => 'Hapus iklan';

  @override
  String get settingsRemoveAdsDetail =>
      'Tanpa iklan antar-level. Video petunjuk tetap ada.';

  @override
  String get settingsAdsRemoved => 'Iklan dihapus — terima kasih';

  @override
  String get settingsPurchaseThanks =>
      'Terima kasih. Iklan antar-level sudah mati.';

  @override
  String get settingsPurchaseAlreadyOwned => 'Sudah dibeli — iklan sudah mati.';

  @override
  String get settingsPurchasePending =>
      'Pembayaran tertunda. Iklan akan mati setelah pembayaran selesai.';

  @override
  String get settingsStoreUnavailable =>
      'Toko sedang tidak tersedia di perangkat ini.';

  @override
  String get settingsPurchaseFailed =>
      'Pembelian tidak berhasil. Kamu tidak dikenai biaya.';

  @override
  String get settingsStoreOpenFailed => 'Toko tidak bisa dibuka.';

  @override
  String get settingsBrowserOpenFailed => 'Browser tidak bisa dibuka.';

  @override
  String get settingsSignedIn => 'Sudah masuk';

  @override
  String get settingsSignedInDetail => 'Progresmu ikut ke mana pun';

  @override
  String get settingsSaveProgressTitle => 'Simpan progresmu';

  @override
  String get settingsSaveProgressDetail => 'Bintangmu ikut saat ganti ponsel';

  @override
  String get settingsPrivacyPolicy => 'Kebijakan privasi';

  @override
  String get settingsTermsAndLicenses => 'Ketentuan & lisensi';

  @override
  String get settingsTermsOfUse => 'Ketentuan penggunaan';

  @override
  String get settingsRefundPolicy => 'Kebijakan pengembalian dana';

  @override
  String get settingsOpenSourceLicenses => 'Lisensi open source';

  @override
  String get settingsAdPrivacyTitle => 'Opsi privasi iklan';

  @override
  String get settingsAdPrivacyDetail => 'Ubah persetujuanmu soal iklan';

  @override
  String get settingsResetRowTitle => 'Reset progres';

  @override
  String get settingsResetRowDetail =>
      'Hapus semua bintang dan mulai dari level 1';

  @override
  String get settingsResetTitle => 'Reset progres?';

  @override
  String get settingsResetNothing => 'Belum ada yang perlu direset.';

  @override
  String settingsResetBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Ini menghapus semua bintang dan skor terbaik di $count level yang sudah selesai, dan mengunci lagi semua level setelah level 1. Tindakan ini tidak bisa dibatalkan.',
    );
    return '$_temp0';
  }

  @override
  String get settingsKeepIt => 'Simpan saja';

  @override
  String get settingsResetConfirm => 'Hapus semua';

  @override
  String get settingsResetDone => 'Progres direset.';

  @override
  String get settingsSignOutTitle => 'Keluar?';

  @override
  String get settingsSignOutBody =>
      'Progresmu tetap ada di ponsel ini. Kamu bisa masuk lagi kapan saja untuk melanjutkannya di tempat lain.';

  @override
  String get settingsSignOutStay => 'Tetap masuk';

  @override
  String get settingsSignOutConfirm => 'Keluar';

  @override
  String get settingsServerUnreachable =>
      'Tidak bisa terhubung ke server, jadi tidak ada yang berubah.';

  @override
  String get settingsDeleteRowTitle => 'Hapus akun';

  @override
  String get settingsDeleteRowDetail => 'Hapus akunmu beserta semua isinya';

  @override
  String get settingsDeleteTitle => 'Hapus akunmu?';

  @override
  String get settingsDeleteBody =>
      'Ini menghapus akunmu, bintangmu, runtunanmu, dan entri peringkatmu, di ponsel ini dan di server kami. Tindakan ini tidak bisa dibatalkan.\n\nHapus Iklan tidak terpengaruh — pembelian itu milik akun toko yang kamu pakai untuk membelinya, dan akan pulih jika kamu bermain lagi.';

  @override
  String get settingsDeleteConfirm => 'Hapus semuanya';

  @override
  String get settingsDeleteServerRefused =>
      'Tidak bisa terhubung ke server. Tidak ada yang dihapus — coba lagi saat kamu online.';

  @override
  String get settingsDeleteNotAuthenticated =>
      'Tidak bisa memastikan ini kamu. Masuk lagi, lalu hapus akunmu — belum ada yang dihapus.';

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
          'Pourfect $version · dibuat dengan $count papan yang terbukti bisa diselesaikan',
    );
    return '$_temp0';
  }

  @override
  String get settingsNamingYou => 'Memberi nama…';

  @override
  String get settingsYourName => 'Namamu';

  @override
  String get settingsGuest => 'Bermain sebagai tamu';

  @override
  String get settingsStatSolved => 'SELESAI';

  @override
  String get settingsStatStars => 'BINTANG';

  @override
  String get settingsNotifyTurnOnTitle => 'Nyalakan notifikasi';

  @override
  String get settingsNotifyDeniedDetail =>
      'Mati di setelan ponselmu. Ketuk untuk membukanya.';

  @override
  String get settingsNotifyNotYetDetail =>
      'Pourfect belum bisa memberi notifikasi';

  @override
  String get settingsRemindersTitle => 'Pengingat Tantangan Harian';

  @override
  String get settingsRemindersDetail =>
      'Pagi dan malam, paling banyak dua kali sehari';

  @override
  String get settingsNewsTitle => 'Kabar game';

  @override
  String get settingsNewsDetail => 'Dunia baru dan pengumuman';

  @override
  String settingsToggleOn(String title) {
    return '$title, nyala';
  }

  @override
  String settingsToggleOff(String title) {
    return '$title, mati';
  }

  @override
  String get settingsFaqSectionPlaying => 'Bermain';

  @override
  String get settingsFaqSectionStuck => 'Buntu?';

  @override
  String get settingsFaqSectionProgress => 'Progresmu';

  @override
  String get settingsFaqSectionAds => 'Iklan & suara';

  @override
  String get settingsFaqHowToPlayQ => 'Bagaimana cara bermain?';

  @override
  String get settingsFaqHowToPlayA =>
      'Ketuk tabung untuk mengambil bola paling atas, lalu ketuk tabung lain untuk menuangnya. Bola hanya bisa mendarat di atas warna yang sama atau di tabung kosong. Susun tiap tabung jadi satu warna, dan level pun selesai. Setelan → Cara bermain mengulang level pertama yang dipandu.';

  @override
  String get settingsFaqStarsQ => 'Apa arti bintang?';

  @override
  String get settingsFaqStarsA =>
      'Bintang hanya menghitung langkah, tidak ada yang lain. Selesai dalam par atau kurang untuk tiga bintang, dalam satu setengah kali par untuk dua, dan asal selesai dapat satu. Par adalah jumlah langkah paling sedikit untuk menyelesaikan level itu.';

  @override
  String get settingsFaqClockQ => 'Apakah jam mengurangi bintang?';

  @override
  String get settingsFaqClockA =>
      'Tidak pernah. Waktu hanya mengubah poinmu. Kalahkan par waktu untuk poin bonus, atau santai saja selama yang kamu mau dan tetap dapat semua bintang.';

  @override
  String get settingsFaqSolvableQ => 'Apakah semua level bisa diselesaikan?';

  @override
  String get settingsFaqSolvableA =>
      'Ya. Setiap papan sudah diselesaikan sebelum dirilis, dan par berasal dari solusi itu, jadi par selalu bisa dicapai.';

  @override
  String get settingsFaqDailyQ => 'Apa itu Tantangan Harian?';

  @override
  String get settingsFaqDailyA =>
      'Papan baru setiap hari, dengan papan peringkatnya sendiri. Butuh koneksi internet. Level kampanye tidak.';

  @override
  String get settingsFaqUndoQ => 'Apakah urungkan terbatas?';

  @override
  String get settingsFaqUndoA =>
      'Tidak. Urungkan gratis dan tanpa batas, di semua level.';

  @override
  String get settingsFaqHintsQ => 'Bagaimana cara kerja petunjuk?';

  @override
  String settingsFaqHintsA(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count petunjuk pertamamu gratis. Setelah itu, satu video singkat memberi satu petunjuk. Jika petunjuk tidak ditemukan, videonya tetap dihitung untuk petunjuk berikutnya.',
      one: 'Petunjuk pertamamu gratis. Setelah itu, satu video singkat memberi satu petunjuk. Jika petunjuk tidak ditemukan, videonya tetap dihitung untuk petunjuk berikutnya.',
    );
    return '$_temp0';
  }

  @override
  String get settingsFaqTubeQ => 'Apa itu tombol + Tabung?';

  @override
  String get settingsFaqTubeA =>
      'Saat langkahmu mencapai par, atau petunjuk menunjukkan tidak ada jalan selesai, kamu bisa menonton video untuk satu tabung kosong tambahan, paling banyak dua per percobaan. Urungkan tidak akan mengambilnya kembali. Level yang selesai dengan tabung tambahan dapat paling banyak dua bintang.';

  @override
  String get settingsFaqHardQ => 'Apa itu level SULIT?';

  @override
  String get settingsFaqHardA =>
      'Level tersulit di setiap sepuluh level memakai lencana merah SULIT. Cara mainnya sama seperti level lain, dan poinnya satu setengah kali lipat.';

  @override
  String get settingsFaqChestsQ => 'Apa itu peti bintang?';

  @override
  String get settingsFaqChestsA =>
      'Setiap 30 bintang membuka satu peti di Perjalanan: dua petunjuk dan satu tabung tambahan, disimpan untuk saat kamu butuh. Setiap peti ketiga juga membuka satu skin bola.';

  @override
  String get settingsFaqFreezeQ => 'Apa itu pelindung runtunan?';

  @override
  String get settingsFaqFreezeA =>
      'Jika kamu melewatkan satu hari Tantangan Harian, pelindung akan menutupinya, jadi runtunanmu tetap berlanjut. Kamu dapat satu gratis setiap Senin, bisa dapat satu per hari dari video, dan bisa menyimpan dua.';

  @override
  String get settingsFaqAccountQ => 'Apakah aku perlu akun?';

  @override
  String get settingsFaqAccountA =>
      'Tidak. Kamu bermain sebagai tamu dan progresmu disimpan di ponsel ini. Dengan masuk, bintangmu tetap ada saat kamu pindah ke ponsel baru.';

  @override
  String get settingsFaqOfflineQ => 'Bisakah aku main offline?';

  @override
  String get settingsFaqOfflineA =>
      'Bisa, seluruh kampanye. Tantangan Harian dan papan peringkat butuh koneksi, dan progresmu disinkronkan saat kamu online lagi.';

  @override
  String get settingsFaqNameQ => 'Bagaimana cara mengganti nama peringkatku?';

  @override
  String get settingsFaqNameA =>
      'Setelan → Ganti namamu. Di sana kamu juga bisa menyembunyikan diri dari papan peringkat; bintangmu tetap dihitung.';

  @override
  String get settingsFaqRemoveAdsQ => 'Apa fungsi Hapus iklan?';

  @override
  String get settingsFaqRemoveAdsA =>
      'Mematikan iklan antar-level. Video petunjuk dan tabung tetap ada, karena kamu hanya melihatnya saat kamu memintanya.';

  @override
  String get settingsFaqReinstallQ =>
      'Aku memasang ulang. Ke mana Hapus iklan?';

  @override
  String get settingsFaqReinstallA =>
      'Pembelian itu milik akun toko yang kamu pakai untuk membelinya, dan biasanya kembali dengan sendirinya. Jika tidak, ketuk Setelan → Pulihkan pembelian.';

  @override
  String get settingsFaqMusicQ => 'Apakah game ini akan menghentikan musikku?';

  @override
  String get settingsFaqMusicA =>
      'Tidak. Pourfect memutar suaranya bersamaan dengan musik atau podcast-mu. Suara dan getaran bisa dimatikan di Setelan.';

  @override
  String get settingsLegalTitle => 'Sebelum menuang';

  @override
  String get settingsLegalIntro =>
      'Pourfect gratis, bisa dimainkan offline, dan tidak butuh akun. Silakan baca dan setujui ini dulu.';

  @override
  String settingsLegalAcceptTerms(String document) {
    return 'Aku menyetujui $document';
  }

  @override
  String settingsLegalReadPrivacy(String document) {
    return 'Aku sudah membaca $document';
  }

  @override
  String settingsLegalAlsoCovers(String document, String version) {
    return 'Dengan menyetujui, kamu juga menyetujui $document kami (versi $version).';
  }

  @override
  String get settingsLegalPrivacyPolicy => 'Kebijakan Privasi';

  @override
  String get settingsLegalTermsOfService => 'Ketentuan Layanan';

  @override
  String get settingsLegalRefundPolicy => 'Kebijakan Pengembalian Dana';

  @override
  String settingsLegalReadDocument(String document) {
    return 'Baca $document';
  }

  @override
  String get settingsLegalAccept => 'AYO MENUANG!';

  @override
  String get settingsLegalReadAgain =>
      'Kamu bisa membacanya lagi kapan saja di Setelan.';

  @override
  String get settingsLegalLoadFailed =>
      'Dokumen ini tidak bisa dimuat di perangkat ini.\n\nKamu bisa membacanya di legal.pranta.dev sebelum menyetujui.';

  @override
  String get settingsUpdateTitle => 'Pourfect baru sudah siap';

  @override
  String get settingsUpdateBody =>
      'Google Play akan mengunduhnya dan membuka game lagi setelah selesai. Bintangmu aman.';

  @override
  String get settingsUpdateMandatoryTitle => 'Saatnya update';

  @override
  String get settingsUpdateMandatoryBody =>
      'Versi Pourfect ini sudah tidak didukung. Google Play akan mengunduh pembaruan dan membuka game lagi. Bintangmu aman.';

  @override
  String get settingsUpdateNow => 'Update sekarang';

  @override
  String get settingsRenameHello => 'HALO';

  @override
  String get settingsRenameMyNameIs => 'NAMAKU';

  @override
  String get settingsRenameHint => 'Pemain lain melihat ini di papan peringkat';

  @override
  String get settingsRenameSave => 'SIMPAN';

  @override
  String settingsCollectionUnlockWith(String how) {
    return 'Buka dengan: $how.';
  }

  @override
  String get settingsCollectionChangeFailed =>
      'Tidak bisa diganti sekarang. Coba lagi nanti.';

  @override
  String get settingsPackThanks =>
      'Terima kasih! Paketnya akan terbuka sebentar lagi.';

  @override
  String get settingsPackAlreadyOwned => 'Sudah milikmu. Sedang dipulihkan.';

  @override
  String get settingsPackPending =>
      'Pembayaran tertunda. Paket terbuka setelah pembayaran selesai.';

  @override
  String get settingsCollectionOffline =>
      'Sambungkan ke internet untuk melihat koleksimu.';

  @override
  String get settingsCollectionBallSkins => 'Skin bola';

  @override
  String get settingsCollectionTubeThemes => 'Tema tabung';

  @override
  String settingsCollectionPreview(String skin, String theme) {
    return 'Bola $skin · tabung $theme';
  }

  @override
  String settingsCollectionItemWorn(String name) {
    return '$name, dipakai';
  }

  @override
  String settingsCollectionItemTapToWear(String name) {
    return '$name, ketuk untuk memakai';
  }

  @override
  String settingsCollectionItemLocked(String name, String how) {
    return '$name, terkunci: $how';
  }

  @override
  String get settingsCollectionWearing => 'Dipakai';

  @override
  String get settingsCollectionTapToWear => 'Ketuk untuk pakai';

  @override
  String settingsUnlockChest(int number) {
    return 'Peti bintang $number';
  }

  @override
  String settingsUnlockStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days hari beruntun',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnlockFree => 'Gratis';

  @override
  String get settingsSkinPack => 'Paket Skin';

  @override
  String get settingsSkinPackDetail =>
      'Bola Marmer, Mutiara, dan Catur, tabung Kayu dan Lilac.';

  @override
  String get settingsOwned => 'DIMILIKI';

  @override
  String get settingsSoon => 'Segera';

  @override
  String get settingsSkinClassic => 'Klasik';

  @override
  String get settingsSkinGlossy => 'Kilap';

  @override
  String get settingsSkinStriped => 'Permen loreng';

  @override
  String get settingsSkinGlow => 'Pendar';

  @override
  String get settingsSkinSpeckled => 'Meses';

  @override
  String get settingsSkinMarble => 'Marmer';

  @override
  String get settingsSkinPearl => 'Mutiara';

  @override
  String get settingsSkinChecker => 'Catur';

  @override
  String get settingsTubeToy => 'Mainan';

  @override
  String get settingsTubeFrost => 'Beku';

  @override
  String get settingsTubeWood => 'Kayu';

  @override
  String get settingsTubeLilac => 'Lilac';
}
