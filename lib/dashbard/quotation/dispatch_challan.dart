import 'package:flutter/material.dart';

class DispatchChallanScreen extends StatefulWidget {
  const DispatchChallanScreen({super.key});

  @override
  State<DispatchChallanScreen> createState() => _DispatchChallanScreenState();
}

class _DispatchChallanScreenState extends State<DispatchChallanScreen> {
  int dispatchQty = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.local_shipping, color: Colors.blue),
                      SizedBox(width: 85),
                      Text(
                        "Dispatch Challan",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text(
                "Delivery Boy",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _inputField("First name")),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField("Last name")),
                ],
              ),

              const SizedBox(height: 12),
              const Text(
                "Contact Number",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              _inputField("Enter Number..."),

              const SizedBox(height: 12),
              const Text(
                "Vehicle number (tempo)",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              _inputField("MH-15"),

              const SizedBox(height: 14),
              const Text(
                "Items for Dispatch",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: const [
                  CircleAvatar(radius: 4, backgroundColor: Colors.green),
                  SizedBox(width: 6),
                  Text(
                    "In Warehouse: 380 boxes",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Text(
                "Yogesh Tiles",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                "Pending in Quote: Boxes",
                style: TextStyle(color: Colors.red, fontSize: 12,),
              ),

              const SizedBox(height: 12),
              const Text(
                "Dispatch Now",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            dispatchQty.toString().padLeft(2, '0'),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() => dispatchQty++);
                                },
                                child: const Icon(Icons.arrow_drop_up, size: 20),
                              ),
                              InkWell(
                                onTap: () {
                                  if (dispatchQty > 0) {
                                    setState(() => dispatchQty--);
                                  }
                                },
                                child:
                                const Icon(Icons.arrow_drop_down, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Box",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.grey.shade600,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: null,
                        child: const Text("Cancel"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFA9C42),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: () {
                          // TODO: Generate Challan Logic
                        },
                        child: const Text(
                          "Generate Challan",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
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

  Widget _inputField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}