/// Tuning for everything under `services/api/`.
///
/// The base URL is NOT here — see `app_env.dart`. It differs per machine and
/// per environment and belongs in the bundled `.env` this project already
/// uses, alongside the Google client id.
///
/// THE GAME IS FULLY PLAYABLE OFFLINE AND THE BACKEND IS OPTIONAL ENRICHMENT.
/// Every caller in this directory treats "no backend configured" as an
/// ordinary state rather than an error: leaderboards and the daily challenge
/// simply do not appear, and the campaign behaves exactly as it does today.
library;

/// How long any single request may take.
///
/// Short on purpose. Nothing behind this client is worth making somebody wait
/// for: the longest of these is a first-launch sync of 150 rows, and if that
/// cannot complete in ten seconds the right answer is to give up and try again
/// later rather than to hold a spinner over a game that does not need one.
const Duration kApiTimeout = Duration(seconds: 10);

/// How long before expiry a session is treated as stale and re-exchanged.
///
/// The server's token lasts long enough that this is generous. Refreshing on
/// the exact second of expiry means every clock skew between the phone and the
/// server turns into a 401 that the player sees as a sync failure.
const Duration kSessionRefreshMargin = Duration(minutes: 5);
