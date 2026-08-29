import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const OrbitApp(),
    ),
  );
}

enum AgeRating {
  all('Tout public', Colors.green),
  plus10('-10 ans', Colors.blue),
  plus12('-12 ans', Colors.orange),
  plus16('-16 ans', Colors.deepOrange),
  plus18('-18 ans', Colors.red);

  final String label;
  final Color color;
  const AgeRating(this.label, this.color);

  static AgeRating detect(String title, [String? rawRating]) {
    final search = '${title.toLowerCase()} ${rawRating?.toLowerCase() ?? ''}';
    if (search.contains('-18') || search.contains('18+') || search.contains('xxx') || search.contains('adult')) {
      return AgeRating.plus18;
    }
    if (search.contains('-16') || search.contains('16+')) {
      return AgeRating.plus16;
    }
    if (search.contains('-12') || search.contains('12+')) {
      return AgeRating.plus12;
    }
    if (search.contains('-10') || search.contains('10+')) {
      return AgeRating.plus10;
    }
    return AgeRating.all;
  }
}

class Channel {
  final String id;
  final String name;
  final String logo;
  final String streamUrl;
  final String group;
  final AgeRating rating;

  Channel({
    required this.id,
    required this.name,
    required this.logo,
    required this.streamUrl,
    required this.group,
    required this.rating,
  });
}

class AppState extends ChangeNotifier {
  String _activeProfile = 'Principal';
  List<Channel> _allChannels = [];
  String _selectedCategory = 'Toutes';
  bool _isLoading = false;
  String? _errorMessage;

  String get activeProfile => _activeProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final groups = _allChannels.map((c) => c.group).toSet().toList();
    groups.sort();
    return ['Toutes', ...groups];
  }

  List<Channel> get filteredChannels {
    if (_selectedCategory == 'Toutes') return _allChannels;
    return _allChannels.where((c) => c.group == _selectedCategory).toList();
  }

  void setProfile(String profile) {
    _activeProfile = profile;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loginXtream(String server, String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanServer = server.endsWith('/') ? server.substring(0, server.length - 1) : server;
      final url = Uri.parse('$cleanServer/player_api.php?username=$username&password=$password&action=get_live_streams');
      
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _allChannels = data.map((item) {
          final streamId = item['stream_id'];
          final name = item['name'] ?? 'Inconnu';
          final rawRating = item['rating']?.toString();
          return Channel(
            id: streamId?.toString() ?? '',
            name: name,
            logo: item['stream_icon'] ?? '',
            streamUrl: '$cleanServer/live/$username/$password/$streamId.ts',
            group: item['category_name'] ?? 'Général',
            rating: AgeRating.detect(name, rawRating),
          );
        }).toList();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server', server);
        await prefs.setString('username', username);
        await prefs.setString('password', password);
      } else {
        _errorMessage = 'Identifiants ou serveur incorrects.';
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion : $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadM3uUrl(String m3uUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(m3uUrl)).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final lines = const LineSplitter().convert(response.body);
        List<Channel> parsed = [];
        String currentName = '';
        String currentLogo = '';
        String currentGroup = 'Général';

        for (var line in lines) {
          line = line.trim();
          if (line.startsWith('#EXTINF:')) {
            final nameMatch = RegExp(r',(.+)$').firstMatch(line);
            currentName = nameMatch?.group(1) ?? 'Chaîne';
            final logoMatch = RegExp(r'tvg-logo="([^"]+)"').firstMatch(line);
            currentLogo = logoMatch?.group(1) ?? '';
            final groupMatch = RegExp(r'group-title="([^"]+)"').firstMatch(line);
            currentGroup = groupMatch?.group(1) ?? 'Général';
          } else if (line.isNotEmpty && !line.startsWith('#')) {
            parsed.add(Channel(
              id: parsed.length.toString(),
              name: currentName,
              logo: currentLogo,
              streamUrl: line,
              group: currentGroup,
              rating: AgeRating.detect(currentName),
            ));
          }
        }
        _allChannels = parsed;
      } else {
        _errorMessage = 'Impossible de télécharger la liste M3U.';
      }
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement M3U : $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class OrbitApp extends StatelessWidget {
  const OrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbit 3D IPTV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF06B6D4),
        ),
      ),
      home: const ProfileSelectionScreen(),
    );
  }
}

