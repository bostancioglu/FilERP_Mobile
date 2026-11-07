class ElectronicDocumentFilter {
  static const erp = -2;

  static bool matches(int? status, int? filter) =>
      filter == null ||
      (filter == erp ? status != 1 && status != 3 : status == filter);
}
