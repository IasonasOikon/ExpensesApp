class UserProfile {
  final String name;
  final String profileImage;
  final double balance;
  final String email;
  final double monthlyBudgetGoal;

  UserProfile({
    required this.name,
    required this.profileImage,
    required this.balance,
    required this.email,
    required this.monthlyBudgetGoal,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      name: data['name'] ?? '',
      profileImage: data['profileImage'] ?? '',
      balance: data['balance']?.toDouble() ?? 0.0,
      email: data['email'] ?? '',
      monthlyBudgetGoal: data['monthlyBudgetGoal']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'profileImage': profileImage,
      'balance': balance,
      'email': email,
      'monthlyBudgetGoal': monthlyBudgetGoal,
    };
  }
}
