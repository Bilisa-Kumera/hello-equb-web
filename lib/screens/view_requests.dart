import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ViewRequests extends StatefulWidget {
  @override
  _ViewRequestsState createState() => _ViewRequestsState();
}

class _ViewRequestsState extends State<ViewRequests> {
  final Dio _dio = Dio(); // Dio instance
  List<EqubCategory> categories = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      final response = await _dio.get(requestUrl);

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data']['equbCategorys'];
        setState(() {
          categories = data.map((categoryData) {
            return EqubCategory(
              id: categoryData['id'],
              name: categoryData['name'],
              description: categoryData['description'],
              orderId: categoryData['order'],
              createdAt: DateTime.parse(categoryData['createdAt']),
            );
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          textScaleFactor: 1.0,
          'Equb Categories',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: isLoading
          ? Center(
              child: LoadingAnimationWidget.threeRotatingDots(
                color: AppColors.vibrantGreen,
                size: 30,
              ),
            )
          : hasError
              ? const Center(
                  child: Text(
                    textScaleFactor: 1.0,
                    'Failed to load requests',
                    style: TextStyle(color: AppColors.red),
                  ),
                )
              : categories.isEmpty
                  ? const Center(
                      child: Text(
                        textScaleFactor: 1.0,
                        'No requests available',
                        style: TextStyle(color: AppColors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return CategoryCard(category: categories[index]);
                      },
                    ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final EqubCategory category;

  const CategoryCard({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                textScaleFactor: 1.0,
                category.name,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                textScaleFactor: 1.0,
                category.description,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    textScaleFactor: 1.0,
                    'Order ID: ${category.orderId}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: AppColors.black54,
                    ),
                  ),
                  Text(
                    textScaleFactor: 1.0,
                    'Created: ${category.createdAt.toLocal()}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: AppColors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EqubCategory {
  final int id;
  final String name;
  final String description;
  final int orderId;
  final DateTime createdAt;

  EqubCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.orderId,
    required this.createdAt,
  });
}