class RatingBadge extends StatelessWidget {
  final AgeRating rating;
  const RatingBadge({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: rating.color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rating.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ProfileSelectionScreen extends StatelessWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tv, size: 80, color: Color(0xFF6366F1)),
            const SizedBox(height: 16),
            const Text(
              'ORBIT 3D IPTV',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProfileCard(context, 'Profil Principal', Icons.person, Colors.indigo),
                const SizedBox(width: 30),
                _buildProfileCard(context, 'Profil Famille', Icons.family_restroom, Colors.teal),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, String title, IconData icon, Color color) {
    return FocusableActionDetector(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return InkWell(
            onTap: () {
              Provider.of<AppState>(context, listen: false).setProfile(title);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 160,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFocused ? Colors.white : color.withOpacity(0.5),
                  width: isFocused ? 3 : 2,
                ),
                boxShadow: isFocused ? [BoxShadow(color: color.withOpacity(0.8), blurRadius: 15)] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, size: 40, color: color),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _serverController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _m3uController = TextEditingController();
  bool _isXtream = true;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Connexion IPTV (${state.activeProfile})')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isXtream ? const Color(0xFF6366F1) : Colors.grey[800],
                        ),
                        onPressed: () => setState(() => _isXtream = true),
                        child: const Text('Xtream Codes'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_isXtream ? const Color(0xFF6366F1) : Colors.grey[800],
                        ),
                        onPressed: () => setState(() => _isXtream = false),
                        child: const Text('Lien M3U'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isXtream) ...[
                  TextField(
                    controller: _serverController,
                    decoration: const InputDecoration(labelText: 'Serveur (ex: http://ex.com:8080)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _userController,
                    decoration: const InputDecoration(labelText: 'Identifiant'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mot de passe'),
                  ),
                ] else ...[
                  TextField(
                    controller: _m3uController,
                    decoration: const InputDecoration(labelText: 'URL de la playlist M3U'),
                  ),
                ],
                const SizedBox(height: 24),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(state.errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                  ),
                state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () async {
                          if (_isXtream) {
                            await state.loginXtream(
                              _serverController.text.trim(),
                              _userController.text.trim(),
                              _passController.text.trim(),
                            );
                          } else {
                            await state.loadM3uUrl(_m3uController.text.trim());
                          }
                          if (state.filteredChannels.isNotEmpty && mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const MainCatalogScreen()),
                            );
                          }
                        },
                        child: const Text('SE CONNECTER'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainCatalogScreen extends StatelessWidget {
  const MainCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final channels = state.filteredChannels;

    return Scaffold(
      appBar: AppBar(
        title: Text('Orbit 3D IPTV (${channels.length} Chaînes)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final cat = state.categories[index];
                final isSelected = cat == state.selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: FocusableActionDetector(
                    child: Builder(
                      builder: (context) {
                        final isFocused = Focus.of(context).hasFocus;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: const Color(0xFF6366F1),
                          side: BorderSide(
                            color: isFocused ? Colors.white : Colors.transparent,
                            width: isFocused ? 2 : 0,
                          ),
                          onSelected: (_) => state.setCategory(cat),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                return TvChannelTile(
                  channel: channel,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlayerScreen(channel: channel),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TvChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;

  const TvChannelTile({super.key, required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFocused ? const Color(0xFF6366F1) : Colors.transparent,
                  width: isFocused ? 3 : 1,
                ),
                boxShadow: isFocused
                    ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.6), blurRadius: 12)]
                    : [],
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: channel.logo.isNotEmpty
                              ? Image.network(
                                  channel.logo,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.tv, size: 40),
                                )
                              : const Icon(Icons.tv, size: 40),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          channel.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
                            color: isFocused ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: RatingBadge(rating: channel.rating),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.channel.streamUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text(widget.channel.name)),
            RatingBadge(rating: widget.channel.rating),
          ],
        ),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}