import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_configue.dart';
import 'user_resort_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _locations = [];
  List<dynamic> _allResorts = [];
  List<dynamic> _filteredResorts = [];

  List<String> _states = [];
  List<String> _cities = [];

  String? _selectedState;
  String? _selectedCity;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final locRes = await http.get(Uri.parse('${ApiConfigue.baseUrl}/api/locations'));
      final resRes = await http.get(Uri.parse('${ApiConfigue.baseUrl}/api/resorts'));

      if (locRes.statusCode == 200 && resRes.statusCode == 200) {
        final locData = json.decode(locRes.body) as List<dynamic>;
        final resData = json.decode(resRes.body) as List<dynamic>;

        final Set<String> stateSet = {};
        for (var loc in locData) {
          if (loc['state'] != null) {
            String stateStr = loc['state'].toString().trim().toLowerCase();
            if (stateStr.isNotEmpty) {
              stateStr = stateStr[0].toUpperCase() + stateStr.substring(1);
              stateSet.add(stateStr);
            }
          }
        }

        setState(() {
          _locations = locData;
          _allResorts = resData;
          _states = stateSet.toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onStateSelected(String? state) {
    if (state == null) return;
    
    final Set<String> citySet = {};
    for (var loc in _locations) {
      if (loc['state'] != null && loc['city'] != null) {
        String locState = loc['state'].toString().trim().toLowerCase();
        if (locState.isNotEmpty) {
           locState = locState[0].toUpperCase() + locState.substring(1);
           if (locState == state) {
             String cityStr = loc['city'].toString().trim().toLowerCase();
             if (cityStr.isNotEmpty) {
               cityStr = cityStr[0].toUpperCase() + cityStr.substring(1);
               citySet.add(cityStr);
             }
           }
        }
      }
    }

    setState(() {
      _selectedState = state;
      _cities = citySet.toList();
      _selectedCity = null; // reset city
      _filteredResorts = [];
    });
  }

  void _onCitySelected(String? city) {
    if (city == null) return;

    final filtered = _allResorts.where((r) {
      final loc = r['location']?.toString().toLowerCase() ?? '';
      return loc.contains(city.toLowerCase());
    }).toList();

    setState(() {
      _selectedCity = city;
      _filteredResorts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Aqua Resorts', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello, Tanvi 👋',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A2B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Find your perfect resort stay',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              icon: Icon(Icons.search, color: Colors.grey),
                              hintText: 'Search resorts, locations...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3E7C59),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.tune, color: Colors.white),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text('Select Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A2B))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedState,
                              hint: const Text('State', style: TextStyle(color: Colors.black87, fontSize: 14)),
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 16),
                              items: _states.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: _onStateSelected,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedCity,
                              hint: const Text('City', style: TextStyle(color: Colors.black87, fontSize: 14)),
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 16),
                              items: _cities.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: _onCitySelected,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (_selectedCity == null) ...[
                    // Banner Placeholder
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFF3E7C59),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1540541338287-41700207dee6?q=80&w=2070&auto=format&fit=crop'), // Placeholder URL
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Select a location above',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'To explore available resorts.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Available Resorts in $_selectedCity',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A2B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_filteredResorts.isEmpty)
                      const Text('No resorts found in this city.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredResorts.length,
                        itemBuilder: (context, index) {
                          final resort = _filteredResorts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserResortDetailsScreen(resortData: resort),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.network(
                                    resort['imageUrl'] ?? 'https://images.unsplash.com/photo-1540541338287-41700207dee6?q=80&w=2070',
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Container(
                                      height: 150,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          resort['name'] ?? 'Resort Name',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                resort['location'] ?? 'Location',
                                                style: const TextStyle(color: Colors.grey),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '\$${resort['price'] ?? 0} / user',
                                              style: const TextStyle(
                                                color: Color(0xFF3E7C59),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                                const SizedBox(width: 4),
                                                Text(
                                                  (resort['rating'] ?? 4.5).toString(),
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}
