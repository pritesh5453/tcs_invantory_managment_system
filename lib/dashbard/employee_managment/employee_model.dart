class EmployeeModel {
  final int id;
  final String firstName;
  final String lastName;
  final String mobile;
  final String email;
  final String dob;
  final String password;
  final String expense;
  final String salary;
  final String commission;
  final bool isActive;

  EmployeeModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.email,
    required this.dob,
    required this.password,
    required this.expense,
    required this.salary,
    required this.commission,
    required this.isActive,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final nameParts = (json['name'] ?? '').split(' ');

    final int parsedId =
        int.tryParse(json['employee_id']?.toString() ?? '') ??
        int.tryParse(json['id']?.toString() ?? '') ??
        0;

    return EmployeeModel(
      id: parsedId,
      firstName: nameParts.isNotEmpty ? nameParts.first : '',
      lastName:
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      mobile: json['phone'] ?? '',
      email: json['email'] ?? '',
      dob: json['birthdate'] ?? '',
      password: json['password'] ?? '',
      expense: json['expense']?.toString() ?? '0',
      salary: json['salary']?.toString() ?? '0',
      commission: json['commission']?.toString() ?? '0',
      isActive: json['status'] == 'active',
    );
  }
}
