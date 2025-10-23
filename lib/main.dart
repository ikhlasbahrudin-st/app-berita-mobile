import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const BeritaApp());
}

class BeritaApp extends StatefulWidget {
  const BeritaApp({super.key});

  @override
  State<BeritaApp> createState() => _BeritaAppState();
}

class _BeritaAppState extends State<BeritaApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeritaApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: BeritaPage(
        toggleTheme: () {
          setState(() {
            _isDarkMode = !_isDarkMode;
          });
        },
        isDarkMode: _isDarkMode,
      ),
    );
  }
}

class BeritaPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const BeritaPage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<BeritaPage> createState() => _BeritaPageState();
}

class _BeritaPageState extends State<BeritaPage> {
  final ApiService apiService = ApiService();
  late Future<List<dynamic>> futureBerita;
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    futureBerita = apiService.fetchNews();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      futureBerita = apiService.fetchNews(query: query);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text(
          'BeritaApp',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () async {
              final query = await showSearch(
                context: context,
                delegate: BeritaSearchDelegate(apiService),
              );
              if (query != null && query.isNotEmpty) {
                _onSearch(query);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Colors.white,
            ),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),

      // ===== BODY =====
      body: FutureBuilder<List<dynamic>>(
        future: futureBerita,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada berita ditemukan.'));
          } else {
            final beritaList = snapshot.data!;
            return ListView.builder(
              itemCount: beritaList.length,
              itemBuilder: (context, index) {
                final berita = beritaList[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 400),
                        pageBuilder: (_, __, ___) =>
                            DetailPage(berita: berita),
                        transitionsBuilder: (_, animation, __, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (berita['urlToImage'] != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: Image.network(
                              berita['urlToImage'],
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 100),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                berita['title'] ?? 'Tanpa Judul',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                berita['description'] ?? '',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),

      // ===== BOTTOM NAV BAR =====
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Hari Ini',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: 'Short',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}

// ==================== Detail Page ====================
class DetailPage extends StatelessWidget {
  final dynamic berita;
  const DetailPage({super.key, required this.berita});

  @override
  Widget build(BuildContext context) {
    final String? url = berita['url'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Berita'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (berita['urlToImage'] != null)
              Image.network(berita['urlToImage'], fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    berita['title'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sumber: ${berita['source']['name'] ?? 'Tidak diketahui'}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    berita['description'] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  if (url != null)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Buka di Browser'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Search Delegate ====================
class BeritaSearchDelegate extends SearchDelegate<String> {
  final ApiService apiService;
  BeritaSearchDelegate(this.apiService);

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          close(context, '');
        },
      );

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: apiService.fetchNews(query: query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final beritaList = snapshot.data!;
        if (beritaList.isEmpty) {
          return const Center(child: Text('Tidak ada berita ditemukan.'));
        }
        return ListView.builder(
          itemCount: beritaList.length,
          itemBuilder: (context, index) {
            final berita = beritaList[index];
            return ListTile(
              title: Text(berita['title'] ?? ''),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailPage(berita: berita),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) =>
      const Center(child: Text('Cari berita berdasarkan topik...'));
}
