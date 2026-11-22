// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get castSearching => 'Searching for Cast devices…';

  @override
  String get castReceiverNotReady => 'Receiver is not ready yet';

  @override
  String castConnectedTo(String name) {
    return 'Connected to $name';
  }

  @override
  String castConnectionFailed(String name) {
    return 'Could not connect to $name.';
  }

  @override
  String get playerPause => 'Pause';

  @override
  String get playerNightFocusOn => 'Night Focus (on)';

  @override
  String get playerNightFocusOff => 'Night Focus (off)';

  @override
  String get playerLoadingProgram => 'Loading programme…';

  @override
  String get audioNightHelp =>
      'Sound optimization applies to the native engine when Night Focus is enabled. Settings are saved for the next playback.';

  @override
  String get audioNightTitle => 'Night optimization (Night Focus)';

  @override
  String get audioDialogueBoost => 'Dialogue boost';

  @override
  String get audioDialogueHelp => 'Boosts the voice frequency range (1–4 kHz)';

  @override
  String get audioBassLimiter => 'Bass reduction and limiter';

  @override
  String get audioBassHelp => 'Reduces deep bass and compresses sudden peaks';

  @override
  String get audioVocalGain => 'Voice amplification:';

  @override
  String get audioSyncTitle => 'Audio delay (A/V sync)';

  @override
  String startupResumeQuestion(String title, String position) {
    return 'Resume “$title” at $position?';
  }

  @override
  String get startupLastSession => 'Last session';

  @override
  String get seriesExternalTracksHint =>
      'With an external player, select audio and subtitles in that player. The preferences below apply to the internal player.';

  @override
  String seriesResetWatchedBody(int count, String title) {
    return 'The $count watched episodes of “$title” will be marked unwatched for this profile.';
  }

  @override
  String seriesResetWatchedDone(String title) {
    return '“$title” removed from watched items.';
  }

  @override
  String get recommendationAffinity => 'Affinity';

  @override
  String get recommendationLoadingCatalog => 'Loading the catalogue…';

  @override
  String get recommendationBuilding => 'Building your recommendations…';

  @override
  String get recommendationLoadingDuration => 'This may take up to 1 minute.';

  @override
  String get memoryPanelTitle => 'Memory and cache';

  @override
  String get memoryPanelHelp => 'Clear history and the in-memory image cache.';

  @override
  String get memoryHistoryTitle => 'Clear viewing history';

  @override
  String get memoryHistoryHelp =>
      'Clears the global history and legacy recent items, as well as recent content and playback positions for the current profile.';

  @override
  String get memoryClear => 'Clear';

  @override
  String get memoryImagesTitle => 'Clear the in-memory image cache';

  @override
  String get memoryImagesHelp =>
      'Releases images cached in memory; cached files on disk are kept.';

  @override
  String get memoryPurge => 'Clear';

  @override
  String get sortOptionsTitle => 'Advanced sorting options';

  @override
  String get sortOptionsHelp => 'Select a mode with the remote:';

  @override
  String get sortRecentDescription => 'Recently imported content';

  @override
  String get sortResumeDescription => 'Put unfinished content first';

  @override
  String get sortRatingDescription => 'Sort by ratings';

  @override
  String get sortYearDescription => 'Sort chronologically by production year';

  @override
  String get sortDurationDescription => 'Sort by content duration';

  @override
  String get sortActive => 'Active';

  @override
  String get onboardingWelcome => 'Welcome to Orbit IPTV';

  @override
  String get onboardingSubtitle => 'Automatic device setup';

  @override
  String get onboardingDeviceDetected => 'Device detected';

  @override
  String get onboardingDevice => 'Device';

  @override
  String get onboardingConnection => 'Connection';

  @override
  String get onboardingMobileNetwork => 'Mobile network';

  @override
  String get onboardingOtherNetwork => 'Other';

  @override
  String get onboardingUnknownMemory => 'Unknown';

  @override
  String onboardingMemoryMb(String value) {
    return '$value MB';
  }

  @override
  String onboardingMemoryGb(String value) {
    return '$value GB';
  }

  @override
  String get onboardingEco => 'Economy';

  @override
  String onboardingProfile(String name) {
    return '$name profile';
  }

  @override
  String get onboardingEcoDescription =>
      'Fast start (1.5 s) · max 1080p · 3D disabled · multi-view off';

  @override
  String get onboardingStandardDescription =>
      'Fast start (2 s) · smooth 3D · multi-view x2';

  @override
  String get onboardingUltraDescription =>
      'Fast channel switching (3 s · 4K HDR possible) · multi-view x4';

  @override
  String get onboardingResetRecommendation => 'Reset recommendation';

  @override
  String get onboardingAdjust => 'Adjust manually';

  @override
  String get onboardingChooseProfile => 'Choose a profile';

  @override
  String get onboardingRecommendedProfile => 'Recommended profile';

  @override
  String get onboardingEcoHint => '3D effects and multi-view disabled.';

  @override
  String get duoTitle => 'Duo mode';

  @override
  String duoChooseOthers(int max) {
    return 'Choose 1 to $max additional profiles';
  }

  @override
  String duoChooseWith(String name, int max) {
    return 'With “$name” — choose 1 to $max other profiles';
  }

  @override
  String get duoCreateProfile => 'Create at least a second profile';

  @override
  String get duoNeedsProfiles =>
      'Duo mode requires at least 2 profiles in total.';

  @override
  String get duoFull => '4 profiles — the Duo team is complete';

  @override
  String duoReady(int count) {
    return '$count profiles selected — ready for Duo';
  }

  @override
  String duoSelectOne(int count) {
    return 'Select at least 1 additional profile ($count/4)';
  }

  @override
  String get duoStart => 'Start Duo';

  @override
  String get duoSelected => 'Selected';

  @override
  String get duoMaximum => 'Maximum reached';

  @override
  String get legalIntroTitle => 'Orbit IPTV · Please read';

  @override
  String get legalIntro =>
      'Before you begin, here is some brief information about using this app and the rights associated with the content displayed.';

  @override
  String get legalServicePlayer =>
      'Orbit IPTV is an IPTV player: it displays streams supplied by third-party servers (M3U / Xtream Codes subscriptions) without hosting any video, audio or subtitle content.';

  @override
  String get legalServiceMetadata =>
      'It aggregates and displays metadata (posters, synopses, EPG) obtained through public APIs. It works as a specialized browser for HLS/DASH streams.';

  @override
  String get legalRightsProvider =>
      'The IPTV subscription provider alone is responsible for channel licences, broadcasting rights and geoblocking of the streams it provides.';

  @override
  String get legalRightsMetadata =>
      'Posters and synopses come from TMDb under its API licence; TMDb attribution appears at the bottom of the rankings page.';

  @override
  String get legalRightsContent =>
      'Orbit IPTV does not store, redistribute or monetize any streamed content.';

  @override
  String get legalUsageTitle => 'Using the app';

  @override
  String get legalUsageRights =>
      'Use only with a subscription for which you hold broadcasting rights.';

  @override
  String get legalUsageRestrictions =>
      'Do not bypass geoblocking or DRM, or share your account outside your household.';

  @override
  String get legalUsageEditorial =>
      'The app makes no editorial selection of streamed content and has no control over streams from third-party servers.';

  @override
  String get legalPrivacyStorage =>
      'Profiles, favourites, history and settings are stored locally. If you enable cloud sharing, selected data is also synchronized in encrypted form.';

  @override
  String get legalPrivacyConsent =>
      'There is no data collection by default; notifications and optional access require explicit consent.';

  @override
  String get legalWarningTitle => 'Warning';

  @override
  String get legalWarningBody =>
      'This document is not legal advice. Rules vary by jurisdiction: check that your use is permitted in your country (applicable law and minimum age).';

  @override
  String get legalAccept => 'I have read and accept · Continue';

  @override
  String get epgReplayAvailableOnChannel => 'Replay available on this channel';

  @override
  String actorBornOn(String date) {
    return 'Born on $date';
  }

  @override
  String get actorGenderMale => 'Male';

  @override
  String get actorGenderFemale => 'Female';

  @override
  String get crewTitle => 'Crew';

  @override
  String get crewDirecting => 'Directing';

  @override
  String get crewWriting => 'Writing';

  @override
  String get crewProduction => 'Production';

  @override
  String get crewSound => 'Sound';

  @override
  String get crewCamera => 'Camera';

  @override
  String get crewEditing => 'Editing';

  @override
  String get crewArt => 'Art direction';

  @override
  String get crewCostume => 'Costume and make-up';

  @override
  String get crewVisualEffects => 'Visual effects';

  @override
  String get crewLighting => 'Lighting';

  @override
  String get menuContinue => 'Continue';

  @override
  String get menuDiscover => 'Discover';

  @override
  String get menuHome => 'Home';

  @override
  String get menuSearch => 'Search';

  @override
  String get menuProfile => 'Profile';

  @override
  String get menuSubscriptions => 'Subscriptions';

  @override
  String get menuSelect => 'Select a submenu';

  @override
  String get menuContent => 'Content';

  @override
  String get profileMustKeepOne =>
      'At least one profile must remain on this device';

  @override
  String profileDeleteBody(String name) {
    return '\"$name\" and their preferences will be permanently deleted. This cannot be undone.';
  }

  @override
  String get profileChange => 'Change profile';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileDelete => 'Delete';

  @override
  String get profileBack => 'Back';

  @override
  String get profileAdult => 'adult';

  @override
  String get profileChild => 'child';

  @override
  String get profileExpert => 'expert';

  @override
  String get categoryTitle => 'Categories';

  @override
  String get categoryShowAll => 'Show all';

  @override
  String get categoryScanFailed =>
      'Scan failed: the provider is not responding.';

  @override
  String get categoryEmptyLive => 'No Live TV categories from this provider.';

  @override
  String get categoryEmptyMovies => 'No movie categories from this provider.';

  @override
  String get categoryEmptySeries => 'No series categories from this provider.';

  @override
  String categoryHidden(String label, int count) {
    return '$label ($count hidden)';
  }

  @override
  String get categoryNeverScanned => 'Never scanned';

  @override
  String get categoryScannedToday => 'Scanned today';

  @override
  String get categoryScannedYesterday => 'Scanned yesterday';

  @override
  String categoryScannedDaysAgo(int days) {
    return 'Scanned $days days ago';
  }

  @override
  String categorySubscriptionSettings(String status) {
    return 'Settings for this subscription — $status';
  }

  @override
  String get categoryScanning => 'Scanning…';

  @override
  String get categoryRescan => 'Rescan categories';

  @override
  String categoryChannelsCount(int count) {
    return '$count channels';
  }

  @override
  String categoryTitlesCount(int count) {
    return '$count titles';
  }

  @override
  String get liveWatchAction => 'Watch';

  @override
  String get livePreviewDisabled =>
      'Video preview is disabled. Press Watch to open the channel.';

  @override
  String get livePreviewFrozen => 'Preview frozen';

  @override
  String get livePreviewRetry => 'Retry';

  @override
  String get episodeMarkWatchedFailed =>
      'Could not mark this episode as watched.';

  @override
  String get episodeAlreadyWatched => 'Episode already watched';

  @override
  String get episodeMarkWatched => 'Mark as watched';

  @override
  String episodeResumeAt(String position) {
    return 'Resume at $position';
  }

  @override
  String get episodeActionsHelp => 'Hold OK to mark as watched or reset.';

  @override
  String episodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes',
      one: '1 episode',
    );
    return '$_temp0';
  }

  @override
  String episodesInProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes in progress',
      one: '1 episode in progress',
    );
    return '$_temp0';
  }

  @override
  String episodesWatchedCount(int seen, int total) {
    return '$seen/$total watched';
  }

  @override
  String get episodeWatched => 'Watched';

  @override
  String get homeRefreshFailed => 'Update failed: no source responded.';

  @override
  String get homeRefreshDone => 'Update complete.';

  @override
  String get homeRefreshEmpty => 'Update complete; no data available.';

  @override
  String get homeChangeSubscription => 'Change subscription';

  @override
  String get homeManageSubscription => 'Manage subscription';

  @override
  String get homeNoSubscription => 'No subscription';

  @override
  String get homeAddOrChangeSubscription => 'Add or change subscription';

  @override
  String get homeMultiStream => 'Up to 4 streams at once';

  @override
  String get homeRadioStations => 'Live stations';

  @override
  String get homeRefreshUnknown => 'Last update unknown';

  @override
  String homeRefreshMinutes(int minutes) {
    return 'Updated $minutes min ago';
  }

  @override
  String get catalogAll => 'All';

  @override
  String get catalogUngrouped => 'Ungrouped';

  @override
  String get catalogSort => 'Sort';

  @override
  String get browseLoading => 'Loading…';

  @override
  String get startupRadio => 'Radio';

  @override
  String get profileCreateFirstHint =>
      'Create your first profile to start watching.';

  @override
  String downloadDirectoryMissing(String path) {
    return 'Directory not found: $path';
  }

  @override
  String downloadFileMissing(String path, String names) {
    return 'File not found: $path. Files present: $names';
  }

  @override
  String get widevineSelectSubscription => 'Select an active subscription';

  @override
  String get widevineLoading => 'Loading configuration';

  @override
  String get widevineLoadFailed => 'Could not load configuration';

  @override
  String widevineNoLicense(String subscription) {
    return '$subscription: no license configured';
  }

  @override
  String get widevineSelectFirst => 'Select an active subscription first.';

  @override
  String get widevineUnavailable => 'Widevine configuration is unavailable.';

  @override
  String widevineSaveFailed(String error) {
    return 'Could not save Widevine: $error';
  }

  @override
  String widevineClearFailed(String error) {
    return 'Could not clear Widevine: $error';
  }

  @override
  String get widevineLicenseUrl => 'License server URL';

  @override
  String get widevineInvalidUrl => 'Enter a valid HTTPS URL.';

  @override
  String get widevineHeaders => 'HTTP headers (JSON, optional)';

  @override
  String get widevineInvalidHeaders =>
      'Headers must be a JSON object of strings.';

  @override
  String get widevineCertificate => 'Base64 certificate (optional)';

  @override
  String get widevineStorageHelp =>
      'The configuration is stored in secure storage and linked to this subscription. It does not make a player that lacks Widevine support compatible.';

  @override
  String get widevineCopyLegacy => 'Copy previous global configuration';

  @override
  String get widevineClear => 'Clear';

  @override
  String get preferenceMultiTvFailed => 'Could not save the Multi TV setting.';

  @override
  String get preferenceLight => 'Light';

  @override
  String get preferenceDark => 'Dark';

  @override
  String get preferenceDisabled => 'Disabled';

  @override
  String preferenceParentalEnabled(String restriction) {
    return 'Enabled · Restriction $restriction';
  }

  @override
  String get preferenceMultiTvHelp =>
      'Show and allow multi-screen playback for this profile.';

  @override
  String get preferenceAllowRecording => 'Allow recording';

  @override
  String get preferenceRecordingHelp =>
      'Allow recording of my favorite content';

  @override
  String get preferenceLivePreview => 'Live video preview';

  @override
  String get preferenceLivePreviewHelp =>
      'Shows live video while browsing Live. This setting applies to this device.';

  @override
  String get preferenceProfileHelp =>
      'Your preferences are applied to your profile.';

  @override
  String get parentalAgeLimit => 'Age restriction';

  @override
  String get parentalNone => 'None';

  @override
  String get parentalHideAdult => 'Hide adult content';

  @override
  String get parentalHideAdultHelp =>
      'Movies, series and channels rated 18+ or erotic';

  @override
  String get parentalHideViolence => 'Hide violence';

  @override
  String get parentalHideViolenceHelp =>
      'Gore / horror / thriller / murder content';

  @override
  String get parentalCurrentPin => 'Current PIN: ••••';

  @override
  String get parentalSetPin => 'Set a PIN';

  @override
  String get parentalNewPin => 'New PIN (4 digits)';

  @override
  String get parentalPin => 'PIN (4 digits)';

  @override
  String get parentalShowPin => 'Show PIN';

  @override
  String get parentalHidePin => 'Hide PIN';

  @override
  String get parentalUpdatePin => 'Update PIN';

  @override
  String get subtitleAvailableTracks => 'Available tracks';

  @override
  String get subtitleAddUrl => 'Add subtitles (.srt/.vtt URL)';

  @override
  String get subtitleLoadAction => 'Load';

  @override
  String subtitleTrackCues(String language, int count) {
    return '$language · $count cues';
  }

  @override
  String multiMaxStreams(int count) {
    return 'Maximum: $count streams on this device.';
  }

  @override
  String get multiDisabledProfile =>
      'Multi TV is disabled for this profile. Enable it in the profile preferences.';

  @override
  String get multiAnalyzingDevice => 'Analyzing device…';

  @override
  String get multiDeviceAnalysisFailed => 'Unable to analyze device';

  @override
  String get multiDisabledEconomy =>
      'Multi-view is disabled by the Economy profile.\nChange the profile in Configure device.';

  @override
  String engineInternal(String name) {
    return '$name (Internal)';
  }

  @override
  String engineExternal(String name) {
    return '$name (External)';
  }

  @override
  String get engineSelectionHelp =>
      'Choose the player for each content type and the fallback player if playback fails.';

  @override
  String get engineVideoDecoding => 'Video decoding';

  @override
  String get engineAutoRecommended => 'Auto (recommended)';

  @override
  String get engineHardware => 'Hardware';

  @override
  String get engineSoftware => 'Software';

  @override
  String get engineAutoSoftware => 'Auto: software selected for this device';

  @override
  String get engineSubtitleDefault => 'Default';

  @override
  String get engineSubtitleDisabled => 'No subtitles';

  @override
  String get engineSubtitleForced => 'Forced subtitles';

  @override
  String get engineVodSubtitles => 'VOD subtitles';

  @override
  String get profilePinsNone => 'No profile has a PIN.';

  @override
  String get profilePinsRemoveQuestion => 'Remove profile PINs?';

  @override
  String profilePinsRemoveConfirmation(int count) {
    return 'PINs will be removed from $count profile(s). Profiles and their data will remain on this device. The changes may be synchronized with devices shared through the cloud.';
  }

  @override
  String get profilePinsRemove => 'Remove PINs';

  @override
  String get profilePinsNothingToRemove => 'No PINs to remove.';

  @override
  String profilePinsRemoved(int count) {
    return 'PINs removed from $count profile(s).';
  }

  @override
  String get profilePinsRemoveFailed =>
      'Could not remove PINs. Please try again.';

  @override
  String get profileProtection => 'Profile protection';

  @override
  String get profilePinsRemoveHelp =>
      'Remove PINs from every profile on this device. Profiles and their data will not be deleted.';

  @override
  String get profilePinsRemoving => 'Removing PINs…';

  @override
  String get profilePinsRemoveAll => 'Remove profile PINs';

  @override
  String get radioEmptyHint => 'Add radio stations in settings.';

  @override
  String get radioStations => 'Stations';

  @override
  String radioStationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stations',
      one: '1 station',
    );
    return '$_temp0';
  }

  @override
  String get radioStreamUnavailable =>
      'Radio stream unavailable for this station';

  @override
  String get livePreviousCategory => 'Previous category';

  @override
  String get liveNextCategory => 'Next category';

  @override
  String get liveGuideUnavailable => 'Guide unavailable';

  @override
  String get liveNoPrograms => 'No programs available';

  @override
  String get liveNoUpcomingPrograms => 'No upcoming programs';

  @override
  String get liveNoDescription => 'No summary available.';

  @override
  String get recommendationSubscriptionChanged =>
      'The subscription changed. Please start again.';

  @override
  String get recommendationCannotFavorite =>
      'This content cannot be added to favorites.';

  @override
  String get recommendationFavoriteFailed =>
      'Could not add this content to favorites.';

  @override
  String get recommendationMovieQuestion => 'Do you own this movie?';

  @override
  String get recommendationSeriesQuestion => 'Do you own this series?';

  @override
  String get recommendationMovieSeen => 'Movie already watched';

  @override
  String get recommendationSeriesSeen => 'Series already watched';

  @override
  String get recommendationRemovedFuture => 'Removed from future suggestions';

  @override
  String get recommendationNotInterested => 'Not interested';

  @override
  String get recommendationExcluded => 'Permanently excluded from suggestions';

  @override
  String get recommendationFavoriteProfile =>
      'Added to the current profile’s favorites';

  @override
  String get startupParsingPlaylist => 'Analyzing the M3U playlist…';

  @override
  String get startupProviderSlow =>
      'The provider is responding slowly (a security check may be in progress). Please wait…';

  @override
  String get startupLoadingRemaining => 'Loading radio and replay';

  @override
  String get startupLoadingInitial =>
      'Loading live channels, movies, series and the TV guide';

  @override
  String get startupCheckingSubscription => 'The subscription check';

  @override
  String get startupRefresh => 'The refresh';

  @override
  String startupStalled(String step, int seconds) {
    return '$step has reported no progress for $seconds seconds. The server may be slow or unavailable.';
  }

  @override
  String startupRefreshStalled(String step, int seconds) {
    return '$step has reported no progress for $seconds seconds. The server may be slow or unavailable; you can check your subscription.';
  }

  @override
  String get startupMovies => 'Movies & VOD';

  @override
  String get startupLive => 'Live channels';

  @override
  String get startupReady => 'Ready!';

  @override
  String get startupBackHome => 'Back to home';

  @override
  String get startupCheckSubscription => 'Check subscription';

  @override
  String get browseRankings => 'Rankings';

  @override
  String get browsePopularRankings => 'Popular rankings';

  @override
  String get browseRankingsUnavailableHint =>
      'TMDB trends are unavailable. Add a TMDB API key in Settings (or TMDB_API_KEY in assets/config/runtime.env).';

  @override
  String get browseTmdbData => 'Data © TMDB';

  @override
  String get browsePopular => 'Popular';

  @override
  String get browseNowPlaying => 'Now playing';

  @override
  String get browseTopRated => 'Top rated';

  @override
  String get browseUpcoming => 'Upcoming';

  @override
  String get browseTrendingWeek => 'Trending this week';

  @override
  String get browseOnTheAir => 'On the air';

  @override
  String get browseAiringToday => 'Airing today';

  @override
  String get browseSeriesType => 'Series';

  @override
  String get browseSynopsis => 'Synopsis';

  @override
  String get browseNotInSubscription =>
      'This title is not in your active subscription. Discover it on a platform listed by TMDB.';

  @override
  String get browseExploreCategories => 'Explore by category';

  @override
  String get browseFavoriteHint => 'Long-press an item to find it here.';

  @override
  String get browseRecentHint => 'Your watched content will appear here.';

  @override
  String get browseSearchEmpty => 'No content matches this search.';

  @override
  String browseTitlesCount(int visible, int total) {
    return '$visible titles (out of $total)';
  }

  @override
  String get catalogSearchMovies => 'Search for a movie or genre…';

  @override
  String get catalogSearchSeries => 'Search for a series or genre…';

  @override
  String get catalogLoading =>
      'Loading the catalog…\nPlease wait a few seconds.';

  @override
  String get catalogNoMovies => 'The movie library is currently empty.';

  @override
  String get catalogNoSeries => 'The series library is currently empty.';

  @override
  String get catalogNoRecentMovies => 'No recent movies';

  @override
  String get catalogNoRecentSeries => 'No recent series';

  @override
  String get catalogNoResults => 'No results';

  @override
  String get catalogNoMoviesInCategory => 'No movies in this category';

  @override
  String get catalogMovieFavoriteHint =>
      'Select a movie\'s heart to find it here.';

  @override
  String get catalogSeriesFavoriteHint =>
      'Select a series\' heart to find it here.';

  @override
  String get catalogRecentMoviesHint => 'Movies you watch will appear here.';

  @override
  String get catalogRecentSeriesHint => 'Series you watch will appear here.';

  @override
  String get catalogMovieSearchEmpty => 'No movies match this search.';

  @override
  String get catalogSeriesSearchEmpty => 'No series match this search.';

  @override
  String get catalogMovieCategoryEmpty => 'No movies match this category.';

  @override
  String removedFromFavorites(String title) {
    return '\"$title\" removed from favorites';
  }

  @override
  String get liveBackToChannels => 'Back to channels';

  @override
  String get liveAddSourceHint => 'Add a channel source in settings.';

  @override
  String get liveNoChannelFound => 'No channels found';

  @override
  String get liveNoRecentChannel => 'No recent channels';

  @override
  String get liveNoChannelInGroup => 'No channels in this group';

  @override
  String get liveTryAnotherSearch => 'Try another search term.';

  @override
  String get liveFavoriteHint => 'Select a channel\'s heart to find it here.';

  @override
  String get liveRecentHint => 'Channels you watch will appear here.';

  @override
  String get liveEmptyGroupHint => 'This group has no channels.';

  @override
  String get liveLoadingHint =>
      'Loading channels…\nPlease wait before starting a stream.';

  @override
  String get replayNoChannels =>
      'No channels in this subscription report catch-up availability.';

  @override
  String get replayEmptyGroup => 'This group has no channels with replay.';

  @override
  String get epgLoadingBanner =>
      'Loading the TV guide… programs will appear shortly.';

  @override
  String get epgNoChannelsInCategory => 'No channels in this category';

  @override
  String get epgLoadingChannels => 'Loading channels…';

  @override
  String get epgChannelsLoadFailed => 'Could not load channels.';

  @override
  String get replayToday => 'Today';

  @override
  String get replayYesterday => 'Yesterday';

  @override
  String searchWithinHint(String type) {
    return 'Search in $type…';
  }

  @override
  String get searchAllHint => 'Search Live TV, Movies, Series, Replay, Guide…';

  @override
  String get searchHint => 'Search…';

  @override
  String searchWithinTitle(String type) {
    return 'Search in $type';
  }

  @override
  String get searchUnifiedTitle => 'Unified search';

  @override
  String searchWithinHelp(String type) {
    return 'Type to search only in $type.';
  }

  @override
  String get searchUnifiedHelp =>
      'Search for live channels, movies, series, replays or TV programs.';

  @override
  String get searchOffline => 'Offline mode — local results only';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get searchNoResultsHelp =>
      'Try different terms or check the spelling.';

  @override
  String get searchAllCategories => 'All';

  @override
  String get searchClearHistory => 'Clear history';

  @override
  String get settingsPlaybackEngines => 'Playback engines';

  @override
  String get settingsCloudAccount => 'Cloud account';

  @override
  String get settingsCloudSignIn => 'Sign in with Google or email';

  @override
  String get settingsSyncUnavailable => 'Full synchronization unavailable';

  @override
  String get settingsSyncUnavailableHelp =>
      'The old unencrypted synchronization is disabled. Profile records can be saved manually from Cloud account; other data is not synchronized.';

  @override
  String get settingsSystemAutomatic => 'Automatic (System)';

  @override
  String get settingsSubtitleDefault => 'Default subtitles';

  @override
  String get settingsSubtitleForced => 'Forced subtitles';

  @override
  String get settingsSubtitleOff => 'Subtitles off';

  @override
  String get settingsSubtitleMoviesSeries => 'Movie and series subtitles';

  @override
  String get settingsSubtitles => 'Subtitles';

  @override
  String get settingsProtectedPlayback => 'Protected playback';

  @override
  String get settingsCategoryFilters => 'Category filters';

  @override
  String get settingsCategoryFiltersHelp => 'Hidden categories by subscription';

  @override
  String get episodeSelectProfile => 'Select a profile to modify this episode.';

  @override
  String get episodeProfileChanged => 'The profile changed. Please try again.';

  @override
  String get episodeStatusFailed => 'Could not change this episode\'s status.';

  @override
  String get episodeResetQuestion => 'Reset episode?';

  @override
  String get episodeMarkWatchedQuestion => 'Mark as watched?';

  @override
  String episodeResetProgressMessage(String title) {
    return '\"$title\" will be marked as unwatched and its playback progress will be cleared.';
  }

  @override
  String episodeMarkUnwatchedMessage(String title) {
    return '\"$title\" will be marked as unwatched for this profile.';
  }

  @override
  String episodeMarkWatchedMessage(String title) {
    return '\"$title\" will be marked as watched for this profile.';
  }

  @override
  String get episodeMarkUnwatched => 'Mark as unwatched';

  @override
  String get detailAiData => 'AI-generated data';

  @override
  String detailSourceData(String source) {
    return '$source data';
  }

  @override
  String get detailUnavailableValue => 'Unavailable';

  @override
  String get detailKeywords => 'Keywords';

  @override
  String get detailGenres => 'Genres';

  @override
  String get detailCast => 'Cast';

  @override
  String get detailTrailerFailed => 'Could not open the trailer';

  @override
  String get detailShowCrew => 'Show crew';

  @override
  String get detailHideCrew => 'Hide crew';

  @override
  String seriesRuntimePerEpisode(int minutes) {
    return '$minutes min/episode';
  }

  @override
  String seriesNetwork(String network) {
    return 'Network: $network';
  }

  @override
  String seriesFirstAired(String date) {
    return 'First aired: $date';
  }

  @override
  String seriesSeasonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seasons',
      one: '1 season',
    );
    return '$_temp0';
  }

  @override
  String get profileDiscardHelp =>
      'Unsaved changes will be lost. Leave anyway?';

  @override
  String get profileLeave => 'Leave';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileAvatarTheme => 'Avatar theme';

  @override
  String get profileAvatarThemeHelp =>
      'Choose a style, then an avatar from the grid';

  @override
  String get profileAvatars => 'Avatars';

  @override
  String profileCurrentTheme(String theme) {
    return 'Current theme: $theme';
  }

  @override
  String get profileRequired => 'Required';

  @override
  String get profileFavoriteMovieGenres => 'Favorite movie genres';

  @override
  String get profileGenresHelp =>
      'Choose one or more styles for recommendations';

  @override
  String get profilePinMismatch => 'The PINs do not match.';

  @override
  String get profilePinCreateFailed => 'Could not create the PIN.';

  @override
  String get profilePinActive => 'A 4-digit PIN is active';

  @override
  String get profilePinPending =>
      'PIN confirmed. Save the profile to activate it.';

  @override
  String get profilePinRequest => 'Ask for a PIN when selecting the profile';

  @override
  String get profilePinCreating => 'Creating PIN…';

  @override
  String get profileNotFound => 'No profile to edit';

  @override
  String get profileSaveActivate => 'Save and enable protection';

  @override
  String get profileCreateActivate => 'Create profile and enable protection';

  @override
  String get profileSaveAction => 'Save';

  @override
  String get profileCreateAction => 'Create profile';

  @override
  String get genreAction => 'Action';

  @override
  String get genreAdventure => 'Adventure';

  @override
  String get genreAnimation => 'Animation';

  @override
  String get genreComedy => 'Comedy';

  @override
  String get genreRomanticComedy => 'Romantic comedy';

  @override
  String get genreDrama => 'Drama';

  @override
  String get genreHorror => 'Horror';

  @override
  String get genreThriller => 'Thriller';

  @override
  String get genreDetective => 'Detective';

  @override
  String get genreCrime => 'Crime';

  @override
  String get genreWar => 'War';

  @override
  String get genreHistorical => 'Historical';

  @override
  String get genreWestern => 'Western';

  @override
  String get genreSciFi => 'Sci-fi';

  @override
  String get genreFantasy => 'Fantasy';

  @override
  String get genreSuperheroes => 'Superheroes';

  @override
  String get genreMystery => 'Mystery';

  @override
  String get genreRomance => 'Romance';

  @override
  String get genreMusical => 'Musical';

  @override
  String get genreMusic => 'Music';

  @override
  String get genreBiopic => 'Biopic';

  @override
  String get genreDocumentary => 'Documentary';

  @override
  String get genreTournament => 'Tournament';

  @override
  String get genreChildren => 'Children';

  @override
  String get genreFamily => 'Family';

  @override
  String get genreSuspense => 'Suspense';

  @override
  String get genreBlackWhite => 'Black & white';

  @override
  String get genreClassic => 'Classic';

  @override
  String get cloudConfirm => 'Confirm';

  @override
  String get cloudShareProfilesTitle => 'Share these profiles?';

  @override
  String cloudDuplicateProfileId(String id) {
    return 'Same name — ID: $id';
  }

  @override
  String get cloudShareProfilesHelp =>
      'Missing profiles will be added without replacing existing ones. Their favorites and activity will be shared, along with preferences and subscriptions, including IPTV credentials. This data is encrypted.\n\nProfiles with the same name remain separate. If data differs, you will choose which to keep.';

  @override
  String get cloudChooseSourceTitle => 'Choose a source in case of conflict';

  @override
  String get cloudChooseSourceHelp =>
      'Different additions will be combined on both devices. If the same data has changed on both sides, the source chosen here will be kept and sent to the other device. This choice applies to all initial conflicts.';

  @override
  String get cloudSourceLocal => 'Use this device as the source';

  @override
  String get cloudSourceRemote => 'Use the cloud as the source';

  @override
  String get cloudResetTitle => 'Start over in the cloud?';

  @override
  String get cloudResetHelp =>
      'All profiles and their shared data will be deleted from the cloud. Local profiles will be kept. Other devices will need to enter the new code. This action cannot be undone.';

  @override
  String get cloudNewCode => 'New code';

  @override
  String get cloudConfirmCode => 'Confirm code';

  @override
  String get cloudResetCodeError =>
      'Enter a new code of 3 to 10 digits and confirm it exactly.';

  @override
  String get cloudRestoreTitle => 'Recover this profile?';

  @override
  String cloudRestoreHelp(String name) {
    return 'The profile for $name will be added without replacing local profiles. Favorites, history, subscriptions and preferences will not be restored.';
  }

  @override
  String cloudDeleteTitle(String name) {
    return 'Delete $name from the cloud?';
  }

  @override
  String get cloudDeleteHelp =>
      'The profile and its synchronized data will be deleted from the cloud. The local profile on this device will not be deleted. Other devices will be paused and must refresh their list.';

  @override
  String get cloudSyncFinished => 'Synchronization complete';

  @override
  String get cloudSyncFinishedHelp =>
      'The selected profiles and their data have been synchronized with the cloud.';

  @override
  String get cloudResolveTitle => 'Resolve conflict?';

  @override
  String get cloudResolveLocalHelp =>
      'For conflicting items in this category, this device’s version will be kept. The other version, including any deletion, will be overwritten.';

  @override
  String get cloudResolveRemoteHelp =>
      'For conflicting items in this category, the cloud version will be kept. The other version, including any deletion, will be overwritten.';

  @override
  String get cloudProfilesTitle => 'My profiles on my devices';

  @override
  String get cloudSignInToContinue => 'Sign in to a cloud account to continue.';

  @override
  String get cloudFirebaseUnavailable =>
      'Firebase is not available on this device.';

  @override
  String get cloudGoogleCanceled =>
      'Google sign-in was canceled or failed. If the problem persists, check this app’s Google configuration.';

  @override
  String get cloudGoogleConfiguration =>
      'Incorrect Google configuration: check the OAuth client and this app’s signature.';

  @override
  String get cloudGoogleUnavailable =>
      'Google sign-in is unavailable on this device.';

  @override
  String get cloudSignInUnavailable =>
      'The sign-in service is unavailable on this device.';

  @override
  String get cloudSignInRetry => 'Could not sign in. Try again.';

  @override
  String get cloudInvalidEmail => 'Invalid email address.';

  @override
  String get cloudWeakPassword => 'The password is too weak.';

  @override
  String get cloudEmailInUse => 'This email address is already in use.';

  @override
  String get cloudInvalidCredentials => 'Incorrect email address or password.';

  @override
  String get cloudNetworkUnavailable => 'Network connection unavailable.';

  @override
  String get cloudTooManyAttempts => 'Too many attempts. Try again later.';

  @override
  String get cloudMethodDisabled => 'This sign-in method is not enabled.';

  @override
  String get cloudGoogleAlreadyLinked =>
      'This account is already linked to Google.';

  @override
  String get cloudGoogleOtherAccount =>
      'This Google account is already associated with another Firebase account. No accounts or data were merged. To use the other account, sign out and then sign in with Google.';

  @override
  String get cloudFirebaseSignInFailed =>
      'Could not sign in. Try again or check the Firebase configuration.';

  @override
  String get cloudAccountIntro =>
      'Sign in to access your profiles and their data on your devices. Your data is encrypted.';

  @override
  String get cloudAccountLinkHelp =>
      'If an account is already signed in, Google will be linked to it without changing its ID. Separate accounts are not merged.';

  @override
  String get cloudAccountStateError => 'Could not read the account status.';

  @override
  String get cloudAccountChecking => 'Checking account…';

  @override
  String get cloudAccountNone => 'No cloud account signed in.';

  @override
  String get cloudPairingCleanupFailed =>
      'Account linked, but cleanup of the temporary session failed.';

  @override
  String get cloudPairTv => 'Pair a TV using a QR code';

  @override
  String get pairSignOutFirst =>
      'Sign out of the cloud account before pairing.';

  @override
  String get pairScannerAccountChanged =>
      'The cloud account changed. Close this screen and start again.';

  @override
  String get pairScannerAccountCheckFailed =>
      'Could not verify the cloud account.';

  @override
  String get pairScannerCameraFailed => 'Could not use the camera.';

  @override
  String get pairScannerInvalidQr =>
      'This QR code does not match an Orbit 3D session.';

  @override
  String get pairScannerAssociationFailed =>
      'Pairing failed. Check your network or create a new QR code on the TV.';

  @override
  String get pairScannerTitle => 'Pair a TV';

  @override
  String get pairScannerSent =>
      'Request sent. Confirm the account shown on the TV.';

  @override
  String get pairScannerCameraPermission =>
      'Camera unavailable. Allow access in settings.';

  @override
  String get pairScannerCompareCode =>
      'Compare this code with the one shown on the TV:';

  @override
  String get pairScannerVerifyWarning =>
      'Only accept if both codes match and you control the TV.';

  @override
  String pairScannerSelectedProfiles(String profiles) {
    return 'The TV will automatically select: $profiles.';
  }

  @override
  String get pairScannerConfirm => 'Confirm and pair';

  @override
  String get pairScannerRescan => 'Scan again';

  @override
  String get pairTemporaryUnavailable =>
      'The temporary session is unavailable.';

  @override
  String get pairCleanupIncomplete =>
      'Cleanup incomplete: the session will expire automatically.';

  @override
  String get pairCleanupFailed =>
      'Cleanup failed: the session will expire automatically.';

  @override
  String get pairUnavailable =>
      'Pairing unavailable. Check the network and Firebase configuration.';

  @override
  String get pairRestart => 'Start pairing again.';

  @override
  String get pairTvTitle => 'Link this TV';

  @override
  String get pairInstructions =>
      'On the signed-in phone, open encrypted sync and scan this QR code. Compare the displayed codes before confirming.';

  @override
  String get pairCreateQr => 'Create a QR code';

  @override
  String pairVerificationCode(String code) {
    return 'Verification code: $code';
  }

  @override
  String get pairExpires => 'The QR code expires after five minutes.';

  @override
  String pairAccount(String account) {
    return 'Account to link: $account';
  }

  @override
  String get pairConfirmAccount => 'Confirm this account';

  @override
  String get pairWaiting => 'Waiting for confirmation on the phone…';

  @override
  String get cloudTemporaryAccount =>
      'A temporary account is signed in on this device.';

  @override
  String cloudAccountConnected(String account) {
    return 'Signed-in account: $account';
  }

  @override
  String get cloudRecoverProfiles => 'Find my profiles on my devices';

  @override
  String get cloudEmail => 'Email address';

  @override
  String get cloudSignIn => 'Sign in';

  @override
  String get cloudCreateAccount => 'Create an account';

  @override
  String get cloudResetEmailSent =>
      'If the account exists, a reset email may be sent.';

  @override
  String get cloudForgotPassword => 'Forgot password';

  @override
  String get cloudGoogleLinked => 'Google account already linked';

  @override
  String get cloudSignInWithGoogle => 'Sign in with Google';

  @override
  String get cloudLinkGoogle => 'Link a Google account';

  @override
  String get cloudSignOut => 'Sign out';

  @override
  String get cloudPrepareCodeHelp =>
      'An adult prepares the code. Then choose the profiles to share.';

  @override
  String get cloudChooseProfilesHelp =>
      'Select the profiles you want on your devices, then press Share.';

  @override
  String get cloudFirstSyncHelp =>
      'The first update may take more than 10 minutes. Keep Orbit open until it finishes.';

  @override
  String get cloudLegacyPhrase => 'Secret phrase (legacy format)';

  @override
  String get cloudAdultCode => 'Code provided by an adult';

  @override
  String get cloudSamePhraseHelp => 'Enter the same phrase on both devices.';

  @override
  String get cloudSameCodeHelp => 'Enter the same code on both devices.';

  @override
  String get cloudShowPhrase => 'Show secret phrase';

  @override
  String get cloudHidePhrase => 'Hide secret phrase';

  @override
  String get cloudShowCode => 'Show cloud code';

  @override
  String get cloudHideCode => 'Hide cloud code';

  @override
  String get cloudSeeProfiles => 'View my profiles';

  @override
  String get cloudRefreshList => 'Refresh list';

  @override
  String get cloudAdultOptions => 'Options for an adult';

  @override
  String get cloudUseLegacyPhrase => 'Use an old secret phrase';

  @override
  String get cloudResetAction => 'Delete all cloud data and start over';

  @override
  String get cloudShareBeforePairing =>
      'First share the selected profiles to make them available on the TV.';

  @override
  String get cloudConfirmYourCode => 'Confirm your code';

  @override
  String get cloudBackupTitle => 'Back up this profile?';

  @override
  String cloudConfirmProfilesHelp(String name) {
    return 'Confirm your code for profiles $name. Keep it safe: without it, you will no longer be able to recover your data.';
  }

  @override
  String cloudBackupHelp(String name) {
    return 'Only $name\'s profile will be backed up, encrypted. Favorites, history, subscriptions and preferences are not included. Losing the secret makes the backup impossible to recover.';
  }

  @override
  String get cloudConfirmPhrase => 'Confirm the secret phrase';

  @override
  String get cloudConfirmCloudCode => 'Confirm the cloud code';

  @override
  String get cloudShowConfirmation => 'Show confirmation';

  @override
  String get cloudHideConfirmation => 'Hide confirmation';

  @override
  String get cloudSecretsMismatch => 'The secrets do not match.';

  @override
  String get cloudSyncProfileTitle => 'Synchronize this profile?';

  @override
  String get cloudSyncProfileHelp =>
      'The active profile, video and radio favorites, recent history, watched episodes and playback positions, as well as preferences and subscriptions, will be synchronized in encrypted form during this session. IPTV credentials are included. The active subscription remains selected on each device.';

  @override
  String get cloudUpdating => 'Updating…';

  @override
  String get cloudAdultMustChoose => 'An adult must choose which data to keep.';

  @override
  String get cloudSharingEnabled => 'Sharing is enabled.';

  @override
  String get cloudKeepOpen =>
      'This may take more than 10 minutes. Keep Orbit open.';

  @override
  String get cloudAutoSharing => 'Changes are shared automatically.';

  @override
  String get cloudConflictHelp =>
      'This device and the other device disagree. Ask an adult to choose the correct version.';

  @override
  String get cloudKeepLocal => 'Keep data from this device';

  @override
  String get cloudKeepRemote => 'Keep data from the other device';

  @override
  String get cloudShareSettings => 'Sharing settings (adult)';

  @override
  String get cloudUpdateNow => 'Update now';

  @override
  String get cloudPause => 'Pause';

  @override
  String get cloudSelectProfiles => 'Choose profiles to share';

  @override
  String get cloudWhichProfiles =>
      'Which profiles do you want on your devices?';

  @override
  String get cloudLocalProfilesUnavailable => 'Local profiles are unavailable.';

  @override
  String get cloudUnselectAll => 'Deselect all';

  @override
  String get cloudSelectAll => 'Select all';

  @override
  String get cloudShareSelected => 'Share selected profiles';

  @override
  String get cloudShareAll => 'Share all profiles';

  @override
  String get cloudProfilesToAdd => 'Profiles to add';

  @override
  String get cloudOtherOptions => 'Other options (adult)';

  @override
  String get cloudShareActiveOnly => 'Share only the active profile';

  @override
  String get cloudLocalProfileKept => 'The local profile is kept.';

  @override
  String get cloudRecover => 'Recover';

  @override
  String get cloudDeleteAction => 'Delete from cloud';

  @override
  String get cloudBackupAction => 'Back up';

  @override
  String get cloudScopeFavorites => 'favorites';

  @override
  String get cloudScopeRadioFavorites => 'radio favorites';

  @override
  String get cloudScopeRecents => 'recent history';

  @override
  String get cloudScopeWatched => 'watched episodes';

  @override
  String get cloudScopePlayback => 'playback positions';

  @override
  String get cloudScopePreferences => 'general preferences';

  @override
  String get cloudScopeProfile => 'profile details';

  @override
  String get cloudProfileFallback => 'profile';

  @override
  String get cloudScopeSubscriptions => 'subscriptions';

  @override
  String get cloudScopeData => 'data';

  @override
  String cloudProgressPercent(int percent) {
    return 'Completed: $percent%';
  }

  @override
  String cloudProgressScope(String scope) {
    return 'Currently: $scope.';
  }

  @override
  String cloudProgressProfile(String scope, String profile) {
    return 'Currently: $scope — $profile.';
  }

  @override
  String cloudConflictProfile(String name, String id) {
    return 'Conflicting profile: $name ($id)';
  }

  @override
  String cloudConflictData(String scope) {
    return 'Data: $scope';
  }

  @override
  String get cloudChangedElsewhere =>
      'The cloud changed elsewhere. Reload before trying again.';

  @override
  String get cloudBadPhrase =>
      'Incorrect secret phrase or corrupted cloud data.';

  @override
  String get cloudBadCode => 'Incorrect cloud code or corrupted cloud data.';

  @override
  String get cloudAccessFailed =>
      'Cannot access the cloud. Check the network and Firebase configuration.';

  @override
  String get cloudInvalidData =>
      'Cloud data is invalid or incompatible; nothing was restored.';

  @override
  String get cloudOperationFailed =>
      'Operation failed. Check the network and refresh the cloud.';

  @override
  String get cloudAskAdult => 'Ask an adult for the code.';

  @override
  String get cloudCodeLength => 'The code must contain 3 to 10 digits.';

  @override
  String get cloudAccountChanged =>
      'The account or secret changed. Start again.';

  @override
  String get cloudPhraseChanged =>
      'The account or phrase changed. Start again.';

  @override
  String get cloudBackupRefreshed => 'Profile saved. Catalog refreshed.';

  @override
  String get cloudAccessEmpty => 'Access confirmed. No profiles saved.';

  @override
  String get cloudCodeUnverified =>
      'No backup found: your code cannot yet be verified.';

  @override
  String get cloudAccessChoose => 'Access confirmed. Choose profiles to share.';

  @override
  String get cloudBackupRefreshFailed =>
      'Profile saved, but the catalog could not be refreshed.';

  @override
  String get cloudPhoneProfilesMissing =>
      'The profiles selected on the phone are no longer available. Refresh the list and select them again.';

  @override
  String get cloudPhoneProfilesReceived =>
      'Profiles received from the phone. Starting sharing…';

  @override
  String get cloudProfileRestored =>
      'Profile recovered. Select it in the app, then return here to enable synchronization.';

  @override
  String get cloudWaitDelete =>
      'Wait for synchronization to finish before deleting.';

  @override
  String get cloudWaitReset =>
      'Wait for synchronization to finish before resetting.';

  @override
  String get cloudResetComplete =>
      'Cloud reset. The new code is active; local profiles were kept.';

  @override
  String get cloudWaitSelection =>
      'Synchronization is in progress. Wait for it to finish before changing the selection.';

  @override
  String get cloudProfilesChanged => 'Profiles changed. Check your selection.';

  @override
  String get cloudRestoredProfileMissing =>
      'A recovered profile could not be found. Try again.';

  @override
  String cloudRestoringProfiles(int current, int total) {
    return 'Recovering profiles: $current / $total.';
  }

  @override
  String get cloudCheckingProfiles => 'Checking and saving cloud profiles.';

  @override
  String get cloudPartialRestore =>
      'Some profiles may have been recovered. Check the list before trying again.';

  @override
  String get cloudStartingSync => 'Starting synchronization.';

  @override
  String get cloudProfilesBackedUp => 'Profiles have been saved.';

  @override
  String get subscriptionTitle => 'Subscriptions';

  @override
  String get subscriptionRefreshSuccess =>
      'Update complete: at least one source was refreshed.';

  @override
  String get subscriptionRefreshFailed => 'Update failed: no data received.';

  @override
  String get subscriptionConnectionHelp =>
      'Connection failed or credentials were rejected. Check the server address, username, password and Internet connection.';

  @override
  String get subscriptionDuplicateHelp =>
      'Possible duplicate: several subscriptions have the same configuration. None were deleted; their favorites may differ.';

  @override
  String get subscriptionRefreshActive =>
      'Force update of the active subscription';

  @override
  String get subscriptionActivationFailed =>
      'Could not activate the subscription.';

  @override
  String get subscriptionDeleteTitle => 'Delete subscription?';

  @override
  String subscriptionDeleteHelp(String name) {
    return 'Delete “$name”? This action cannot be undone.';
  }

  @override
  String get subscriptionNoActive =>
      'No active subscription. Select one or add a new one.';

  @override
  String get subscriptionActivate => 'Activate';

  @override
  String get subscriptionNone => 'No subscriptions';

  @override
  String get subscriptionEmptyHelp =>
      'Add your first Xtream Codes or M3U subscription to get started.';

  @override
  String get subscriptionFilterHelp =>
      'Choose categories to hide in Settings > Advanced settings > Category filters.';

  @override
  String get subscriptionPossibleDuplicate => 'Possible duplicate';

  @override
  String get subscriptionInactive => 'Inactive';

  @override
  String get subscriptionTesting => 'Testing…';

  @override
  String get subscriptionUntested => 'Not tested';

  @override
  String get subscriptionTestOk => 'Test OK';

  @override
  String subscriptionTestLatency(int latency) {
    return 'Test OK • $latency ms';
  }

  @override
  String get subscriptionTestFailed => 'Failed';

  @override
  String get subscriptionTestAction => 'Test';

  @override
  String get subscriptionIncomplete => 'Incomplete configuration';

  @override
  String get connectionInvalidConfiguration =>
      'The settings for this subscription are missing or invalid.';

  @override
  String get connectionCheckServerOrPlaylist =>
      'Check the server or playlist URL.';

  @override
  String get connectionCheckCredentials =>
      'Also check the username and password.';

  @override
  String get connectionCertificateExpired => 'SSL certificate expired';

  @override
  String get connectionSslError => 'SSL/TLS error';

  @override
  String get connectionCertificateExpiredHelp =>
      'The server’s security certificate has expired.';

  @override
  String get connectionSslHelp =>
      'A secure connection to the server could not be established.';

  @override
  String get connectionCheckDateTime => 'Check your device’s date and time.';

  @override
  String get connectionContactProvider =>
      'Contact your provider if the problem persists.';

  @override
  String get connectionDnsFailure => 'Server not found (DNS)';

  @override
  String get connectionDnsFailureHelp =>
      'Could not find the server. Check its address and your Internet connection.';

  @override
  String get connectionNetworkUnavailable => 'Network unreachable';

  @override
  String get connectionNetworkUnavailableHelp =>
      'Could not reach the server’s network. Check your Internet connection.';

  @override
  String get connectionServerError => 'Server temporarily unavailable';

  @override
  String get connectionServerUnreachable => 'Server unreachable';

  @override
  String get connectionServerUnreachableHelp =>
      'Could not reach the server. Check the address and your Internet connection.';

  @override
  String get connectionCheckUrl => 'Check the URL for typing errors.';

  @override
  String get connectionTryAnotherNetwork => 'Try another network.';

  @override
  String get connectionContactUnreachableProvider =>
      'Contact your provider if the server remains unreachable.';

  @override
  String get connectionTimeout => 'Connection timed out';

  @override
  String get connectionTimeoutHelp =>
      'The server did not respond in time. It may be slow or temporarily overloaded.';

  @override
  String get connectionTryLater => 'Try again in a few minutes.';

  @override
  String get connectionCheckInternet => 'Check your Internet connection.';

  @override
  String get connectionInvalidCredentials => 'Invalid credentials';

  @override
  String get connectionAccessDenied => 'Access denied';

  @override
  String get connectionXtreamRejected =>
      'The server rejected the Xtream username or password.';

  @override
  String get connectionM3uAuthorization =>
      'The M3U playlist requires authorization or a valid URL.';

  @override
  String get connectionCheckCredentialsCase =>
      'Check the username and password, including capitalization.';

  @override
  String get connectionConfirmCredentials =>
      'Ask your provider to confirm the login details.';

  @override
  String get connectionAccountUnavailable =>
      'Subscription or account unavailable';

  @override
  String get connectionAccountUnavailableHelp =>
      'The account may have expired, been disabled, or reached its connection limit.';

  @override
  String get connectionCheckSubscription =>
      'Check the subscription status with your provider.';

  @override
  String get connectionCloseOtherDevices =>
      'Close connections on other devices and try again.';

  @override
  String get connectionForbidden => 'Access forbidden';

  @override
  String get connectionForbiddenHelp =>
      'The server refused the connection. The account or IP address may be blocked.';

  @override
  String get connectionCheckActiveSubscription =>
      'Check that the subscription is still active.';

  @override
  String get connectionCheckProviderAccess =>
      'Contact your provider to check access.';

  @override
  String get connectionNotFound => 'Address not found (404)';

  @override
  String get connectionInvalidRequest => 'Invalid request';

  @override
  String get connectionInvalidAddress =>
      'The server address or endpoint appears incorrect.';

  @override
  String get connectionCheckBaseUrl => 'Check the server base URL or M3U URL.';

  @override
  String get connectionUseXtreamPanel =>
      'Use the Xtream panel address without adding player_api.php.';

  @override
  String connectionServerUnavailable(int status) {
    return 'Server temporarily unavailable ($status)';
  }

  @override
  String get connectionServerProblem =>
      'The provider’s server is experiencing a problem.';

  @override
  String get connectionInvalidPlaylist => 'Invalid or empty M3U playlist';

  @override
  String get connectionInvalidPlaylistHelp =>
      'The playlist contains no readable data in the expected format.';

  @override
  String get connectionCheckPlaylistUrl =>
      'Check that the URL points to an up-to-date M3U playlist.';

  @override
  String get connectionRequestNewUrl => 'Ask your provider for a new URL.';

  @override
  String get connectionTestFailed => 'Connection test failed';

  @override
  String get connectionUnexpectedError =>
      'An unexpected error prevented connection to this subscription.';

  @override
  String get connectionCheckSubscriptionAndInternet =>
      'Check the subscription details and your Internet connection.';

  @override
  String get connectionRetryOrContact =>
      'Try again or contact your provider if the problem persists.';

  @override
  String get connectionThingsToCheck => 'Things to check';

  @override
  String get connectionTechnicalDetails => 'Technical details';

  @override
  String subscriptionSemantic(String name) {
    return 'Subscription $name';
  }

  @override
  String get subscriptionSemanticActive => 'active';

  @override
  String get subscriptionSemanticDuplicate => 'possible duplicate';

  @override
  String get subscriptionAdded => 'Subscription added';

  @override
  String subscriptionAddedHelp(String name) {
    return '“$name” has been saved. You can test the connection and then activate the subscription.';
  }

  @override
  String get subscriptionTestRunning => 'Testing connection…';

  @override
  String get subscriptionTestSuccess => 'Connection test successful.';

  @override
  String get subscriptionTestUnavailable => 'The test result is unavailable.';

  @override
  String get subscriptionTestError => 'Could not complete the connection test.';

  @override
  String get subscriptionEditTitle => 'Edit subscription';

  @override
  String get subscriptionNewTitle => 'New subscription';

  @override
  String get subscriptionName => 'Subscription name';

  @override
  String get subscriptionUsername => 'Username';

  @override
  String get subscriptionPassword => 'Password';

  @override
  String get subscriptionShowPassword => 'Show password';

  @override
  String get subscriptionHidePassword => 'Hide password';

  @override
  String get subscriptionAdd => 'Add';

  @override
  String get playerExternalOpened => 'Playback opened in an external player';

  @override
  String get playerExternalTrackHelp =>
      'Choose audio tracks and subtitles in the external player: Orbit’s preferences are not passed to it.';

  @override
  String get playerProviderBlocked =>
      'Stream temporarily blocked by the provider';

  @override
  String get playerStreamNotStarting =>
      'The stream is being received but playback is not starting. The track may be too demanding for this device.';

  @override
  String get playerStreamFrozen =>
      'The stream is being received but playback is frozen.';

  @override
  String get playerStreamRecovering =>
      'The stream has stopped progressing. Attempting to recover…';

  @override
  String playerCooldown(int seconds) {
    return 'Protected server (anti-leech), retry in ${seconds}s';
  }

  @override
  String get playerProviderBlockedHelp =>
      'Playback was stopped by the server’s anti-leech protection. Wait 3 to 5 minutes without playback, then restart this channel without changing channels.';

  @override
  String get playerLiveUnavailable => 'Stream unavailable';

  @override
  String get playerLiveUnavailableHelp =>
      'Unable to start this channel. Check your subscription or try again.';

  @override
  String playerNextEpisode(String title) {
    return 'Next episode: $title';
  }

  @override
  String playerNextEpisodeCountdown(String title, int seconds) {
    return 'Next episode: $title ($seconds s)';
  }

  @override
  String get profileSelectToContinue => 'Select a profile to continue';

  @override
  String get profileCreateToWatch =>
      'Create your first profile to start watching.';

  @override
  String get profileNavigationHelp =>
      'Arrows + OK to navigate · Tap a card to select';

  @override
  String get profileActive => 'Active';

  @override
  String get resumeAction => 'Resume';

  @override
  String get refreshRecommendations => 'Refresh recommendations';

  @override
  String get localVideoProxy => 'Experimental local video proxy';

  @override
  String get localVideoProxySubtitle =>
      'For movies and series in the internal player, with a limited disk cache.';

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
  String get deleteDownload => 'Delete';

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
    return 'Last sync (this installation): $time';
  }

  @override
  String get cloudSyncNow => 'Sync now';

  @override
  String get cloudSyncNowSubtitle =>
      'Sync favorites, history, and playback progress from this installation';

  @override
  String get cloudSyncSubtitleOff =>
      'Sync favorites, watched episodes, recents, and playback progress for this installation';

  @override
  String get cloudflareReset => 'Reset Cloudflare config';

  @override
  String get cloudflareResetSubtitle =>
      'Disables TLS impersonation and restores the player\'s standard User-Agent';

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
  String currentProfileLabel(String name) {
    return 'Current profile: $name';
  }

  @override
  String get dataAlreadyFresh => 'Data already up to date (less than 8 hours)';

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
  String downloadAdded(String title) {
    return '“$title” added to downloads';
  }

  @override
  String get downloadCompleted => 'Downloaded';

  @override
  String get downloadInProgress => 'Download in progress';

  @override
  String get downloadOffline => 'Download for offline use';

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
  String get noneOption => 'None';

  @override
  String get play => 'Play';

  @override
  String get newAnd4K => 'Movies on Demand';

  @override
  String get seasonsAndEpisodes => 'Series on Demand';

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
  String get moreResults => 'Show more results';

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
  String get noGroupAffinity => 'No shared affinity found';

  @override
  String get noHistory => 'No history';

  @override
  String get historyLoading => 'Loading history…';

  @override
  String get historyEmptyHint => 'Your recent viewing will appear here.';

  @override
  String get refreshAction => 'Refresh';

  @override
  String get favoritesAdd => 'Add to favorites';

  @override
  String get favoritesRemove => 'Remove from favorites';

  @override
  String get favoritesNeedScope =>
      'An active profile and subscription are required.';

  @override
  String get favoritesReplayHint =>
      'Tap the heart on a replay to find it here.';

  @override
  String favoritesClearPrompt(int total) {
    return 'Remove the $total saved favorites? The favorites list will be cleared.';
  }

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
  String get noRecommendations => 'No recommendations available';

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
  String get pinRequired => 'PIN required';

  @override
  String get pinSet => 'Set a PIN';

  @override
  String get pinThisProfile => 'this profile';

  @override
  String pinEnterForProfile(String name) {
    return 'Enter the PIN for $name';
  }

  @override
  String get pinConfirmFourDigits => 'Confirm your 4-digit code';

  @override
  String get pinChooseFourDigits => 'Choose a 4-digit code';

  @override
  String get pinVerifyFailed => 'Could not verify the PIN.';

  @override
  String get pinConfirmInstruction => 'After 4 digits, press ✓ to confirm.';

  @override
  String pinIncorrectAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts remaining',
      one: '1 attempt remaining',
    );
    return 'Incorrect code — $_temp0';
  }

  @override
  String get pinChecking => 'Checking…';

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
  String profilesSelected(int count) {
    return '$count profiles selected';
  }

  @override
  String get profileVisible => 'Visible profile';

  @override
  String get programGrid => 'Program guide';

  @override
  String get protectWithPin => 'Protect with PIN';

  @override
  String get rankingsUnavailable => 'Rankings unavailable';

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
  String get tmdbMovieRecommendations => 'TMDB recommendations';

  @override
  String get tmdbRecommendationsEmpty =>
      'No TMDB recommendations for this movie.';

  @override
  String get tmdbRecommendationsError => 'Could not load TMDB recommendations.';

  @override
  String get tmdbRecommendationsUnavailable =>
      'TMDB recommendations are unavailable for this movie.';

  @override
  String get playbackDelayedTitle => 'Playback is taking too long';

  @override
  String get playbackDelayedMessage =>
      'Playback has not started or resumed. The stream, connection or video format may be responsible.';

  @override
  String get playbackContinueWaiting => 'Keep waiting';

  @override
  String get playbackUnavailableTitle => 'Playback unavailable';

  @override
  String get playbackUnavailableMessage =>
      'This movie or episode cannot be played right now. Retry or check the connection and file format.';

  @override
  String get protectedPlaybackUnsupportedMessage =>
      'The built-in player cannot safely play this DASH or relayed stream with protected headers.';

  @override
  String get greenScreenDetectedTitle => 'Video display problem detected';

  @override
  String get externalPlayerLimitationsTitle => 'External player limitations';

  @override
  String get externalPlayerLimitationsDescription =>
      'Orbit does not pass its audio and subtitle preferences to VLC or MX Player: select tracks in the external player. For series, the next episode starts automatically only when MX Player confirms playback has ended; otherwise, start it manually after returning to Orbit. This also applies to the fallback player.';

  @override
  String get actorShowFilmography => 'View filmography';

  @override
  String get actorFilmographyUnavailable => 'Filmography unavailable.';

  @override
  String get actorCreditFilm => 'Film';

  @override
  String get actorCreditSeries => 'Series';

  @override
  String actorCreditRole(String role) {
    return 'Role: $role';
  }

  @override
  String get actorCreditTmdbUnavailable => 'TMDB details unavailable.';

  @override
  String get actorCreditSynopsisUnavailable => 'Synopsis unavailable.';

  @override
  String get actorCreditCatalogUnconfirmed =>
      'No confirmed match in the catalog.';

  @override
  String get actorCreditOpenCatalog => 'View in catalog';

  @override
  String get greenScreenDetectedMessage =>
      'A video display problem (green screen) was detected. The current player may not decode this stream correctly. Try another player in Settings > Player > Playback engines, then restart playback.';

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
  String selectAtLeastOneProfile(int count) {
    return 'Select at least 1 additional profile ($count/4)';
  }

  @override
  String get selectProfileForRecommendations =>
      'Select a profile to see its recommendations';

  @override
  String get series => 'Series';

  @override
  String get seriesNotFound => 'Series not found';

  @override
  String get seriesMissingId =>
      'Series ID is missing (incorrect navigation). Return to the list and try again.';

  @override
  String get seriesEnriching => 'Enriching metadata…';

  @override
  String get seriesLoading => 'Loading series…';

  @override
  String get seriesNoEpisodesHint => 'This series has no episodes yet.';

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
  String get sortAffinity => 'By affinity';

  @override
  String get sortAffinityDescription =>
      'Ranks by your declared profile tastes (matchmaking)';

  @override
  String get sortAscending => 'Ascending order';

  @override
  String get sortByDuration => 'By duration';

  @override
  String get sortByRating => 'By rating';

  @override
  String get sortByYear => 'By year';

  @override
  String get sortDescending => 'Descending order';

  @override
  String get sortLatestM3UXtream => 'Latest M3U/Xtream additions';

  @override
  String get sortNameAToZ => 'Name (A → Z)';

  @override
  String get sortNameZToA => 'Name (Z → A)';

  @override
  String get sortResumePriority => 'Resume first';

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
  String get tmdbKeyValid => 'TMDB key is valid';

  @override
  String get tmdbKeyValidationFailed =>
      'TMDB rejected the key or the network is unavailable: check the key';

  @override
  String get tvChannels => 'TV Channels';

  @override
  String get unableToBuildReplayUrl => 'Unable to build the replay URL.';

  @override
  String get unlockCloudflare => 'Unlock (Cloudflare)';

  @override
  String get cloudflareCheckRequired => 'Provider verification required';

  @override
  String get cloudflareChallengeHelp =>
      'The provider is asking for a Cloudflare check. Complete it in this window, close it, then retry. This page\'s cookies are not sent to the player, so playback may remain blocked.';

  @override
  String get openProviderWebsite => 'Open provider website';

  @override
  String get providerWebsiteUnavailable =>
      'Could not open the provider website. Check the subscription address and try again.';

  @override
  String get unstableConnection => 'Unstable connection';

  @override
  String get updateAllData => 'Update all data';

  @override
  String get aiTopicsTitle => 'AI Recommended Topics';

  @override
  String get updateThisCategory => 'Update this category';

  @override
  String get updating => 'Updating…';

  @override
  String get updatingMediaContent => 'Updating media content…';

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

  @override
  String get subtitleSection => 'Subtitles';

  @override
  String get seriesDefaultAudioLanguage => 'Default audio language';

  @override
  String get seriesDefaultSubtitleLanguage => 'Default subtitle language';

  @override
  String get seriesSelectLanguage => 'Select a language';

  @override
  String get seriesStreamDefault => '(Stream default)';

  @override
  String get seriesChooseLanguageFirst => 'Choose a language first';

  @override
  String get seriesDefaultAllEpisodes =>
      'Use the stream default for all episodes';

  @override
  String get seriesDefaultUnlessEpisodeChoice =>
      'Use the stream default unless chosen per episode';

  @override
  String get seriesForceLanguageAllEpisodes =>
      'Force this language for all episodes';

  @override
  String get seriesApplyIfAvailable => 'Apply if available';

  @override
  String get seriesSearchingAudio => 'Looking for audio tracks…';

  @override
  String get seriesSubtitlesDisabled => '(Disabled)';

  @override
  String get seriesDisableSubtitlesAll => 'Disable subtitles for all episodes';

  @override
  String get seriesDisableSubtitlesDefault => 'Disable subtitles by default';

  @override
  String get seriesSearchingSubtitles => 'Looking for subtitle tracks…';

  @override
  String get seriesNoSubtitleTracks =>
      'No tracks detected: choose a language and it will be used if available.';

  @override
  String get seriesLanguageFrench => 'French';

  @override
  String get seriesLanguageEnglish => 'English';

  @override
  String get seriesLanguageSpanish => 'Spanish';

  @override
  String get seriesLanguageGerman => 'German';

  @override
  String get seriesLanguageItalian => 'Italian';

  @override
  String get seriesLanguageArabic => 'Arabic';

  @override
  String get subtitleEmbeddedSection => 'Embedded subtitles';

  @override
  String get subtitleForcedLabel => 'Forced';

  @override
  String get subtitleEmbeddedLabel => 'Embedded';

  @override
  String get audioSection => 'Audio';

  @override
  String get videoSection => 'Video';

  @override
  String get autoQuality => 'Automatic';

  @override
  String get subtitleNotApplicable => 'Not applicable';

  @override
  String get subtitleNotApplicableInfo =>
      'A live stream publishes no subtitle track.';

  @override
  String get subtitleUnavailable => 'Unavailable';

  @override
  String get subtitleNoTrack => 'No track';

  @override
  String get subtitleNoTrackInfo =>
      'The provider publishes no subtitles for this content.';

  @override
  String get subtitleGuessed => 'Guessed tracks';

  @override
  String get subtitleGuessedInfo =>
      'The provider does not declare its subtitles: these tracks are derived from a URL convention. One that does not exist reports an error when activated.';

  @override
  String get subtitleUnavailableToast => 'Subtitle unavailable';

  @override
  String get audioTrackFallback => 'Audio track';

  @override
  String get subtitleLoading => 'Loading subtitles…';

  @override
  String get videoQualityFallback => 'Video quality';

  @override
  String get close => 'Close';

  @override
  String get streamTracksError => 'Could not read this stream\'s tracks.';

  @override
  String get subtitleProviderNoAnswer => 'The provider did not answer.';

  @override
  String subtitleUnavailableDetail(Object reason) {
    return 'Subtitle unavailable: $reason';
  }

  @override
  String get epgNoDataTitle => 'No programme data';

  @override
  String get epgLiveNow => 'Live';

  @override
  String get epgSelectChannelHint => 'Select a channel to see its programme';

  @override
  String get epgNow => 'Now';

  @override
  String get epgZoomIn => 'Zoom in';

  @override
  String get epgZoomOut => 'Zoom out';

  @override
  String get epgNoCurrentProgram => 'No current programme';

  @override
  String replayWindowBadge(Object days) {
    return 'Replay $days d';
  }

  @override
  String replayWindowBadgeHours(Object hours) {
    return 'Replay $hours h';
  }

  @override
  String get replayNoAvailable => 'No replay available';

  @override
  String replayNoneInArchiveDays(Object days) {
    return 'No programme already aired within this account\'s $days-day archive for this channel.';
  }

  @override
  String get replayNonePublished =>
      'The provider publishes no already-aired programme for this channel.';

  @override
  String get epgActionFavorite => 'Favorite';

  @override
  String get epgActionRecording => 'Rec.';

  @override
  String get epgActionReminder => 'Reminder';

  @override
  String get epgStartReplay => 'Start replay';

  @override
  String get epgBack => 'Back';

  @override
  String epgWatchChannel(Object name) {
    return 'Watch $name';
  }

  @override
  String get subtitleNoneServedByPanel =>
      'The provider serves no subtitles for this content.';

  @override
  String subtitleVerifying(Object count) {
    return 'Checking subtitles… ($count)';
  }

  @override
  String get favorites => 'Favorites';

  @override
  String get films => 'Movies';

  @override
  String get replay => 'Replay';

  @override
  String get myContent => 'My content';

  @override
  String get contentTypeSelector => 'Content type';

  @override
  String get downloadStatusDownloading => 'Downloading';

  @override
  String get downloadStatusPreparing => 'Preparing';

  @override
  String get downloadStatusPaused => 'Paused';

  @override
  String get downloadStatusCompleted => 'Completed';

  @override
  String get downloadStatusFailed => 'Failed';

  @override
  String get downloadStatusCancelled => 'Cancelled';

  @override
  String get downloadStatusQueued => 'Queued';

  @override
  String get history => 'History';

  @override
  String get explore => 'Explore';

  @override
  String get downloadsEmptyHint =>
      'Add content from a movie or series detail page.';

  @override
  String get downloadsLocation => 'Files';

  @override
  String get advancedSettingsTitle => 'Advanced settings';

  @override
  String get advancedSettingsIntro =>
      'API credentials and network settings. These settings commit your account to third-party services: a shared key uses up its quota, and a wrong network setting can stop the app from starting.';

  @override
  String get advancedStatus => 'Credential status';

  @override
  String get advancedAccessTitle => 'Restricted access';

  @override
  String get advancedAccessHint => 'Code';

  @override
  String get advancedAccessConfirm => 'Open';

  @override
  String get advancedAccessWrong => 'Wrong code';

  @override
  String get advancedHiddenHint => 'Long press for advanced settings';

  @override
  String get favoritesAndDownloads => 'Favorites & Downloads';

  @override
  String get activeAudio => 'Audio playing on this screen';

  @override
  String get addChannel => 'Add a channel';

  @override
  String get noChannelSelected => 'No channel selected';

  @override
  String get removeChannel => 'Remove channel';

  @override
  String get avatarCategoryAll => 'All';

  @override
  String get avatarCategoryCharacters => 'Characters';

  @override
  String get avatarCategorySuperheroes => 'Superheroes';

  @override
  String get avatarCategoryAnimals => 'Animals';

  @override
  String get avatarCategoryFlowers => 'Flowers';

  @override
  String get avatarCategoryNature => 'Nature';

  @override
  String get avatarCategoryYouth => 'Youth';

  @override
  String get avatarCategorySmileys => 'Smileys';

  @override
  String get avatarCategoryBlackWhite => 'Black & White';

  @override
  String get updateTitle => 'Updates';

  @override
  String get updateSettingsSubtitle =>
      'Check the latest official GitHub release';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String get updateCurrent => 'You already have the latest available version.';

  @override
  String get updateAvailable => 'A new version is available:';

  @override
  String get updateDownloading => 'Downloading and verifying the APK…';

  @override
  String get updateReady => 'Opening the Android installer…';

  @override
  String get updatePermission =>
      'Allow Orbit to install unknown apps in Android settings, then return here and retry.';

  @override
  String get updateNoRelease => 'No stable release is available on GitHub.';

  @override
  String get updateAssetError =>
      'The release does not contain the official universal APK or its verification information.';

  @override
  String get updateInvalidApk =>
      'The APK is incompatible, signed with another key, or does not have a higher Android version. Installation cancelled.';

  @override
  String get updateIntegrityError =>
      'The downloaded file failed verification. Installation cancelled.';

  @override
  String get updateGenericError =>
      'The update failed. Check your connection and retry.';

  @override
  String get updateLater => 'Later';

  @override
  String get updateInstall => 'Update';

  @override
  String get updateRetryInstall => 'Retry installation';

  @override
  String get updateRetry => 'Retry';

  @override
  String get avatarCategoryPixels => 'Pixels';

  @override
  String get unassignedLegacyLibraryItems =>
      'Some older favorites or downloads are hidden because their original subscription is unknown. They are still saved.';

  @override
  String get forceNoSubtitles => 'Force no subtitles';

  @override
  String get forceNoSubtitlesSubtitle =>
      'Automatically disable subtitles when starting a movie or series';

  @override
  String get backTooltip => 'Back';

  @override
  String get categoryFilters => 'Category filters';

  @override
  String get categoryFiltersSubtitle => 'Categories hidden per subscription';

  @override
  String get memoryCacheTitle => 'Memory & cache management';

  @override
  String get memoryCacheSubtitle => 'Free up space and clean up local data.';

  @override
  String get clearWatchHistoryTitle => 'Clear watch history';

  @override
  String get clearWatchHistorySubtitle =>
      'Clears the recently watched list and resume positions.';

  @override
  String get clearWatchHistoryAction => 'Clear';

  @override
  String get clearCoverCacheTitle => 'Clear the cover cache';

  @override
  String get clearCoverCacheSubtitle =>
      'Frees the disk space used by locally stored VOD/EPG thumbnails.';

  @override
  String get clearCoverCacheAction => 'Purge';

  @override
  String get enginesDescription =>
      'Choose the engine used for each content type, and the fallback engine used when playback fails.';

  @override
  String get sortAdvancedTitle => 'Advanced sort options';

  @override
  String get sortAdvancedSubtitle => 'Select a mode with the remote:';

  @override
  String get sortDescRecentlyAdded => 'Content added to the list recently';

  @override
  String get sortDescResumePriority => 'Puts unfinished items at the top';

  @override
  String get sortDescByRating => 'Ranked by the ratings given';

  @override
  String get sortDescByYear => 'Chronological order by release year';

  @override
  String get sortDescByDuration => 'Sorted by content duration';

  @override
  String get sortOptionActive => 'Active';

  @override
  String get showAll => 'Show all';

  @override
  String get noActiveSubscription => 'No active subscription';

  @override
  String get noVodCategories => 'No movie categories on this panel.';

  @override
  String get noSeriesCategories => 'No series categories on this panel.';

  @override
  String get neverScanned => 'Never scanned';

  @override
  String get scannedToday => 'Scanned today';

  @override
  String get scannedYesterday => 'Scanned yesterday';

  @override
  String scannedDaysAgo(int days) {
    return 'Scanned $days days ago';
  }

  @override
  String subscriptionSettingsNote(String scanned) {
    return 'Settings specific to this subscription — $scanned';
  }

  @override
  String get rescanCategories => 'Rescan categories';

  @override
  String get scanningCategories => 'Scanning…';
}
