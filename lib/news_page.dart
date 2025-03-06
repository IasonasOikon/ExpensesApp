import 'package:expensesappflutter/common/colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<dynamic> articles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNews(); // Fetch news articles on page load
  }

  // Fetch news data from the API and filter out "[Removed]"
  Future<void> fetchNews() async {
    final response = await http.get(Uri.parse(
      'https://newsapi.org/v2/everything?q=personal%20finance&apiKey=4379657efacd4179923f34400f59c55b',
    ));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      List<dynamic> fetchedArticles = jsonResponse['articles'];

      // Filter out articles containing "[Removed]"
      setState(() {
        articles = fetchedArticles
            .where((article) =>
                article['title'] != '[Removed]' &&
                article['description'] != '[Removed]' &&
                article['content'] != '[Removed]' &&
                article['source']['name'] != '[Removed]')
            .toList();
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load news');
    }
  }

  // Uses the url_launcher package, for redirecting to browser within the app
  Future<void> _launchUrl(String url) async {
    final Uri newsUrl = Uri.parse(url);
    if (!await launchUrl(newsUrl)) {
      throw Exception('Could not launch $newsUrl');
    }
  }

  // Converts the `publishedAt` timestamp into readable time difference
  String timeAgo(String publishedAt) {
    DateTime publishedDate = DateTime.parse(publishedAt);
    Duration difference = DateTime.now().difference(publishedDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBase,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: articles.isEmpty
                ? const Center(
                    child: Text(
                    'No articles found.',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w400),
                  ))
                : ListView.builder(
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _launchUrl(articles[index]['url']);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: AppColors.mediumAccent,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Display article image or placeholder
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: articles[index]['urlToImage'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          articles[index]['urlToImage'],
                                          fit: BoxFit.cover,
                                          height: 100,
                                          width: 100,
                                          errorBuilder: (BuildContext context,
                                              Object error,
                                              StackTrace? stackTrace) {
                                            // Show placeholder if the image fails to load
                                            return Container(
                                              height: 100,
                                              width: 100,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                  Icons.image_not_supported),
                                            );
                                          },
                                        ),
                                      )
                                    : Container(
                                        height: 100,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                            Icons.image_not_supported),
                                      ),
                              ),

                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        articles[index]['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppColors.primaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timeAgo(articles[index]['publishedAt']),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.secondaryText,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Custom loading animation
          if (isLoading)
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.mediumAccent,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.lightAccent),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
