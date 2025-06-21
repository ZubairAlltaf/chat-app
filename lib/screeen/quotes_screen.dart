import 'package:flutter/material.dart';
import 'package:my_chat_app/screeen/quote_api_fetch.dart';
import '../model/quotes_model.dart';

class QuotesScreen extends StatefulWidget {
  @override
  _QuotesScreenState createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  late Future<QuotesModel> futureQuotes;

  @override
  void initState() {
    super.initState();
    futureQuotes = fetchQuotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inspirational Quotes"),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5D9CEC), Color(0xFFA8E6CF)], // Softer colors
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE3FDFD), // Light blue
              Color(0xFFFFE6FA), // Soft pinkish purple
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<QuotesModel>(
          future: futureQuotes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.black87),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.quotes!.isEmpty) {
              return const Center(
                child: Text(
                  'No quotes found.',
                  style: TextStyle(color: Colors.black87),
                ),
              );
            } else {
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: snapshot.data!.quotes!.length,
                itemBuilder: (context, index) {
                  var quote = snapshot.data!.quotes![index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white.withOpacity(0.85),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          spreadRadius: 1,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.format_quote, size: 28, color: Colors.blueAccent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '"${quote.quote}"',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "- ${quote.author}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
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
      ),
    );
  }
}
