import 'package:flutter/material.dart';
import 'package:userapp/main.dart';
import 'package:userapp/tailor_profile.dart';

class SearchTailor extends StatefulWidget {
  const SearchTailor({super.key});

  @override
  _SearchTailorState createState() => _SearchTailorState();
}

class _SearchTailorState extends State<SearchTailor> {
  List<Map<String, dynamic>> tailors = [];
  List<Map<String, dynamic>> filteredTailors = [];
  bool isLoading = true;

  TextEditingController searchController = TextEditingController();

  Future<void> fetchTailor() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch tailors with their average rating from tbl_rating
      final response = await supabase
          .from('tbl_tailor')
          .select('''
            *,
            avg_rating: tbl_rating!tailor_id(
              rating_count
            )
          ''')
          .eq('tailor_status', 1);

      if (mounted) {
        setState(() {
          tailors = List<Map<String, dynamic>>.from(response).map((tailor) {
            // Calculate the average rating for each tailor
            final ratings = tailor['avg_rating'] as List<dynamic>? ?? [];
            double averageRating = 0.0;
            if (ratings.isNotEmpty) {
              final totalRating = ratings.fold<double>(
                  0.0,
                  (sum, rating) =>
                      sum + (rating['rating_count'] as num).toDouble());
              averageRating = totalRating / ratings.length;
            }
            return {
              ...tailor,
              'average_rating': averageRating,
            };
          }).toList();
          filteredTailors = tailors;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading tailors. Please try again.")),
        );
      }
      print("Error fetching tailors: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTailor();
  }

  void _filterTailors(String query) {
    setState(() {
      filteredTailors = tailors
          .where((tailor) =>
              tailor['tailor_name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF6A1B9A); // Deep purple for fashion theme
    final accentColor = Color(0xFFE91E63); // Pink accent

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildCustomAppBar(primaryColor),

            // Main Content
            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : filteredTailors.isEmpty
                      ? _buildEmptyState(primaryColor)
                      : _buildTailorsList(primaryColor, accentColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: primaryColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Text(
                "Find Your Perfect Tailor",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: _filterTailors,
              decoration: InputDecoration(
                hintText: "Search by tailor name...",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          searchController.clear();
                          _filterTailors("");
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF6A1B9A),
          ),
          SizedBox(height: 16),
          Text(
            "Finding tailors near you...",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            "No tailors found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Try adjusting your search or filters",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              searchController.clear();
              setState(() {
                filteredTailors = tailors;
              });
            },
            icon: Icon(Icons.refresh),
            label: Text("Reset Search"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTailorsList(Color primaryColor, Color accentColor) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results count
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "${filteredTailors.length} tailors found",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Tailors List
          Expanded(
            child: ListView.builder(
              itemCount: filteredTailors.length,
              itemBuilder: (context, index) {
                final data = filteredTailors[index];
                // Use the fetched average rating, default to 0.0 if null
                final rating = (data['average_rating'] as double?)?.clamp(0.0, 5.0) ?? 0.0;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TailorProfile(tailor: data['tailor_id']),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tailor Image and Quick Info
                        Row(
                          children: [
                            // Tailor Image
                            Container(
                              width: 100,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                color: Colors.grey.shade200,
                                image: data['tailor_photo'] != null &&
                                        data['tailor_photo'].toString().isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(data['tailor_photo']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: data['tailor_photo'] == null ||
                                      data['tailor_photo'].toString().isEmpty
                                  ? Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.grey.shade400,
                                      ),
                                    )
                                  : null,
                            ),
                            // Tailor Info
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name and Verified Badge
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            data['tailor_name'] ?? "Unknown Tailor",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade800,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.verified,
                                          color: accentColor,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    // Rating
                                    Row(
                                      children: [
                                        ...List.generate(5, (i) {
                                          return Icon(
                                            i < rating.floor()
                                                ? Icons.star
                                                : i == rating.floor() && rating % 1 != 0
                                                    ? Icons.star_half
                                                    : Icons.star_border,
                                            color: Colors.amber,
                                            size: 16,
                                          );
                                        }),
                                        SizedBox(width: 4),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    // Specialization
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.design_services,
                                          color: primaryColor,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            data['specialization'] ?? "Custom Tailoring",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    // Contact
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          color: primaryColor,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          data['tailor_contact'] ?? "No contact",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Implement call functionality
                                  },
                                  icon: Icon(Icons.call, size: 16),
                                  label: Text("Call"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryColor,
                                    side: BorderSide(color: primaryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TailorProfile(tailor: data['tailor_id']),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.visibility, size: 16),
                                  label: Text("View"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}