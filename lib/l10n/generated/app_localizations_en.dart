// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accountDeviceProfile => 'Device profile & Diagnostics';

  @override
  String accountDeviceProfileSubtitle(String label) {
    return 'Profile $label · player diagnostics';
  }

  @override
  String get accountNoSubscription => 'No active subscription';

  @override
  String get accountPreferences => 'Profile preferences';

  @override
  String get accountPreferencesSubtitle =>
      'Language, theme, age restrictions, PIN';

  @override
  String get accountProfiles => 'User profiles';

  @override
  String get accountProfilesSubtitle =>
      'Manage profiles and the active profile';

  @override
  String get accountSubscriptions => 'Xtream/M3U subscriptions';

  @override
  String activeCountOngoing(Object count) {
    return '$count in progress';
  }

  @override
  String get addSubscription => 'Add a subscription';

  @override
  String addedToFavorites(Object title) {
    return '\"$title\" added to favorites';
  }

  @override
  String get age => 'Age';

  @override
  String get ageRange13to17 => '13 - 17';

  @override
  String get ageRange18to24 => '18 - 24';

  @override
  String get ageRange25to34 => '25 - 34';

  @override
  String get ageRange35to44 => '35 - 44';

  @override
  String get ageRange45to54 => '45 - 54';

  @override
  String get ageRange55plus => '55 and over';

  @override
  String get ageRangeUnder12 => 'Under 12';

  @override
  String get appTitle => 'Orbit IPTV';

  @override
  String get appearInSearchAndRecommendations =>
      'Appear in searches and recommendations';

  @override
  String get apply => 'Apply';

  @override
  String get audioAndNightFocus => 'Audio & Night Focus';

  @override
  String get audioAndNightFocusSubtitle =>
      'Night optimization, dialogue boost, A/V sync';

  @override
  String get audioShift => 'Configurable audio offset';

  @override
  String get audioShiftMinus50 => '-50 ms';

  @override
  String get audioShiftPlus50 => '+50 ms';

  @override
  String get audioShiftSubtitle => 'Manual audio/video offset (ms)';

  @override
  String get autoQualityDescription =>
      'Lets the player choose the best quality';

  @override
  String get autoReconnectLive => 'Live auto-reconnect';

  @override
  String get autoReconnectLiveSubtitle =>
      'Automatically reconnect if the stream drops';

  @override
  String get avSyncDialogHint =>
      'Positive = audio ahead, Negative = audio delayed';

  @override
  String get avSyncDialogLabel => 'Offset (ms)';

  @override
  String get avSyncDialogTitle => 'A/V calibration';

  @override
  String get backupExport => 'Export configuration';

  @override
  String get backupExportSubtitle => 'Copy the full config to the clipboard';

  @override
  String get backupImport => 'Import configuration';

  @override
  String get backupImportSubtitle => 'Restore from the clipboard (JSON)';

  @override
  String get bassKiller => 'Bass Killer (cut < 120 Hz)';

  @override
  String get bassKillerSubtitle =>
      'Attenuates low frequencies to avoid vibrations';

  @override
  String get cancel => 'Cancel';

  @override
  String get castToChromecast => 'Cast to Chromecast';

  @override
  String get catchUpTv => 'Catch-up TV';

  @override
  String get categories => 'Categories';

  @override
  String get certPinning => 'Enable Certificate Pinning';

  @override
  String get certPinningAdd => 'Add the fingerprints above';

  @override
  String get certPinningHint =>
      'Allowed fingerprints (one per line, uppercase hex):';

  @override
  String get certPinningSubtitle =>
      'Checks the SHA-256 fingerprint of the server SSL certificate (anti-MITM)';

  @override
  String get changePinCode => 'Change PIN code';

  @override
  String get channelsUnavailable => 'Channels unavailable';

  @override
  String get chooseProfile => 'Choose a profile';

  @override
  String get clearCaches => 'Clear all caches';

  @override
  String get clearCachesSubtitle =>
      'Images, search index, TMDB/TVmaze metadata';

  @override
  String get cloudSyncEnabled => 'Sync enabled';

  @override
  String cloudSyncLastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String get cloudSyncNow => 'Sync now';

  @override
  String get cloudSyncNowSubtitle => 'Push local changes to the cloud';

  @override
  String get cloudSyncSubtitleOff =>
      'Sync favorites, watched and recents to the cloud';

  @override
  String get cloudflareReset => 'Reset Cloudflare config';

  @override
  String get cloudflareResetSubtitle =>
      'Clears cookies, sets TLS Impersonation=OFF, default ExoPlayer UA';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get confirmAndContinue => 'Confirm and continue';

  @override
  String get coverCacheCleared => 'Cover art cache cleared.';

  @override
  String get createKidProfile => 'Create a kids profile';

  @override
  String get createNewProfile => 'Create a new profile';

  @override
  String get createProfile => 'Create a profile';

  @override
  String get dataAlreadyFresh => 'Data already up to date (less than 30 min)';

  @override
  String get dataAndPrivacy => 'Data & privacy';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get deleteAllConfirm => 'Delete all?';

  @override
  String get deletePin => 'Delete PIN';

  @override
  String get deleteProfileConfirm => 'Delete profile?';

  @override
  String get detailUnavailable => 'Details unavailable';

  @override
  String get diagnosticUnavailable => 'Diagnostic unavailable';

  @override
  String get dialogueBoost => 'Dialogue Boost (+4 dB)';

  @override
  String get dialogueBoostSubtitle =>
      'Amplifies voices relative to effects/music';

  @override
  String get disableSubtitles => 'Disable subtitles';

  @override
  String get dnsCloudflare => '1.1.1.1 (Cloudflare DoH)';

  @override
  String get dnsGoogle => '8.8.8.8 (Google DoH)';

  @override
  String get dnsProvider => 'DNS provider (DoH)';

  @override
  String get dnsProviderSubtitle => 'Server used for DNS over HTTPS queries';

  @override
  String get dnsQuad9 => '9.9.9.9 (Quad9 DoH)';

  @override
  String get dnsSystem => 'Automatic (System)';

  @override
  String downloadFailed(Object error) {
    return 'Download failed: $error';
  }

  @override
  String get downloads => 'Downloads';

  @override
  String get dpadNavigation => 'Enhanced D-pad navigation';

  @override
  String get dpadNavigationSubtitle =>
      'Visible focus, glow halo, text wrap (TV mode)';

  @override
  String get enableParentalControl => 'Enable parental control';

  @override
  String enginesSubtitle(String live, String vod) {
    return 'Live: $live · VOD: $vod';
  }

  @override
  String get enginesTile => 'Playback engines';

  @override
  String get enterNew4DigitPin => 'Enter a new 4-digit code';

  @override
  String get epgGrille => 'EPG (grid)';

  @override
  String get epgGuideTv => 'TV Guide (EPG)';

  @override
  String get episode => 'Episode';

  @override
  String errorGeneric(Object error) {
    return 'Error: $error';
  }

  @override
  String errorLoading(Object error) {
    return 'Loading error: $error';
  }

  @override
  String get errorSaving => 'Error while saving';

  @override
  String get exitWithoutSaving => 'Exit without saving?';

  @override
  String get failedToLoadProfiles => 'Unable to load profiles';

  @override
  String get fallbackEngine => 'Fallback engine';

  @override
  String get favoriteGenres => 'Favorite genres';

  @override
  String get filmsVod => 'Movies (VOD)';

  @override
  String get firstName => 'First name';

  @override
  String get fontSize => 'Increased text size';

  @override
  String get fontSizeSubtitle => 'Enlarges text throughout the app';

  @override
  String get forYou => 'For You';

  @override
  String get forYouAndDuo => 'For You & Duo';

  @override
  String get forYouMatchmaking => 'For You (Matchmaking)';

  @override
  String get forward10s => 'Forward 10s';

  @override
  String get forward30s => 'Forward 30s';

  @override
  String get groupMode => 'Group';

  @override
  String get highContrast => 'High contrast mode';

  @override
  String get highContrastSubtitle =>
      'Improves readability for the visually impaired';

  @override
  String get historyUnavailable => 'History unavailable';

  @override
  String get instantZapping => 'Instant Zapping (Prefetch)';

  @override
  String get instantZappingSubtitle =>
      'Prefetch adjacent channels into the buffer';

  @override
  String get kidsContent => 'Kids-friendly content';

  @override
  String get kidsMode => 'Kids Mode';

  @override
  String get langArabic => 'العربية';

  @override
  String get langFrench => 'Français';

  @override
  String get langPortuguese => 'Português';

  @override
  String get langSpanish => 'Español';

  @override
  String get language => 'Language';

  @override
  String get languageExample => 'Français, English, etc.';

  @override
  String get languagePreference => 'Application language';

  @override
  String get languageUndetermined => 'Undetermined';

  @override
  String get later => 'Later';

  @override
  String get legalNotice => 'Read me · Legal notice';

  @override
  String get legalNoticeSubtitle => 'App usage, rights holders and privacy';

  @override
  String get liveChannelsAndZapping => 'Live channels & Zapping';

  @override
  String get liveTv => 'Live TV';

  @override
  String get logsDiagnostic => 'Logs & Diagnostics';

  @override
  String get logsDiagnosticSubtitle => 'View logs, export, clear cache';

  @override
  String get m3uPlaylist => 'M3U Playlist';

  @override
  String get m3uPlaylistUrl => 'M3U playlist URL';

  @override
  String get mainCast => 'Main cast';

  @override
  String get manualAvCalibration => 'Manual A/V calibration';

  @override
  String manualAvCalibrationSubtitle(int ms) {
    return 'Current offset: $ms ms';
  }

  @override
  String get matchmaking => 'For you (Matchmaking)';

  @override
  String get matchmakingSubtitle =>
      'Manage pairing and personalized suggestions';

  @override
  String maxProfilesReached(Object max) {
    return 'Maximum number of profiles reached ($max)';
  }

  @override
  String get memory => 'Memory';

  @override
  String get moviesUnavailable => 'Movies unavailable';

  @override
  String get multiScreen => 'Multi-screen';

  @override
  String get multiVideo => 'Multi-video';

  @override
  String get myProfile => 'My profile';

  @override
  String get nameOptional => 'Name (optional)';

  @override
  String get nameOrNickname => 'Name / Nickname';

  @override
  String get navigateToOkToSelect => 'Navigate to OK to select';

  @override
  String get networkDisconnected => 'Network disconnected';

  @override
  String get never => 'never';

  @override
  String get newAnd4K => 'New & 4K';

  @override
  String get newProfile => 'New profile';

  @override
  String get nextChannel => 'Next channel';

  @override
  String get nightFocusEnable => 'Enable Night Focus';

  @override
  String get nightFocusEnableSubtitle =>
      'Real-time audio processing: dialogue boost, bass cut, sync';

  @override
  String get nightFocusTitle => 'Night Focus (Night Mode)';

  @override
  String get noAudioTrackDetected => 'No audio track detected';

  @override
  String get noChannelsAvailable => 'No channels available';

  @override
  String get noChromecastDeviceFound => 'No Chromecast device found.';

  @override
  String get noDownloads => 'No downloads';

  @override
  String get noEpisodes => 'No episodes';

  @override
  String get noFavoriteChannels => 'No favorite channels';

  @override
  String get noFavoriteMovies => 'No favorite movies';

  @override
  String get noFavoriteReplays => 'No favorite replays';

  @override
  String get noFavoriteSeries => 'No favorite series';

  @override
  String get noHistory => 'No history';

  @override
  String get noKidsChannels => 'No kids channels';

  @override
  String get noKidsMovies => 'No kids movies';

  @override
  String get noKidsReplays => 'No kids replays';

  @override
  String get noKidsSeries => 'No kids series';

  @override
  String get noMoviesAvailable => 'No movies available';

  @override
  String get noProfileAvailable => 'No profile available';

  @override
  String get noProfilesYet => 'No profiles yet';

  @override
  String get noProgramInfoAvailable => 'No program information available';

  @override
  String get noRankings => 'No rankings';

  @override
  String get noReplaysInCategory => 'No replays in this category';

  @override
  String noResultsFor(Object query) {
    return 'No results for $query';
  }

  @override
  String get noSeriesAvailable => 'No series available';

  @override
  String get noStationsAvailable => 'No stations available';

  @override
  String get noVideoQualityDetected => 'No video quality detected';

  @override
  String get notAvailableInCatalog => 'Not available in the catalog';

  @override
  String get offline => 'Offline';

  @override
  String get parentalControl => 'Parental control';

  @override
  String get parentalControlSubtitle => 'Add a PIN code and restrict content';

  @override
  String get pauseDownload => 'Pause';

  @override
  String get pinCode => 'PIN code';

  @override
  String get pinDeleted => 'PIN deleted';

  @override
  String get pinMustBe4Digits => 'PIN must be exactly 4 digits';

  @override
  String get pinSaved => 'PIN saved';

  @override
  String get pip => 'Picture-in-Picture (PiP)';

  @override
  String get pipUnavailable =>
      'Picture-in-Picture (PiP) not available on this device';

  @override
  String get playHistoryCleared => 'Play history cleared.';

  @override
  String plusAgeYears(Object age) {
    return '+$age years';
  }

  @override
  String get preferences => 'Preferences';

  @override
  String get previousChannel => 'Previous channel';

  @override
  String get primaryEngine => 'Primary engine';

  @override
  String get profileVisible => 'Visible profile';

  @override
  String get programGrid => 'Program guide';

  @override
  String get protectWithPin => 'Protect with PIN';

  @override
  String get rankingsUnavailable => 'Rankings unavailable';

  @override
  String get receiveAlertsAndTips => 'Receive alerts and tips';

  @override
  String get recentSearch => 'Recent search';

  @override
  String get recentSearches => 'Recent';

  @override
  String get recentlyWatched => 'Recently watched';

  @override
  String get removeAll => 'Remove all';

  @override
  String get removeFromWatchedConfirm => 'Remove all from watched?';

  @override
  String get replaysUnavailable => 'Replays unavailable';

  @override
  String get reset => 'Reset';

  @override
  String get resetApp => 'Reset application';

  @override
  String get resetAppDialogBody =>
      'All data will be erased: profiles, favorites, history, settings. This action is irreversible.';

  @override
  String get resetAppDialogConfirm => 'Erase everything';

  @override
  String get resetAppDialogTitle => 'Reset application?';

  @override
  String get resetAppSubtitle =>
      'Erases all user data (profiles, favorites, history)';

  @override
  String get resetCompleted => 'Reset completed';

  @override
  String get resumePlayback => 'Resume playback?';

  @override
  String get retry => 'Retry';

  @override
  String get retrySearch => 'Retry search';

  @override
  String get rewind10s => 'Rewind 10s';

  @override
  String get rewind30s => 'Rewind 30s';

  @override
  String get rightsHolders => 'Rights holders';

  @override
  String get save => 'Save';

  @override
  String get sdkAndroid => 'SDK Android';

  @override
  String get searchChannel => 'Search for a channel';

  @override
  String get searchError => 'Search error';

  @override
  String get searchMovie => 'Search for a movie';

  @override
  String get searchSeries => 'Search for a series';

  @override
  String seasonNumber(Object season) {
    return 'Season $season';
  }

  @override
  String get seasonsAndEpisodes => 'Seasons & Episodes';

  @override
  String get sectionAccessibility => 'Accessibility';

  @override
  String get sectionAccountProfile => 'Account & Profile';

  @override
  String get sectionAntiThrottle => 'ISP throttling protection';

  @override
  String get sectionAudioNight => 'Audio & Night Focus';

  @override
  String get sectionAvSync => 'A/V sync';

  @override
  String get sectionBackup => 'Backup / Restore';

  @override
  String get sectionCertPinning => 'Certificate Pinning (SHA-256)';

  @override
  String get sectionCloudSync => 'Cloud Sync (multi-device)';

  @override
  String get sectionCloudflare => 'Cloudflare optimization';

  @override
  String get sectionDiagnostics => 'Diagnostics & Maintenance';

  @override
  String get sectionEngines => 'Playback engines';

  @override
  String get sectionLegal => 'Legal information';

  @override
  String get sectionMemory => 'Memory & Cache';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get sectionOutput => 'Audio output';

  @override
  String get sectionParental => 'Parental control';

  @override
  String get sectionRecommendations => 'Recommendations';

  @override
  String get sectionResilience => 'Service resilience';

  @override
  String get sectionTmdb => 'TMDB rankings';

  @override
  String get sectionZapping => 'Zapping & Performance';

  @override
  String get select => 'Select';

  @override
  String get selectProfileForRecommendations =>
      'Select a profile to see its recommendations';

  @override
  String get series => 'Series';

  @override
  String get seriesNotFound => 'Series not found';

  @override
  String get seriesUnavailable => 'Series unavailable';

  @override
  String get seriesUnavailableTemporarily => 'Series temporarily unavailable.';

  @override
  String get serverProtectedAntiLeech => 'Server protected (anti-leech)';

  @override
  String get serverUrlPlaceholder => 'Server URL (e.g. https://provider.com)';

  @override
  String get serviceNature => 'Nature of the service';

  @override
  String get setAsDefaultServer => 'Set as default server';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get similarMovies => 'Similar movies';

  @override
  String get snackBackupExported => 'Configuration exported to the clipboard';

  @override
  String get snackCacheCleared => 'Caches cleared';

  @override
  String get snackCloudflareReset => 'Cloudflare config reset';

  @override
  String snackImportError(String message) {
    return 'Error: $message';
  }

  @override
  String get snackImportSuccess => 'Configuration imported successfully';

  @override
  String get snackNoBackup => 'No backup found';

  @override
  String get sortBestRated => 'Highest rated (XCIPTV)';

  @override
  String get sortLatestM3UXtream => 'Latest M3U/Xtream additions';

  @override
  String get sortNameAToZ => 'Name (A → Z)';

  @override
  String get sortNameZToA => 'Name (Z → A)';

  @override
  String get sortResumePriority => 'Resume first';

  @override
  String get sortYearRecentToOld => 'Release year (New → Old)';

  @override
  String specialGuestsSeason(Object season) {
    return 'Special guests - Season $season';
  }

  @override
  String get srtVttUrl => 'URL .srt / .vtt';

  @override
  String get start => 'Start';

  @override
  String get stationsUnavailable => 'Stations unavailable';

  @override
  String get stopCasting => 'Stop casting';

  @override
  String get streamDetails => 'Stream details';

  @override
  String subtitleLoadError(Object error) {
    return 'Subtitle loading error: $error';
  }

  @override
  String get subtitlesUnavailable => 'Subtitles: unavailable';

  @override
  String get system => 'System';

  @override
  String get tabAccount => 'Account';

  @override
  String get tabAdvanced => 'Advanced';

  @override
  String get tabAudio => 'Audio';

  @override
  String get tabNetwork => 'Network';

  @override
  String get tabPlayer => 'Player';

  @override
  String get tabSecurity => 'Security';

  @override
  String get testNotifications => 'Test notifications';

  @override
  String get testNotificationsSubtitle => 'Send a local test notification';

  @override
  String get theme => 'Theme';

  @override
  String get tlsImpersonation => 'TLS Impersonation (Local Proxy)';

  @override
  String get tlsImpersonationSubtitle =>
      'Simulates a modern browser fingerprint to bypass Cloudflare';

  @override
  String get tmdbKeyActive => 'Personal key active - the shared key is ignored';

  @override
  String get tmdbKeyColumn => 'TMDB keys';

  @override
  String get tmdbKeyDelete => 'Delete personal key';

  @override
  String get tmdbKeyHint => 'The embedded shared key is used by default';

  @override
  String get tmdbKeyLabel => 'Personal TMDB API key (optional)';

  @override
  String get tmdbKeyShared => 'Embedded shared key in use (no personal key)';

  @override
  String get tvChannels => 'TV Channels';

  @override
  String get unableToBuildReplayUrl => 'Unable to build the replay URL.';

  @override
  String get unlockCloudflare => 'Unlock (Cloudflare)';

  @override
  String get unstableConnection => 'Unstable connection';

  @override
  String get updateAllData => 'Update all data';

  @override
  String get updateThisCategory => 'Update this category';

  @override
  String get updating => 'Updating…';

  @override
  String get volumeNormalization => 'Volume normalization';

  @override
  String get volumeNormalizationSubtitle =>
      'Limits volume peaks between channels/programs (AGC)';

  @override
  String get watchLive => 'Watch live';

  @override
  String get whoIsWatching => 'Who\'s watching?';

  @override
  String get xtreamCodes => 'Xtream Codes';

  @override
  String get yourChannelsAndContent => 'Your channels & content';
}
