class OrganizerProfile {
  final String id;
  final String companyName;
  final String city;
  final String? gstNumber;
  final String? billingAddress;

  OrganizerProfile({
    required this.id,
    required this.companyName,
    required this.city,
    this.gstNumber,
    this.billingAddress,
  });

  factory OrganizerProfile.fromSupabase(Map<String, dynamic> map) {
    return OrganizerProfile(
      id: map['id'] as String,
      companyName: map['company_name'] as String? ?? 'Acme Events Pvt Ltd',
      city: map['city'] as String? ?? 'Bengaluru',
      gstNumber: map['gst_number'] as String?,
      billingAddress: map['billing_address'] as String?,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'company_name': companyName,
      'city': city,
      'gst_number': gstNumber,
      'billing_address': billingAddress,
    };
  }
}
