// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get accountGoogleFailed =>
      'O login com o Google não funcionou neste celular. Tente de novo ou use o e-mail abaixo.';

  @override
  String get accountAppleFailed =>
      'O login com a Apple não funcionou neste celular. Confira se você está conectado à sua Conta Apple em Ajustes ou use o e-mail abaixo.';

  @override
  String get accountExistsNoLocal =>
      'Você já tem uma conta com esse e-mail. Entre nela e este celular vai carregar as estrelas salvas lá.';

  @override
  String accountExistsWithLocal(int solved) {
    String _temp0 = intl.Intl.pluralLogic(
      solved,
      locale: localeName,
      other:
          'Você já tem uma conta com esse e-mail. Este celular tem $solved níveis resolvidos que não estão nela, e os dois não podem ser combinados: ao entrar, eles serão substituídos pelo que estiver nessa conta.',
      one:
          'Você já tem uma conta com esse e-mail. Este celular tem $solved nível resolvido que não está nela, e os dois não podem ser combinados: ao entrar, ele será substituído pelo que estiver nessa conta.',
    );
    return '$_temp0';
  }

  @override
  String get accountEmailInUse =>
      'Já existe uma conta com esse e-mail. Tente entrar nela.';

  @override
  String get accountEmailMalformed => 'Isso não parece um endereço de e-mail.';

  @override
  String get accountPasswordWeak =>
      'Essa senha é fácil demais de adivinhar. Tente uma mais longa.';

  @override
  String get accountWrongPassword =>
      'Esse e-mail e essa senha não correspondem.';

  @override
  String get accountTooManyAttempts =>
      'Tentativas demais. Espere alguns minutos e tente de novo.';

  @override
  String get accountNeedsRecentLogin => 'Entre de novo primeiro.';

  @override
  String get accountMethodNotEnabled =>
      'O login por e-mail não está disponível agora. Tente Continuar com o Google.';

  @override
  String get accountSessionUnavailable =>
      'Você entrou, mas seu progresso ainda não foi salvo no servidor. Ele será sincronizado quando a conexão voltar.';

  @override
  String get accountUnavailable =>
      'Não foi possível conectar ao servidor. Seu progresso continua seguro neste dispositivo.';

  @override
  String get accountUseThatAccount => 'Usar essa conta';

  @override
  String get accountExistingTitle => 'Você já tem uma conta';

  @override
  String get accountExistingBodyEmpty =>
      'Este celular vai carregar as estrelas já salvas nela.';

  @override
  String accountExistingBodyLocal(int cleared) {
    String _temp0 = intl.Intl.pluralLogic(
      cleared,
      locale: localeName,
      other:
          'Este celular tem $cleared níveis resolvidos que não estão nessa conta. Não dá para combinar, então eles serão substituídos pelo que a conta já tem.',
      one:
          'Este celular tem $cleared nível resolvido que não está nessa conta. Não dá para combinar, então ele será substituído pelo que a conta já tem.',
    );
    return '$_temp0';
  }

  @override
  String get accountSignIn => 'Entrar';

  @override
  String get accountSignInCancelled => 'Login cancelado. Nada mudou.';

  @override
  String get accountSignedInToast =>
      'Pronto, você entrou. Agora suas estrelas vão com você para um celular novo.';

  @override
  String get accountResetNeedsEmail =>
      'Digite seu e-mail primeiro e depois toque em Esqueceu a senha?';

  @override
  String get accountResetSent =>
      'Se esse e-mail tiver uma conta, um link para redefinir a senha está a caminho.';

  @override
  String get accountYourAccount => 'Sua conta';

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
      'Este cartão vai junto com sua conta, então um celular novo começa exatamente de onde você parou.';

  @override
  String get accountYourNameHeader => 'Seu nome';

  @override
  String get accountChangeName => 'Mudar seu nome';

  @override
  String get accountChangeNameDetail => 'Como você aparece nos rankings';

  @override
  String get accountShowOnBoards => 'Mostrar meu nome nos rankings';

  @override
  String get accountShowOnBoardsDetail =>
      'Desligado, oculta nome e posição. Estrelas contam.';

  @override
  String get accountYourPlayHeader => 'Seu jogo';

  @override
  String get accountStatistics => 'Estatísticas';

  @override
  String get accountStatisticsDetail =>
      'Seus tempos, atividade e todos os níveis';

  @override
  String get accountSessionHeader => 'Sessão';

  @override
  String get accountDeleteHint =>
      'Para excluir sua conta, vá em Configurações → Zona de perigo.';

  @override
  String get accountVisibilityFailed =>
      'Não foi possível conectar ao servidor, então nada mudou.';

  @override
  String get accountSignOutTitle => 'Sair?';

  @override
  String get accountSignOutBody =>
      'Seu progresso fica neste celular. Você pode entrar de novo quando quiser para continuar em outro lugar.';

  @override
  String get accountStaySignedIn => 'Continuar conectado';

  @override
  String get accountSignOut => 'Sair';

  @override
  String get accountSignOutDetail => 'Seu progresso fica neste celular';

  @override
  String get accountSaveTitle => 'Salve seu progresso';

  @override
  String get accountSaveIntro =>
      'Suas estrelas, sua sequência e seu nome no ranking vão junto com sua conta, então um celular novo começa de onde você parou.';

  @override
  String get accountContinueApple => 'Continuar com a Apple';

  @override
  String get accountContinueGoogle => 'Continuar com o Google';

  @override
  String get accountOr => 'OU';

  @override
  String get accountEmailLabel => 'E-mail';

  @override
  String get accountEmailEmpty => 'Digite seu e-mail.';

  @override
  String get accountPasswordLabel => 'Senha';

  @override
  String get accountPasswordHelper => 'Pelo menos 8 caracteres';

  @override
  String get accountPasswordEmpty => 'Digite uma senha.';

  @override
  String get accountPasswordShort => 'Pelo menos 8 caracteres.';

  @override
  String get accountShowPassword => 'Mostrar senha';

  @override
  String get accountHidePassword => 'Ocultar senha';

  @override
  String get accountCreate => 'Criar conta';

  @override
  String get accountSwitchToSignIn => 'Já tem uma conta? Entrar';

  @override
  String get accountSwitchToSignInSemantic => 'Entrar em uma conta existente';

  @override
  String get accountSwitchToCreate => 'Não tem conta? Crie uma';

  @override
  String get accountSwitchToCreateSemantic => 'Criar uma conta';

  @override
  String get accountForgotPassword => 'Esqueceu a senha?';

  @override
  String get accountForgotPasswordSemantic => 'Redefinir sua senha';

  @override
  String get accountNaming => 'Escolhendo seu nome…';

  @override
  String get accountSignedInLabel => 'Conectado';

  @override
  String accountPouringSince(String month, int year) {
    return 'JOGANDO DESDE $month DE $year';
  }

  @override
  String get accountPlayerCardTag => 'CARTÃO';

  @override
  String get accountStatSolved => 'FEITOS';

  @override
  String get accountStatStars => 'ESTRELAS';

  @override
  String get accountStatStreak => 'SEQUÊNCIA';

  @override
  String get accountStatRank => 'POSIÇÃO';

  @override
  String accountStarsValue(int stars) {
    return '$stars★';
  }

  @override
  String get accountSyncing => 'Sincronizando…';

  @override
  String get accountSyncingDetail => 'Salvando o progresso na sua conta';

  @override
  String get accountWaitingToSync => 'Aguardando sincronização';

  @override
  String get accountWaitingOffline => 'Salva quando você voltar a ficar online';

  @override
  String get accountWaitingPending => 'Seus últimos níveis são os próximos';

  @override
  String get accountSyncedDetail => 'Progresso salvo na sua conta';

  @override
  String get accountSynced => 'Sincronizado';

  @override
  String get accountSyncedJustNow => 'Sincronizado agora mesmo';

  @override
  String accountSyncedMinutesAgo(int minutes) {
    return 'Sincronizado há ${minutes}min';
  }

  @override
  String accountSyncedHoursAgo(int hours) {
    return 'Sincronizado há ${hours}h';
  }

  @override
  String accountSyncedDaysAgo(int days) {
    return 'Sincronizado há ${days}d';
  }

  @override
  String get accountCrestSignedIn => 'Sua conta';

  @override
  String get accountCrestGuest => 'Jogando como convidado';

  @override
  String get accountRenameRefused => 'Esse nome não foi aceito.';

  @override
  String get accountRenameOffline =>
      'Não foi possível conectar ao servidor. Tente de novo em instantes.';

  @override
  String get ranksTitle => 'Rankings';

  @override
  String get ranksTabToday => 'Hoje';

  @override
  String get ranksTabCampaign => 'Campanha';

  @override
  String get ranksLoading => 'Buscando o ranking…';

  @override
  String get ranksEmptyDailyTitle =>
      'Ninguém terminou o tabuleiro de hoje ainda';

  @override
  String get ranksEmptyDailyDetail => 'Seja o primeiro.';

  @override
  String get ranksEmptyCampaignTitle => 'Ainda não há jogadores no ranking';

  @override
  String get ranksEmptyCampaignDetail => 'Aqui quem decide são as estrelas.';

  @override
  String get ranksYourSpot => 'Sua posição';

  @override
  String ranksPlayerCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString jogadores neste ranking',
      one: '1 jogador neste ranking',
    );
    return '$_temp0';
  }

  @override
  String ranksMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogadas',
      one: '$count jogada',
    );
    return '$_temp0';
  }

  @override
  String ranksStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrelas',
      one: '$count estrela',
    );
    return '$_temp0';
  }

  @override
  String ranksLevels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count níveis',
      one: '$count nível',
    );
    return '$_temp0';
  }

  @override
  String ranksInTime(String time) {
    return 'em $time';
  }

  @override
  String get ranksOpenSpot => 'Vaga aberta';

  @override
  String ranksNameYou(String name) {
    return '$name (você)';
  }

  @override
  String ranksPlaceOpen(int place) {
    return '$placeº lugar, vago';
  }

  @override
  String ranksPlaceSemantic(int rank, String name, String score) {
    return '$rankº lugar, $name, $score';
  }

  @override
  String ranksScoreWithTieBreak(String score, String tieBreak) {
    return '$score, $tieBreak';
  }

  @override
  String get ranksOffTitle => 'Os rankings estão desativados nesta versão';

  @override
  String get ranksOffDetail => 'A campanha não é afetada.';

  @override
  String get ranksLoadFailed => 'Não foi possível carregar o ranking';

  @override
  String get ranksOffline =>
      'Parece que você está offline. Todos os níveis continuam jogáveis sem conexão.';

  @override
  String get ranksTimeout => 'O servidor demorou demais para responder.';

  @override
  String get ranksServerError =>
      'Algo deu errado do nosso lado. Seu progresso está seguro.';

  @override
  String get ranksHiddenTitle => 'Você está oculto';

  @override
  String get ranksHiddenDetail =>
      'Suas estrelas e sua sequência continuam contando, você só não aparece aqui. A opção fica nas Configurações.';

  @override
  String get statsTitle => 'Suas estatísticas';

  @override
  String get statsTabOverview => 'Resumo';

  @override
  String get statsTabLevels => 'Níveis';

  @override
  String get statsTabBadges => 'Medalhas';

  @override
  String get statsPaceOnPar => 'no par';

  @override
  String statsPaceUnder(int percent) {
    return '$percent% abaixo';
  }

  @override
  String statsPaceOver(int percent) {
    return '$percent% acima';
  }

  @override
  String get statsEmptyTitle => 'Nada para mostrar ainda';

  @override
  String get statsEmptyBody =>
      'Resolva um nível e isto aqui vai se encher: seus tempos em relação ao par, suas melhores soluções e os dias em que você jogou.';

  @override
  String get statsBackToLevels => 'Voltar aos níveis';

  @override
  String get statsLevelsSolved => 'níveis resolvidos';

  @override
  String get statsStars => 'estrelas';

  @override
  String get statsPoints => 'pontos';

  @override
  String get statsPlayed => 'jogados';

  @override
  String get statsNowOn => 'atual';

  @override
  String get statsBestSolveMoves => 'jogadas nas melhores soluções';

  @override
  String get statsAgainstClock => 'CONTRA O RELÓGIO';

  @override
  String get statsNoTimes =>
      'Nenhum tempo registrado ainda. Níveis concluídos antes de o relógio existir não têm tempo: jogue um de novo e ele começa a contar.';

  @override
  String get statsFastest => 'Mais rápido';

  @override
  String get statsLongest => 'Mais longo';

  @override
  String get statsAvgPace => 'Ritmo médio';

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
          '$count dos seus níveis resolvidos foram concluídos antes do relógio e não têm tempo registrado.',
      one:
          '$count dos seus níveis resolvidos foi concluído antes do relógio e não tem tempo registrado.',
    );
    return '$_temp0';
  }

  @override
  String statsUnderParSemantic(int under, int total) {
    return '$under de $total níveis cronometrados abaixo do par';
  }

  @override
  String get statsUnderParTag => 'ABAIXO';

  @override
  String get statsLast30Days => 'ÚLTIMOS 30 DIAS';

  @override
  String statsStreakChip(int count) {
    return 'sequência de $count dias';
  }

  @override
  String get statsNoStreak => 'sem sequência';

  @override
  String statsDaysPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias jogados',
      one: '$count dia jogado',
    );
    return '$_temp0';
  }

  @override
  String statsLevelsFinished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count níveis concluídos',
      one: '$count nível concluído',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'recorde: $count dias',
      one: 'recorde: $count dia',
    );
    return '$_temp0';
  }

  @override
  String get statsToday => 'Hoje';

  @override
  String statsMonthShort(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'jan': 'jan',
      'feb': 'fev',
      'mar': 'mar',
      'apr': 'abr',
      'may': 'mai',
      'jun': 'jun',
      'jul': 'jul',
      'aug': 'ago',
      'sep': 'set',
      'oct': 'out',
      'nov': 'nov',
      'dec': 'dez',
      'other': '$month',
    });
    return '$_temp0';
  }

  @override
  String statsMonthDay(String month, int day) {
    return '$day de $month';
  }

  @override
  String statsBarLevels(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$day · $count níveis',
      one: '$day · $count nível',
    );
    return '$_temp0';
  }

  @override
  String statsBarNoPlay(String day) {
    return '$day · sem jogo';
  }

  @override
  String get statsWorldAhead => 'a seguir';

  @override
  String get statsWorldNoTimes => 'sem tempos';

  @override
  String statsWorldPoints(int points) {
    final intl.NumberFormat pointsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String pointsString = pointsNumberFormat.format(points);

    return '$pointsString pts';
  }

  @override
  String statsWorldSolvedSemantic(String name, int cleared, int total) {
    return '$name: $cleared de $total resolvidos';
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

    return '$pointsString pontos';
  }

  @override
  String get statsColLevel => 'NÍV';

  @override
  String get statsColStars => 'ESTR.';

  @override
  String get statsColMoves => 'JOGADAS';

  @override
  String get statsColTime => 'TEMPO';

  @override
  String get statsColPoints => 'PTS';

  @override
  String statsMovesBestPossible(int moves, int best) {
    return '$moves jogadas, melhor possível $best';
  }

  @override
  String statsMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogadas',
      one: '$count jogada',
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
  String get badgeNotYet => 'Ainda não';

  @override
  String badgeProgress(int shown, int target) {
    return '$shown de $target';
  }

  @override
  String badgeSemantic(String title, String description, String status) {
    return '$title: $description $status';
  }

  @override
  String get badgeFirstPourTitle => 'Primeira jogada';

  @override
  String get badgeFirstPourDesc => 'Conclua seu primeiro nível.';

  @override
  String get badgePar10Title => 'No par';

  @override
  String get badgePar10Desc => 'Conclua 10 níveis exatamente no par.';

  @override
  String get badgePar50Title => 'Mestre do par';

  @override
  String get badgePar50Desc => 'Conclua 50 níveis exatamente no par.';

  @override
  String get badgeCleanClearTitle => 'Sem voltar atrás';

  @override
  String get badgeCleanClearDesc => 'Conclua um nível sem usar o desfazer.';

  @override
  String get badgeSpeedyTitle => 'Mão rápida';

  @override
  String get badgeSpeedyDesc => 'Conclua um nível em menos de 30 segundos.';

  @override
  String get badgeLevels100Title => 'Centurião';

  @override
  String get badgeLevels100Desc => 'Conclua 100 níveis.';

  @override
  String get badgeStars300Title => 'Caça-estrelas';

  @override
  String get badgeStars300Desc => 'Junte 300 estrelas.';

  @override
  String get badgeWorldPerfectTitle => 'Mundo impecável';

  @override
  String get badgeWorldPerfectDesc =>
      'Ganhe três estrelas em todos os níveis de um mundo.';

  @override
  String get badgeStreak7Title => 'Semana completa';

  @override
  String get badgeStreak7Desc =>
      'Chegue a uma sequência de 7 dias no Desafio Diário.';

  @override
  String get badgeStreak30Title => 'Mês completo';

  @override
  String get badgeStreak30Desc =>
      'Chegue a uma sequência de 30 dias no Desafio Diário.';

  @override
  String get badgeChests5Title => 'Caçador de tesouros';

  @override
  String get badgeChests5Desc => 'Abra 5 baús de estrelas.';

  @override
  String get badgeHard5Title => 'Osso duro';

  @override
  String get badgeHard5Desc => 'Conclua 5 níveis com o selo DIFÍCIL.';

  @override
  String get badgeEventFullTitle => 'Semana cheia';

  @override
  String get badgeEventFullDesc =>
      'Conclua os sete tabuleiros de um evento semanal.';

  @override
  String get badgeZen25Title => 'Jardim zen';

  @override
  String get badgeZen25Desc => 'Conclua 25 tabuleiros no modo Zen.';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonRetry => 'Tentar de novo';

  @override
  String get commonNotNow => 'Agora não';

  @override
  String commonLevelN(int level) {
    return 'Nível $level';
  }

  @override
  String get hubAccountYours => 'Sua conta';

  @override
  String get hubAccountSave => 'Salve seu progresso';

  @override
  String get hubPlayerFallback => 'Jogador';

  @override
  String get hubSettings => 'Configurações';

  @override
  String get hubTagline => 'DESPEJE · SEPARE · RELAXE';

  @override
  String hubStatChipSemantic(String value, String label) {
    return '$value $label. Estatísticas';
  }

  @override
  String get hubStatSolved => 'resolvidos';

  @override
  String get hubStatStars => 'estrelas';

  @override
  String get hubStatStreak => 'sequência';

  @override
  String hubStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String hubRankNumber(int rank) {
    return '#$rank';
  }

  @override
  String hubEventSemantic(int cleared, int total) {
    return 'Evento semanal, $cleared de $total tabuleiros';
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
    return 'O modo Zen é desbloqueado no nível $level';
  }

  @override
  String get hubZenOpen => 'Sem fim, sem relógio';

  @override
  String hubZenLocked(int level, int remaining) {
    return 'Nível $level · faltam $remaining';
  }

  @override
  String get hubDockJourney => 'Jornada';

  @override
  String get hubDockRankings => 'Rankings';

  @override
  String get hubDockStats => 'Estatísticas';

  @override
  String get hubTip =>
      'Boa! A Jornada mostra todos os níveis, e todo dia tem um novo Desafio Diário para jogar.';

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
  String get hubPlay => 'JOGAR';

  @override
  String hubPlaySemantic(int level) {
    return 'Jogar o nível $level';
  }

  @override
  String get hubMoreUpdateTitle => 'Atualize para mais níveis';

  @override
  String get hubMoreUpdateBody =>
      'Um novo mundo chegou e precisa da versão mais recente do Pourfect. Atualize o jogo para continuar despejando.';

  @override
  String get hubMoreDownloadingTitle => 'Novos níveis a caminho';

  @override
  String get hubMoreDownloadingBody =>
      'O próximo mundo está sendo baixado. Só leva um instante.';

  @override
  String get hubMoreAllDoneTitle => 'Você despejou tudo!';

  @override
  String get hubMoreOfflineBody =>
      'Conecte-se à internet e mais níveis serão baixados em segundo plano. Enquanto isso, o Desafio Diário de hoje está esperando por você.';

  @override
  String get hubMoreOnlineBody =>
      'Mais níveis são baixados em segundo plano sempre que você estiver online. Enquanto isso, o Desafio Diário de hoje está esperando por você.';

  @override
  String get hubMoreCheckAgain => 'Verificar de novo';

  @override
  String hubAchievementOne(String title) {
    return 'Conquista desbloqueada: $title';
  }

  @override
  String hubAchievementMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conquistas desbloqueadas!',
    );
    return '$_temp0';
  }

  @override
  String get hubUpdateReady => 'Uma atualização está pronta para instalar.';

  @override
  String get hubUpdateRestart => 'Reiniciar';

  @override
  String hubSpanSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String hubSpanMinutes(int minutes) {
    return '${minutes}min';
  }

  @override
  String hubSpanMinutesSeconds(int minutes, int seconds) {
    return '${minutes}min ${seconds}s';
  }

  @override
  String hubSpanHours(int hours) {
    return '${hours}h';
  }

  @override
  String hubSpanHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}min';
  }

  @override
  String get hubParOn => 'no par';

  @override
  String hubParUnder(int percent) {
    return '$percent% abaixo do par';
  }

  @override
  String hubParOver(int percent) {
    return '$percent% acima do par';
  }

  @override
  String get dailyTitle => 'Desafio Diário';

  @override
  String get dailyCardSemantic => 'Desafio de hoje';

  @override
  String get dailyCardUnavailable => 'tabuleiro de hoje indisponível';

  @override
  String get dailyCardSolved => 'resolvido';

  @override
  String dailyCardNextIn(String time) {
    return 'próximo em $time';
  }

  @override
  String dailyCardEndsIn(String time) {
    return 'termina em $time';
  }

  @override
  String dailyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sequência de $count dias',
      one: 'sequência de 1 dia',
    );
    return '$_temp0';
  }

  @override
  String dailyStreakMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sequência de $count dias!',
      one: 'Sequência de 1 dia!',
    );
    return '$_temp0';
  }

  @override
  String get dailyRankSemantic => 'Ranking';

  @override
  String dailyRankSemanticRanked(int rank) {
    return 'Ranking, posição $rank';
  }

  @override
  String get dailyRankSticker => 'RANK';

  @override
  String get dailyLeaveLost =>
      'Suas jogadas no Desafio Diário de hoje não serão salvas. Você pode recomeçar quando quiser hoje.';

  @override
  String get dailySubmitRefused => 'O servidor não aceitou esse resultado.';

  @override
  String get dailySubmitFailed =>
      'Resolvido, mas não foi possível enviar o resultado. Tente de novo mais tarde.';

  @override
  String get dailyHudLabel => 'Desafio';

  @override
  String get dailyHudValue => 'Diário';

  @override
  String get dailyDeadEndRestart =>
      'Não dá para terminar a partir daqui. Reinicie para tentar outro caminho.';

  @override
  String dailyDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Não dá para terminar a partir daqui. Desfaça $count jogadas para voltar ao caminho certo.',
      one: 'Não dá para terminar a partir daqui. Desfaça 1 jogada para voltar ao caminho certo.',
    );
    return '$_temp0';
  }

  @override
  String get dailyActionRestart => 'Reiniciar';

  @override
  String dailyActionUndo(int count) {
    return 'Desfazer $count';
  }

  @override
  String get dailyNoHint => 'Nenhuma dica para esta posição.';

  @override
  String get dailyLoadingTitle => 'Carregando o tabuleiro de hoje';

  @override
  String get dailyOffTitle =>
      'Os desafios diários estão desativados nesta versão';

  @override
  String get dailyOffDetail =>
      'A campanha não é afetada: todos os níveis estão neste dispositivo.';

  @override
  String get dailyNoBoardTitle => 'Sem tabuleiro hoje';

  @override
  String get dailyNoBoardDetail =>
      'O desafio de hoje vem do servidor, e não foi possível conectar a ele. A campanha não depende disso.';

  @override
  String get dailyLoaderCaption => 'Preparando o tabuleiro de hoje…';

  @override
  String get dailyBackToLevels => 'Voltar aos níveis';

  @override
  String dailyWeekSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return 'Sua sequência: $_temp0. Abrir';
  }

  @override
  String dailyDaySemantic(String weekday, String state) {
    return '$weekday, $state';
  }

  @override
  String get dailyDayFrozen => 'perdido, coberto por um congelamento';

  @override
  String get dailyDayPlayedToday => 'jogado hoje';

  @override
  String get dailyDayPlayed => 'jogado';

  @override
  String get dailyDayToday => 'hoje, ainda não jogado';

  @override
  String get dailyDayMissed => 'não jogado';

  @override
  String get dailyDayFuture => 'ainda por vir';

  @override
  String get dailyOutcomeBest => 'Novo recorde';

  @override
  String get dailyOutcomeSolved => 'Resolvido';

  @override
  String get dailyFigureMoves => 'jogadas';

  @override
  String get dailyFigureStreak => 'sequência';

  @override
  String get dailyUnranked => 'sem posição';

  @override
  String dailyOfPlayers(int count) {
    return 'de $count';
  }

  @override
  String get dailyReminderOn => 'Você vai receber um lembrete amanhã à noite.';

  @override
  String get dailyRemindMe => 'Lembrar amanhã';

  @override
  String get dailyDone => 'PRONTO';

  @override
  String get dailyFreezeVideoUnfinished =>
      'Sem congelamento: o vídeo não foi até o fim.';

  @override
  String get dailyFreezeNoVideo => 'Nenhum vídeo disponível no momento.';

  @override
  String get dailyFreezeError => 'Algo deu errado. Tente de novo mais tarde.';

  @override
  String get dailyFreezeAdded =>
      'Congelamento adicionado. Um dia perdido fica coberto.';

  @override
  String get dailyFreezeNoRoom => 'Não cabe mais nenhum congelamento hoje.';

  @override
  String get dailyFreezeLoadingVideo => 'Carregando vídeo…';

  @override
  String get dailyFreezeWatch => 'Assista a um vídeo e ganhe um congelamento';

  @override
  String get dailyFreezesFull =>
      'Congelamentos no máximo. Cada um cobre um dia perdido.';

  @override
  String get dailyFreezeTomorrow =>
      'Um congelamento por vídeo ao dia. Volte amanhã.';

  @override
  String get dailyStreakTitle => 'Sua sequência';

  @override
  String get dailyStreakNone => 'Nenhuma sequência ainda';

  @override
  String get dailyStreakStart =>
      'Jogue o Desafio Diário de hoje para começar uma.';

  @override
  String dailyStreakBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recorde: $count dias',
      one: 'Recorde: 1 dia',
    );
    return '$_temp0';
  }

  @override
  String dailyFreezesSemantic(int count, int max) {
    return '$count de $max congelamentos de sequência';
  }

  @override
  String get dailyFreezesTitle => 'Congelamentos';

  @override
  String get dailyFreezesEach => 'Cada um cobre um dia perdido.';

  @override
  String dailyFreezeWeekly(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Um grátis toda segunda-feira: em $days dias.',
      one: 'Um grátis toda segunda-feira: amanhã.',
    );
    return '$_temp0';
  }

  @override
  String get dailyCalendarPrevious => 'Mês anterior';

  @override
  String get dailyCalendarNext => 'Próximo mês';

  @override
  String dailyCalendarCellSemantic(String date, String state) {
    return '$date, $state';
  }

  @override
  String get dailyCalendarPlayed => 'jogado';

  @override
  String get dailyCalendarFrozen => 'congelado';

  @override
  String get dailyCalendarFuture => 'por vir';

  @override
  String get dailyLegendPlayed => 'Jogado';

  @override
  String get dailyLegendFrozen => 'Congelado';

  @override
  String get dailyLegendToday => 'Hoje';

  @override
  String get eventTitle => 'Evento semanal';

  @override
  String get eventUnreachable =>
      'Não foi possível carregar o evento desta semana agora.';

  @override
  String get eventEnded => 'encerrado';

  @override
  String eventEndsIn(String timeLeft) {
    return 'termina em $timeLeft';
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
    return '${minutes}min';
  }

  @override
  String eventSummary(int cleared, int total, String endsIn) {
    return '$cleared de $total tabuleiros · $endsIn';
  }

  @override
  String get eventFigurePoints => 'pontos';

  @override
  String eventRankOf(int count) {
    return 'de $count';
  }

  @override
  String get eventRankPlay => 'jogue um tabuleiro para entrar';

  @override
  String get eventRankSetName => 'escolha um nome para entrar';

  @override
  String eventTileSemanticDone(int slot, int stars, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars estrelas',
      one: '1 estrela',
    );
    return 'Tabuleiro $slot, $_temp0, $points pontos';
  }

  @override
  String eventTileSemanticNew(int slot) {
    return 'Tabuleiro $slot, não jogado';
  }

  @override
  String eventTilePoints(int points) {
    return '$points pts';
  }

  @override
  String get eventStandingsTitle => 'Ranking da semana';

  @override
  String get eventStandingsEmpty =>
      'Ninguém no ranking ainda. Seja o primeiro.';

  @override
  String eventStandingsCleared(int cleared) {
    return ' · $cleared/7';
  }

  @override
  String get eventSubmitRefused =>
      'O servidor não aceitou esse resultado. O evento pode ter terminado.';

  @override
  String get eventSubmitFailed =>
      'Resolvido, mas não foi possível enviar o resultado. Tente de novo.';

  @override
  String eventDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Não dá para terminar a partir daqui. Desfaça $count jogadas.',
      one: 'Não dá para terminar a partir daqui. Desfaça 1 jogada.',
    );
    return '$_temp0';
  }

  @override
  String get eventNoHint => 'Nenhuma dica para esta posição no momento.';

  @override
  String get eventHudLabel => 'Tabuleiro';

  @override
  String eventHudBand(String event, String endsIn) {
    return '$event · $endsIn';
  }

  @override
  String get eventSending => 'Enviando…';

  @override
  String eventResult(int points, int total) {
    return '$points pontos · $total nesta semana';
  }

  @override
  String eventResultRanked(int points, int total, int rank) {
    return '$points pontos · $total nesta semana · #$rank';
  }

  @override
  String get journeyTitle => 'Jornada';

  @override
  String journeyStarsSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estrelas',
      one: '1 estrela',
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
    return 'Mundo $world de $worlds, $name, $solved de $total resolvidos';
  }

  @override
  String journeyWorldOf(int world, int worlds) {
    return 'MUNDO $world DE $worlds';
  }

  @override
  String journeyRibbonSemantic(int world, String name, int solved, int total) {
    return 'Mundo $world, $name, $solved de $total resolvidos. Rolar até ele';
  }

  @override
  String journeyRibbonLabel(int world, String name) {
    return 'MUNDO $world · $name';
  }

  @override
  String get journeyYouPin => 'VOCÊ';

  @override
  String journeyBandCaps(int world, int count) {
    return 'MUNDO $world · $count';
  }

  @override
  String get journeyBandFirstPours => 'Primeiros Passos';

  @override
  String get journeyBandFindingRhythm => 'Pegando o Ritmo';

  @override
  String get journeyBandDeepWater => 'Águas Profundas';

  @override
  String get journeyBandMastery => 'Maestria';

  @override
  String get notifSoftAskTitle => 'Quer um lembrete?';

  @override
  String get notifSoftAskBody =>
      'Um aviso quando o Desafio Diário de hoje sair ou quando seu próximo nível estiver esperando. Nunca mais de dois por dia, e você pode desativar quando quiser nas Configurações.';

  @override
  String get notifSoftAskBodyDenied =>
      'As notificações do Pourfect estão desativadas. Ative nas configurações do celular para receber um aviso quando o Desafio Diário sair ou um novo mundo chegar. Nunca mais de dois por dia.';

  @override
  String get notifSoftAskOpenSettings => 'Abrir configurações';

  @override
  String get notifSoftAskYes => 'Quero sim';

  @override
  String get notifChannelName => 'Lembretes';

  @override
  String get notifChannelDescription =>
      'O Desafio Diário, seu próximo nível e novos mundos. Nunca mais de dois por dia.';

  @override
  String get playHudLevel => 'Nível';

  @override
  String playHudTitle(String label, String value) {
    return '$label $value';
  }

  @override
  String get playHudHard => 'DIFÍCIL ×1,5';

  @override
  String get playHudHardLabel => 'Nível difícil, uma vez e meia os pontos';

  @override
  String get playHudMoves => 'JOGADAS';

  @override
  String playHudMovesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogadas',
      one: '1 jogada',
    );
    return '$_temp0';
  }

  @override
  String playParLeftFor3Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltam $count jogadas para 3 estrelas',
      one: 'Falta 1 jogada para 3 estrelas',
    );
    return '$_temp0';
  }

  @override
  String get playParSpent => 'Par atingido · 2 estrelas daqui em diante';

  @override
  String playParLeftFor2Stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltam $count jogadas para 2 estrelas',
      one: 'Falta 1 jogada para 2 estrelas',
    );
    return '$_temp0';
  }

  @override
  String get playParOneStarFromHere =>
      '1 estrela daqui em diante · basta terminar';

  @override
  String get playParAnyFinish => 'Terminar já vale 1 estrela';

  @override
  String playParMeterLabel(int stars, int used, int par, String words) {
    return 'Ritmo de $stars estrelas, $used de $par jogadas do par. $words';
  }

  @override
  String playHudBusyLabel(String label) {
    return '$label, processando. Toque para cancelar';
  }

  @override
  String get playHudUndo => 'Desfazer';

  @override
  String get playHudHint => 'Dica';

  @override
  String get playHudRestart => 'Reiniciar';

  @override
  String get playExtraTubeLabel =>
      'Assista a um vídeo para ganhar um tubo extra';

  @override
  String get playExtraTubeChip => '+ Tubo';

  @override
  String playStarsOfTotal(int earned, int total) {
    return '$earned de $total estrelas';
  }

  @override
  String get playDismiss => 'Fechar';

  @override
  String get playLeaveTitleSoSoon => 'Já vai embora?';

  @override
  String get playLeaveTitleMissYou => 'As bolinhas vão sentir sua falta';

  @override
  String get playLeaveTitleAbandon => 'Desistir da jogada?';

  @override
  String get playLeaveTitleMidPour => 'Vai sair no meio da jogada?';

  @override
  String get playLeaveBody =>
      'Suas jogadas e seu tempo neste tabuleiro não serão salvos.';

  @override
  String get playLeaveKeepPouring => 'Continuar';

  @override
  String get playLeaveConfirm => 'Sair';

  @override
  String get playTutorialSkipLabel => 'Pular o tutorial';

  @override
  String get playTutorialSkip => 'Pular';

  @override
  String playTipBubbleLabel(String text) {
    return '$text. Fechar';
  }

  @override
  String get playTipPar =>
      'Termine dentro do par para ganhar três estrelas. A barra mostra quanto você já usou.';

  @override
  String get playTipTallTubes =>
      'Tubos mais altos! Agora cada um comporta cinco bolinhas.';

  @override
  String get playTipHint => 'Travou? A Dica mostra uma boa próxima jogada.';

  @override
  String get playTipUndo =>
      'Passou do par? Desfazer é grátis: volte quanto quiser.';

  @override
  String get playGuideSorted =>
      'Organizado! Agora deixe cada tubo de uma cor só.';

  @override
  String get playGuideDrop =>
      'Agora toque no destino: sobre a mesma cor ou num tubo vazio.';

  @override
  String get playGuideWrongTube =>
      'Toque no tubo que a mão indica para pegar essas bolinhas.';

  @override
  String get playGuideFirstTap =>
      'Toque num tubo para pegar as bolinhas de cima.';

  @override
  String get playGuideFirstPour => 'Isso aí, primeira jogada! Continue.';

  @override
  String get playGuideKeepGoing => 'Continue: uma cor por tubo.';

  @override
  String playCoachHolding(int count) {
    return 'Segurando $count · solte num tubo que pula';
  }

  @override
  String get playExtraTubeAdTitle =>
      'Assistir a um vídeo para ganhar um tubo extra?';

  @override
  String get playExtraTubeAdBody =>
      'Mais um tubo vazio para este nível. Um nível concluído com tubo extra vale no máximo duas estrelas.';

  @override
  String get playExtraTubeNotFinished => 'Sem tubo: o vídeo não foi até o fim.';

  @override
  String get playExtraTubeSaved => 'Guardado: seu próximo tubo é grátis.';

  @override
  String get playNoVideo => 'Nenhum vídeo disponível no momento.';

  @override
  String get playRewardFailed => 'Algo deu errado. Nada foi gasto.';

  @override
  String get playHintShowing =>
      'Sua dica já está na tela: despeje no tubo brilhante.';

  @override
  String get playHintNoneNothingUsed =>
      'Nenhuma dica para esta posição. Nada foi gasto.';

  @override
  String get playHintNotFinished => 'Sem dica: o vídeo não foi até o fim.';

  @override
  String get playHintVideoSaved =>
      'Seu vídeo ficou guardado para a próxima dica.';

  @override
  String get playHintNoneVideoSaved =>
      'Nenhuma dica para esta posição: seu vídeo fica guardado para a próxima.';

  @override
  String get playHintNone => 'Nenhuma dica disponível para esta posição.';

  @override
  String get playHintHere => 'Aqui está sua dica: despeje no tubo brilhante.';

  @override
  String get playDeadEndRestart =>
      'Não dá para terminar a partir daqui. Reinicie para tentar outro caminho.';

  @override
  String get playDeadEndRestartTube =>
      'Não dá para terminar a partir daqui. Reinicie para tentar outro caminho. Ou toque em + Tubo para ganhar um tubo extra.';

  @override
  String playDeadEndUndo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Não dá para terminar a partir daqui. Desfaça $count jogadas para voltar ao caminho certo.',
      one: 'Não dá para terminar a partir daqui. Desfaça 1 jogada para voltar ao caminho certo.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoTube(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Não dá para terminar a partir daqui. Desfaça $count jogadas para voltar ao caminho certo. Ou toque em + Tubo para ganhar um tubo extra.',
      one: 'Não dá para terminar a partir daqui. Desfaça 1 jogada para voltar ao caminho certo. Ou toque em + Tubo para ganhar um tubo extra.',
    );
    return '$_temp0';
  }

  @override
  String playDeadEndUndoAction(int count) {
    return 'Desfazer $count';
  }

  @override
  String get playHintAdTitle => 'Assistir a um vídeo para ganhar uma dica?';

  @override
  String playHintAdFreeLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Você ainda tem $count dicas grátis.',
      one: 'Você ainda tem 1 dica grátis.',
    );
    return '$_temp0';
  }

  @override
  String get playHintAdNoneLeft =>
      'Suas dicas grátis acabaram. Um vídeo curto rende mais uma.';

  @override
  String get playWatch => 'Assistir';

  @override
  String get playLoadFailed => 'Não foi possível carregar os níveis';

  @override
  String get playTubeSorted => 'PRONTO!';

  @override
  String get playWinTitlePerfect => 'Jogada\nPerfeita!';

  @override
  String get playWinTitleNice => 'Mandou\nBem!';

  @override
  String get playWinTitlePoured => 'Feito!';

  @override
  String get playWinLastPour => 'Última jogada…';

  @override
  String playWinMovesPar(int count, int par) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count JOGADAS · PAR $par',
      one: '1 JOGADA · PAR $par',
    );
    return '$_temp0';
  }

  @override
  String playWinLevelBand(int level, String band) {
    return 'Nível $level · $band';
  }

  @override
  String get playWinNewBest => 'RECORDE!';

  @override
  String playWinMovesChip(int par) {
    return 'jogadas · par $par';
  }

  @override
  String get playWinUntimed => 'sem tempo';

  @override
  String get playWinFastest => 'seu mais rápido!';

  @override
  String get playWinTime => 'tempo';

  @override
  String get playWinUnderPar => 'ABAIXO DO PAR!';

  @override
  String get playWinPoints => 'pontos';

  @override
  String playWinWorldBand(int world, String band) {
    return 'MUNDO $world · $band';
  }

  @override
  String get playWinTryAssisted =>
      'Para três estrelas, termine sem o tubo extra.';

  @override
  String playWinTryShort(int par, int took, int short) {
    String _temp0 = intl.Intl.pluralLogic(
      short,
      locale: localeName,
      other: 'Par $par, você fez $took. A $short jogadas das 3★.',
      one: 'Par $par, você fez $took. A uma jogada das 3★.',
    );
    return '$_temp0';
  }

  @override
  String playWinTryInReach(int par) {
    return 'Par $par. As três estrelas estão ao seu alcance.';
  }

  @override
  String get playWinTryButton => 'TENTAR 3★';

  @override
  String get playWinTryButtonLabel =>
      'Jogar este nível de novo para ganhar três estrelas';

  @override
  String get playWinReplayLabel => 'Jogar este nível de novo';

  @override
  String get playWinHomeLabel => 'Voltar à tela inicial';

  @override
  String get playWinNextLevel => 'PRÓXIMO NÍVEL';

  @override
  String get playWinBackToLevels => 'VOLTAR AOS NÍVEIS';

  @override
  String playChestNextAtLabel(int stars) {
    return 'Próximo baú de estrelas com $stars estrelas';
  }

  @override
  String get playChestOpenLabel => 'Abrir baú de estrelas';

  @override
  String get playChestReady => 'Um baú de estrelas está pronto!';

  @override
  String playChestNextAt(int stars) {
    return 'Próximo baú com $stars ★';
  }

  @override
  String get playChestOpen => 'ABRIR';

  @override
  String get playChestDoubleFailed => 'Não deu para dobrar desta vez.';

  @override
  String get playChestDoubleNotFinished =>
      'Não dobrou: o vídeo não foi até o fim.';

  @override
  String get playChestOpening => 'Abrindo…';

  @override
  String playChestTitle(int index) {
    return 'Baú de estrelas $index';
  }

  @override
  String get playChestNotYetTitle => 'Quase lá';

  @override
  String get playChestAlreadyOpenTitle => 'Já foi aberto';

  @override
  String get playChestFailedTitle => 'Não deu para abrir';

  @override
  String get playChestNotYetNote =>
      'Suas estrelas mais recentes ainda estão a caminho do servidor. Tente de novo em instantes.';

  @override
  String get playChestAlreadyOpenNote =>
      'Este baú foi aberto em outro dispositivo.';

  @override
  String get playChestFailedNote => 'Verifique sua conexão e tente de novo.';

  @override
  String playChestRewardCount(int count) {
    return '+$count';
  }

  @override
  String playChestHintsCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dicas',
      one: 'dica',
    );
    return '$_temp0';
  }

  @override
  String playChestTubesCaption(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tubos extras',
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
    return 'Visual de bolinha $skin';
  }

  @override
  String playChestTubeThemeName(String theme) {
    return 'Tubos $theme';
  }

  @override
  String get playChestNewLook => 'um visual novo';

  @override
  String get playChestSavedNote =>
      'Guardados para quando precisar. A Dica e o + Tubo usam estes primeiro.';

  @override
  String get playChestLoadingVideo => 'Carregando vídeo…';

  @override
  String get playChestDouble => 'Dobre com um vídeo';

  @override
  String get playChestCollect => 'Pegar';

  @override
  String playClockLabel(String time) {
    return 'Tempo $time';
  }

  @override
  String playClockDetailLabel(
    String time,
    String par,
    String sign,
    int percent,
  ) {
    String _temp0 = intl.Intl.selectLogic(sign, {
      'plus': 'mais',
      'other': 'menos',
    });
    return 'Tempo $time de um par de $par, $_temp0 $percent pontos percentuais';
  }

  @override
  String playClockBonusChip(String sign, int percent) {
    return '$sign$percent% pts';
  }

  @override
  String get playLoading => 'Carregando';

  @override
  String get playWorking => 'Processando';

  @override
  String get playZenTitle => 'Zen';

  @override
  String get playZenIntro =>
      'Tabuleiros sem fim. Sem relógio, sem estrelas, sem ranking: é só despejar.';

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
      other: '$count cores',
      one: '1 cor',
    );
    return '$_temp0';
  }

  @override
  String playZenPaceLabel(String pace, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$pace, $count cores',
      one: '$pace, 1 cor',
    );
    return '$_temp0';
  }

  @override
  String playZenBandPoured(String pace, int count) {
    return '$pace · $count concluídos';
  }

  @override
  String playZenPoured(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Feito! $count até agora.',
      one: 'Feito!',
    );
    return '$_temp0';
  }

  @override
  String get playZenNext => 'PRÓXIMO';

  @override
  String get playZenLeaveBody =>
      'As jogadas deste tabuleiro não serão salvas. Sua contagem de concluídos continua.';

  @override
  String get playZenDeadEnd =>
      'Não dá para terminar a partir daqui. Desfaça ou reinicie.';

  @override
  String get playZenNoHint => 'Nenhuma dica para esta posição no momento.';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsSectionFeel => 'Sensação';

  @override
  String get settingsSectionVisibility => 'Visibilidade';

  @override
  String get settingsSectionLeaderboard => 'Ranking';

  @override
  String get settingsSectionNotifications => 'Notificações';

  @override
  String get settingsSectionSupport => 'Suporte';

  @override
  String get settingsSectionAccount => 'Conta e sobre';

  @override
  String get settingsSectionDanger => 'Zona de perigo';

  @override
  String get settingsSoundTitle => 'Efeitos sonoros';

  @override
  String get settingsSoundDetail => 'Jogadas, botões e recompensas';

  @override
  String get settingsSoundVolume => 'Volume dos efeitos';

  @override
  String get settingsMusicTitle => 'Música';

  @override
  String get settingsMusicDetail => 'Nunca toca por cima da sua música';

  @override
  String get settingsMusicVolume => 'Volume da música';

  @override
  String get settingsHapticsTitle => 'Vibração';

  @override
  String get settingsHapticsDetail => 'Um toque a cada bolinha que cai';

  @override
  String get settingsSmoothMotionTitle => 'Movimento suave';

  @override
  String get settingsSmoothMotionAuto => 'Auto';

  @override
  String get settingsSmoothMotion60 => '60 Hz';

  @override
  String get settingsSmoothMotionMax => 'Máx.';

  @override
  String get settingsMotionUnknown =>
      'No Auto, usa a taxa mais alta da tela se o celular acompanhar';

  @override
  String settingsMotionFixed(String max) {
    return 'Esta tela só funciona a $max Hz';
  }

  @override
  String settingsMotionBatterySaver(String current) {
    return 'A Economia de bateria está mantendo em $current Hz';
  }

  @override
  String settingsMotionAutoStuttered(String current, String max) {
    return 'Rodando a $current Hz · este celular travou a $max Hz';
  }

  @override
  String settingsMotionAuto(String current) {
    return 'Rodando a $current Hz · cai para 60 Hz se travar';
  }

  @override
  String settingsMotionPinnedByPhone(String current) {
    return 'A configuração de tela do seu celular mantém em $current Hz';
  }

  @override
  String settingsMotionStandard(String current, String max) {
    return 'Rodando a $current Hz · esta tela chega a $max Hz';
  }

  @override
  String settingsMotionMax(String current) {
    return 'Rodando a $current Hz, o máximo desta tela';
  }

  @override
  String get settingsBoldSymbolsTitle => 'Símbolos em negrito';

  @override
  String get settingsBoldSymbolsDetail => 'Formas mais fortes para daltonismo';

  @override
  String get settingsRenameTitle => 'Mudar seu nome';

  @override
  String get settingsRenameDetail => 'Como você aparece nos rankings';

  @override
  String get settingsShowOnBoardsTitle => 'Mostrar meu nome nos rankings';

  @override
  String get settingsShowOnBoardsDetail =>
      'Desligado, oculta seu nome e sua posição. As estrelas continuam contando.';

  @override
  String get settingsHowToPlayTitle => 'Como jogar';

  @override
  String get settingsHowToPlayDetail => 'Jogue de novo o primeiro nível guiado';

  @override
  String get settingsQuestionsTitle => 'Perguntas';

  @override
  String get settingsQuestionsDetail => 'Estrelas, dicas, o relógio e mais';

  @override
  String get settingsRateTitle => 'Avaliar o Pourfect';

  @override
  String get settingsRateDetail => 'Conte aos outros jogadores o que você acha';

  @override
  String get settingsCollectionTitle => 'Coleção';

  @override
  String get settingsCollectionDetail => 'Visuais de bolinhas e temas de tubos';

  @override
  String get settingsRestoreTitle => 'Restaurar compras';

  @override
  String get settingsRestoreDetail => 'Remover anúncios ou o Pacote de visuais';

  @override
  String get settingsRestoreDone => 'Compras restauradas, se havia alguma.';

  @override
  String get settingsRemoveAdsTitle => 'Remover anúncios';

  @override
  String get settingsRemoveAdsDetail =>
      'Sem anúncios entre os níveis. Os vídeos de dica continuam.';

  @override
  String get settingsAdsRemoved => 'Anúncios removidos. Obrigado!';

  @override
  String get settingsPurchaseThanks =>
      'Obrigado! Os anúncios entre os níveis foram desativados.';

  @override
  String get settingsPurchaseAlreadyOwned =>
      'Já comprado: os anúncios estão desativados.';

  @override
  String get settingsPurchasePending =>
      'Pagamento pendente. Os anúncios serão desativados assim que ele for aprovado.';

  @override
  String get settingsStoreUnavailable =>
      'A loja não está disponível neste dispositivo no momento.';

  @override
  String get settingsPurchaseFailed =>
      'A compra não foi concluída. Você não foi cobrado.';

  @override
  String get settingsStoreOpenFailed => 'Não foi possível abrir a loja.';

  @override
  String get settingsBrowserOpenFailed => 'Não foi possível abrir o navegador.';

  @override
  String get settingsSignedIn => 'Conectado';

  @override
  String get settingsSignedInDetail => 'Seu progresso vai com você';

  @override
  String get settingsSaveProgressTitle => 'Salve seu progresso';

  @override
  String get settingsSaveProgressDetail =>
      'Mantenha suas estrelas se trocar de celular';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidade';

  @override
  String get settingsTermsAndLicenses => 'Termos e licenças';

  @override
  String get settingsTermsOfUse => 'Termos de uso';

  @override
  String get settingsRefundPolicy => 'Política de reembolso';

  @override
  String get settingsOpenSourceLicenses => 'Licenças de código aberto';

  @override
  String get settingsAdPrivacyTitle => 'Privacidade de anúncios';

  @override
  String get settingsAdPrivacyDetail =>
      'Mude o que você autorizou para anúncios';

  @override
  String get settingsResetRowTitle => 'Redefinir progresso';

  @override
  String get settingsResetRowDetail =>
      'Apague todas as estrelas e recomece do nível 1';

  @override
  String get settingsResetTitle => 'Redefinir progresso?';

  @override
  String get settingsResetNothing => 'Ainda não há nada para redefinir.';

  @override
  String settingsResetBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Isso apaga todas as estrelas e melhores marcas de $count níveis resolvidos e bloqueia de novo tudo depois do nível 1. Não dá para desfazer.',
      one: 'Isso apaga todas as estrelas e melhores marcas de 1 nível resolvido e bloqueia de novo tudo depois do nível 1. Não dá para desfazer.',
    );
    return '$_temp0';
  }

  @override
  String get settingsKeepIt => 'Manter';

  @override
  String get settingsResetConfirm => 'Apagar tudo';

  @override
  String get settingsResetDone => 'Progresso redefinido.';

  @override
  String get settingsSignOutTitle => 'Sair?';

  @override
  String get settingsSignOutBody =>
      'Seu progresso fica neste celular. Você pode entrar de novo quando quiser para continuar em outro lugar.';

  @override
  String get settingsSignOutStay => 'Continuar conectado';

  @override
  String get settingsSignOutConfirm => 'Sair';

  @override
  String get settingsServerUnreachable =>
      'Não foi possível conectar ao servidor, então nada mudou.';

  @override
  String get settingsDeleteRowTitle => 'Excluir conta';

  @override
  String get settingsDeleteRowDetail => 'Remova sua conta e tudo que está nela';

  @override
  String get settingsDeleteTitle => 'Excluir sua conta?';

  @override
  String get settingsDeleteBody =>
      'Isso remove sua conta, suas estrelas, sua sequência e sua entrada no ranking, neste celular e no nosso servidor. Não dá para desfazer.\n\nRemover anúncios não é afetado: a compra pertence à conta da loja em que você comprou e é restaurada se você voltar a jogar.';

  @override
  String get settingsDeleteConfirm => 'Excluir tudo';

  @override
  String get settingsDeleteServerRefused =>
      'Não foi possível conectar ao servidor. Nada foi excluído: tente de novo quando estiver online.';

  @override
  String get settingsDeleteNotAuthenticated =>
      'Não foi possível confirmar que é você. Entre de novo e depois exclua sua conta. Nada foi excluído ainda.';

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
          'Pourfect $version · feito com $count tabuleiros com solução comprovada',
      one: 'Pourfect $version · feito com 1 tabuleiro com solução comprovada',
    );
    return '$_temp0';
  }

  @override
  String get settingsNamingYou => 'Escolhendo seu nome…';

  @override
  String get settingsYourName => 'Seu nome';

  @override
  String get settingsGuest => 'Jogando como convidado';

  @override
  String get settingsStatSolved => 'FEITOS';

  @override
  String get settingsStatStars => 'ESTRELAS';

  @override
  String get settingsNotifyTurnOnTitle => 'Ativar notificações';

  @override
  String get settingsNotifyDeniedDetail =>
      'Desativadas nas configurações do celular. Toque para abrir.';

  @override
  String get settingsNotifyNotYetDetail =>
      'O Pourfect ainda não pode te notificar';

  @override
  String get settingsRemindersTitle => 'Lembretes do Desafio Diário';

  @override
  String get settingsRemindersDetail =>
      'De manhã e à noite, nunca mais de dois por dia';

  @override
  String get settingsNewsTitle => 'Novidades do jogo';

  @override
  String get settingsNewsDetail => 'Novos mundos e avisos';

  @override
  String settingsToggleOn(String title) {
    return '$title, ativado';
  }

  @override
  String settingsToggleOff(String title) {
    return '$title, desativado';
  }

  @override
  String get settingsFaqSectionPlaying => 'Jogando';

  @override
  String get settingsFaqSectionStuck => 'Travou?';

  @override
  String get settingsFaqSectionProgress => 'Seu progresso';

  @override
  String get settingsFaqSectionAds => 'Anúncios e som';

  @override
  String get settingsFaqHowToPlayQ => 'Como eu jogo?';

  @override
  String get settingsFaqHowToPlayA =>
      'Toque num tubo para pegar as bolinhas de cima e depois toque em outro tubo para despejá-las. As bolinhas só caem sobre a mesma cor ou num tubo vazio. Deixe cada tubo de uma cor só e o nível está concluído. Em Configurações → Como jogar, você joga de novo o primeiro nível guiado.';

  @override
  String get settingsFaqStarsQ => 'O que as estrelas significam?';

  @override
  String get settingsFaqStarsA =>
      'As estrelas contam jogadas, nada mais. Termine no par ou com menos jogadas para ganhar três estrelas, com até uma vez e meia o par para ganhar duas, e qualquer final vale uma. O par é o menor número de jogadas em que o nível pode ser resolvido.';

  @override
  String get settingsFaqClockQ => 'O relógio me faz perder estrelas?';

  @override
  String get settingsFaqClockA =>
      'Nunca. O tempo só muda seus pontos. Bata o par de tempo para ganhar pontos extras, ou leve o tempo que quiser e fique com todas as estrelas.';

  @override
  String get settingsFaqSolvableQ => 'Todo nível tem solução?';

  @override
  String get settingsFaqSolvableA =>
      'Sim. Cada tabuleiro foi resolvido antes de ser lançado, e o par vem dessa solução, então ele sempre é alcançável.';

  @override
  String get settingsFaqDailyQ => 'O que é o Desafio Diário?';

  @override
  String get settingsFaqDailyA =>
      'Um tabuleiro novo todo dia, com seu próprio ranking. Ele precisa de conexão com a internet. Os níveis da campanha, não.';

  @override
  String get settingsFaqUndoQ => 'O desfazer é limitado?';

  @override
  String get settingsFaqUndoA =>
      'Não. Desfazer é grátis e ilimitado, em todos os níveis.';

  @override
  String get settingsFaqHintsQ => 'Como funcionam as dicas?';

  @override
  String settingsFaqHintsA(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Suas primeiras $count dicas são grátis. Depois disso, um vídeo curto rende uma. Se não for possível encontrar uma dica, o vídeo continua valendo para a próxima.',
      one: 'Sua primeira dica é grátis. Depois disso, um vídeo curto rende uma. Se não for possível encontrar uma dica, o vídeo continua valendo para a próxima.',
    );
    return '$_temp0';
  }

  @override
  String get settingsFaqTubeQ => 'O que é o botão + Tubo?';

  @override
  String get settingsFaqTubeA =>
      'Quando suas jogadas chegam ao par, ou quando uma dica mostra que não dá para terminar, você pode assistir a um vídeo para ganhar um tubo vazio extra, até dois por tentativa. O desfazer não tira o tubo. Um nível concluído com tubo extra vale no máximo duas estrelas.';

  @override
  String get settingsFaqHardQ => 'O que são os níveis com selo DIFÍCIL?';

  @override
  String get settingsFaqHardA =>
      'O nível mais difícil de cada dez leva um selo vermelho de DIFÍCIL. Ele é jogado como qualquer outro nível e vale uma vez e meia os pontos.';

  @override
  String get settingsFaqChestsQ => 'O que são os baús de estrelas?';

  @override
  String get settingsFaqChestsA =>
      'A cada 30 estrelas, um baú se abre na sua Jornada: duas dicas e um tubo extra, guardados para quando você precisar. A cada três baús, você também desbloqueia um visual de bolinha.';

  @override
  String get settingsFaqFreezeQ => 'O que é um congelamento de sequência?';

  @override
  String get settingsFaqFreezeA =>
      'Se você perder um dia do Desafio Diário, um congelamento cobre esse dia e sua sequência continua. Você ganha um grátis toda segunda-feira, pode ganhar um por dia com um vídeo e pode guardar até dois.';

  @override
  String get settingsFaqAccountQ => 'Preciso de uma conta?';

  @override
  String get settingsFaqAccountA =>
      'Não. Você joga como convidado e seu progresso fica salvo neste celular. Entrar numa conta mantém suas estrelas quando você trocar de celular.';

  @override
  String get settingsFaqOfflineQ => 'Dá para jogar offline?';

  @override
  String get settingsFaqOfflineA =>
      'Sim, a campanha inteira. O Desafio Diário e os rankings precisam de conexão, e seu progresso é sincronizado quando você voltar a ficar online.';

  @override
  String get settingsFaqNameQ => 'Como mudo meu nome no ranking?';

  @override
  String get settingsFaqNameA =>
      'Em Configurações → Mudar seu nome. Ali você também pode se ocultar dos rankings; suas estrelas continuam contando.';

  @override
  String get settingsFaqRemoveAdsQ => 'O que o Remover anúncios faz?';

  @override
  String get settingsFaqRemoveAdsA =>
      'Desativa os anúncios entre os níveis. Os vídeos de dica e de tubo continuam, porque você só vê um quando pede.';

  @override
  String get settingsFaqReinstallQ =>
      'Reinstalei o jogo. Cadê o Remover anúncios?';

  @override
  String get settingsFaqReinstallA =>
      'A compra pertence à conta da loja em que você comprou e normalmente volta sozinha. Se não voltar, toque em Configurações → Restaurar compras.';

  @override
  String get settingsFaqMusicQ => 'O jogo vai parar minha música?';

  @override
  String get settingsFaqMusicA =>
      'Não. O Pourfect toca os sons junto com sua música ou podcast. Som e vibração podem ser desativados nas Configurações.';

  @override
  String get settingsLegalTitle => 'Antes de começar';

  @override
  String get settingsLegalIntro =>
      'O Pourfect é grátis, funciona offline e não precisa de conta. Leia e aceite estes documentos primeiro.';

  @override
  String settingsLegalAcceptTerms(String document) {
    return 'Aceito os $document';
  }

  @override
  String settingsLegalReadPrivacy(String document) {
    return 'Li a $document';
  }

  @override
  String settingsLegalAlsoCovers(String document, String version) {
    return 'Ao aceitar, você também concorda com nossa $document (versão $version).';
  }

  @override
  String get settingsLegalPrivacyPolicy => 'Política de Privacidade';

  @override
  String get settingsLegalTermsOfService => 'Termos de Serviço';

  @override
  String get settingsLegalRefundPolicy => 'Política de Reembolso';

  @override
  String settingsLegalReadDocument(String document) {
    return 'Ler: $document';
  }

  @override
  String get settingsLegalAccept => 'BORA JOGAR!';

  @override
  String get settingsLegalReadAgain =>
      'Você pode ler estes documentos de novo quando quiser nas Configurações.';

  @override
  String get settingsLegalLoadFailed =>
      'Não foi possível carregar este documento neste dispositivo.\n\nVocê pode lê-lo em legal.pranta.dev antes de aceitar.';

  @override
  String get settingsUpdateTitle => 'Um novo Pourfect está pronto';

  @override
  String get settingsUpdateBody =>
      'O Google Play vai baixar a atualização e abrir o jogo de novo quando terminar. Suas estrelas estão seguras.';

  @override
  String get settingsUpdateMandatoryTitle => 'Hora de atualizar';

  @override
  String get settingsUpdateMandatoryBody =>
      'Esta versão do Pourfect não é mais compatível. O Google Play vai baixar a atualização e abrir o jogo de novo. Suas estrelas estão seguras.';

  @override
  String get settingsUpdateNow => 'Atualizar agora';

  @override
  String get settingsRenameHello => 'OLÁ';

  @override
  String get settingsRenameMyNameIs => 'MEU NOME É';

  @override
  String get settingsRenameHint => 'Outros jogadores veem isto nos rankings';

  @override
  String get settingsRenameSave => 'SALVAR';

  @override
  String settingsCollectionUnlockWith(String how) {
    return 'Desbloqueie com: $how.';
  }

  @override
  String get settingsCollectionChangeFailed =>
      'Não foi possível trocar agora. Tente de novo mais tarde.';

  @override
  String get settingsPackThanks =>
      'Obrigado! O pacote será desbloqueado em instantes.';

  @override
  String get settingsPackAlreadyOwned => 'Já é seu. Restaurando agora.';

  @override
  String get settingsPackPending =>
      'Pagamento pendente. O pacote será desbloqueado assim que ele for aprovado.';

  @override
  String get settingsCollectionOffline =>
      'Conecte-se à internet para ver sua coleção.';

  @override
  String get settingsCollectionBallSkins => 'Visuais de bolinhas';

  @override
  String get settingsCollectionTubeThemes => 'Temas de tubos';

  @override
  String settingsCollectionPreview(String skin, String theme) {
    return 'Bolinhas $skin · tubos $theme';
  }

  @override
  String settingsCollectionItemWorn(String name) {
    return '$name, em uso';
  }

  @override
  String settingsCollectionItemTapToWear(String name) {
    return '$name, toque para usar';
  }

  @override
  String settingsCollectionItemLocked(String name, String how) {
    return '$name, bloqueado: $how';
  }

  @override
  String get settingsCollectionWearing => 'Em uso';

  @override
  String get settingsCollectionTapToWear => 'Toque para usar';

  @override
  String settingsUnlockChest(int number) {
    return 'Baú de estrelas $number';
  }

  @override
  String settingsUnlockStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Sequência de $days dias',
      one: 'Sequência de 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnlockFree => 'Grátis';

  @override
  String get settingsSkinPack => 'Pacote de visuais';

  @override
  String get settingsSkinPackDetail =>
      'Bolinhas Mármore, Pérola e Xadrez, tubos Madeira e Lilás.';

  @override
  String get settingsOwned => 'SEU';

  @override
  String get settingsSoon => 'Em breve';

  @override
  String get settingsSkinClassic => 'Clássico';

  @override
  String get settingsSkinGlossy => 'Lustroso';

  @override
  String get settingsSkinStriped => 'Listrado';

  @override
  String get settingsSkinGlow => 'Neon';

  @override
  String get settingsSkinSpeckled => 'Granulado';

  @override
  String get settingsSkinMarble => 'Mármore';

  @override
  String get settingsSkinPearl => 'Pérola';

  @override
  String get settingsSkinChecker => 'Xadrez';

  @override
  String get settingsTubeToy => 'Brinquedo';

  @override
  String get settingsTubeFrost => 'Gelo';

  @override
  String get settingsTubeWood => 'Madeira';

  @override
  String get settingsTubeLilac => 'Lilás';
}
