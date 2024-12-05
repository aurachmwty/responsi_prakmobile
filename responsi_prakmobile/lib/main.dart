import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nintendo Amiibo List',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    const AmiiboListPage(),
    const FavoritesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favorites'),
        ],
      ),
    );
  }
}

class AmiiboListPage extends StatefulWidget {
  const AmiiboListPage({super.key});

  @override
  _AmiiboListPageState createState() => _AmiiboListPageState();
}

class _AmiiboListPageState extends State<AmiiboListPage> {
  List<dynamic> amiiboList = [];
  Set<String> favoriteIds = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAmiiboList();
    loadFavorites();
  }

  Future<void> fetchAmiiboList() async {
    try {
      final response =
          await http.get(Uri.parse('https://www.amiiboapi.com/api/amiibo'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          amiiboList = data['amiibo'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Error fetching amiibo list: $e");
    }
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteIds = prefs.getStringList('favorites')?.toSet() ?? {};
    });
  }

  Future<void> toggleFavorite(String amiiboId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (favoriteIds.contains(amiiboId)) {
        favoriteIds.remove(amiiboId);
      } else {
        favoriteIds.add(amiiboId);
      }
      prefs.setStringList('favorites', favoriteIds.toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nintendo Amiibo List'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: amiiboList.length,
              itemBuilder: (context, index) {
                final amiibo = amiiboList[index];
                final isFavorite = favoriteIds.contains(amiibo['tail']);
                return ListTile(
                  leading:
                      Image.network(amiibo['image'], width: 50, height: 50),
                  title: Text(amiibo['name']),
                  subtitle: Text('Game Series: ${amiibo['gameSeries']}'),
                  trailing: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    onPressed: () => toggleFavorite(amiibo['tail']),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AmiiboDetailPage(
                          head: amiibo['head'],
                          tail: '',
                          amiibo: null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class AmiiboDetailPage extends StatelessWidget {
  final dynamic amiibo; // Menerima data Amiibo

  const AmiiboDetailPage(
      {Key? key, required this.amiibo, required String tail, required head})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(amiibo['name']),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  backgroundImage: NetworkImage(amiibo['image']),
                  radius: 100,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Name: ${amiibo['name']}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Game Series: ${amiibo['gameSeries']}'),
              const SizedBox(height: 8),
              Text('Type: ${amiibo['type']}'),
              const SizedBox(height: 8),
              Text('Release Date: ${amiibo['release']?['au'] ?? 'N/A'}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Kembali ke halaman sebelumnya
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                child: const Text('Back to List'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Set<String> favoriteIds = {};
  List<dynamic> favoriteAmiibos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final storedFavorites = prefs.getStringList('favorites')?.toSet() ?? {};
    setState(() {
      favoriteIds = storedFavorites;
    });

    await fetchFavoriteAmiibos();
  }

  Future<void> fetchFavoriteAmiibos() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response =
          await http.get(Uri.parse('https://www.amiiboapi.com/api/amiibo'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          favoriteAmiibos = data['amiibo']
              .where((amiibo) => favoriteIds.contains(amiibo['tail']))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching favorite Amiibos: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> removeFavorite(String amiiboId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteIds.remove(amiiboId);
      prefs.setStringList('favorites', favoriteIds.toList());
      favoriteAmiibos = favoriteAmiibos
          .where((amiibo) => amiibo['tail'] != amiiboId)
          .toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$amiiboId removed from favorites'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteAmiibos.isEmpty
              ? const Center(
                  child: Text('No favorites added yet!'),
                )
              : ListView.builder(
                  itemCount: favoriteAmiibos.length,
                  itemBuilder: (context, index) {
                    final amiibo = favoriteAmiibos[index];
                    return Dismissible(
                      key: Key(amiibo['tail']),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        removeFavorite(amiibo['tail']);
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        leading: Image.network(
                          amiibo['image'],
                          width: 50,
                          height: 50,
                        ),
                        title: Text('${amiibo['name']} - ${amiibo['type']}'),
                        subtitle: Text(amiibo['tail']),
                      ),
                    );
                  },
                ),
    );
  }
}
