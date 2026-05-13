class Bank {
  final String id;
  final String name;
  final String description;
  final String state;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bank({
    required this.id,
    required this.name,
    required this.description,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      state: json['state'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'state': state,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class BankAccount {
  final String id;
  final dynamic accountNumber;
  final String accountName;
  final bool isPrimary;
  final String bankId;
  final String userId;
  final String state;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Bank bank;

  BankAccount({
    required this.id,
    required this.accountNumber,
    required this.accountName,
    required this.isPrimary,
    required this.bankId,
    required this.userId,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    required this.bank,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'],
      accountNumber: json['accountNumber'],
      accountName: json['accountName'],
      isPrimary: json['isPrimary'],
      bankId: json['bankId'],
      userId: json['userId'],
      state: json['state'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      bank: Bank.fromJson(json['bank']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'isPrimary': isPrimary,
      'bankId': bankId,
      'userId': userId,
      'state': state,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'bank': bank.toJson(),
    };
  }
}

class ResponseData {
  final String status;
  final List<BankAccount> bankAccounts;

  ResponseData({
    required this.status,
    required this.bankAccounts,
  });

  factory ResponseData.fromJson(Map<String, dynamic> json) {
    var bankAccountsJson = json['data']['bankAccounts'] as List;
    List<BankAccount> bankAccountsList = bankAccountsJson.map((i) => BankAccount.fromJson(i)).toList();

    return ResponseData(
      status: json['status'],
      bankAccounts: bankAccountsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': {
        'bankAccounts': bankAccounts.map((bankAccount) => bankAccount.toJson()).toList(),
      },
    };
  }
}