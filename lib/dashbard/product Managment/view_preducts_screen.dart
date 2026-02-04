import 'package:flutter/material.dart';
import 'package:tcs_invantory_managment_system/dashbard/product%20Managment/Product_Management.dart';

class ProductViewScreen extends StatelessWidget {
  const ProductViewScreen({super.key, required Product product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xffFFA54A),
        title: const Text("Product Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Name: Sagar Marbel",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text("Category: Marbel"),
              Text("Brand: Somany"),
              Text("Rate: ₹150"),
            ],
          ),
        ),
      ),
    );
  }
}
