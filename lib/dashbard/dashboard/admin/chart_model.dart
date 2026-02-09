// chart_models.dart
class ChartDataResponse {
  final bool success;
  final ChartData data;

  ChartDataResponse({
    required this.success,
    required this.data,
  });

  factory ChartDataResponse.fromJson(Map<String, dynamic> json) {
    return ChartDataResponse(
      success: json['success'] ?? false,
      data: ChartData.fromJson(json['data'] ?? {}),
    );
  }
}

class ChartData {
  final List<SalesVsPurchaseData> salesVsPurchase;
  final List<CashFlowData> cashFlow;

  ChartData({
    required this.salesVsPurchase,
    required this.cashFlow,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      salesVsPurchase: List<SalesVsPurchaseData>.from(
        (json['salesVsPurchase'] as List? ?? []).map(
          (item) => SalesVsPurchaseData.fromJson(item),
        ),
      ),
      cashFlow: List<CashFlowData>.from(
        (json['cashFlow'] as List? ?? []).map(
          (item) => CashFlowData.fromJson(item),
        ),
      ),
    );
  }
}

class SalesVsPurchaseData {
  final String month;
  final double purchase;

  SalesVsPurchaseData({
    required this.month,
    required this.purchase,
  });

  factory SalesVsPurchaseData.fromJson(Map<String, dynamic> json) {
    return SalesVsPurchaseData(
      month: json['month']?.toString() ?? '',
      purchase: double.tryParse(json['purchase']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class CashFlowData {
  final String day;
  final double inAmount;
  final double outAmount;

  CashFlowData({
    required this.day,
    required this.inAmount,
    required this.outAmount,
  });

  factory CashFlowData.fromJson(Map<String, dynamic> json) {
    return CashFlowData(
      day: json['day']?.toString() ?? '',
      inAmount: double.tryParse(json['inAmount']?.toString() ?? '0') ?? 0.0,
      outAmount: double.tryParse(json['outAmount']?.toString() ?? '0') ?? 0.0,
    );
  }
}