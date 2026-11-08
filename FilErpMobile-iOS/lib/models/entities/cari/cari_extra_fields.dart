const cariExtraTextFields = <String, String>{
  'Hesapno': 'Hesap No',
  'Iban': 'IBAN',
  'Bankaaciklama': 'Banka Açıklaması',
  'Efaturaalias': 'E-Fatura Alias',
  'Eirsaliyealias': 'E-İrsaliye Alias',
  'Efaturaiban': 'E-Fatura IBAN',
  'Kosulkodu': 'Koşul Kodu',
  'Vat': 'VAT No',
  'Kurumsalfax': 'Kurumsal Faks',
  'Kurumsalmobil': 'Kurumsal GSM',
  'Kurumsalweb': 'Web Adresi',
  'Kurumsalemail': 'Kurumsal E-Posta',
  'Yetkiliunvan': 'Yetkili Ünvanı',
  'Yetkiliad': 'Yetkili Ad Soyad',
  'Yetkiliemail': 'Yetkili E-Posta',
  'Yetkilitel': 'Yetkili Telefon',
  'Ortakkod': 'Ortak Kod',
  'Muhasebeortakkod': 'Muhasebe Ortak Kodu',
};
const cariExtraIdFields = <String, String>{
  'Bankaid': 'Banka',
  'Bankasubeid': 'Banka Şubesi',
  'Baglicariid': 'Bağlı Cari',
  'Komisyoncucariid': 'Komisyoncu Cari',
  'Hesapplaniid': 'Muhasebe Hesabı',
  'Kurfarkigelirhesapplaniid': 'Kur Farkı Gelir Hesabı',
  'Kurfarkigiderhesapplaniid': 'Kur Farkı Gider Hesabı',
};
const cariExtraBoolFields = <String, String>{
  'Efaturamukkellefi': 'E-Fatura Mükellefi',
  'Eirsaliyemukkellefi': 'E-İrsaliye Mükellefi',
  'Riskkontroluvar': 'Risk Kontrolü',
  'Plasiyerortak': 'Plasiyer Ortak',
  'Ortakkoduvar': 'Ortak Kod Kullan',
};
int? cariInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
Map<String, String> cariSelectionLabels(Map<String, dynamic> json) {
  const navigation = {
    'Bankaid': 'Banka',
    'Bankasubeid': 'Bankasube',
    'Baglicariid': 'Baglicari',
    'Komisyoncucariid': 'Komisyoncucari',
    'Hesapplaniid': 'Hesapplani',
    'Kurfarkigelirhesapplaniid': 'Kurfarkigelirhesapplani',
    'Kurfarkigiderhesapplaniid': 'Kurfarkigiderhesapplani'
  };
  return {
    for (final entry in navigation.entries)
      if (json[entry.value] is Map)
        entry.key: [json[entry.value]['Kod'], json[entry.value]['Ad']]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(' · ')
  };
}
