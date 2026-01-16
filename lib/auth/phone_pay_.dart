// import 'dart:convert';
// import 'dart:developer';
// import 'package:crypto/crypto.dart';
// import 'package:flutter/material.dart';
// import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
// import 'package:http/http.dart' as http;

// class PhonePeSandboxPayment extends StatefulWidget {
//   const PhonePeSandboxPayment({super.key});

//   @override
//   State<PhonePeSandboxPayment> createState() =>
//       _PhonePeSandboxPaymentState();
// }

// class _PhonePeSandboxPaymentState extends State<PhonePeSandboxPayment> {
//   /// 🔹 SANDBOX CONFIG
//   final String environment = "UAT";
//   final String appId = "";
//   final String merchantId = "PGTESTPAYUAT";
//   final String saltKey = "96434309-7796-489d-8924-ab56988a6076";
//   final String saltIndex = "1";

//   final String apiEndPoint = "/pg/v1/pay";
//   final String callbackUrl = "https://webhook.site/";

//   late String transactionId;
//   late String requestBody;
//   late String checksum;

//   String result = "";

//   @override
//   void initState() {
//     super.initState();
//     transactionId =
//         DateTime.now().millisecondsSinceEpoch.toString();
//     _initPhonePe();
//     _prepareRequest();
//   }

//   /// 🔹 INIT SDK
//   Future<void> _initPhonePe() async {
//     await PhonePePaymentSdk.init(
//       environment,
//       appId,
//       merchantId,
//       true,
//     );
//   }

//   /// 🔹 CREATE BODY + CHECKSUM
//   void _prepareRequest() {
//     final data = {
//       "merchantId": merchantId,
//       "merchantTransactionId": transactionId,
//       "merchantUserId": "MUID123",
//       "amount": 100, // ₹1
//       "mobileNumber": "9999999999",
//       "callbackUrl": callbackUrl,
//       "paymentInstrument": {"type": "PAY_PAGE"}
//     };

//     requestBody =
//         base64.encode(utf8.encode(jsonEncode(data)));

//     checksum =
//         "${sha256.convert(utf8.encode(requestBody + apiEndPoint + saltKey))}###$saltIndex";

//     log("Checksum: $checksum");
//   }

//   /// 🔹 START PAYMENT (NEW SDK SIGNATURE)
//   Future<void> startTransaction() async {
//     try {
//       var response = await PhonePePaymentSdk.startTransaction(
//   requestBody,     // base64 body
//   callbackUrl,     // callback URL
//   checksum,        // checksum
//   apiEndPoint,     // "/pg/v1/pay"
// );

//       if (response != null && response['status'] == 'SUCCESS') {
//         await checkStatus();
//       } else {
//         showToast("Payment Failed");
//       }
//     } catch (e) {
//       showToast("Error: $e");
//     }
//   }

//   /// 🔹 CHECK PAYMENT STATUS (SANDBOX)
//   Future<void> checkStatus() async {
//     final url =
//         "https://api-preprod.phonepe.com/apis/pg-sandbox/pg/v1/status/$merchantId/$transactionId";

//     final verify =
//         "${sha256.convert(utf8.encode("/pg/v1/status/$merchantId/$transactionId$saltKey"))}###$saltIndex";

//     final res = await http.get(
//       Uri.parse(url),
//       headers: {
//         "Content-Type": "application/json",
//         "X-VERIFY": verify,
//         "X-MERCHANT-ID": merchantId,
//       },
//     );

//     final data = jsonDecode(res.body);
//     log("STATUS: $data");

//     if (data["code"] == "PAYMENT_SUCCESS") {
//       showToast("Payment Successful 🎉");
//     } else {
//       showToast("Payment Pending / Failed");
//     }
//   }

//   void showToast(String msg) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text(msg)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("PhonePe Sandbox")),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: startTransaction,
//           child: const Text("Pay ₹1 (Sandbox)"),
//         ),
//       ),
//     );
//   }
// }
