// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get accountGoogleFailed =>
      'No se pudo iniciar sesión con Google en este teléfono. Intenta de nuevo o usa tu email abajo.';

  @override
  String get accountAppleFailed =>
      'No se pudo iniciar sesión con Apple en este teléfono. Revisa que hayas iniciado sesión en tu Cuenta de Apple en Configuración, o usa tu email abajo.';

  @override
  String get accountExistsNoLocal =>
      'Ya tienes una cuenta con ese email. Inicia sesión y este teléfono cargará las estrellas guardadas en ella.';

  @override
  String accountExistsWithLocal(int solved) {
    String _temp0 = intl.Intl.pluralLogic(
      solved,
      locale: localeName,
      other:
          'Ya tienes una cuenta con ese email. Este teléfono tiene $solved niveles resueltos que no están en ella, y no se pueden combinar: al iniciar sesión se reemplazan por lo que tenga esa cuenta.',
      one:
          'Ya tienes una cuenta con ese email. Este teléfono tiene $solved nivel resuelto que no está en ella, y no se pueden combinar: al iniciar sesión se reemplaza por lo que tenga esa cuenta.',
    );
    return '$_temp0';
  }

  @override
  String get accountEmailInUse =>
      'Ya existe una cuenta con ese email. Mejor intenta iniciar sesión.';

  @override
  String get accountEmailMalformed => 'Eso no parece un email.';

  @override
  String get accountPasswordWeak =>
      'Esa contraseña es muy fácil de adivinar. Prueba con una más larga.';

  @override
  String get accountWrongPassword => 'El email y la contraseña no coinciden.';

  @override
  String get accountTooManyAttempts =>
      'Demasiados intentos. Espera unos minutos e intenta de nuevo.';

  @override
  String get accountNeedsRecentLogin => 'Primero vuelve a iniciar sesión.';

  @override
  String get accountMethodNotEnabled =>
      'El inicio de sesión con email no está disponible ahora. Prueba Continuar con Google.';

  @override
  String get accountSessionUnavailable =>
      'Sesión iniciada, pero tu progreso aún no se guardó en el servidor. Se sincronizará cuando vuelva la conexión.';

  @override
  String get accountUnavailable =>
      'No se pudo conectar con el servidor. Tu progreso sigue a salvo en este dispositivo.';

  @override
  String get accountUseThatAccount => 'Usar esa cuenta';

  @override
  String get accountExistingTitle => 'Ya tienes una cuenta';

  @override
  String get accountExistingBodyEmpty =>
      'Este teléfono cargará las estrellas ya guardadas en ella.';

  @override
  String accountExistingBodyLocal(int cleared) {
    String _temp0 = intl.Intl.pluralLogic(
      cleared,
      locale: localeName,
      other:
          'Este teléfono tiene $cleared niveles resueltos que no están en esa cuenta. No se pueden combinar, así que se reemplazarán por lo que ya tenga la cuenta.',
      one:
          'Este teléfono tiene $cleared nivel resuelto que no está en esa cuenta. No se pueden combinar, así que se reemplazará por lo que ya tenga la cuenta.',
    );
    return '$_temp0';
  }

  @override
  String get accountSignIn => 'Iniciar sesión';

  @override
  String get accountSignInCancelled =>
      'Inicio de sesión cancelado. No cambió nada.';

  @override
  String get accountSignedInToast =>
      'Sesión iniciada. Tus estrellas ahora te siguen a un teléfono nuevo.';

  @override
  String get accountResetNeedsEmail =>
      'Primero escribe tu email y luego toca ¿Olvidaste tu contraseña?';

  @override
  String get accountResetSent =>
      'Si ese email tiene una cuenta, el enlace para restablecerla va en camino.';

  @override
  String get accountYourAccount => 'Tu cuenta';

  @override
  String accountRankValue(int rank) {
    return '#$rank';
  }

  @override
  String accountStreakValue(int days) {
    return '${days}d';
  }

  @override
  String get accountCardTravels =>
      'Esta tarjeta va con tu cuenta, así que en un teléfono nuevo sigues justo donde te quedaste.';

  @override
  String get accountYourNameHeader => 'Tu nombre';

  @override
  String get accountChangeName => 'Cambiar tu nombre';

  @override
  String get accountChangeNameDetail => 'Cómo apareces en las tablas';

  @override
  String get accountShowOnBoards => 'Mostrarme en las clasificaciones';

  @override
  String get accountShowOnBoardsDetail =>
      'Apagado oculta tu nombre y puesto. Las estrellas cuentan igual.';

  @override
  String get accountYourPlayHeader => 'Tu juego';

  @override
  String get accountStatistics => 'Estadísticas';

  @override
  String get accountStatisticsDetail => 'Tus tiempos, actividad y cada nivel';

  @override
  String get accountSessionHeader => 'Sesión';

  @override
  String get accountDeleteHint =>
      'Para eliminar tu cuenta, ve a Ajustes → Zona de peligro.';

  @override
  String get accountVisibilityFailed =>
      'No se pudo conectar con el servidor, así que no cambió nada.';

  @override
  String get accountSignOutTitle => '¿Cerrar sesión?';

  @override
  String get accountSignOutBody =>
      'Tu progreso se queda en este teléfono. Puedes volver a iniciar sesión cuando quieras para seguir en otro lado.';

  @override
  String get accountStaySignedIn => 'Seguir conectado';

  @override
  String get accountSignOut => 'Cerrar sesión';

  @override
  String get accountSignOutDetail => 'Tu progreso se queda en este teléfono';

  @override
  String get accountSaveTitle => 'Guarda tu progreso';

  @override
  String get accountSaveIntro =>
      'Tus estrellas, tu racha y tu nombre en las clasificaciones van con tu cuenta, así que en un teléfono nuevo sigues donde te quedaste.';

  @override
  String get accountContinueApple => 'Continuar con Apple';

  @override
  String get accountContinueGoogle => 'Continuar con Google';

  @override
  String get accountOr => 'O';

  @override
  String get accountEmailLabel => 'Email';

  @override
  String get accountEmailEmpty => 'Escribe tu email.';

  @override
  String get accountPasswordLabel => 'Contraseña';

  @override
  String get accountPasswordHelper => 'Al menos 8 caracteres';

  @override
  String get accountPasswordEmpty => 'Escribe una contraseña.';

  @override
  String get accountPasswordShort => 'Al menos 8 caracteres.';

  @override
  String get accountShowPassword => 'Mostrar contraseña';

  @override
  String get accountHidePassword => 'Ocultar contraseña';

  @override
  String get accountCreate => 'Crear cuenta';

  @override
  String get accountSwitchToSignIn => '¿Ya tienes una cuenta? Inicia sesión';

  @override
  String get accountSwitchToSignInSemantic => 'Mejor iniciar sesión';

  @override
  String get accountSwitchToCreate => '¿No tienes cuenta? Crea una';

  @override
  String get accountSwitchToCreateSemantic => 'Mejor crear una cuenta';

  @override
  String get accountForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get accountForgotPasswordSemantic => 'Restablecer tu contraseña';

  @override
  String get accountNaming => 'Buscando tu nombre…';

  @override
  String get accountSignedInLabel => 'Sesión iniciada';

  @override
  String accountPouringSince(String month, int year) {
    return 'JUGANDO DESDE $month $year';
  }

  @override
  String get accountPlayerCardTag => 'TARJETA';

  @override
  String get accountStatSolved => 'NIVELES';

  @override
  String get accountStatStars => 'ESTRELLAS';

  @override
  String get accountStatStreak => 'RACHA';

  @override
  String get accountStatRank => 'PUESTO';

  @override
  String accountStarsValue(int stars) {
    return '$stars★';
  }

  @override
  String get accountSyncing => 'Sincronizando…';

  @override
  String get accountSyncingDetail => 'Guardando el progreso en tu cuenta';

  @override
  String get accountWaitingToSync => 'Esperando para sincronizar';

  @override
  String get accountWaitingOffline =>
      'Se guarda cuando vuelvas a estar en línea';

  @override
  String get accountWaitingPending =>
      'Tus últimos niveles se suben a continuación';

  @override
  String get accountSyncedDetail => 'Progreso guardado en tu cuenta';

  @override
  String get accountSynced => 'Sincronizado';

  @override
  String get accountSyncedJustNow => 'Sincronizado recién';

  @override
  String accountSyncedMinutesAgo(int minutes) {
    return 'Sincronizado hace $minutes min';
  }

  @override
  String accountSyncedHoursAgo(int hours) {
    return 'Sincronizado hace $hours h';
  }

  @override
  String accountSyncedDaysAgo(int days) {
    return 'Sincronizado hace $days d';
  }

  @override
  String get accountCrestSignedIn => 'Tu cuenta';

  @override
  String get accountCrestGuest => 'Jugando como invitado';

  @override
  String get accountRenameRefused => 'Ese nombre no fue aceptado.';

  @override
  String get accountRenameOffline =>
      'No se pudo conectar con el servidor. Intenta de nuevo en un momento.';

  @override
  String get ranksTitle => 'Clasificación';

  @override
  String get ranksTabToday => 'Hoy';

  @override
  String get ranksTabCampaign => 'Campaña';

  @override
  String get ranksLoading => 'Cargando la clasificación…';

  @override
  String get ranksEmptyDailyTitle => 'Nadie terminó la tabla de hoy todavía';

  @override
  String get ranksEmptyDailyDetail => 'Sé la primera persona.';

  @override
  String get ranksEmptyCampaignTitle => 'Aún no hay jugadores clasificados';

  @override
  String get ranksEmptyCampaignDetail => 'Aquí deciden las estrellas.';

  @override
  String get ranksYourSpot => 'Tu lugar';

  @override
  String ranksPlayerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString jugadores en esta tabla',
      one: '1 jugador en esta tabla',
    );
    return '$_temp0';
  }

  @override
  String ranksMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimientos',
      one: '$count movimiento',
    );
    return '$_temp0';
  }

  @override
  String ranksStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrellas',
      one: '$count estrella',
    );
    return '$_temp0';
  }

  @override
  String ranksLevels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count niveles',
      one: '$count nivel',
    );
    return '$_temp0';
  }

  @override
  String ranksInTime(String time) {
    return 'en $time';
  }

  @override
  String get ranksOpenSpot => 'Lugar libre';

  @override
  String ranksNameYou(String name) {
    return '$name (tú)';
  }

  @override
  String ranksPlaceOpen(int place) {
    return 'Puesto $place, libre';
  }

  @override
  String ranksPlaceSemantic(int rank, String name, String score) {
    return 'Puesto $rank, $name, $score';
  }

  @override
  String ranksScoreWithTieBreak(String score, String tieBreak) {
    return '$score, $tieBreak';
  }

  @override
  String get ranksOffTitle =>
      'Las clasificaciones están desactivadas en esta versión';

  @override
  String get ranksOffDetail => 'La campaña no se ve afectada.';

  @override
  String get ranksLoadFailed => 'No se pudo cargar la tabla';

  @override
  String get ranksOffline =>
      'Parece que no tienes conexión. Todos los niveles se pueden jugar sin internet.';

  @override
  String get ranksTimeout => 'El servidor tardó demasiado en responder.';

  @override
  String get ranksServerError =>
      'Algo salió mal de nuestro lado. Tu progreso está a salvo.';

  @override
  String get ranksHiddenTitle => 'Estás oculto';

  @override
  String get ranksHiddenDetail =>
      'Tus estrellas y tu racha siguen contando, solo que no apareces aquí. El interruptor está en Ajustes.';

  @override
  String get statsTitle => 'Tus estadísticas';

  @override
  String get statsTabOverview => 'Resumen';

  @override
  String get statsTabLevels => 'Niveles';

  @override
  String get statsTabBadges => 'Insignias';

  @override
  String get statsPaceOnPar => 'en par';

  @override
  String statsPaceUnder(int percent) {
    return '$percent% menos';
  }

  @override
  String statsPaceOver(int percent) {
    return '$percent% más';
  }

  @override
  String get statsEmptyTitle => 'Aún no hay nada';

  @override
  String get statsEmptyBody =>
      'Resuelve un nivel y esto se llena: tus tiempos contra el par, tus mejores partidas y los días que jugaste.';

  @override
  String get statsBackToLevels => 'Volver a niveles';

  @override
  String get statsLevelsSolved => 'niveles resueltos';

  @override
  String get statsStars => 'estrellas';

  @override
  String get statsPoints => 'puntos';

  @override
  String get statsPlayed => 'jugado';

  @override
  String get statsNowOn => 'vas en';

  @override
  String get statsBestSolveMoves => 'movimientos en mejores partidas';

  @override
  String get statsAgainstClock => 'CONTRA RELOJ';

  @override
  String get statsNoTimes =>
      'Aún no hay tiempos registrados. Los niveles que superaste antes de que llegara el reloj no tienen tiempo: vuelve a jugar uno y empieza a contar.';

  @override
  String get statsFastest => 'Más rápido';

  @override
  String get statsLongest => 'Más largo';

  @override
  String get statsAvgPace => 'Ritmo prom.';

  @override
  String statsClockValue(String time, int level) {
    return '$time · N$level';
  }

  @override
  String statsUntimed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count de tus niveles resueltos se superaron antes del reloj y no tienen tiempo registrado.',
      one:
          '$count de tus niveles resueltos se superó antes del reloj y no tiene tiempo registrado.',
    );
    return '$_temp0';
  }

  @override
  String statsUnderParSemantic(int under, int total) {
    return '$under de $total niveles cronometrados bajo par';
  }

  @override
  String get statsUnderParTag => 'BAJO PAR';

  @override
  String get statsLast30Days => 'ÚLTIMOS 30 DÍAS';

  @override
  String statsStreakChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'racha de $count días',
      one: 'racha de 1 día',
    );
    return '$_temp0';
  }

  @override
  String get statsNoStreak => 'sin racha';

  @override
  String statsDaysPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días jugados',
      one: '$count día jugado',
    );
    return '$_temp0';
  }

  @override
  String statsLevelsFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count niveles superados',
      one: '$count nivel superado',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'récord $count días',
      one: 'récord $count día',
    );
    return '$_temp0';
  }

  @override
  String get statsToday => 'Hoy';

  @override
  String statsMonthShort(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'jan': 'Ene',
      'feb': 'Feb',
      'mar': 'Mar',
      'apr': 'Abr',
      'may': 'May',
      'jun': 'Jun',
      'jul': 'Jul',
      'aug': 'Ago',
      'sep': 'Sep',
      'oct': 'Oct',
      'nov': 'Nov',
      'dec': 'Dic',
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
      other: '$day · $count niveles',
      one: '$day · $count nivel',
    );
    return '$_temp0';
  }

  @override
  String statsBarNoPlay(String day) {
    return '$day · sin jugar';
  }

  @override
  String get statsWorldAhead => 'pendiente';

  @override
  String get statsWorldNoTimes => 'sin tiempos';

  @override
  String statsWorldPoints(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString pts';
  }

  @override
  String statsWorldSolvedSemantic(String name, int cleared, int total) {
    return '$name: $cleared de $total resueltos';
  }

  @override
  String statsWorldPaceSemantic(String pace) {
    return 'ritmo $pace';
  }

  @override
  String statsWorldPointsSemantic(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString puntos';
  }

  @override
  String get statsColLevel => 'NIV';

  @override
  String get statsColStars => 'ESTR.';

  @override
  String get statsColMoves => 'MOV.';

  @override
  String get statsColTime => 'TIEMPO';

  @override
  String get statsColPoints => 'PTS';

  @override
  String statsMovesBestPossible(int moves, int best) {
    return '$moves movimientos, mejor posible $best';
  }

  @override
  String statsMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimientos',
      one: '$count movimiento',
    );
    return '$_temp0';
  }

  @override
  String badgeUnlockedCount(int earned, int total) {
    return '$earned de $total desbloqueadas';
  }

  @override
  String get badgeUnlocked => 'Desbloqueada';

  @override
  String get badgeNotYet => 'Aún no';

  @override
  String badgeProgress(int shown, int target) {
    return '$shown de $target';
  }

  @override
  String badgeSemantic(String title, String description, String status) {
    return '$title: $description $status';
  }

  @override
  String get badgeFirstPourTitle => 'Primer vertido';

  @override
  String get badgeFirstPourDesc => 'Supera tu primer nivel.';

  @override
  String get badgePar10Title => 'En par';

  @override
  String get badgePar10Desc => 'Supera 10 niveles justo en par.';

  @override
  String get badgePar50Title => 'Maestro del par';

  @override
  String get badgePar50Desc => 'Supera 50 niveles justo en par.';

  @override
  String get badgeCleanClearTitle => 'Sin vuelta atrás';

  @override
  String get badgeCleanClearDesc => 'Supera un nivel sin deshacer.';

  @override
  String get badgeSpeedyTitle => 'Vertido veloz';

  @override
  String get badgeSpeedyDesc => 'Supera un nivel en menos de 30 segundos.';

  @override
  String get badgeLevels100Title => 'Centurión';

  @override
  String get badgeLevels100Desc => 'Supera 100 niveles.';

  @override
  String get badgeStars300Title => 'Juntaestrellas';

  @override
  String get badgeStars300Desc => 'Junta 300 estrellas.';

  @override
  String get badgeWorldPerfectTitle => 'Mundo impecable';

  @override
  String get badgeWorldPerfectDesc =>
      'Consigue tres estrellas en todos los niveles de un mundo.';

  @override
  String get badgeStreak7Title => 'Semana de vertidos';

  @override
  String get badgeStreak7Desc => 'Logra una racha de 7 días en el Reto Diario.';

  @override
  String get badgeStreak30Title => 'Mes de vertidos';

  @override
  String get badgeStreak30Desc =>
      'Logra una racha de 30 días en el Reto Diario.';

  @override
  String get badgeChests5Title => 'Cazatesoros';

  @override
  String get badgeChests5Desc => 'Abre 5 cofres de estrellas.';

  @override
  String get badgeHard5Title => 'Hueso duro';

  @override
  String get badgeHard5Desc => 'Supera 5 niveles DIFÍCIL.';

  @override
  String get badgeEventFullTitle => 'Semana completa';

  @override
  String get badgeEventFullDesc =>
      'Supera los siete tableros de un evento semanal.';

  @override
  String get badgeZen25Title => 'Jardín Zen';

  @override
  String get badgeZen25Desc => 'Resuelve 25 tableros en modo Zen.';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonNotNow => 'Ahora no';

  @override
  String commonLevelN(int level) {
    return 'Nivel $level';
  }

  @override
  String get hubAccountYours => 'Tu cuenta';

  @override
  String get hubAccountSave => 'Guarda tu progreso';

  @override
  String get hubPlayerFallback => 'Jugador';

  @override
  String get hubSettings => 'Ajustes';

  @override
  String get hubTagline => 'VIERTE · ORDENA · RELAX';

  @override
  String hubStatChipSemantic(String value, String label) {
    return '$value $label. Estadísticas';
  }

  @override
  String get hubStatSolved => 'resueltos';

  @override
  String get hubStatStars => 'estrellas';

  @override
  String get hubStatStreak => 'racha';

  @override
  String hubStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String hubRankNumber(int rank) {
    return '#$rank';
  }

  @override
  String hubEventSemantic(int cleared, int total) {
    return 'Evento semanal, $cleared de $total tableros';
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
  String get hubZenSemantic => 'Modo Zen';

  @override
  String hubZenLockedSemantic(int level) {
    return 'El modo Zen se desbloquea en el nivel $level';
  }

  @override
  String get hubZenOpen => 'Sin fin, sin reloj';

  @override
  String hubZenLocked(int level, int remaining) {
    return 'Nivel $level · faltan $remaining';
  }

  @override
  String get hubDockJourney => 'Viaje';

  @override
  String get hubDockRankings => 'Ranking';

  @override
  String get hubDockStats => 'Progreso';

  @override
  String get hubTip =>
      '¡Bien! En Viaje están todos los niveles, y cada día hay un nuevo Reto Diario para jugar.';

  @override
  String hubHeroWorld(int world) {
    return 'Mundo $world';
  }

  @override
  String hubHeroWorldBand(int world, String band) {
    return 'Mundo $world · $band';
  }

  @override
  String hubHeroPar(int par) {
    return 'par $par';
  }

  @override
  String get hubPlay => 'JUGAR';

  @override
  String hubPlaySemantic(int level) {
    return 'Jugar nivel $level';
  }

  @override
  String get hubMoreUpdateTitle => 'Actualiza para más niveles';

  @override
  String get hubMoreUpdateBody =>
      'Salió un mundo nuevo y necesita la última versión de Pourfect. Actualiza el juego para seguir vertiendo.';

  @override
  String get hubMoreDownloadingTitle => 'Nuevos niveles en camino';

  @override
  String get hubMoreDownloadingBody =>
      'El siguiente mundo se está descargando. Solo toma un momento.';

  @override
  String get hubMoreAllDoneTitle => '¡Los vertiste todos!';

  @override
  String get hubMoreOfflineBody =>
      'Conéctate a internet y se descargarán más niveles en segundo plano. Mientras tanto, el Reto Diario de hoy te espera.';

  @override
  String get hubMoreOnlineBody =>
      'Se descargan más niveles en segundo plano cuando estás en línea. Mientras tanto, el Reto Diario de hoy te espera.';

  @override
  String get hubMoreCheckAgain => 'Buscar de nuevo';

  @override
  String hubAchievementOne(String title) {
    return 'Logro desbloqueado: $title';
  }

  @override
  String hubAchievementMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡$count logros desbloqueados!',
    );
    return '$_temp0';
  }

  @override
  String get hubUpdateReady => 'Hay una actualización lista para instalar.';

  @override
  String get hubUpdateRestart => 'Reiniciar';

  @override
  String hubSpanSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String hubSpanMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String hubSpanMinutesSeconds(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String hubSpanHours(int hours) {
    return '${hours}h';
  }

  @override
  String hubSpanHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get hubParOn => 'en par';

  @override
  String hubParUnder(int percent) {
    return '$percent% bajo el par';
  }

  @override
  String hubParOver(int percent) {
    return '$percent% sobre el par';
  }

  @override
  String get dailyTitle => 'Reto Diario';

  @override
  String get dailyCardSemantic => 'Reto de hoy';

  @override
  String get dailyCardUnavailable => 'no se pudo cargar el tablero de hoy';

  @override
  String get dailyCardSolved => 'resuelto';

  @override
  String dailyCardNextIn(String time) {
    return 'siguiente en $time';
  }

  @override
  String dailyCardEndsIn(String time) {
    return 'termina en $time';
  }

  @override
  String dailyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'racha de $count días',
      one: 'racha de $count día',
    );
    return '$_temp0';
  }

  @override
  String dailyStreakMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡Racha de $count días!',
      one: '¡Racha de $count día!',
    );
    return '$_temp0';
  }

  @override
  String get dailyRankSemantic => 'Clasificación';

  @override
  String dailyRankSemanticRanked(int rank) {
    return 'Clasificación, puesto $rank';
  }

  @override
  String get dailyRankSticker => 'PUESTO';

  @override
  String get dailyLeaveLost =>
      'Tus movimientos en el Reto Diario de hoy no se guardarán. Puedes volver a empezarlo cuando quieras hoy.';

  @override
  String get dailySubmitRefused => 'El servidor no aceptó ese resultado.';

  @override
  String get dailySubmitFailed =>
      'Resuelto, pero no se pudo enviar el resultado. Intenta más tarde.';

  @override
  String get dailyHudLabel => 'Reto';

  @override
  String get dailyHudValue => 'Diario';

  @override
  String get dailyDeadEndRestart =>
      'No hay forma de terminar desde aquí. Reinicia para probar otro camino.';

  @override
  String dailyDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'No hay forma de terminar desde aquí. Deshaz $count movimientos para retomar el camino.',
      one: 'No hay forma de terminar desde aquí. Deshaz 1 movimiento para retomar el camino.',
    );
    return '$_temp0';
  }

  @override
  String get dailyActionRestart => 'Reiniciar';

  @override
  String dailyActionUndo(int count) {
    return 'Deshacer $count';
  }

  @override
  String get dailyNoHint => 'No hay pista para esta posición.';

  @override
  String get dailyLoadingTitle => 'Cargando el tablero de hoy';

  @override
  String get dailyOffTitle =>
      'Los retos diarios están desactivados en esta versión';

  @override
  String get dailyOffDetail =>
      'La campaña no se ve afectada: todos los niveles están en este dispositivo.';

  @override
  String get dailyNoBoardTitle => 'Hoy no hay tablero';

  @override
  String get dailyNoBoardDetail =>
      'El reto de hoy viene del servidor y no se pudo conectar. La campaña no lo necesita.';

  @override
  String get dailyLoaderCaption => 'Preparando el tablero de hoy…';

  @override
  String get dailyBackToLevels => 'Volver a niveles';

  @override
  String dailyWeekSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return 'Tu racha: $_temp0. Abrir';
  }

  @override
  String dailyDaySemantic(String weekday, String state) {
    return '$weekday, $state';
  }

  @override
  String get dailyDayFrozen => 'perdido, cubierto por un congelador';

  @override
  String get dailyDayPlayedToday => 'jugado hoy';

  @override
  String get dailyDayPlayed => 'jugado';

  @override
  String get dailyDayToday => 'hoy, aún sin jugar';

  @override
  String get dailyDayMissed => 'sin jugar';

  @override
  String get dailyDayFuture => 'por venir';

  @override
  String get dailyOutcomeBest => 'Nuevo récord';

  @override
  String get dailyOutcomeSolved => 'Resuelto';

  @override
  String get dailyFigureMoves => 'movimientos';

  @override
  String get dailyFigureStreak => 'racha';

  @override
  String get dailyUnranked => 'sin puesto';

  @override
  String dailyOfPlayers(int count) {
    return 'de $count';
  }

  @override
  String get dailyReminderOn =>
      'Recibirás un recordatorio mañana por la tarde.';

  @override
  String get dailyRemindMe => 'Recuérdamelo mañana';

  @override
  String get dailyDone => 'LISTO';

  @override
  String get dailyFreezeVideoUnfinished =>
      'Sin congelador: el video no se terminó.';

  @override
  String get dailyFreezeNoVideo => 'No hay videos disponibles ahora.';

  @override
  String get dailyFreezeError => 'Algo salió mal. Intenta más tarde.';

  @override
  String get dailyFreezeAdded =>
      'Congelador añadido. Un día perdido queda cubierto.';

  @override
  String get dailyFreezeNoRoom => 'Hoy no caben más congeladores.';

  @override
  String get dailyFreezeLoadingVideo => 'Cargando video…';

  @override
  String get dailyFreezeWatch => 'Mira un video por un congelador';

  @override
  String get dailyFreezesFull =>
      'Congeladores al máximo. Cada uno cubre un día que faltes.';

  @override
  String get dailyFreezeTomorrow =>
      'Un congelador por video al día. Vuelve mañana.';

  @override
  String get dailyStreakTitle => 'Tu racha';

  @override
  String get dailyStreakNone => 'Aún no hay racha';

  @override
  String get dailyStreakStart =>
      'Juega el Reto Diario de hoy para empezar una.';

  @override
  String dailyStreakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Récord: $count días',
      one: 'Récord: 1 día',
    );
    return '$_temp0';
  }

  @override
  String dailyFreezesSemantic(int count, int max) {
    return '$count de $max congeladores de racha';
  }

  @override
  String get dailyFreezesTitle => 'Congeladores de racha';

  @override
  String get dailyFreezesEach => 'Cada uno cubre un día perdido.';

  @override
  String dailyFreezeWeekly(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Uno gratis cada lunes: en $days días.',
      one: 'Uno gratis cada lunes: mañana.',
    );
    return '$_temp0';
  }

  @override
  String get dailyCalendarPrevious => 'Mes anterior';

  @override
  String get dailyCalendarNext => 'Mes siguiente';

  @override
  String dailyCalendarCellSemantic(String date, String state) {
    return '$date, $state';
  }

  @override
  String get dailyCalendarPlayed => 'jugado';

  @override
  String get dailyCalendarFrozen => 'congelado';

  @override
  String get dailyCalendarFuture => 'por venir';

  @override
  String get dailyLegendPlayed => 'Jugado';

  @override
  String get dailyLegendFrozen => 'Congelado';

  @override
  String get dailyLegendToday => 'Hoy';

  @override
  String get eventTitle => 'Evento semanal';

  @override
  String get eventUnreachable => 'No se pudo cargar el evento de esta semana.';

  @override
  String get eventEnded => 'terminado';

  @override
  String eventEndsIn(String timeLeft) {
    return 'termina en $timeLeft';
  }

  @override
  String eventTimeLeftDaysHours(int days, int hours) {
    return '${days}d ${hours}h';
  }

  @override
  String eventTimeLeftHours(int hours) {
    return '${hours}h';
  }

  @override
  String eventTimeLeftMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String eventSummary(int cleared, int total, String endsIn) {
    return '$cleared de $total tableros · $endsIn';
  }

  @override
  String get eventFigurePoints => 'puntos';

  @override
  String eventRankOf(int count) {
    return 'de $count';
  }

  @override
  String get eventRankPlay => 'juega un tablero para clasificar';

  @override
  String get eventRankSetName => 'elige un nombre para clasificar';

  @override
  String eventTileSemanticDone(int slot, int stars, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars estrellas',
      one: '1 estrella',
    );
    return 'Tablero $slot, $_temp0, $points puntos';
  }

  @override
  String eventTileSemanticNew(int slot) {
    return 'Tablero $slot, sin jugar';
  }

  @override
  String eventTilePoints(int points) {
    return '$points pts';
  }

  @override
  String get eventStandingsTitle => 'Clasificación semanal';

  @override
  String get eventStandingsEmpty =>
      'Aún no hay nadie en la tabla. Sé la primera persona.';

  @override
  String eventStandingsCleared(int cleared) {
    return ' · $cleared/7';
  }

  @override
  String get eventSubmitRefused =>
      'El servidor no aceptó ese resultado. Puede que el evento haya terminado.';

  @override
  String get eventSubmitFailed =>
      'Resuelto, pero no se pudo enviar el resultado. Intenta de nuevo.';

  @override
  String eventDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'No hay forma de terminar desde aquí. Deshaz $count movimientos.',
      one: 'No hay forma de terminar desde aquí. Deshaz 1 movimiento.',
    );
    return '$_temp0';
  }

  @override
  String get eventNoHint => 'Ahora no hay pista para esta posición.';

  @override
  String get eventHudLabel => 'Tablero';

  @override
  String eventHudBand(String event, String endsIn) {
    return '$event · $endsIn';
  }

  @override
  String get eventSending => 'Enviando…';

  @override
  String eventResult(int points, int total) {
    return '$points puntos · $total esta semana';
  }

  @override
  String eventResultRanked(int points, int total, int rank) {
    return '$points puntos · $total esta semana · #$rank';
  }

  @override
  String get journeyTitle => 'Viaje';

  @override
  String journeyStarsSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrellas',
      one: '1 estrella',
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
    return 'Mundo $world de $worlds, $name, $solved de $total resueltos';
  }

  @override
  String journeyWorldOf(int world, int worlds) {
    return 'MUNDO $world DE $worlds';
  }

  @override
  String journeyRibbonSemantic(int world, String name, int solved, int total) {
    return 'Mundo $world, $name, $solved de $total resueltos. Ir ahí';
  }

  @override
  String journeyRibbonLabel(int world, String name) {
    return 'MUNDO $world · $name';
  }

  @override
  String get journeyYouPin => 'TÚ';

  @override
  String journeyBandCaps(int world, int count) {
    return 'MUNDO $world · $count';
  }

  @override
  String get journeyBandFirstPours => 'Primeros Pasos';

  @override
  String get journeyBandFindingRhythm => 'Agarrando el Ritmo';

  @override
  String get journeyBandDeepWater => 'Aguas Profundas';

  @override
  String get journeyBandMastery => 'Maestría';

  @override
  String get notifSoftAskTitle => '¿Te avisamos?';

  @override
  String get notifSoftAskBody =>
      'Un aviso cuando salga el Reto Diario de hoy o tu siguiente nivel te esté esperando. Nunca más de dos al día, y puedes desactivarlos cuando quieras en Ajustes.';

  @override
  String get notifSoftAskBodyDenied =>
      'Las notificaciones de Pourfect están desactivadas. Actívalas en la configuración de tu teléfono para recibir un aviso cuando salga el Reto Diario o llegue un mundo nuevo. Nunca más de dos al día.';

  @override
  String get notifSoftAskOpenSettings => 'Abrir configuración';

  @override
  String get notifSoftAskYes => 'Sí, por favor';

  @override
  String get notifChannelName => 'Recordatorios';

  @override
  String get notifChannelDescription =>
      'El Reto Diario, tu siguiente nivel y mundos nuevos. Nunca más de dos al día.';

  @override
  String get playHudLevel => 'Nivel';

  @override
  String playHudTitle(String label, String value) {
    return '$label $value';
  }

  @override
  String get playHudHard => 'DIFÍCIL ×1.5';

  @override
  String get playHudHardLabel =>
      'Nivel difícil, vale una vez y media los puntos';

  @override
  String get playHudMoves => 'MOV.';

  @override
  String playHudMovesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimientos',
      one: '1 movimiento',
    );
    return '$_temp0';
  }

  @override
  String playParLeftFor3Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te quedan $count movimientos para 3 estrellas',
      one: 'Te queda 1 movimiento para 3 estrellas',
    );
    return '$_temp0';
  }

  @override
  String get playParSpent => 'Par agotado · 2 estrellas desde aquí';

  @override
  String playParLeftFor2Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te quedan $count movimientos para 2 estrellas',
      one: 'Te queda 1 movimiento para 2 estrellas',
    );
    return '$_temp0';
  }

  @override
  String get playParOneStarFromHere =>
      '1 estrella desde aquí · con solo terminar';

  @override
  String get playParAnyFinish => 'Terminar te da 1 estrella';

  @override
  String playParMeterLabel(int stars, int used, int par, String words) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'Ritmo de $stars estrellas',
      one: 'Ritmo de 1 estrella',
    );
    return '$_temp0, $used de $par movimientos de par. $words';
  }

  @override
  String playHudBusyLabel(String label) {
    return '$label, trabajando. Toca para cancelar';
  }

  @override
  String get playHudUndo => 'Deshacer';

  @override
  String get playHudHint => 'Pista';

  @override
  String get playHudRestart => 'Reiniciar';

  @override
  String get playExtraTubeLabel => 'Mira un video por un tubo extra';

  @override
  String get playExtraTubeChip => '+ Tubo';

  @override
  String playStarsOfTotal(int earned, int total) {
    return '$earned de $total estrellas';
  }

  @override
  String get playDismiss => 'Cerrar';

  @override
  String get playLeaveTitleSoSoon => '¿Ya te vas?';

  @override
  String get playLeaveTitleMissYou => 'Las bolitas te van a extrañar';

  @override
  String get playLeaveTitleAbandon => '¿Abandonar el vertido?';

  @override
  String get playLeaveTitleMidPour => '¿Te vas a medio vertido?';

  @override
  String get playLeaveBody =>
      'Tus movimientos y tu tiempo en este tablero no se guardarán.';

  @override
  String get playLeaveKeepPouring => 'Seguir jugando';

  @override
  String get playLeaveConfirm => 'Salir';

  @override
  String get playTutorialSkipLabel => 'Saltar el tutorial';

  @override
  String get playTutorialSkip => 'Saltar';

  @override
  String playTipBubbleLabel(String text) {
    return '$text. Cerrar';
  }

  @override
  String get playTipPar =>
      'Termina dentro del par para tres estrellas. La barra muestra cuánto llevas.';

  @override
  String get playTipTallTubes =>
      '¡Tubos más altos! Ahora cada uno lleva cinco bolitas.';

  @override
  String get playTipHint =>
      '¿Atascado? Pista te muestra un buen siguiente movimiento.';

  @override
  String get playTipUndo =>
      '¿Pasaste el par? Deshacer es gratis: retrocede todo lo que quieras.';

  @override
  String get playGuideSorted =>
      '¡Ordenado! Ahora deja cada tubo de un solo color.';

  @override
  String get playGuideDrop =>
      'Ahora toca dónde van: sobre el mismo color o en un tubo vacío.';

  @override
  String get playGuideWrongTube =>
      'Toca el tubo que señala la mano para tomar esas bolitas.';

  @override
  String get playGuideFirstTap =>
      'Toca un tubo para tomar las bolitas de arriba.';

  @override
  String get playGuideFirstPour => '¡Eso es un vertido! Sigue así.';

  @override
  String get playGuideKeepGoing => 'Sigue así: un color por tubo.';

  @override
  String playCoachHolding(int count) {
    return 'Tienes $count · suéltalas en un tubo que rebote';
  }

  @override
  String get playExtraTubeAdTitle => '¿Ver un video por un tubo extra?';

  @override
  String get playExtraTubeAdBody =>
      'Un tubo vacío más para este nivel. Un nivel terminado con un tubo extra da hasta dos estrellas.';

  @override
  String get playExtraTubeNotFinished => 'Sin tubo: el video no se terminó.';

  @override
  String get playExtraTubeSaved => 'Guardado: tu próximo tubo es gratis.';

  @override
  String get playNoVideo => 'No hay videos disponibles ahora.';

  @override
  String get playRewardFailed => 'Algo salió mal. No se usó nada.';

  @override
  String get playHintShowing =>
      'Tu pista ya está en pantalla: vierte en el tubo que brilla.';

  @override
  String get playHintNoneNothingUsed =>
      'No hay pista para esta posición. No se usó nada.';

  @override
  String get playHintNotFinished => 'Sin pista: el video no se terminó.';

  @override
  String get playHintVideoSaved =>
      'Tu video queda guardado para la próxima pista.';

  @override
  String get playHintNoneVideoSaved =>
      'No hay pista para esta posición: tu video queda guardado para la próxima.';

  @override
  String get playHintNone => 'No hay pista disponible para esta posición.';

  @override
  String get playHintHere =>
      'Aquí está tu pista: vierte en el tubo que brilla.';

  @override
  String get playDeadEndRestart =>
      'No hay forma de terminar desde aquí. Reinicia para probar otro camino.';

  @override
  String get playDeadEndRestartTube =>
      'No hay forma de terminar desde aquí. Reinicia para probar otro camino. O toca + Tubo para un tubo extra.';

  @override
  String playDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'No hay forma de terminar desde aquí. Deshaz $count movimientos para retomar el camino.',
      one: 'No hay forma de terminar desde aquí. Deshaz 1 movimiento para retomar el camino.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoTube(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'No hay forma de terminar desde aquí. Deshaz $count movimientos para retomar el camino. O toca + Tubo para un tubo extra.',
      one: 'No hay forma de terminar desde aquí. Deshaz 1 movimiento para retomar el camino. O toca + Tubo para un tubo extra.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoAction(int count) {
    return 'Deshacer $count';
  }

  @override
  String get playHintAdTitle => '¿Ver un video por una pista?';

  @override
  String playHintAdFreeLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te quedan $count pistas gratis.',
      one: 'Te queda 1 pista gratis.',
    );
    return '$_temp0';
  }

  @override
  String get playHintAdNoneLeft =>
      'Ya usaste tus pistas gratis. Un video corto te da una más.';

  @override
  String get playWatch => 'Ver';

  @override
  String get playLoadFailed => 'No se pudieron cargar los niveles';

  @override
  String get playTubeSorted => '¡LISTO!';

  @override
  String get playWinTitlePerfect => '¡Vertido\nperfecto!';

  @override
  String get playWinTitleNice => '¡Buen\nvertido!';

  @override
  String get playWinTitlePoured => '¡Vertido!';

  @override
  String get playWinLastPour => 'Último vertido…';

  @override
  String playWinMovesPar(int count, int par) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count MOV. · PAR $par',
      one: '1 MOV. · PAR $par',
    );
    return '$_temp0';
  }

  @override
  String playWinLevelBand(int level, String band) {
    return 'Nivel $level · $band';
  }

  @override
  String get playWinNewBest => '¡RÉCORD!';

  @override
  String playWinMovesChip(int par) {
    return 'mov. · par $par';
  }

  @override
  String get playWinUntimed => 'sin reloj';

  @override
  String get playWinFastest => '¡tu mejor tiempo!';

  @override
  String get playWinTime => 'tiempo';

  @override
  String get playWinUnderPar => '¡BAJO PAR!';

  @override
  String get playWinPoints => 'puntos';

  @override
  String playWinWorldBand(int world, String band) {
    return 'MUNDO $world · $band';
  }

  @override
  String get playWinTryAssisted =>
      'Para tres estrellas, supéralo sin el tubo extra.';

  @override
  String playWinTryShort(int par, int took, int short) {
    String _temp0 = intl.Intl.pluralLogic(
      short,
      locale: localeName,
      other: 'Par $par, hiciste $took. A $short movimientos de 3★.',
      one: 'Par $par, hiciste $took. A un movimiento de 3★.',
    );
    return '$_temp0';
  }

  @override
  String playWinTryInReach(int par) {
    return 'Par $par. Las tres estrellas están a tu alcance.';
  }

  @override
  String get playWinTryButton => 'POR 3★';

  @override
  String get playWinTryButtonLabel =>
      'Volver a jugar este nivel por tres estrellas';

  @override
  String get playWinReplayLabel => 'Volver a jugar este nivel';

  @override
  String get playWinHomeLabel => 'Volver a la pantalla de inicio';

  @override
  String get playWinNextLevel => 'SIGUIENTE';

  @override
  String get playWinBackToLevels => 'A LOS NIVELES';

  @override
  String playChestNextAtLabel(int stars) {
    return 'Próximo cofre de estrellas a las $stars estrellas';
  }

  @override
  String get playChestOpenLabel => 'Abrir cofre de estrellas';

  @override
  String get playChestReady => '¡Hay un cofre de estrellas listo!';

  @override
  String playChestNextAt(int stars) {
    return 'Próximo cofre a las $stars ★';
  }

  @override
  String get playChestOpen => 'ABRIR';

  @override
  String get playChestDoubleFailed => 'Esta vez no se pudo duplicar.';

  @override
  String get playChestDoubleNotFinished =>
      'Sin duplicar: el video no se terminó.';

  @override
  String get playChestOpening => 'Abriendo…';

  @override
  String playChestTitle(int index) {
    return 'Cofre de estrellas $index';
  }

  @override
  String get playChestNotYetTitle => 'Ya casi';

  @override
  String get playChestAlreadyOpenTitle => 'Ya está abierto';

  @override
  String get playChestFailedTitle => 'No se pudo abrir';

  @override
  String get playChestNotYetNote =>
      'Tus estrellas más nuevas aún van camino al servidor. Intenta de nuevo en un momento.';

  @override
  String get playChestAlreadyOpenNote =>
      'Este cofre se abrió en otro dispositivo.';

  @override
  String get playChestFailedNote => 'Revisa tu conexión e intenta de nuevo.';

  @override
  String playChestRewardCount(int count) {
    return '+$count';
  }

  @override
  String playChestHintsCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pistas',
      one: 'pista',
    );
    return '$_temp0';
  }

  @override
  String playChestTubesCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tubos extra',
      one: 'tubo extra',
    );
    return '$_temp0';
  }

  @override
  String playChestUnlocked(String name) {
    return 'Desbloqueado: $name';
  }

  @override
  String playChestBallSkinName(String skin) {
    return 'aspecto de bolitas $skin';
  }

  @override
  String playChestTubeThemeName(String theme) {
    return 'tubos $theme';
  }

  @override
  String get playChestNewLook => 'un nuevo aspecto';

  @override
  String get playChestSavedNote =>
      'Guardados para cuando los necesites. Pista y + Tubo los usan primero.';

  @override
  String get playChestLoadingVideo => 'Cargando video…';

  @override
  String get playChestDouble => 'Duplícalo con un video';

  @override
  String get playChestCollect => 'Recoger';

  @override
  String playClockLabel(String time) {
    return 'Tiempo $time';
  }

  @override
  String playClockDetailLabel(
    String time,
    String par,
    String sign,
    int percent,
  ) {
    String _temp0 = intl.Intl.selectLogic(sign, {
      'plus': 'más',
      'other': 'menos',
    });
    return 'Tiempo $time de $par de par, $_temp0 $percent por ciento de puntos';
  }

  @override
  String playClockBonusChip(String sign, int percent) {
    return '$sign$percent% pts';
  }

  @override
  String get playLoading => 'Cargando';

  @override
  String get playWorking => 'Trabajando';

  @override
  String get playZenTitle => 'Zen';

  @override
  String get playZenIntro =>
      'Tableros sin fin. Sin reloj, sin estrellas, sin clasificación: solo vierte.';

  @override
  String get playZenPaceCalm => 'Tranquilo';

  @override
  String get playZenPaceSteady => 'Constante';

  @override
  String get playZenPaceDeep => 'Profundo';

  @override
  String playZenPaceColors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count colores',
      one: '1 color',
    );
    return '$_temp0';
  }

  @override
  String playZenPaceLabel(String pace, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$pace, $count colores',
      one: '$pace, 1 color',
    );
    return '$_temp0';
  }

  @override
  String playZenBandPoured(String pace, int count) {
    return '$pace · $count resueltos';
  }

  @override
  String playZenPoured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡Vertido! Llevas $count.',
      one: '¡Vertido!',
    );
    return '$_temp0';
  }

  @override
  String get playZenNext => 'OTRO';

  @override
  String get playZenLeaveBody =>
      'Los movimientos de este tablero no se guardarán. Tu cuenta de resueltos se mantiene.';

  @override
  String get playZenDeadEnd =>
      'No hay forma de terminar desde aquí. Deshaz o reinicia.';

  @override
  String get playZenNoHint => 'Ahora no hay pista para esta posición.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionFeel => 'Sensación';

  @override
  String get settingsSectionVisibility => 'Visibilidad';

  @override
  String get settingsSectionLeaderboard => 'Clasificación';

  @override
  String get settingsSectionNotifications => 'Notificaciones';

  @override
  String get settingsSectionSupport => 'Ayuda';

  @override
  String get settingsSectionAccount => 'Cuenta e info';

  @override
  String get settingsSectionDanger => 'Zona de peligro';

  @override
  String get settingsSoundTitle => 'Efectos de sonido';

  @override
  String get settingsSoundDetail => 'Vertidos, botones y premios';

  @override
  String get settingsSoundVolume => 'Volumen de efectos';

  @override
  String get settingsMusicTitle => 'Música';

  @override
  String get settingsMusicDetail => 'Nunca suena encima de tu propia música';

  @override
  String get settingsMusicVolume => 'Volumen de música';

  @override
  String get settingsHapticsTitle => 'Vibración';

  @override
  String get settingsHapticsDetail => 'Un toque al caer cada bolita';

  @override
  String get settingsSmoothMotionTitle => 'Movimiento fluido';

  @override
  String get settingsSmoothMotionAuto => 'Auto';

  @override
  String get settingsSmoothMotion60 => '60 Hz';

  @override
  String get settingsSmoothMotionMax => 'Máx.';

  @override
  String get settingsMotionUnknown =>
      'Auto usa la frecuencia más alta de tu pantalla si este teléfono aguanta';

  @override
  String settingsMotionFixed(String max) {
    return 'Esta pantalla solo funciona a $max Hz';
  }

  @override
  String settingsMotionBatterySaver(String current) {
    return 'El Ahorro de batería la mantiene en $current Hz';
  }

  @override
  String settingsMotionAutoStuttered(String current, String max) {
    return 'A $current Hz · este teléfono se trabó a $max Hz';
  }

  @override
  String settingsMotionAuto(String current) {
    return 'A $current Hz · baja a 60 Hz si se traba';
  }

  @override
  String settingsMotionPinnedByPhone(String current) {
    return 'El ajuste de pantalla de tu teléfono la mantiene en $current Hz';
  }

  @override
  String settingsMotionStandard(String current, String max) {
    return 'A $current Hz · esta pantalla llega a $max Hz';
  }

  @override
  String settingsMotionMax(String current) {
    return 'A $current Hz, lo más rápido de esta pantalla';
  }

  @override
  String get settingsBoldSymbolsTitle => 'Símbolos marcados';

  @override
  String get settingsBoldSymbolsDetail => 'Formas más marcadas para daltonismo';

  @override
  String get settingsRenameTitle => 'Cambiar tu nombre';

  @override
  String get settingsRenameDetail => 'Cómo apareces en las tablas';

  @override
  String get settingsShowOnBoardsTitle => 'Mostrarme en las clasificaciones';

  @override
  String get settingsShowOnBoardsDetail =>
      'Apagado oculta tu nombre y puesto. Las estrellas cuentan igual.';

  @override
  String get settingsHowToPlayTitle => 'Cómo jugar';

  @override
  String get settingsHowToPlayDetail => 'Repite el primer nivel guiado';

  @override
  String get settingsQuestionsTitle => 'Preguntas';

  @override
  String get settingsQuestionsDetail => 'Estrellas, pistas, el reloj y más';

  @override
  String get settingsRateTitle => 'Califica Pourfect';

  @override
  String get settingsRateDetail => 'Cuéntales a otros jugadores qué te parece';

  @override
  String get settingsCollectionTitle => 'Colección';

  @override
  String get settingsCollectionDetail => 'Aspectos de bolitas y temas de tubos';

  @override
  String get settingsRestoreTitle => 'Restaurar compras';

  @override
  String get settingsRestoreDetail =>
      'Quitar anuncios o el Paquete de aspectos';

  @override
  String get settingsRestoreDone => 'Compras restauradas, si había alguna.';

  @override
  String get settingsRemoveAdsTitle => 'Quitar anuncios';

  @override
  String get settingsRemoveAdsDetail =>
      'Sin anuncios entre niveles. Los videos de pistas siguen.';

  @override
  String get settingsAdsRemoved => 'Anuncios quitados. ¡Gracias!';

  @override
  String get settingsPurchaseThanks =>
      '¡Gracias! Ya no hay anuncios entre niveles.';

  @override
  String get settingsPurchaseAlreadyOwned =>
      'Ya lo compraste: los anuncios están desactivados.';

  @override
  String get settingsPurchasePending =>
      'Pago pendiente. Los anuncios se desactivarán cuando se confirme.';

  @override
  String get settingsStoreUnavailable =>
      'La tienda no está disponible en este dispositivo ahora.';

  @override
  String get settingsPurchaseFailed =>
      'La compra no se completó. No se te cobró nada.';

  @override
  String get settingsStoreOpenFailed => 'No se pudo abrir la tienda.';

  @override
  String get settingsBrowserOpenFailed => 'No se pudo abrir el navegador.';

  @override
  String get settingsSignedIn => 'Sesión iniciada';

  @override
  String get settingsSignedInDetail => 'Tu progreso va contigo';

  @override
  String get settingsSaveProgressTitle => 'Guarda tu progreso';

  @override
  String get settingsSaveProgressDetail =>
      'Conserva tus estrellas si cambias de teléfono';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsTermsAndLicenses => 'Términos y licencias';

  @override
  String get settingsTermsOfUse => 'Términos de uso';

  @override
  String get settingsRefundPolicy => 'Política de reembolso';

  @override
  String get settingsOpenSourceLicenses => 'Licencias de código abierto';

  @override
  String get settingsAdPrivacyTitle => 'Privacidad de anuncios';

  @override
  String get settingsAdPrivacyDetail =>
      'Cambia lo que aceptaste sobre publicidad';

  @override
  String get settingsResetRowTitle => 'Reiniciar progreso';

  @override
  String get settingsResetRowDetail =>
      'Borra todas las estrellas y empieza desde el nivel 1';

  @override
  String get settingsResetTitle => '¿Reiniciar progreso?';

  @override
  String get settingsResetNothing => 'Aún no hay nada que reiniciar.';

  @override
  String settingsResetBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Esto borra todas las estrellas y mejores marcas de $count niveles resueltos, y vuelve a bloquear todo después del nivel 1. No se puede deshacer.',
      one: 'Esto borra todas las estrellas y mejores marcas de 1 nivel resuelto, y vuelve a bloquear todo después del nivel 1. No se puede deshacer.',
    );
    return '$_temp0';
  }

  @override
  String get settingsKeepIt => 'Conservar';

  @override
  String get settingsResetConfirm => 'Borrar todo';

  @override
  String get settingsResetDone => 'Progreso reiniciado.';

  @override
  String get settingsSignOutTitle => '¿Cerrar sesión?';

  @override
  String get settingsSignOutBody =>
      'Tu progreso se queda en este teléfono. Puedes volver a iniciar sesión cuando quieras para seguir en otro lado.';

  @override
  String get settingsSignOutStay => 'Seguir conectado';

  @override
  String get settingsSignOutConfirm => 'Cerrar sesión';

  @override
  String get settingsServerUnreachable =>
      'No se pudo conectar con el servidor, así que no cambió nada.';

  @override
  String get settingsDeleteRowTitle => 'Eliminar cuenta';

  @override
  String get settingsDeleteRowDetail => 'Elimina tu cuenta y todo lo que tiene';

  @override
  String get settingsDeleteTitle => '¿Eliminar tu cuenta?';

  @override
  String get settingsDeleteBody =>
      'Esto elimina tu cuenta, tus estrellas, tu racha y tu lugar en las clasificaciones, en este teléfono y en nuestro servidor. No se puede deshacer.\n\nQuitar anuncios no se ve afectado: pertenece a la cuenta de la tienda con la que lo compraste y se restaura si vuelves a jugar.';

  @override
  String get settingsDeleteConfirm => 'Eliminar todo';

  @override
  String get settingsDeleteServerRefused =>
      'No se pudo conectar con el servidor. No se eliminó nada: intenta de nuevo cuando vuelvas a estar en línea.';

  @override
  String get settingsDeleteNotAuthenticated =>
      'No pudimos confirmar que eres tú. Vuelve a iniciar sesión y luego elimina tu cuenta. Todavía no se eliminó nada.';

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
          'Pourfect $version · hecho con $count tableros con solución comprobada',
      one: 'Pourfect $version · hecho con 1 tablero con solución comprobada',
    );
    return '$_temp0';
  }

  @override
  String get settingsNamingYou => 'Buscando tu nombre…';

  @override
  String get settingsYourName => 'Tu nombre';

  @override
  String get settingsGuest => 'Jugando como invitado';

  @override
  String get settingsStatSolved => 'RESUELTOS';

  @override
  String get settingsStatStars => 'ESTRELLAS';

  @override
  String get settingsNotifyTurnOnTitle => 'Activar notificaciones';

  @override
  String get settingsNotifyDeniedDetail =>
      'Desactivadas en tu teléfono. Toca para abrir la configuración.';

  @override
  String get settingsNotifyNotYetDetail => 'Pourfect aún no puede avisarte';

  @override
  String get settingsRemindersTitle => 'Recordatorios del Reto Diario';

  @override
  String get settingsRemindersDetail =>
      'Mañana y tarde, nunca más de dos al día';

  @override
  String get settingsNewsTitle => 'Novedades';

  @override
  String get settingsNewsDetail => 'Mundos nuevos y anuncios';

  @override
  String settingsToggleOn(String title) {
    return '$title, activado';
  }

  @override
  String settingsToggleOff(String title) {
    return '$title, desactivado';
  }

  @override
  String get settingsFaqSectionPlaying => 'Cómo se juega';

  @override
  String get settingsFaqSectionStuck => '¿Atascado?';

  @override
  String get settingsFaqSectionProgress => 'Tu progreso';

  @override
  String get settingsFaqSectionAds => 'Anuncios y sonido';

  @override
  String get settingsFaqHowToPlayQ => '¿Cómo se juega?';

  @override
  String get settingsFaqHowToPlayA =>
      'Toca un tubo para tomar las bolitas de arriba y luego toca otro tubo para verterlas. Las bolitas solo caen sobre el mismo color o en un tubo vacío. Deja cada tubo de un solo color y el nivel está listo. En Ajustes → Cómo jugar puedes repetir el primer nivel guiado.';

  @override
  String get settingsFaqStarsQ => '¿Qué significan las estrellas?';

  @override
  String get settingsFaqStarsA =>
      'Las estrellas cuentan movimientos, nada más. Termina en el par o menos para tres estrellas, en hasta una vez y media el par para dos, y cualquier final te da una. El par es la menor cantidad de movimientos con que se puede resolver el nivel.';

  @override
  String get settingsFaqClockQ => '¿El reloj me quita estrellas?';

  @override
  String get settingsFaqClockA =>
      'Nunca. El tiempo solo cambia tus puntos. Supera el par de tiempo para ganar puntos extra, o tómate todo el tiempo que quieras y conserva todas las estrellas.';

  @override
  String get settingsFaqSolvableQ => '¿Todos los niveles tienen solución?';

  @override
  String get settingsFaqSolvableA =>
      'Sí. Cada tablero se resolvió antes de publicarse, y el par sale de esa solución, así que siempre se puede alcanzar.';

  @override
  String get settingsFaqDailyQ => '¿Qué es el Reto Diario?';

  @override
  String get settingsFaqDailyA =>
      'Un tablero nuevo cada día, con su propia clasificación. Necesita conexión a internet. Los niveles de la campaña no.';

  @override
  String get settingsFaqUndoQ => '¿Deshacer tiene límite?';

  @override
  String get settingsFaqUndoA =>
      'No. Deshacer es gratis e ilimitado, en todos los niveles.';

  @override
  String get settingsFaqHintsQ => '¿Cómo funcionan las pistas?';

  @override
  String settingsFaqHintsA(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tus primeras $count pistas son gratis. Después, un video corto te da una. Si no se encuentra una pista, el video cuenta igual para la siguiente.',
      one: 'Tu primera pista es gratis. Después, un video corto te da una. Si no se encuentra una pista, el video cuenta igual para la siguiente.',
    );
    return '$_temp0';
  }

  @override
  String get settingsFaqTubeQ => '¿Qué es el botón + Tubo?';

  @override
  String get settingsFaqTubeA =>
      'Cuando tus movimientos llegan al par, o una pista muestra que no hay forma de terminar, puedes ver un video por un tubo vacío extra, hasta dos por intento. Deshacer no te lo quita. Un nivel terminado con un tubo extra da hasta dos estrellas.';

  @override
  String get settingsFaqHardQ => '¿Qué son los niveles DIFÍCIL?';

  @override
  String get settingsFaqHardA =>
      'El nivel más duro de cada diez lleva una insignia roja de DIFÍCIL. Se juega como cualquier otro nivel y vale una vez y media los puntos.';

  @override
  String get settingsFaqChestsQ => '¿Qué son los cofres de estrellas?';

  @override
  String get settingsFaqChestsA =>
      'Cada 30 estrellas se abre un cofre en tu Viaje: dos pistas y un tubo extra, guardados para cuando los necesites. Cada tercer cofre también desbloquea un aspecto de bolitas.';

  @override
  String get settingsFaqFreezeQ => '¿Qué es un congelador de racha?';

  @override
  String get settingsFaqFreezeA =>
      'Si te pierdes un día del Reto Diario, un congelador lo cubre y tu racha sigue. Recibes uno gratis cada lunes, puedes ganar uno al día con un video y puedes guardar dos.';

  @override
  String get settingsFaqAccountQ => '¿Necesito una cuenta?';

  @override
  String get settingsFaqAccountA =>
      'No. Juegas como invitado y tu progreso se guarda en este teléfono. Al iniciar sesión conservas tus estrellas cuando cambies a un teléfono nuevo.';

  @override
  String get settingsFaqOfflineQ => '¿Puedo jugar sin conexión?';

  @override
  String get settingsFaqOfflineA =>
      'Sí, toda la campaña. El Reto Diario y las clasificaciones necesitan conexión, y tu progreso se sincroniza cuando vuelves a estar en línea.';

  @override
  String get settingsFaqNameQ => '¿Cómo cambio mi nombre en la clasificación?';

  @override
  String get settingsFaqNameA =>
      'En Ajustes → Cambiar tu nombre. Ahí también puedes ocultarte de las tablas; tus estrellas cuentan igual.';

  @override
  String get settingsFaqRemoveAdsQ => '¿Qué hace Quitar anuncios?';

  @override
  String get settingsFaqRemoveAdsA =>
      'Desactiva los anuncios entre niveles. Los videos de pistas y tubos se mantienen, porque solo ves uno cuando lo pides.';

  @override
  String get settingsFaqReinstallQ =>
      'Reinstalé el juego. ¿Dónde quedó Quitar anuncios?';

  @override
  String get settingsFaqReinstallA =>
      'Pertenece a la cuenta de la tienda con la que lo compraste y normalmente vuelve solo. Si no, toca Ajustes → Restaurar compras.';

  @override
  String get settingsFaqMusicQ => '¿El juego va a detener mi música?';

  @override
  String get settingsFaqMusicA =>
      'No. Pourfect reproduce sus sonidos junto con tu música o podcast. El sonido y la vibración se pueden desactivar en Ajustes.';

  @override
  String get settingsLegalTitle => 'Antes de empezar';

  @override
  String get settingsLegalIntro =>
      'Pourfect es gratis, funciona sin conexión y no necesita cuenta. Primero lee y acepta esto, por favor.';

  @override
  String settingsLegalAcceptTerms(String document) {
    return 'Acepto los $document';
  }

  @override
  String settingsLegalReadPrivacy(String document) {
    return 'Leí la $document';
  }

  @override
  String settingsLegalAlsoCovers(String document, String version) {
    return 'Al aceptar, también aceptas nuestra $document (versión $version).';
  }

  @override
  String get settingsLegalPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsLegalTermsOfService => 'Términos del servicio';

  @override
  String get settingsLegalRefundPolicy => 'Política de reembolso';

  @override
  String settingsLegalReadDocument(String document) {
    return 'Leer: $document';
  }

  @override
  String get settingsLegalAccept => '¡A JUGAR!';

  @override
  String get settingsLegalReadAgain =>
      'Puedes volver a leerlos cuando quieras en Ajustes.';

  @override
  String get settingsLegalLoadFailed =>
      'Este documento no se pudo cargar en este dispositivo.\n\nPuedes leerlo en legal.pranta.dev antes de aceptar.';

  @override
  String get settingsUpdateTitle => 'Hay un nuevo Pourfect';

  @override
  String get settingsUpdateBody =>
      'Google Play lo descargará y volverá a abrir el juego cuando termine. Tus estrellas están a salvo.';

  @override
  String get settingsUpdateMandatoryTitle => 'Hora de actualizar';

  @override
  String get settingsUpdateMandatoryBody =>
      'Esta versión de Pourfect ya no tiene soporte. Google Play descargará la actualización y volverá a abrir el juego. Tus estrellas están a salvo.';

  @override
  String get settingsUpdateNow => 'Actualizar';

  @override
  String get settingsRenameHello => 'HOLA';

  @override
  String get settingsRenameMyNameIs => 'ME LLAMO';

  @override
  String get settingsRenameHint => 'Otros jugadores lo ven en las tablas';

  @override
  String get settingsRenameSave => 'GUARDAR';

  @override
  String settingsCollectionUnlockWith(String how) {
    return 'Desbloquéalo con: $how.';
  }

  @override
  String get settingsCollectionChangeFailed =>
      'No se pudo cambiar ahora. Intenta más tarde.';

  @override
  String get settingsPackThanks =>
      '¡Gracias! El paquete se desbloquea en un momento.';

  @override
  String get settingsPackAlreadyOwned => 'Ya es tuyo. Restaurándolo ahora.';

  @override
  String get settingsPackPending =>
      'Pago pendiente. El paquete se desbloquea cuando se confirme.';

  @override
  String get settingsCollectionOffline =>
      'Conéctate a internet para ver tu colección.';

  @override
  String get settingsCollectionBallSkins => 'Aspectos de bolitas';

  @override
  String get settingsCollectionTubeThemes => 'Temas de tubos';

  @override
  String settingsCollectionPreview(String skin, String theme) {
    return 'Bolitas $skin · tubos $theme';
  }

  @override
  String settingsCollectionItemWorn(String name) {
    return '$name, en uso';
  }

  @override
  String settingsCollectionItemTapToWear(String name) {
    return '$name, toca para usar';
  }

  @override
  String settingsCollectionItemLocked(String name, String how) {
    return '$name, bloqueado: $how';
  }

  @override
  String get settingsCollectionWearing => 'En uso';

  @override
  String get settingsCollectionTapToWear => 'Toca para usar';

  @override
  String settingsUnlockChest(int number) {
    return 'Cofre de estrellas $number';
  }

  @override
  String settingsUnlockStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Racha de $days días',
      one: 'Racha de $days día',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnlockFree => 'Gratis';

  @override
  String get settingsSkinPack => 'Paquete de aspectos';

  @override
  String get settingsSkinPackDetail =>
      'Bolitas Mármol, Perla y Cuadros, tubos Madera y Lila.';

  @override
  String get settingsOwned => 'TUYO';

  @override
  String get settingsSoon => 'Pronto';

  @override
  String get settingsSkinClassic => 'Clásico';

  @override
  String get settingsSkinGlossy => 'Brillante';

  @override
  String get settingsSkinStriped => 'Caramelo';

  @override
  String get settingsSkinGlow => 'Neón';

  @override
  String get settingsSkinSpeckled => 'Chispitas';

  @override
  String get settingsSkinMarble => 'Mármol';

  @override
  String get settingsSkinPearl => 'Perla';

  @override
  String get settingsSkinChecker => 'Cuadros';

  @override
  String get settingsTubeToy => 'Juguete';

  @override
  String get settingsTubeFrost => 'Escarcha';

  @override
  String get settingsTubeWood => 'Madera';

  @override
  String get settingsTubeLilac => 'Lila';
}
