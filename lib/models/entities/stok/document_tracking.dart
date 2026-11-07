enum TrackingDocument {
  salesInvoice(1, 301, 'Fatura', 'SatisFaturasi'),
  purchaseInvoice(2, 302, 'FaturaAlis', 'AlisFaturasi'),
  salesWaybill(3, 501, 'Irsaliye', 'SatisIrsaliyesi'),
  purchaseWaybill(4, 502, 'IrsaliyeAlis', 'AlisIrsaliyesi');

  final int type, module;
  final String controller, saveRoute;
  const TrackingDocument(
      this.type, this.module, this.controller, this.saveRoute);
  bool get incoming => type == 2 || type == 4;
  String get fullRoute => type < 3 ? 'FaturaFull' : 'IrsaliyeFull';
}

class TrackingLine {
  final TrackingDocument document;
  final String? documentId, lineId, addressId, direction;
  final int? stockId, warehouseId, featureId;
  final double quantity, multiplier;
  const TrackingLine(
      {required this.document,
      required this.documentId,
      required this.lineId,
      required this.stockId,
      this.warehouseId,
      this.addressId,
      this.featureId,
      this.direction,
      required this.quantity,
      required this.multiplier});
  bool get incoming =>
      direction == 'G' || (direction != 'C' && document.incoming);
  bool get saved =>
      documentId != null &&
      documentId!.isNotEmpty &&
      (int.tryParse(lineId ?? '') ?? 0) > 0;
}

class TrackingChoice {
  final int id;
  final int? partyId;
  final String label;
  final DateTime? expiry;
  final double balance;
  const TrackingChoice(
      {required this.id,
      this.partyId,
      required this.label,
      this.expiry,
      this.balance = 0});
  factory TrackingChoice.fromJson(Map<String, dynamic> j,
          {required bool serial}) =>
      TrackingChoice(
          id: j['Id'] as int,
          partyId: serial ? j['Partiid'] as int? : j['Id'] as int,
          label: (j[serial ? 'Numara' : 'Kod'] ?? j['Id']).toString(),
          expiry: DateTime.tryParse(j['Sonkullanmatarihi']?.toString() ?? ''),
          balance: (j['KesinBakiyeTemel'] as num?)?.toDouble() ?? 0);
}

class TrackingDetail {
  final String id;
  final int? partyId, serialId;
  final double quantity;
  final int status;
  final DateTime? expiry;
  const TrackingDetail(
      {required this.id,
      this.partyId,
      this.serialId,
      required this.quantity,
      required this.status,
      this.expiry});
  factory TrackingDetail.fromJson(Map<String, dynamic> j) => TrackingDetail(
      id: j['Id'].toString(),
      partyId: j['Partiid'] as int?,
      serialId: j['Seriid'] as int?,
      quantity: (j['Miktar'] as num?)?.toDouble() ??
          ((j['Miktartemel'] as num?)?.toDouble() ?? 0) *
              ((j['Olcubrcarpim'] as num?)?.toDouble() ?? 1),
      status: j['Kayitdurumu'] as int? ?? 2,
      expiry: DateTime.tryParse(j['Sonkullanmatarihi']?.toString() ?? ''));
}

class TrackingSelection {
  final int mode;
  final List<TrackingChoice> parties, serials;
  const TrackingSelection(
      {required this.mode, required this.parties, required this.serials});
  factory TrackingSelection.fromJson(Map<String, dynamic> j) =>
      TrackingSelection(
          mode: j['TakipModu'] as int? ?? 0,
          parties: (j['Partiler'] as List? ?? [])
              .map((e) => TrackingChoice.fromJson(Map<String, dynamic>.from(e),
                  serial: false))
              .toList(),
          serials: (j['Seriler'] as List? ?? [])
              .map((e) => TrackingChoice.fromJson(Map<String, dynamic>.from(e),
                  serial: true))
              .toList());
}
