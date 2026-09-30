package io.flutter.plugins.videoplayer;

import android.net.Uri;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.media3.datasource.DataSource;
import androidx.media3.datasource.DataSpec;
import androidx.media3.datasource.TransferListener;
import java.io.IOException;

/**
 * Enveloppe un {@link DataSource} pour journaliser l'echange HTTP reel.
 *
 * Expose ce qu'aucun log Dart ne montre : l'URL FINALE apres redirection
 * (donc la cible CDN reelle) et le volume d'octets effectivement lus dans le
 * temps. Un ecran fige avec position a 0 se distingue immediatement d'un
 * flux bloque a la redirection d'un flux ouvert mais sans donnees.
 */
final class LoggingDataSource implements DataSource {
  private static final String TAG = "OrbitHttp";

  /** Nombre max d'ouvertures pour une meme demande (401 inclus). */
  private static final int MAX_ATTEMPTS = 4;

  /**
   * Espacement minimal entre deux ouvertures apres un SUCCES. Assez court pour
   * ne pas penaliser un MKV (ExoPlayer ouvre le fichier plusieurs fois : tete,
   * puis la fin pour les cues), assez long pour eviter deux sockets dans la
   * meme milliseconde.
   */
  private static final long MIN_GAP_MS = 200L;

  /** Delais avant nouvelle tentative apres un refus. */
  private static final long[] BACKOFF_MS = {3000L, 8000L, 20000L};

  private final DataSource delegate;
  private long bytesRead;
  private int lastLoggedBucket;

  LoggingDataSource(DataSource delegate) {
    this.delegate = delegate;
  }

  @Override
  public void addTransferListener(TransferListener transferListener) {
    delegate.addTransferListener(transferListener);
  }

  @Override
  public long open(DataSpec dataSpec) throws IOException {
    bytesRead = 0L;
    lastLoggedBucket = 0;
    // Le CDN en aval du 302 est anti-leech : il refuse une part importante des
    // requetes, et la duree du refus croft avec le volume de requetes. Mesure
    // sur draap.online : 4 requetes quasi simultanees en boucle => 0 % de
    // reussite, contre ~50 % en requete isolee. On espace donc les tentatives
    // et on retente ici : l'echec remonte a Dart comme "Source error" generique,
    // sans le code HTTP, donc l'arbitrage doit se faire natif.
    for (int attempt = 0; ; attempt++) {
      awaitCooldown();
      try {
        Log.i(
            TAG,
            "OPEN(try "
                + (attempt + 1)
                + ") uri="
                + dataSpec.uri
                + " position="
                + dataSpec.position
                + " length="
                + dataSpec.length);
        long length = delegate.open(dataSpec);
        Log.i(TAG, "  OK finalUri=" + delegate.getUri() + " length=" + length);
        resetCooldown();
        return length;
      } catch (IOException e) {
        if (isRateLimited(e) && attempt < MAX_ATTEMPTS - 1) {
          long backoff = BACKOFF_MS[Math.min(attempt, BACKOFF_MS.length - 1)];
          Log.w(TAG, "  401 throttle, retry in " + backoff + "ms");
          // Le refus etant anti-leech, on bloque aussi les AUTRES controleurs
          // pendant ce delai : sans cela ils epuisent eux aussi la fenetre.
          synchronized (OPEN_GATE) {
            nextOpenAllowedAtMs = Math.max(nextOpenAllowedAtMs, System.currentTimeMillis() + backoff);
          }
          sleepMs(backoff);
          continue;
        }
        Log.e(TAG, "  FAILED finalUri=" + delegate.getUri() + " -> " + e);
        throw e;
      }
    }
  }

  /** Vrai si l'exception correspond a un refus HTTP du panneau/CDN. */
  private static boolean isRateLimited(IOException e) {
    final String m = String.valueOf(e.getMessage());
    return m.contains("Response code: 401") || m.contains("Response code: 403");
  }

  /**
   * Serveur global du rythme d'ouverture. Sans lui, plusieurs controleurs
   * (lecture, preload, voisins) ouvrent des sockets dans la meme milliseconde
   * et se sanctionnent mutuellement.
   */
  private static final Object OPEN_GATE = new Object();

  private static long nextOpenAllowedAtMs;

  private static void awaitCooldown() {
    long waitMs;
    synchronized (OPEN_GATE) {
      waitMs = nextOpenAllowedAtMs - System.currentTimeMillis();
    }
    // Sommeil HORS du moniteur : une attente prolongée (jusqu'à 3+8+20=31 s
    // avec la suite de backoff) bloquait tous les autres threads qui voulaient
    // lire/prolonger nextOpenAllowedAtMs, y compris le prolongement du
    // cooldown suite à un nouveau 401 — exactement le comportement qu'on
    // voulait éviter. Le calcul reste atomique sous verrou, pas le sommeil.
    if (waitMs > 0) {
      Log.i(TAG, "  gate: attente " + waitMs + "ms avant ouverture");
      sleepMs(waitMs);
    }
  }

  private static void resetCooldown() {
    synchronized (OPEN_GATE) {
      nextOpenAllowedAtMs = System.currentTimeMillis() + MIN_GAP_MS;
    }
  }

  private static void sleepMs(long ms) {
    try {
      Thread.sleep(ms);
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
    }
  }

  @Override
  public Uri getUri() {
    return delegate.getUri();
  }

  @Nullable
  @Override
  public java.util.Map<String, java.util.List<String>> getResponseHeaders() {
    return delegate.getResponseHeaders();
  }

  @Override
  public int read(byte[] buffer, int offset, int length) throws IOException {
    int n = delegate.read(buffer, offset, length);
    if (n > 0) {
      bytesRead += n;
      // Un log par tranche de 1 Mo : assez pour voir si le flux avance,
      // assez rare pour ne pas noyer logcat (2,5 logs/s à 256 Ko aurait
      // saturé le buffer logcat sur une soirée de lecture).
      int bucket = (int) (bytesRead / (1024 * 1024));
      if (bucket != lastLoggedBucket) {
        lastLoggedBucket = bucket;
        Log.i(TAG, "  READ total=" + bytesRead + "B uri=" + delegate.getUri());
      }
    }
    return n;
  }

  @Override
  public void close() throws IOException {
    Log.i(TAG, "CLOSE totalRead=" + bytesRead + "B uri=" + delegate.getUri());
    delegate.close();
  }

  /**
   * Fabrique produisant des {@link LoggingDataSource} autour d'une source reelle.
   *
   * <p>Le rythme est partage statiquement : tous les controleurs de la page
   * passent par le meme intervalle minimal.
   */
  static final class Factory implements DataSource.Factory {
    private final DataSource.Factory delegate;

    Factory(DataSource.Factory delegate) {
      this.delegate = delegate;
    }

    @NonNull
    @Override
    public DataSource createDataSource() {
      return new LoggingDataSource(delegate.createDataSource());
    }
  }
}
