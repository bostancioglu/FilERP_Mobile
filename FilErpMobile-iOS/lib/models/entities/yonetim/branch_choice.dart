/// Only display metadata is retained; nested company/ERP credentials are omitted.
Map<String, dynamic>? branchChoice(Map row) {
  final branch = row['Sube'] is Map ? row['Sube'] as Map : row;
  final company = branch['Sirket'] is Map ? branch['Sirket'] as Map : const {};
  final id = branch['Id'] ?? row['Subeid'];
  final companyId = branch['Sirketid'] ?? company['Id'];
  if (id is! int || companyId is! int) return null;
  return {
    'Id': id,
    'Ad': branch['Ad'],
    'Kod': branch['Kod'],
    'Sirketid': companyId,
    'Sirket': {'Id': companyId, 'Ad': company['Ad'], 'Kod': company['Kod']}
  };
}
