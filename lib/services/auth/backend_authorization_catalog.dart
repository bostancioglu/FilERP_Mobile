// Generated from local Shared Modules.cs and API HasAuthority attributes.
// Regenerate: python tool/generate_authorization_catalog.py
import 'authorization_session.dart';

class BackendAccessRule {
  final String api, method, pattern;
  final int module;
  final Access access;
  const BackendAccessRule(
      this.api, this.method, this.pattern, this.module, this.access);
}

const backendAccessRules = <BackendAccessRule>[
  BackendAccessRule(
      'ebelge', 'GET', r'^/efatura/dizaynayar$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/addtenantlogo$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/addtenantxslt$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/belge\-iptalred$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/dizaynayar$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/earsivlist\-gelen$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/earsivlist\-giden$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/efaturalist\-gelen$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/efaturalist\-giden$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/efaturastatus\-changed$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/efaturastatus\-giden$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/erpdurumkodu\-esle$', 301, Access.read),
  BackendAccessRule('ebelge', 'POST', r'^/efatura/filexml$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/getcompanyinfo$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/getfileall$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/gettenantxslt$', 301, Access.read),
  BackendAccessRule('ebelge', 'POST', r'^/efatura/preview$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/send\-back\-erp/[^/]+$', 301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/send\-invoice$', 301, Access.read),
  BackendAccessRule('ebelge', 'POST', r'^/efatura/user\-creditcounterinfo$',
      301, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/efatura/user\-creditinfo$', 301, Access.read),
  BackendAccessRule('ebelge', 'POST', r'^/eihracat/eihracatfaturalist\-gelen$',
      1601, Access.read),
  BackendAccessRule('ebelge', 'POST', r'^/eihracat/eihracatfaturalist\-giden$',
      1601, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/eihracat/filexml$', 1601, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/eihracat/getfileall$', 1601, Access.read),
  BackendAccessRule('ebelge', 'POST', r'^/eihracat/ihracatfaturastatus\-giden$',
      1601, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/eihracat/preview$', 1601, Access.read),
  BackendAccessRule('ebelge', 'POST', r'^/eihracat/send\-back\-erp/[^/]+$',
      1601, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/eihracat/send\-ihracatfatura$', 1601, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/eirsaliye/eirsaliyelist\-gelen$', 501, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/eirsaliye/eirsaliyelist\-giden$', 501, Access.read),
  BackendAccessRule('ebelge', 'POST', r'^/eirsaliye/eirsaliyestatus\-giden$',
      501, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/eirsaliye/getfileall$', 501, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/eirsaliye/preview$', 501, Access.read),
  BackendAccessRule('ebelge', 'POST', r'^/eirsaliye/send\-back\-erp/[^/]+$',
      501, Access.read),
  BackendAccessRule(
      'ebelge', 'POST', r'^/eirsaliye/send\-waybill$', 501, Access.read),
  BackendAccessRule('erp', 'DELETE', r'^/ambargc/removewithitems/[^/]+$', 1301,
      Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/ambargchareket/removesingle/[^/]+$',
      1301, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/arac/[^/]+$', 22, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/arayuzmetinsirket/[^/]+$', 30, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/bankahareket/[^/]+$', 1004, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/bankahesap/[^/]+$', 1002, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/belgeseri/[^/]+$', 5, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/cari/[^/]+$', 201, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/cari/cariadres/[^/]+$', 201, Access.update),
  BackendAccessRule(
      'erp', 'DELETE', r'^/cari/carisube/[^/]+$', 201, Access.update),
  BackendAccessRule('erp', 'DELETE', r'^/caridevir/removewithitems/[^/]+$', 206,
      Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/caridevirhareket/[^/]+$', 206, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/caridevirhareket/removesingle/[^/]+$',
      206, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/carikategori/[^/]+$', 205, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/caririsk/[^/]+$', 202, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/cekalinan/removewithitems/[^/]+$',
      1005, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/cekalinanciro/removewithitems/[^/]+$',
      1006, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/cekalinancirohareket/removesingle/[^/]+$', 1006, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/cekalinanhareket/[^/]+$', 1005, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/cekalinanhareket/removesingle/[^/]+$',
      1005, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/cekalinaniade/removewithitems/[^/]+$',
      1010, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/cekalinaniadehareket/[^/]+$', 1010, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/cekalinaniadehareket/removesingle/[^/]+$', 1010, Access.delete),
  BackendAccessRule(
      'erp',
      'DELETE',
      r'^/cekalinanportfoydentahsil/removewithitems/[^/]+$',
      1011,
      Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/cekalinanportfoydentahsilhareket/[^/]+$', 1011, Access.delete),
  BackendAccessRule(
      'erp',
      'DELETE',
      r'^/cekalinanportfoydentahsilhareket/removesingle/[^/]+$',
      1011,
      Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/cekalinanprotesto/removewithitems/[^/]+$', 1009, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/cekalinanprotestohareket/[^/]+$', 1009,
      Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/cekalinanprotestohareket/removesingle/[^/]+$', 1009, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/cekalinantahsil/removewithitems/[^/]+$', 1007, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/cekalinantahsilhareket/[^/]+$', 1007, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/cekalinantahsilhareket/removesingle/[^/]+$', 1007, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/cekverilen/removewithitems/[^/]+$',
      1012, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/cekverilenhareket/[^/]+$', 1012, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/cekverilenhareket/removesingle/[^/]+$',
      1012, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/cekverilenhareketdagilim/[^/]+$', 1032,
      Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/cekverileniade/removewithitems/[^/]+$',
      1014, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/cekverileniadehareket/[^/]+$', 1014, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/cekverileniadehareket/removesingle/[^/]+$', 1014, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/cekverilenodeme/removewithitems/[^/]+$', 1013, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/cekverilenodemehareket/[^/]+$', 1013, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/cekverilenodemehareket/removesingle/[^/]+$', 1013, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/dat/removewithitems/[^/]+$', 801, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/dathareket/removesingle/[^/]+$', 801, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/depoadres/[^/]+$', 9, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/depotanim/[^/]+$', 8, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/dosyabelge/[^/]+$', 1201, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/dysdosya/[^/]+$', 1102, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/dysdosyabelge/[^/]+$', 1102, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/dysdosyatur/[^/]+$', 1104, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/dysklasor/[^/]+$', 1101, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/dyskullanicigrup/[^/]+$', 1105, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/dyskullanicigrupdetay/[^/]+$', 1105, Access.delete),
  BackendAccessRule(
      'erp',
      'DELETE',
      r'^/dyskullanicigrupdetay/removewithkullanici/[^/]+/[^/]+$',
      1105,
      Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/dyskullanicigrupklasoryetki/[^/]+$',
      1103, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/fatura/removewithitems/[^/]+$', 301, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/faturaalis/removewithitems/[^/]+$',
      302, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/faturahareket/removesingle/[^/]+$',
      301, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/faturahareketalis/removesingle/[^/]+$',
      302, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/finansplan/removewithitems/[^/]+$',
      1028, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/finansplankayit/removewithitems/[^/]+$', 1034, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/finansplankayithareket/deletesingle/[^/]+$', 1034, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/finansplankayitverigiris/delete/[^/]+$', 1037, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/firmakredikarti/[^/]+$', 1026, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/giderfisi/removewithitems/[^/]+$',
      1701, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/giderfisihareket/removesingle/[^/]+$',
      1701, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/hesapplani/[^/]+$', 1501, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/irsaliye/removewithitems/[^/]+$', 501,
      Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/irsaliyealis/removewithitems/[^/]+$',
      502, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/irsaliyehareket/removesingle/[^/]+$',
      501, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/irsaliyehareketalis/removesingle/[^/]+$', 502, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/kasa/[^/]+$', 1001, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/kasahareket/[^/]+$', 1003, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/kredi/[^/]+$', 1031, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/kredikartisozlesme/[^/]+$', 1024, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/krediodemeplani/[^/]+$', 1031, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/kullanici/[^/]+$', 2, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/localyaziciayar/[^/]+$', 29, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/masraf/[^/]+$', 26, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/muhasebeentegrasyonceksenet/[^/]+$',
      1505, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/muhasebeentegrasyonkdv/[^/]+$', 1503, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/muhasebeentegrasyontevkifat/[^/]+$',
      1504, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/odeme/[^/]+$', 1027, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/ozelhesapkapatma/[^/]+$', 208, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/parametrekullanicisirket/[^/]+$', 21, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/parametresirketerpview/[^/]+$', 31, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/plasiyer/[^/]+$', 3, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/proformafatura/removewithitems/[^/]+$',
      1601, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/proje/[^/]+$', 4, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/recete/removewithitems/[^/]+$', 901, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/recetebilesen/removesingle/[^/]+$',
      901, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/referans/[^/]+$', 24, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/sabloncari/[^/]+$', 207, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/sablonstok/[^/]+$', 114, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/senetalinan/removewithitems/[^/]+$',
      1015, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetalinanciro/removewithitems/[^/]+$', 1016, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetalinancirohareket/removesingle/[^/]+$', 1016, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/senetalinanhareket/[^/]+$', 1015, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetalinanhareket/removesingle/[^/]+$', 1015, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetalinaniade/removewithitems/[^/]+$', 1019, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/senetalinaniadehareket/[^/]+$', 1019, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetalinaniadehareket/removesingle/[^/]+$', 1019, Access.delete),
  BackendAccessRule(
      'erp',
      'DELETE',
      r'^/senetalinanportfoydentahsil/removewithitems/[^/]+$',
      1020,
      Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetalinanportfoydentahsilhareket/[^/]+$', 1020, Access.delete),
  BackendAccessRule(
      'erp',
      'DELETE',
      r'^/senetalinanportfoydentahsilhareket/removesingle/[^/]+$',
      1020,
      Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetalinanprotesto/removewithitems/[^/]+$', 1018, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/senetalinanprotestohareket/[^/]+$',
      1018, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetalinanprotestohareket/removesingle/[^/]+$', 1018, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetalinantahsil/removewithitems/[^/]+$', 1017, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/senetalinantahsilhareket/[^/]+$', 1017,
      Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetalinantahsilhareket/removesingle/[^/]+$', 1017, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/senetverilen/removewithitems/[^/]+$',
      1021, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/senetverilenhareket/[^/]+$', 1021, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetverilenhareket/removesingle/[^/]+$', 1021, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/senetverilenhareketdagilim/[^/]+$',
      1033, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetverileniade/removewithitems/[^/]+$', 1023, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/senetverileniadehareket/[^/]+$', 1023,
      Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetverileniadehareket/removesingle/[^/]+$', 1023, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetverilenodeme/removewithitems/[^/]+$', 1022, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/senetverilenodemehareket/[^/]+$', 1022,
      Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/senetverilenodemehareket/removesingle/[^/]+$', 1022, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/siparis/removewithitems/[^/]+$', 401, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/siparisalis/removewithitems/[^/]+$',
      402, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/siparisalishareketonay/tumonaylariiptalet$', 404, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/siparishareket/removesingle/[^/]+$',
      401, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/siparishareketalis/removesingle/[^/]+$', 402, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/siparissatishareketonay/tumonaylariiptalet$', 403, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/sirketozelrapor/[^/]+$', 20, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/stok/[^/]+$', 101, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/stok/stokalternatif/[^/]+$', 101, Access.update),
  BackendAccessRule(
      'erp', 'DELETE', r'^/stok/stokbarkod/[^/]+$', 101, Access.update),
  BackendAccessRule(
      'erp', 'DELETE', r'^/stok/stokfiyat/[^/]+$', 101, Access.update),
  BackendAccessRule(
      'erp', 'DELETE', r'^/stok/stokolcubr/[^/]+$', 101, Access.update),
  BackendAccessRule(
      'erp', 'DELETE', r'^/stok/stokozellik/[^/]+$', 101, Access.update),
  BackendAccessRule(
      'erp', 'DELETE', r'^/stok/stoksube/[^/]+$', 101, Access.update),
  BackendAccessRule('erp', 'DELETE', r'^/stokcari/[^/]+$', 109, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/stokdevir/removewithitems/[^/]+$', 105,
      Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/stokdevirhareket/removesingle/[^/]+$',
      105, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/stokfiyatlistesi/removewithitems/[^/]+$', 113, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/stokfiyatlistesihareket/removesingle/[^/]+$', 113, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/stokkategori/[^/]+$', 110, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/stokozelliksabit/[^/]+$', 27, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/stokparti/[^/]+$', 116, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/stoksayim/removewithitems/[^/]+$', 115,
      Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/stoksayim/stoksayimiptal/[^/]+$', 115,
      Access.create),
  BackendAccessRule('erp', 'DELETE', r'^/stoksayimhareket/removesingle/[^/]+$',
      115, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/stokseri/[^/]+$', 117, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/stokvirman/removewithitems/[^/]+$',
      112, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/stokvirmanhareket/removesingle/[^/]+$',
      112, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/surucu/[^/]+$', 23, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/tahsilat/[^/]+$', 1025, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/talep/removewithitems/[^/]+$', 701, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/talepalis/removewithitems/[^/]+$', 702,
      Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/talepalishareketonay/tumonaylariiptalet$', 704, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/talephareket/removesingle/[^/]+$', 701,
      Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/talephareketalis/removesingle/[^/]+$',
      702, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/talephareketatama/[^/]+$', 707, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/talepsatishareketonay/tumonaylariiptalet$', 703, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/tedarikciteklif/removebyteklifid/[^/]+$', 607, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/teklif/removewithitems/[^/]+$', 601, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/teklifalis/removewithitems/[^/]+$',
      602, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/teklifhareket/removesingle/[^/]+$',
      601, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/teklifhareketalis/removesingle/[^/]+$',
      602, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/teklifsatishareketonay/tumonaylariiptalet$', 603, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/uretim/removewithitems/[^/]+$', 902, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/uretimemri/removewithitems/[^/]+$',
      903, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/uretimemrihareket/removesingle/[^/]+$',
      903, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/uretimhareket/removesingle/[^/]+$',
      902, Access.delete),
  BackendAccessRule('erp', 'DELETE', r'^/yevmiyefisi/removewithitems/[^/]+$',
      1502, Access.delete),
  BackendAccessRule(
      'erp', 'DELETE', r'^/yevmiyefisihareket/[^/]+$', 1502, Access.delete),
  BackendAccessRule('erp', 'DELETE',
      r'^/yevmiyefisihareket/removesingle/[^/]+$', 1502, Access.delete),
  BackendAccessRule('erp', 'GET', r'^/ambargc$', 1301, Access.read),
  BackendAccessRule('erp', 'GET', r'^/ambargc/allbyuser$', 1301, Access.read),
  BackendAccessRule('erp', 'GET', r'^/ambargc/alldetay$', 1301, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/ambargc/ambargcfull/[^/]+$', 1301, Access.read),
  BackendAccessRule('erp', 'GET', r'^/ambargc/getnewambargcno/[^/]+/[^/]+$',
      1301, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/ambargc/isvalidambargcno/[^/]+/[^/]+/[^/]+$', 1301, Access.read),
  BackendAccessRule('erp', 'GET', r'^/ambargchareket/getallbyambargcid/[^/]+$',
      1301, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/ambargchareket/getbyid/[^/]+$', 1301, Access.read),
  BackendAccessRule('erp', 'GET', r'^/arac$', 22, Access.read),
  BackendAccessRule('erp', 'GET', r'^/arac/arac/[^/]+$', 22, Access.read),
  BackendAccessRule('erp', 'GET', r'^/arayuzmetinsirket$', 30, Access.read),
  BackendAccessRule('erp', 'GET', r'^/bankahareket$', 1004, Access.read),
  BackendAccessRule('erp', 'GET', r'^/bankahareket/alldetayforentegrasyon$',
      1004, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/bankahareket/bankahareket/[^/]+$', 1004, Access.read),
  BackendAccessRule('erp', 'GET', r'^/bankahareket/getnewbelgeno/[^/]+/[^/]+$',
      1004, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/bankahareket/isvalidbelgeno/[^/]+/[^/]+/[^/]+$', 1004, Access.read),
  BackendAccessRule('erp', 'GET', r'^/bankahesap$', 1002, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/bankahesap/bankahesap/[^/]+$', 1002, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cari$', 201, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cari/allbyuser$', 201, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cari/alldetayforentegrasyon$', 201, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cari/allplasiyercari$', 201, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cari/cariadres/[^/]+$', 201, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cari/carifull/[^/]+$', 201, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cari/carifullbykod/[^/]+$', 201, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cari/carisube/[^/]+$', 201, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cari/checkifremove/[^/]+$', 201, Access.delete),
  BackendAccessRule('erp', 'GET', r'^/caridevir$', 206, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/caridevir/caridevirfull/[^/]+$', 206, Access.read),
  BackendAccessRule('erp', 'GET', r'^/caridevir/getnewcaridevirno/[^/]+/[^/]+$',
      206, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/caridevir/isvalidcaridevirno/[^/]+/[^/]+/[^/]+$', 206, Access.read),
  BackendAccessRule('erp', 'GET', r'^/caridevirhareket/allbycaridevirid/[^/]+$',
      206, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/caridevirhareket/caridevirhareketfull/[^/]+$', 206, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/caridevirhareket/getallbycaridevirid/[^/]+$', 206, Access.read),
  BackendAccessRule('erp', 'GET', r'^/caririsk$', 202, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/caririsk/getbycariid/[^/]+$', 202, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/caririsk/getbyid/[^/]+$', 202, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/caririsk/hasriskbycariid/[^/]+$', 202, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekalinan$', 1005, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekalinan/allbyuser$', 1005, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cekalinan/alldetayforentegrasyon$', 1005, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cekalinan/cekalinanfull/[^/]+$', 1005, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekalinan/getnewcekalinanno/[^/]+/[^/]+$',
      1005, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/cekalinan/isvalidcekalinanno/[^/]+/[^/]+/[^/]+$', 1005, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekalinanciro$', 1006, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cekalinanciro/allbyuser$', 1006, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekalinanciro/alldetayforentegrasyon$',
      1006, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekalinanciro/cekalinancirofull/[^/]+$',
      1006, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/cekalinanciro/getnewcekalinancirono/[^/]+/[^/]+$', 1006, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanciro/isvalidcekalinancirono/[^/]+/[^/]+/[^/]+$',
      1006,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinancirohareket/cekalinancirohareketfull/[^/]+$',
      1006,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinancirohareket/getallbycekalinanciroid/[^/]+$',
      1006,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekalinanhareket/allbycekalinanid/[^/]+$',
      1005, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/cekalinanhareket/cekalinanhareketfull/[^/]+$', 1005, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/cekalinanhareket/getallbycekalinanid/[^/]+$', 1005, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanhareket/getnewcekalinanhareketno/[^/]+/[^/]+$',
      1005,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanhareket/isvalidcekalinanhareketno/[^/]+/[^/]+/[^/]+$',
      1005,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekalinaniade$', 1010, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cekalinaniade/allbyuser$', 1010, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekalinaniade/alldetayforentegrasyon$',
      1010, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekalinaniade/cekalinaniadefull/[^/]+$',
      1010, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/cekalinaniade/getnewcekalinaniadeno/[^/]+/[^/]+$', 1010, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinaniade/isvalidcekalinaniadeno/[^/]+/[^/]+/[^/]+$',
      1010,
      Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/cekalinaniadehareket/allbycekalinaniadeid/[^/]+$', 1010, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinaniadehareket/cekalinaniadehareketfull/[^/]+$',
      1010,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinaniadehareket/getallbycekalinaniadeid/[^/]+$',
      1010,
      Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cekalinanportfoydentahsil$', 1011, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekalinanportfoydentahsil/allbyuser$',
      1011, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanportfoydentahsil/alldetayforentegrasyon$',
      1011,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanportfoydentahsil/cekalinanportfoydentahsilfull/[^/]+$',
      1011,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanportfoydentahsil/getnewcekalinanportfoydentahsilno/[^/]+/[^/]+$',
      1011,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanportfoydentahsil/isvalidcekalinanportfoydentahsilno/[^/]+/[^/]+/[^/]+$',
      1011,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanportfoydentahsilhareket/allbycekalinanhareketid/[^/]+$',
      1011,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanportfoydentahsilhareket/allbycekalinanportfoydentahsilid/[^/]+$',
      1011,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanportfoydentahsilhareket/cekalinanportfoydentahsilhareketfull/[^/]+$',
      1011,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanportfoydentahsilhareket/getallbycekalinanportfoydentahsilid/[^/]+$',
      1011,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekalinanprotesto$', 1009, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cekalinanprotesto/allbyuser$', 1009, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/cekalinanprotesto/alldetayforentegrasyon$', 1009, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/cekalinanprotesto/cekalinanprotestofull/[^/]+$', 1009, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanprotesto/getnewcekalinanprotestono/[^/]+/[^/]+$',
      1009,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanprotesto/isvalidcekalinanprotestono/[^/]+/[^/]+/[^/]+$',
      1009,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanprotestohareket/allbycekalinanprotestoid/[^/]+$',
      1009,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanprotestohareket/cekalinanprotestohareketfull/[^/]+$',
      1009,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinanprotestohareket/getallbycekalinanprotestoid/[^/]+$',
      1009,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekalinantahsil$', 1007, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cekalinantahsil/allbyuser$', 1007, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekalinantahsil/alldetayforentegrasyon$',
      1007, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/cekalinantahsil/cekalinantahsilfull/[^/]+$', 1007, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinantahsil/getnewcekalinantahsilno/[^/]+/[^/]+$',
      1007,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinantahsil/isvalidcekalinantahsilno/[^/]+/[^/]+/[^/]+$',
      1007,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinantahsilhareket/allbycekalinantahsilid/[^/]+$',
      1007,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinantahsilhareket/cekalinantahsilhareketfull/[^/]+$',
      1007,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekalinantahsilhareket/getallbycekalinantahsilid/[^/]+$',
      1007,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekverilen$', 1012, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cekverilen/allbyuser$', 1012, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cekverilen/alldetayforentegrasyon$', 1012, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cekverilen/cekverilenfull/[^/]+$', 1012, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/cekverilen/getnewcekverilenno/[^/]+/[^/]+$', 1012, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekverilen/isvalidcekverilenno/[^/]+/[^/]+/[^/]+$',
      1012,
      Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/cekverilenhareket/allbycekverilenid/[^/]+$', 1012, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/cekverilenhareket/cekverilenhareketfull/[^/]+$', 1012, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/cekverilenhareket/getallbycekverilenid/[^/]+$', 1012, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekverilenhareket/getnewcekverilenhareketno/[^/]+/[^/]+$',
      1012,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekverilenhareket/isvalidcekverilenhareketno/[^/]+/[^/]+/[^/]+$',
      1012,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekverilenhareketdagilim/allbycekverilenhareketid/[^/]+$',
      1032,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekverilenhareketdagilim/full/[^/]+$',
      1032, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekverileniade$', 1014, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cekverileniade/allbyuser$', 1014, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekverileniade/alldetayforentegrasyon$',
      1014, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekverileniade/cekverileniadefull/[^/]+$',
      1014, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekverileniade/getnewcekverileniadeno/[^/]+/[^/]+$',
      1014,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekverileniade/isvalidcekverileniadeno/[^/]+/[^/]+/[^/]+$',
      1014,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekverileniadehareket/allbycekverileniadeid/[^/]+$',
      1014,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekverileniadehareket/cekverileniadehareketfull/[^/]+$',
      1014,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekverileniadehareket/getallbycekverileniadeid/[^/]+$',
      1014,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekverilenodeme$', 1013, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/cekverilenodeme/allbyuser$', 1013, Access.read),
  BackendAccessRule('erp', 'GET', r'^/cekverilenodeme/alldetayforentegrasyon$',
      1013, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/cekverilenodeme/cekverilenodemefull/[^/]+$', 1013, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekverilenodeme/getnewcekverilenodemeno/[^/]+/[^/]+$',
      1013,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekverilenodeme/isvalidcekverilenodemeno/[^/]+/[^/]+/[^/]+$',
      1013,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekverilenodemehareket/allbycekverilenodemeid/[^/]+$',
      1013,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekverilenodemehareket/cekverilenodemehareketfull/[^/]+$',
      1013,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/cekverilenodemehareket/getallbycekverilenodemeid/[^/]+$',
      1013,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/dashfinans$', 5101, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dashfinansuyari$', 5101, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dashkdv$', 5101, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dashsatinalma$', 5102, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dashsatinalmagrafik$', 5102, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dashsatis$', 5103, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dashsatisgrafik$', 5103, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dat$', 801, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dat/allbyuser$', 801, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dat/alldetay$', 801, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dat/alldetayforentegrasyon$', 801, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dat/datfull/[^/]+$', 801, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dat/getnewdatno/[^/]+/[^/]+$', 801, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dat/isvaliddatno/[^/]+/[^/]+/[^/]+$', 801, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dathareket/getallbydatid/[^/]+$', 801, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dathareket/getbyid/[^/]+$', 801, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dosyabelge/getbybelge/[^/]+/[^/]+$', 1201, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dosyabelge/getbybelge2/[^/]+/[^/]+$',
      1201, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dosyabelge/getfull/[^/]+$', 1201, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dysdosya/getbyklasorid/[^/]+$', 1102, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dysdosya/getfull/[^/]+$', 1102, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dysdosyabelge/getbydosyaid/[^/]+$', 1102, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dysdosyabelge/getfull/[^/]+$', 1102, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dysdosyatur$', 1104, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dysdosyatur/getfull/[^/]+$', 1104, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dysklasor/getbyustklasoriid/[^/]+$', 1101, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dysklasor/getfull/[^/]+$', 1101, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dysklasor/getfullbyactiveuser$', 1101, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dysklasor/getustklasorlist/[^/]+$', 1101, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dyskullanicigrup$', 1105, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dyskullanicigrup/dyskullanicigrup/[^/]+$',
      1105, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dyskullanicigrupdetay$', 1105, Access.read),
  BackendAccessRule('erp', 'GET', r'^/dyskullanicigrupdetay/allbygrupid/[^/]+$',
      1105, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/dyskullanicigrupdetay/dyskullanicigrupdetay/[^/]+$',
      1105,
      Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/dyskullanicigrupklasoryetki$', 1103, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/dyskullanicigrupklasoryetki/getbykullaniciid/[^/]+$',
      1103,
      Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/dyskullanicigrupklasoryetki/getfull/[^/]+$', 1103, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/efatura/all\-unsuccessful$', 301, Access.authorized),
  BackendAccessRule(
      'erp', 'GET', r'^/efatura/new\-all$', 301, Access.authorized),
  BackendAccessRule(
      'erp', 'GET', r'^/efatura/new\-earsiv$', 301, Access.authorized),
  BackendAccessRule(
      'erp', 'GET', r'^/efatura/new\-efatura$', 301, Access.authorized),
  BackendAccessRule(
      'erp', 'GET', r'^/eihracat/all\-unsuccessful$', 1601, Access.authorized),
  BackendAccessRule(
      'erp', 'GET', r'^/eihracat/new\-all$', 1601, Access.authorized),
  BackendAccessRule(
      'erp', 'GET', r'^/eirsaliye/all\-unsuccessful$', 501, Access.authorized),
  BackendAccessRule(
      'erp', 'GET', r'^/eirsaliye/new\-all$', 501, Access.authorized),
  BackendAccessRule('erp', 'GET', r'^/fatura$', 301, Access.read),
  BackendAccessRule('erp', 'GET', r'^/fatura/allbyuser$', 301, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/fatura/alldetayforentegrasyon$', 301, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/fatura/faturafull/[^/]+$', 301, Access.read),
  BackendAccessRule('erp', 'GET', r'^/fatura/getnewfaturano/[^/]+/[^/]+$', 301,
      Access.update),
  BackendAccessRule('erp', 'GET',
      r'^/fatura/isvalidfaturano/[^/]+/[^/]+/[^/]+/[^/]+$', 301, Access.update),
  BackendAccessRule('erp', 'GET', r'^/faturaalis$', 302, Access.update),
  BackendAccessRule(
      'erp', 'GET', r'^/faturaalis/allbyuser$', 302, Access.update),
  BackendAccessRule(
      'erp', 'GET', r'^/faturaalis/alldetayforentegrasyon$', 302, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/faturaalis/faturafull/[^/]+$', 302, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/faturaalis/isvalidfaturano/[^/]+/[^/]+/[^/]+/[^/]+$',
      302,
      Access.update),
  BackendAccessRule('erp', 'GET', r'^/faturahareket/getallbyfaturaid/[^/]+$',
      301, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/faturahareket/getbyid/[^/]+$', 301, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/faturahareketalis/getallbyfaturaid/[^/]+$', 302, Access.read),
  BackendAccessRule('erp', 'GET', r'^/finanskesinplan$', 1030, Access.read),
  BackendAccessRule('erp', 'GET', r'^/finansplan$', 1028, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/finansplan/finansplanfull/[^/]+$', 1028, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/finansplan/getnewfinansplanno/[^/]+/[^/]+$', 1028, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/finansplan/isvalidfinansplanno/[^/]+/[^/]+/[^/]+$',
      1028,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/finansplanhareket/getallbycariid/[^/]+$',
      1028, Access.read),
  BackendAccessRule('erp', 'GET', r'^/finansplanhareket/getallbycarikod/[^/]+$',
      1028, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/finansplanhareket/getallbyfinansplanid/[^/]+$', 1028, Access.read),
  BackendAccessRule('erp', 'GET', r'^/finansplankayit$', 1034, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/finansplankayit/getbyid/[^/]+$', 1034, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/finansplankayit/getnewfinansplankayitno/[^/]+/[^/]+$',
      1034,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/finansplankayit/isvalidfinansplankayitno/[^/]+/[^/]+/[^/]+$',
      1034,
      Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/finansplankayitgerceklesen$', 1036, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/finansplankayitgerceklesen/getbyid/[^/]+$', 1036, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/finansplankayitgerceklesen/getitems/[^/]+$', 1036, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/finansplankayithareket/getallbyfinansplankayitid/[^/]+$',
      1034,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/finansplankayithareket/getbyid/[^/]+$',
      1034, Access.read),
  BackendAccessRule('erp', 'GET', r'^/finansplankayitonay$', 1035, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/finansplankayitonay/getbyid/[^/]+$', 1035, Access.read),
  BackendAccessRule('erp', 'GET', r'^/finansplankayitonay/getitems/[^/]+$',
      1035, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/finansplankayitverigiris$', 1037, Access.read),
  BackendAccessRule('erp', 'GET', r'^/finansplankayitverigiris/getbyid/[^/]+$',
      1037, Access.read),
  BackendAccessRule('erp', 'GET', r'^/finansplankayitverigiris/getitems/[^/]+$',
      1037, Access.read),
  BackendAccessRule('erp', 'GET', r'^/finanstakibi$', 1029, Access.read),
  BackendAccessRule('erp', 'GET', r'^/finanstakibi/getallbyfinansplanid/[^/]+$',
      1029, Access.read),
  BackendAccessRule('erp', 'GET', r'^/firmakredikarti$', 1026, Access.read),
  BackendAccessRule('erp', 'GET', r'^/firmakredikarti/allbybankahesapid/[^/]+$',
      1026, Access.read),
  BackendAccessRule('erp', 'GET', r'^/firmakredikarti/firmakredikarti/[^/]+$',
      1026, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/formdat/allbydatid/[^/]+$', 801, Access.read),
  BackendAccessRule('erp', 'GET', r'^/giderfisi$', 1701, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/giderfisi/alldetayforentegrasyon$', 1701, Access.read),
  BackendAccessRule('erp', 'GET', r'^/giderfisi/getnewgiderfisino/[^/]+/[^/]+$',
      1701, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/giderfisi/giderfisifull/[^/]+$', 1701, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/giderfisi/isvalidgiderfisino/[^/]+/[^/]+/[^/]+$', 1701, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/giderfisihareket/getallbygiderfisiid/[^/]+$', 1701, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/giderfisihareket/getbyid/[^/]+$', 1701, Access.read),
  BackendAccessRule('erp', 'GET', r'^/irsaliye$', 501, Access.read),
  BackendAccessRule('erp', 'GET', r'^/irsaliye/allbyuser$', 501, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/irsaliye/alldetayforentegrasyon$', 501, Access.read),
  BackendAccessRule('erp', 'GET', r'^/irsaliye/getnewirsaliyeno/[^/]+/[^/]+$',
      501, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/irsaliye/irsaliyefull/[^/]+$', 501, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/irsaliye/irsaliyefulladjustedwithfatura/[^/]+$', 501, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/irsaliye/isvalidirsaliyeno/[^/]+/[^/]+/[^/]+/[^/]+$',
      501,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/irsaliyealis$', 502, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/irsaliyealis/allbyuser$', 502, Access.read),
  BackendAccessRule('erp', 'GET', r'^/irsaliyealis/alldetayforentegrasyon$',
      502, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/irsaliyealis/irsaliyefull/[^/]+$', 502, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/irsaliyealis/irsaliyefulladjustedwithfatura/[^/]+$',
      502,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/irsaliyealis/isvalidirsaliyeno/[^/]+/[^/]+/[^/]+/[^/]+$',
      502,
      Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/irsaliyehareket/getallbyirsaliyeid/[^/]+$', 501, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/irsaliyehareket/getbyid/[^/]+$', 501, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/irsaliyehareketalis/getallbyirsaliyeid/[^/]+$', 502, Access.read),
  BackendAccessRule('erp', 'GET', r'^/kasa$', 1001, Access.read),
  BackendAccessRule('erp', 'GET', r'^/kasa/kasa/[^/]+$', 1001, Access.read),
  BackendAccessRule('erp', 'GET', r'^/kasahareket$', 1003, Access.read),
  BackendAccessRule('erp', 'GET', r'^/kasahareket/alldetayforentegrasyon$',
      1003, Access.read),
  BackendAccessRule('erp', 'GET', r'^/kasahareket/getnewbelgeno/[^/]+/[^/]+$',
      1003, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/kasahareket/isvalidbelgeno/[^/]+/[^/]+/[^/]+$', 1003, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/kasahareket/kasahareket/[^/]+$', 1003, Access.read),
  BackendAccessRule('erp', 'GET', r'^/kredi$', 1031, Access.read),
  BackendAccessRule('erp', 'GET', r'^/kredi/kredi/[^/]+$', 1031, Access.read),
  BackendAccessRule('erp', 'GET', r'^/kredikartisozlesme$', 1024, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/kredikartisozlesme/allbybankahesapid/[^/]+$', 1024, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/kredikartisozlesme/kredikartisozlesme/[^/]+$', 1024, Access.read),
  BackendAccessRule('erp', 'GET', r'^/krediodemeplani/allbykrediid/[^/]+$',
      1031, Access.read),
  BackendAccessRule('erp', 'GET', r'^/krediodemeplani/krediodemeplani/[^/]+$',
      1031, Access.read),
  BackendAccessRule('erp', 'GET', r'^/kullanicigrup$', 2, Access.read),
  BackendAccessRule('erp', 'GET', r'^/kullanicigrup/[^/]+$', 2, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/kullanicigrup/getbykullanici/[^/]+$', 2, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/kullanicigrup/getbymodulgrup/[^/]+$', 2, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/kullanicigrupyetkiistisna/[^/]+$', 2, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/kullanicigrupyetkiistisna/getbykullanici/[^/]+$', 2, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/kullanicigrupyetkiistisna/getgrupmodulleri/[^/]+$', 2, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/kullanicioturum/aktifler$', 28, Access.read),
  BackendAccessRule('erp', 'GET', r'^/odeme$', 1027, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/odeme/allbybelgeid/[^/]+$', 1027, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/odeme/getnewodemeno/[^/]+/[^/]+$', 1027, Access.create),
  BackendAccessRule('erp', 'GET', r'^/odeme/isvalidodemeno/[^/]+/[^/]+/[^/]+$',
      1027, Access.create),
  BackendAccessRule('erp', 'GET', r'^/odeme/odeme/[^/]+$', 1027, Access.read),
  BackendAccessRule('erp', 'GET', r'^/ozelhesapkapatma$', 208, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/ozelhesapkapatma/getallbyalacakcarihareketid/[^/]+$',
      208,
      Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/ozelhesapkapatma/getallbyborccarihareketid/[^/]+$', 208, Access.read),
  BackendAccessRule('erp', 'GET', r'^/ozelhesapkapatma/getallbycariid/[^/]+$',
      208, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/ozelhesapkapatma/ozelhesapkapatmafull/[^/]+$', 208, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/parametrekullanicisirket$', 21, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/parametrekullanicisirket/parametrekullanicisirket/[^/]+$',
      21,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/parametresirket$', 19, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/parametresirket/getbysirket$', 19, Access.read),
  BackendAccessRule('erp', 'GET', r'^/parametresirket/parametresirket/[^/]+$',
      19, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/parametresirketerpview$', 31, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/parametresirketerpview/[^/]+$', 31, Access.read),
  BackendAccessRule('erp', 'GET', r'^/proformafatura$', 1601, Access.read),
  BackendAccessRule('erp', 'GET', r'^/proformafatura/alldetayforentegrasyon$',
      1601, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/proformafatura/getnewproformafaturano/[^/]+/[^/]+$',
      1601,
      Access.update),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/proformafatura/isvalidproformafaturano/[^/]+/[^/]+/[^/]+$',
      1601,
      Access.update),
  BackendAccessRule('erp', 'GET', r'^/proformafatura/proformafaturafull/[^/]+$',
      1601, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/proformafaturahareket/getallbyproformafaturaid/[^/]+$',
      1601,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/proformafaturahareket/getbyid/[^/]+$',
      1601, Access.read),
  BackendAccessRule('erp', 'GET', r'^/recete$', 901, Access.read),
  BackendAccessRule('erp', 'GET', r'^/recete/allbyuser$', 901, Access.read),
  BackendAccessRule('erp', 'GET', r'^/recete/alldetay$', 901, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/recete/alldetayforentegrasyon$', 901, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/recete/recetefull/[^/]+$', 901, Access.read),
  BackendAccessRule('erp', 'GET', r'^/recetebilesen/getallbyreceteid/[^/]+$',
      901, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/sabloncari/sabloncari/[^/]+$', 207, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/sablonstok/sablonstok/[^/]+$', 114, Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetalinan$', 1015, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/senetalinan/allbyuser$', 1015, Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetalinan/alldetayforentegrasyon$',
      1015, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/senetalinan/getnewsenetalinanno/[^/]+/[^/]+$', 1015, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinan/isvalidsenetalinanno/[^/]+/[^/]+/[^/]+$',
      1015,
      Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/senetalinan/senetalinanfull/[^/]+$', 1015, Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetalinanciro$', 1016, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/senetalinanciro/allbyuser$', 1016, Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetalinanciro/alldetayforentegrasyon$',
      1016, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanciro/getnewsenetalinancirono/[^/]+/[^/]+$',
      1016,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanciro/isvalidsenetalinancirono/[^/]+/[^/]+/[^/]+$',
      1016,
      Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/senetalinanciro/senetalinancirofull/[^/]+$', 1016, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinancirohareket/getallbysenetalinanciroid/[^/]+$',
      1016,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinancirohareket/senetalinancirohareketfull/[^/]+$',
      1016,
      Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/senetalinanhareket/allbysenetalinanid/[^/]+$', 1015, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/senetalinanhareket/getallbysenetalinanid/[^/]+$', 1015, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanhareket/getnewsenetalinanhareketno/[^/]+/[^/]+$',
      1015,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanhareket/isvalidsenetalinanhareketno/[^/]+/[^/]+/[^/]+$',
      1015,
      Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/senetalinanhareket/senetalinanhareketfull/[^/]+$', 1015, Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetalinaniade$', 1019, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/senetalinaniade/allbyuser$', 1019, Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetalinaniade/alldetayforentegrasyon$',
      1019, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinaniade/getnewsenetalinaniadeno/[^/]+/[^/]+$',
      1019,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinaniade/isvalidsenetalinaniadeno/[^/]+/[^/]+/[^/]+$',
      1019,
      Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/senetalinaniade/senetalinaniadefull/[^/]+$', 1019, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinaniadehareket/allbysenetalinaniadeid/[^/]+$',
      1019,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinaniadehareket/getallbysenetalinaniadeid/[^/]+$',
      1019,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinaniadehareket/senetalinaniadehareketfull/[^/]+$',
      1019,
      Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/senetalinanportfoydentahsil$', 1020, Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetalinanportfoydentahsil/allbyuser$',
      1020, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanportfoydentahsil/alldetayforentegrasyon$',
      1020,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanportfoydentahsil/getnewsenetalinanportfoydentahsilno/[^/]+/[^/]+$',
      1020,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanportfoydentahsil/isvalidsenetalinanportfoydentahsilno/[^/]+/[^/]+/[^/]+$',
      1020,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanportfoydentahsil/senetalinanportfoydentahsilfull/[^/]+$',
      1020,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanportfoydentahsilhareket/allbysenetalinanhareketid/[^/]+$',
      1020,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanportfoydentahsilhareket/allbysenetalinanportfoydentahsilid/[^/]+$',
      1020,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanportfoydentahsilhareket/getallbysenetalinanportfoydentahsilid/[^/]+$',
      1020,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanportfoydentahsilhareket/senetalinanportfoydentahsilhareketfull/[^/]+$',
      1020,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetalinanprotesto$', 1018, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/senetalinanprotesto/allbyuser$', 1018, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/senetalinanprotesto/alldetayforentegrasyon$', 1018, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanprotesto/getnewsenetalinanprotestono/[^/]+/[^/]+$',
      1018,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanprotesto/isvalidsenetalinanprotestono/[^/]+/[^/]+/[^/]+$',
      1018,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanprotesto/senetalinanprotestofull/[^/]+$',
      1018,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanprotestohareket/allbysenetalinanprotestoid/[^/]+$',
      1018,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanprotestohareket/getallbysenetalinanprotestoid/[^/]+$',
      1018,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinanprotestohareket/senetalinanprotestohareketfull/[^/]+$',
      1018,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetalinantahsil$', 1017, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/senetalinantahsil/allbyuser$', 1017, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/senetalinantahsil/alldetayforentegrasyon$', 1017, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinantahsil/getnewsenetalinantahsilno/[^/]+/[^/]+$',
      1017,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinantahsil/isvalidsenetalinantahsilno/[^/]+/[^/]+/[^/]+$',
      1017,
      Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/senetalinantahsil/senetalinantahsilfull/[^/]+$', 1017, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinantahsilhareket/allbysenetalinantahsilid/[^/]+$',
      1017,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinantahsilhareket/getallbysenetalinantahsilid/[^/]+$',
      1017,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetalinantahsilhareket/senetalinantahsilhareketfull/[^/]+$',
      1017,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetverilen$', 1021, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/senetverilen/allbyuser$', 1021, Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetverilen/alldetayforentegrasyon$',
      1021, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/senetverilen/getnewsenetverilenno/[^/]+/[^/]+$', 1021, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverilen/isvalidsenetverilenno/[^/]+/[^/]+/[^/]+$',
      1021,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetverilen/senetverilenfull/[^/]+$',
      1021, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/senetverilenhareket/allbysenetverilenid/[^/]+$', 1021, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverilenhareket/getallbysenetverilenid/[^/]+$',
      1021,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverilenhareket/getnewsenetverilenhareketno/[^/]+/[^/]+$',
      1021,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverilenhareket/isvalidsenetverilenhareketno/[^/]+/[^/]+/[^/]+$',
      1021,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverilenhareket/senetverilenhareketfull/[^/]+$',
      1021,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverilenhareketdagilim/allbysenetverilenhareketid/[^/]+$',
      1033,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetverilenhareketdagilim/full/[^/]+$',
      1033, Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetverileniade$', 1023, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/senetverileniade/allbyuser$', 1023, Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetverileniade/alldetayforentegrasyon$',
      1023, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverileniade/getnewsenetverileniadeno/[^/]+/[^/]+$',
      1023,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverileniade/isvalidsenetverileniadeno/[^/]+/[^/]+/[^/]+$',
      1023,
      Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/senetverileniade/senetverileniadefull/[^/]+$', 1023, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverileniadehareket/allbysenetverileniadeid/[^/]+$',
      1023,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverileniadehareket/getallbysenetverileniadeid/[^/]+$',
      1023,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverileniadehareket/senetverileniadehareketfull/[^/]+$',
      1023,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/senetverilenodeme$', 1022, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/senetverilenodeme/allbyuser$', 1022, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/senetverilenodeme/alldetayforentegrasyon$', 1022, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverilenodeme/getnewsenetverilenodemeno/[^/]+/[^/]+$',
      1022,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverilenodeme/isvalidsenetverilenodemeno/[^/]+/[^/]+/[^/]+$',
      1022,
      Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/senetverilenodeme/senetverilenodemefull/[^/]+$', 1022, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverilenodemehareket/allbysenetverilenodemeid/[^/]+$',
      1022,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverilenodemehareket/getallbysenetverilenodemeid/[^/]+$',
      1022,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/senetverilenodemehareket/senetverilenodemehareketfull/[^/]+$',
      1022,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/siparis$', 401, Access.read),
  BackendAccessRule('erp', 'GET', r'^/siparis/allbyhasitemwithstatus/[^/]+$',
      401, Access.read),
  BackendAccessRule('erp', 'GET', r'^/siparis/allbyuser$', 401, Access.read),
  BackendAccessRule('erp', 'GET', r'^/siparis/alldetay$', 401, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/siparis/alldetayforentegrasyon$', 401, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/siparis/getbaglantisiparis/[^/]+/[^/]+/[^/]+$', 401, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/siparis/getbaglantisiparishareketbystokid/[^/]+$', 401, Access.read),
  BackendAccessRule('erp', 'GET', r'^/siparis/getnewsiparisno/[^/]+/[^/]+$',
      401, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/siparis/isvalidsiparisno/[^/]+/[^/]+/[^/]+$', 401, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/siparis/siparisfull/[^/]+$', 401, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/siparis/siparisfulladjustedwithirsaliye/[^/]+$', 401, Access.read),
  BackendAccessRule('erp', 'GET', r'^/siparis/siparisfullwithoutred/[^/]+$',
      401, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/siparis/siparisonaysureci/[^/]+$', 401, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/siparis/siparisonaysurecidetay/[^/]+/[^/]+$', 401, Access.read),
  BackendAccessRule('erp', 'GET', r'^/siparisalis$', 402, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/siparisalis/allbyhasitemwithstatus/[^/]+$', 402, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/siparisalis/allbyuser$', 402, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/siparisalis/alldetayforentegrasyon$', 402, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/siparisalis/getbaglantisiparis/[^/]+/[^/]+/[^/]+$', 402, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/siparisalis/getbaglantisiparishareketbystokid/[^/]+$',
      402,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/siparisalis/getnewsiparisno/[^/]+/[^/]+$',
      402, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/siparisalis/isvalidsiparisno/[^/]+/[^/]+/[^/]+$', 402, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/siparisalis/siparisfull/[^/]+$', 402, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/siparisalis/siparisfulladjustedwithbaglanti/[^/]+$',
      402,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/siparisalis/siparisfulladjustedwithirsaliye/[^/]+$',
      402,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/siparisalis/siparisfullwithoutred/[^/]+$',
      402, Access.read),
  BackendAccessRule('erp', 'GET', r'^/siparisalis/siparisonaysureci/[^/]+$',
      402, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/siparisalis/siparisonaysurecidetay/[^/]+/[^/]+$', 402, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/siparisalishareketonay/getallsiparisforonay$', 404, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/siparisalishareketonay/getsiparishareketforonay/[^/]+$',
      404,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/siparisaliskapanis/getbysiparisid/[^/]+$',
      406, Access.read),
  BackendAccessRule('erp', 'GET', r'^/siparishareket/getallbysiparisid/[^/]+$',
      401, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/siparishareket/getbyid/[^/]+$', 401, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/siparishareketalis/getallbysiparisid/[^/]+$', 402, Access.read),
  BackendAccessRule('erp', 'GET', r'^/sipariskapanis/getbysiparisid/[^/]+$',
      405, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/siparissatishareketonay/allonaylist/[^/]+$', 403, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/siparissatishareketonay/getallsiparisforonay$', 403, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/siparissatishareketonay/getsiparishareketforonay/[^/]+$',
      403,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/sirket$', 1, Access.read),
  BackendAccessRule('erp', 'GET', r'^/sirketozelrapor$', 20, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stok$', 101, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stok/allbyuser$', 101, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stok/alldetayforentegrasyon$', 101, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stok/allforconnect$', 101, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stok/allmamulstok$', 101, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stok/checkifremove/[^/]+$', 101, Access.delete),
  BackendAccessRule(
      'erp', 'GET', r'^/stok/stokalternatif/[^/]+$', 101, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stok/stokbarkod/[^/]+$', 101, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stok/stokbybarcode/[^/]+$', 101, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stok/stokfiyat/[^/]+$', 101, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stok/stokfull/[^/]+$', 101, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stok/stokfullbykod/[^/]+$', 101, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stok/stokolcubr/[^/]+$', 101, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stok/stokozellik/[^/]+$', 101, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stok/stokplanlama/[^/]+$', 111, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stok/stoksube/[^/]+$', 101, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stokcari$', 109, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stokcari/getbycariid/[^/]+$', 109, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stokcari/getbyid/[^/]+$', 109, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stokcari/getbystokid/[^/]+$', 109, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stokdevir$', 105, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stokdevir/allbyuser$', 105, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stokdevir/alldetay$', 105, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stokdevir/getnewstokdevirno/[^/]+/[^/]+$',
      105, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/stokdevir/isvalidstokdevirno/[^/]+/[^/]+/[^/]+$', 105, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stokdevir/stokdevirfull/[^/]+$', 105, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/stokdevirhareket/getallbystokdevirid/[^/]+$', 105, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stokdevirhareket/getbyid/[^/]+$', 105, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stokfiyatlistesi$', 113, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/stokfiyatlistesi/stokfiyatlistesifull/[^/]+$', 113, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/stokfiyatlistesihareket/getallbystokfiyatlistesiid/[^/]+$',
      113,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/stokfiyatlistesihareket/stokfiyatlistesihareketfull/[^/]+$',
      113,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/stokparti/[^/]+$', 116, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stokparti/search$', 116, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stoksayim$', 115, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stoksayim/alldetay$', 115, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stoksayim/getnewstoksayimno/[^/]+/[^/]+$',
      115, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/stoksayim/isvalidstoksayimno/[^/]+/[^/]+/[^/]+$', 115, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stoksayim/stoksayimfull/[^/]+$', 115, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stoksayim/stoksayimozet/[^/]+$', 115, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/stoksayim/stoksayimozetwithsifirlama/[^/]+$', 115, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/stoksayimhareket/getallbystoksayimid/[^/]+$', 115, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stoksayimhareket/getbyid/[^/]+$', 115, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stokseri/[^/]+$', 117, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stokseri/search$', 117, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stokvirman$', 112, Access.read),
  BackendAccessRule('erp', 'GET', r'^/stokvirman/alldetay$', 112, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/stokvirman/getnewstokvirmanno/[^/]+/[^/]+$', 112, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/stokvirman/isvalidstokvirmanno/[^/]+/[^/]+/[^/]+$', 112, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stokvirman/stokvirmanfull/[^/]+$', 112, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/stokvirmanhareket/getallbystokvirmanid/[^/]+$', 112, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/stokvirmanhareket/getbyid/[^/]+$', 112, Access.read),
  BackendAccessRule('erp', 'GET', r'^/sube$', 6, Access.read),
  BackendAccessRule('erp', 'GET', r'^/surucu$', 23, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/surucu/getbycariid/[^/]+$', 23, Access.read),
  BackendAccessRule('erp', 'GET', r'^/surucu/surucu/[^/]+$', 23, Access.read),
  BackendAccessRule('erp', 'GET', r'^/tahsilat$', 1025, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/tahsilat/allbybelgeid/[^/]+$', 1025, Access.read),
  BackendAccessRule('erp', 'GET', r'^/tahsilat/getnewtahsilatno/[^/]+/[^/]+$',
      1025, Access.create),
  BackendAccessRule('erp', 'GET',
      r'^/tahsilat/isvalidtahsilatno/[^/]+/[^/]+/[^/]+$', 1025, Access.create),
  BackendAccessRule(
      'erp', 'GET', r'^/tahsilat/tahsilat/[^/]+$', 1025, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talep$', 701, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/talep/allbyhasitemwithstatus/[^/]+$', 701, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talep/allbyuser$', 701, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talep/alldetay$', 701, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/talep/getnewtalepno/[^/]+/[^/]+$', 701, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talep/isvalidtalepno/[^/]+/[^/]+/[^/]+$',
      701, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/talep/talepfull/[^/]+$', 701, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talep/talepfulladjustedwithteklif/[^/]+$',
      701, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talepalis$', 702, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talepalis/allbyhasitemwithstatus/[^/]+$',
      702, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talepalis/allbyuser$', 702, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talepalis/getnewtalepno/[^/]+/[^/]+$',
      702, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/talepalis/gettalephareketlistfullasync/[^/]+$', 702, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/talepalis/isvalidtalepno/[^/]+/[^/]+/[^/]+$', 702, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/talepalis/talepfull/[^/]+$', 702, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/talepalis/talepfulladjustedwithteklif/[^/]+$', 702, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talepalis/talepfullwithoutred/[^/]+$',
      702, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talepalishareketonay/allonaylist/[^/]+$',
      704, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talepalishareketonay/getalltalepforonay$',
      704, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/talepalishareketonay/gettalephareketforonay/[^/]+$',
      704,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/talepaliskapanis/getbytalepid/[^/]+$',
      706, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/talephareket/getallbytalepid/[^/]+$', 701, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/talephareket/getbyid/[^/]+$', 701, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talephareketalis/getallbytalepid/[^/]+$',
      702, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talephareketatama$', 707, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/talephareketatama/getatanantaleplerbykullaniciid/[^/]+$',
      707,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/talephareketatama/getbykullaniciandtalepid/[^/]+/[^/]+$',
      707,
      Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/talephareketatama/talephareketatamafull/[^/]+$', 707, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/talepkapanis/getbytalepid/[^/]+$', 705, Access.read),
  BackendAccessRule('erp', 'GET', r'^/talepsatishareketonay/allonaylist/[^/]+$',
      703, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/talepsatishareketonay/getalltalepforonay$', 703, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/talepsatishareketonay/gettalephareketforonay/[^/]+$',
      703,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/tedarikciteklif/getbyteklifid/[^/]+$',
      607, Access.read),
  BackendAccessRule('erp', 'GET', r'^/teklif$', 601, Access.read),
  BackendAccessRule('erp', 'GET', r'^/teklif/allbyhasitemwithstatus/[^/]+$',
      601, Access.read),
  BackendAccessRule('erp', 'GET', r'^/teklif/allbyuser$', 601, Access.read),
  BackendAccessRule('erp', 'GET', r'^/teklif/alldetay$', 601, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/teklif/getnewteklifno/[^/]+/[^/]+$', 601, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/teklif/isvalidteklifno/[^/]+/[^/]+/[^/]+$', 601, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/teklif/tekliffull/[^/]+$', 601, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/teklif/tekliffulladjustedwithsiparis/[^/]+$', 601, Access.read),
  BackendAccessRule('erp', 'GET', r'^/teklifalis$', 602, Access.read),
  BackendAccessRule('erp', 'GET', r'^/teklifalis/allbyhasitemwithstatus/[^/]+$',
      602, Access.read),
  BackendAccessRule('erp', 'GET', r'^/teklifalis/allbyuser$', 602, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/teklifalis/getnewgrupno$', 602, Access.read),
  BackendAccessRule('erp', 'GET', r'^/teklifalis/getnewteklifno/[^/]+/[^/]+$',
      602, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/teklifalis/isvalidteklifno/[^/]+/[^/]+/[^/]+$', 602, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/teklifalis/tekliffull/[^/]+$', 602, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/teklifalis/tekliffulladjustedwithsiparis/[^/]+$', 602, Access.read),
  BackendAccessRule('erp', 'GET', r'^/teklifalis/tekliffullwithoutred/[^/]+$',
      602, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/teklifalishareketonay/getallteklifkarsilastirmaliforonay$',
      604,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/teklifalishareketonay/getteklifhareketkarsilastirmaliforonay/[^/]+$',
      604,
      Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/teklifalishareketonay/getteklifhareketkarsilastirmalionayfullasync/[^/]+$',
      604,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/teklifaliskapanis/getbyteklifid/[^/]+$',
      606, Access.read),
  BackendAccessRule('erp', 'GET', r'^/teklifhareket/getallbyteklifid/[^/]+$',
      601, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/teklifhareket/getbyid/[^/]+$', 601, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/teklifhareketalis/getallbyteklifid/[^/]+$', 602, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/teklifkapanis/getbyteklifid/[^/]+$', 605, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/teklifsatishareketonay/allonaylist/[^/]+$', 603, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/teklifsatishareketonay/getallteklifforonay$', 603, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/teklifsatishareketonay/getteklifhareketforonay/[^/]+$',
      603,
      Access.read),
  BackendAccessRule('erp', 'GET', r'^/uretim$', 902, Access.read),
  BackendAccessRule('erp', 'GET', r'^/uretim/allbyuser$', 902, Access.read),
  BackendAccessRule('erp', 'GET', r'^/uretim/alldetay$', 902, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/uretim/alldetayforentegrasyon$', 902, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/uretim/getallbygrupno/[^/]+$', 902, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/uretim/getnewuretimno/[^/]+/[^/]+$', 902, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/uretim/isvaliduretimno/[^/]+/[^/]+/[^/]+$', 902, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/uretim/uretimfull/[^/]+$', 902, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/uretim/uretimfullfromrecete/[^/]+/[^/]+/[^/]+$', 902, Access.read),
  BackendAccessRule('erp', 'GET', r'^/uretimemri$', 903, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/uretimemri/full/[^/]+$', 903, Access.read),
  BackendAccessRule('erp', 'GET', r'^/uretimemri/getnewdocumentno/[^/]+/[^/]+$',
      903, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/uretimemri/isvaliddocumentno/[^/]+/[^/]+/[^/]+$', 903, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/uretimemrihareket/getallbyuretimemriid/[^/]+$', 903, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/uretimemrihareket/getallforuretimemrindenuretim$', 903, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/uretimemrihareket/getbyid/[^/]+$', 903, Access.read),
  BackendAccessRule('erp', 'GET', r'^/uretimhareket/getallbyuretimid/[^/]+$',
      902, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/uretimhareket/getbyid/[^/]+$', 902, Access.read),
  BackendAccessRule('erp', 'GET', r'^/vw_finansplankayit$', 5073, Access.read),
  BackendAccessRule('erp', 'GET', r'^/vw_finansplankayit/byfinansplanid/[^/]+$',
      5073, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/vw_finansplannakitakis$', 5074, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/vw_finansplannakitakis/byfinansplanid/[^/]+$', 5074, Access.read),
  BackendAccessRule('erp', 'GET', r'^/yevmiyefisi$', 1502, Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/yevmiyefisi/allbyuser$', 1502, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/yevmiyefisi/getnewyevmiyefisino/[^/]+/[^/]+$', 1502, Access.read),
  BackendAccessRule(
      'erp',
      'GET',
      r'^/yevmiyefisi/isvalidyevmiyefisino/[^/]+/[^/]+/[^/]+$',
      1502,
      Access.read),
  BackendAccessRule(
      'erp', 'GET', r'^/yevmiyefisi/yevmiyefisifull/[^/]+$', 1502, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/yevmiyefisi/yevmiyefisiidbyortakislemno/[^/]+$', 1502, Access.read),
  BackendAccessRule('erp', 'GET', r'^/yevmiyefisihareket$', 1502, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/yevmiyefisihareket/allbyyevmiyefisiid/[^/]+$', 1502, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/yevmiyefisihareket/getallbyyevmiyefisiid/[^/]+$', 1502, Access.read),
  BackendAccessRule('erp', 'GET',
      r'^/yevmiyefisihareket/yevmiyefisihareketfull/[^/]+$', 1502, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/ambargc/copywithitems/[^/]+$', 1301, Access.delete),
  BackendAccessRule('erp', 'POST', r'^/ambargc/filter$', 1301, Access.read),
  BackendAccessRule('erp', 'POST', r'^/ambargc/query$', 1301, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/ambargc/savefaturadanambargc$', 1301, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/ambargc/saveirsaliyedenambargc$', 1301, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/ambargc/savesingle$', 1301, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/ambargc/savewithitems$', 1301, Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/ambargchareket/savelistfromimport/[^/]+$', 1301, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/ambargchareket/savesingle$', 1301, Access.create),
  BackendAccessRule('erp', 'POST', r'^/arac$', 22, Access.create),
  BackendAccessRule('erp', 'POST', r'^/arayuzmetinsirket$', 30, Access.create),
  BackendAccessRule('erp', 'POST', r'^/bankahareket$', 1004, Access.create),
  BackendAccessRule('erp', 'POST', r'^/bankahesap$', 1002, Access.create),
  BackendAccessRule('erp', 'POST', r'^/belgeseri$', 5, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cari$', 201, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cari/cariadres$', 201, Access.update),
  BackendAccessRule('erp', 'POST', r'^/cari/carisube$', 201, Access.update),
  BackendAccessRule('erp', 'POST', r'^/cari/easysave$', 201, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cari/savefromexcel$', 201, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cari/savelist$', 201, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/caridevir/copywithitems/[^/]+$', 206, Access.delete),
  BackendAccessRule('erp', 'POST', r'^/caridevir/filter$', 206, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/caridevir/savesingle$', 206, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/caridevir/savewithitems$', 206, Access.create),
  BackendAccessRule('erp', 'POST', r'^/caridevirhareket$', 206, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/caridevirhareket/savesingle$', 206, Access.create),
  BackendAccessRule('erp', 'POST', r'^/carikategori$', 205, Access.create),
  BackendAccessRule('erp', 'POST', r'^/caririsk$', 202, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinan/copywithitems/[^/]+$', 1005, Access.delete),
  BackendAccessRule('erp', 'POST', r'^/cekalinan/filter$', 1005, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinan/savesingle$', 1005, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinan/savewithitems$', 1005, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinanciro/filter$', 1006, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinanciro/savesingle$', 1006, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cekalinancirohareket/savesingle$', 1006,
      Access.create),
  BackendAccessRule('erp', 'POST', r'^/cekalinanhareket$', 1005, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinanhareket/filter$', 1005, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinanhareket/savesingle$', 1005, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cekalinaniade/copywithitems/[^/]+$',
      1010, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinaniade/filter$', 1010, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinaniade/savesingle$', 1010, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinaniade/savewithitems$', 1010, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinaniadehareket$', 1010, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cekalinaniadehareket/savesingle$', 1010,
      Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinanportfoydentahsil/filter$', 1011, Access.read),
  BackendAccessRule('erp', 'POST', r'^/cekalinanportfoydentahsil/savesingle$',
      1011, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cekalinanportfoydentahsilhareket$', 1011,
      Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/cekalinanportfoydentahsilhareket/savesingle$', 1011, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cekalinanprotesto/copywithitems/[^/]+$',
      1009, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinanprotesto/filter$', 1009, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinanprotesto/savesingle$', 1009, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cekalinanprotesto/savewithitems$', 1009,
      Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinanprotestohareket$', 1009, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cekalinanprotestohareket/savesingle$',
      1009, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cekalinantahsil/copywithitems/[^/]+$',
      1007, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinantahsil/filter$', 1007, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinantahsil/savesingle$', 1007, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinantahsil/savewithitems$', 1007, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekalinantahsilhareket$', 1007, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cekalinantahsilhareket/savesingle$',
      1007, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverilen/copywithitems/[^/]+$', 1012, Access.delete),
  BackendAccessRule('erp', 'POST', r'^/cekverilen/filter$', 1012, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverilen/savesingle$', 1012, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverilen/savewithitems$', 1012, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverilenhareket$', 1012, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverilenhareket/filter$', 1012, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverilenhareket/savesingle$', 1012, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverilenhareketdagilim$', 1032, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cekverileniade/copywithitems/[^/]+$',
      1014, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverileniade/filter$', 1014, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverileniade/savesingle$', 1014, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverileniade/savewithitems$', 1014, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverileniadehareket$', 1014, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cekverileniadehareket/savesingle$', 1014,
      Access.create),
  BackendAccessRule('erp', 'POST', r'^/cekverilenodeme/copywithitems/[^/]+$',
      1013, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverilenodeme/filter$', 1013, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverilenodeme/savesingle$', 1013, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverilenodeme/savewithitems$', 1013, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/cekverilenodemehareket$', 1013, Access.create),
  BackendAccessRule('erp', 'POST', r'^/cekverilenodemehareket/savesingle$',
      1013, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/dat/copywithitems/[^/]+$', 801, Access.delete),
  BackendAccessRule('erp', 'POST', r'^/dat/filter$', 801, Access.read),
  BackendAccessRule('erp', 'POST', r'^/dat/query$', 801, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/dat/saveirsaliyedendat$', 801, Access.create),
  BackendAccessRule('erp', 'POST', r'^/dat/savesingle$', 801, Access.create),
  BackendAccessRule('erp', 'POST', r'^/dat/savewithitems$', 801, Access.create),
  BackendAccessRule('erp', 'POST', r'^/dathareket/savelistfromimport/[^/]+$',
      801, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/dathareket/savesingle$', 801, Access.create),
  BackendAccessRule('erp', 'POST', r'^/depo$', 7, Access.create),
  BackendAccessRule('erp', 'POST', r'^/depoadres$', 9, Access.create),
  BackendAccessRule('erp', 'POST', r'^/depotanim$', 8, Access.create),
  BackendAccessRule('erp', 'POST', r'^/dosyabelge$', 1201, Access.create),
  BackendAccessRule('erp', 'POST', r'^/dysdosya$', 1102, Access.create),
  BackendAccessRule('erp', 'POST', r'^/dysdosya/filter$', 1102, Access.read),
  BackendAccessRule('erp', 'POST', r'^/dysdosyabelge$', 1102, Access.create),
  BackendAccessRule('erp', 'POST', r'^/dysdosyatur$', 1104, Access.create),
  BackendAccessRule('erp', 'POST', r'^/dysklasor$', 1101, Access.create),
  BackendAccessRule('erp', 'POST', r'^/dyskullanicigrup$', 1105, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/dyskullanicigrupdetay$', 1105, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/dyskullanicigrupdetay/set$', 1105, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/dyskullanicigrupklasoryetki$', 1103, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/efatura/portaldan\-aktar$', 301, Access.authorized),
  BackendAccessRule(
      'erp', 'POST', r'^/efatura/set\-ebelge/[^/]+$', 301, Access.authorized),
  BackendAccessRule('erp', 'POST', r'^/efatura/set\-error/[^/]+/[^/]+$', 301,
      Access.authorized),
  BackendAccessRule(
      'erp', 'POST', r'^/efatura/set\-iptal/[^/]+$', 301, Access.authorized),
  BackendAccessRule(
      'erp', 'POST', r'^/efatura/set\-new/[^/]+$', 301, Access.authorized),
  BackendAccessRule(
      'erp', 'POST', r'^/efatura/update\-durumkodu$', 301, Access.authorized),
  BackendAccessRule(
      'erp', 'POST', r'^/eihracat/set\-ebelge/[^/]+$', 1601, Access.authorized),
  BackendAccessRule(
      'erp', 'POST', r'^/eihracat/set\-new/[^/]+$', 1601, Access.authorized),
  BackendAccessRule(
      'erp', 'POST', r'^/eihracat/update\-durumkodu$', 1601, Access.authorized),
  BackendAccessRule(
      'erp', 'POST', r'^/eirsaliye/set\-ebelge/[^/]+$', 501, Access.authorized),
  BackendAccessRule(
      'erp', 'POST', r'^/eirsaliye/set\-new/[^/]+$', 501, Access.authorized),
  BackendAccessRule(
      'erp', 'POST', r'^/eirsaliye/update\-durumkodu$', 501, Access.authorized),
  BackendAccessRule(
      'erp', 'POST', r'^/fatura/copywithitems/[^/]+$', 301, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/fatura/easysavewithitems$', 301, Access.create),
  BackendAccessRule('erp', 'POST', r'^/fatura/filter$', 301, Access.read),
  BackendAccessRule('erp', 'POST', r'^/fatura/portala\-gonder/[^/]+$', 301,
      Access.authorized),
  BackendAccessRule('erp', 'POST', r'^/fatura/query$', 301, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/fatura/saveiadefaturasi$', 301, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/fatura/saveirsaliyedenfatura$', 301, Access.create),
  BackendAccessRule('erp', 'POST', r'^/fatura/savesingle$', 301, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/fatura/savesiparistenfatura$', 301, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/fatura/savewithitems$', 301, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/faturaalis/copywithitems/[^/]+$', 302, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/faturaalis/easysavewithitems$', 302, Access.create),
  BackendAccessRule('erp', 'POST', r'^/faturaalis/filter$', 302, Access.update),
  BackendAccessRule('erp', 'POST', r'^/faturaalis/query$', 302, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/faturaalis/resolve$', 302, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/faturaalis/resolvefromimage$', 302, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/faturaalis/resolvefrompdf$', 302, Access.create),
  BackendAccessRule('erp', 'POST', r'^/faturaalis/resolvefromportal/[^/]+$',
      302, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/faturaalis/resolvefromxml$', 302, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/faturaalis/saveiadefaturasi$', 302, Access.create),
  BackendAccessRule('erp', 'POST', r'^/faturaalis/saveirsaliyedenfatura$', 302,
      Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/faturaalis/savesingle$', 302, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/faturaalis/savesiparistenfatura$', 302, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/faturaalis/savewithitems$', 302, Access.create),
  BackendAccessRule('erp', 'POST', r'^/faturahareket/savelistfromimport/[^/]+$',
      301, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/faturahareket/savesingle$', 301, Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/faturahareketalis/savelistfromimport/[^/]+$', 302, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/faturahareketalis/savesingle$', 302, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/finansplan/savesingle$', 1028, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/finansplan/savewithitems$', 1028, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/finansplanhareket/savelist$', 1028, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/finansplanhareket/savesingle$', 1028, Access.create),
  BackendAccessRule('erp', 'POST', r'^/finansplankayit/copywithitems/[^/]+$',
      1034, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/finansplankayit/savesingle$', 1034, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/finansplankayit/savewithitems$', 1034, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/finansplankayit/sonrayaaktar$', 1034, Access.create),
  BackendAccessRule('erp', 'POST', r'^/finansplankayithareket/savelist$', 1034,
      Access.create),
  BackendAccessRule('erp', 'POST', r'^/finansplankayithareket/savesingle$',
      1034, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/finansplankayitverigiris/save$', 1037, Access.create),
  BackendAccessRule('erp', 'POST', r'^/firmakredikarti$', 1026, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/giderfisi/copywithitems/[^/]+$', 1701, Access.delete),
  BackendAccessRule('erp', 'POST', r'^/giderfisi/filter$', 1701, Access.read),
  BackendAccessRule('erp', 'POST', r'^/giderfisi/query$', 1701, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/giderfisi/savesingle$', 1701, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/giderfisi/savewithitems$', 1701, Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/giderfisihareket/savelistfromimport/[^/]+$', 1701, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/giderfisihareket/savesingle$', 1701, Access.create),
  BackendAccessRule('erp', 'POST', r'^/hesapplani$', 1501, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/hesapplani/kopyala$', 1501, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/irsaliye/copywithitems/[^/]+$', 501, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/irsaliye/easysavewithitems$', 501, Access.create),
  BackendAccessRule('erp', 'POST', r'^/irsaliye/filter$', 501, Access.read),
  BackendAccessRule('erp', 'POST', r'^/irsaliye/portala\-gonder/[^/]+$', 501,
      Access.authorized),
  BackendAccessRule('erp', 'POST', r'^/irsaliye/query$', 501, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/irsaliye/savesingle$', 501, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/irsaliye/savesiparistenirsaliye$', 501, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/irsaliye/savewithitems$', 501, Access.create),
  BackendAccessRule('erp', 'POST', r'^/irsaliyealis/copywithitems/[^/]+$', 502,
      Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/irsaliyealis/easysavewithitems$', 502, Access.create),
  BackendAccessRule('erp', 'POST', r'^/irsaliyealis/filter$', 502, Access.read),
  BackendAccessRule('erp', 'POST',
      r'^/irsaliyealis/getirsaliyelistfromimportdto$', 502, Access.read),
  BackendAccessRule('erp', 'POST', r'^/irsaliyealis/query$', 502, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/irsaliyealis/savesingle$', 502, Access.create),
  BackendAccessRule('erp', 'POST', r'^/irsaliyealis/savesiparistenirsaliye$',
      502, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/irsaliyealis/savewithitems$', 502, Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/irsaliyehareket/savelistfromimport/[^/]+$', 501, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/irsaliyehareket/savesingle$', 501, Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/irsaliyehareketalis/savelistfromimport/[^/]+$', 502, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/irsaliyehareketalis/savesingle$', 502, Access.create),
  BackendAccessRule('erp', 'POST', r'^/kasa$', 1001, Access.create),
  BackendAccessRule('erp', 'POST', r'^/kasahareket$', 1003, Access.create),
  BackendAccessRule('erp', 'POST', r'^/kredi$', 1031, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/kredikartisozlesme$', 1024, Access.create),
  BackendAccessRule('erp', 'POST', r'^/krediodemeplani$', 1031, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/krediodemeplani/savelist$', 1031, Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/krediodemeplani/savelistfromimport/[^/]+$', 1031, Access.create),
  BackendAccessRule('erp', 'POST', r'^/kullanici$', 2, Access.create),
  BackendAccessRule('erp', 'POST', r'^/kullanici/copy$', 2, Access.create),
  BackendAccessRule('erp', 'POST', r'^/kullanicigrup/set$', 2, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/kullanicigrupyetkiistisna/set$', 2, Access.create),
  BackendAccessRule('erp', 'POST', r'^/localyaziciayar$', 29, Access.create),
  BackendAccessRule('erp', 'POST', r'^/masraf$', 26, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/muhasebeentegrasyonceksenet$', 1505, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/muhasebeentegrasyonkdv$', 1503, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/muhasebeentegrasyontevkifat$', 1504, Access.create),
  BackendAccessRule('erp', 'POST', r'^/odeme$', 1027, Access.create),
  BackendAccessRule('erp', 'POST', r'^/odeme/query$', 1027, Access.read),
  BackendAccessRule('erp', 'POST', r'^/ozelhesapkapatma$', 208, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/parametrekullanicisirket$', 21, Access.create),
  BackendAccessRule('erp', 'POST', r'^/parametresirket$', 19, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/parametresirketerpview$', 31, Access.create),
  BackendAccessRule('erp', 'POST', r'^/parametresirketerpview/senkronize$', 31,
      Access.create),
  BackendAccessRule('erp', 'POST', r'^/plasiyer$', 3, Access.create),
  BackendAccessRule('erp', 'POST', r'^/proformafatura/copywithitems/[^/]+$',
      1601, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/proformafatura/filter$', 1601, Access.read),
  BackendAccessRule('erp', 'POST', r'^/proformafatura/portala\-gonder/[^/]+$',
      1601, Access.authorized),
  BackendAccessRule(
      'erp', 'POST', r'^/proformafatura/query$', 1601, Access.read),
  BackendAccessRule('erp', 'POST',
      r'^/proformafatura/saveirsaliyedenproformafatura$', 1601, Access.create),
  BackendAccessRule('erp', 'POST', r'^/proje$', 4, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/recete/copywithitems$', 901, Access.delete),
  BackendAccessRule('erp', 'POST', r'^/recete/savesingle$', 901, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/recete/savewithitems$', 901, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/recetebilesen/savesingle$', 901, Access.create),
  BackendAccessRule('erp', 'POST', r'^/referans$', 24, Access.create),
  BackendAccessRule('erp', 'POST', r'^/sabloncari$', 207, Access.create),
  BackendAccessRule('erp', 'POST', r'^/sablonstok$', 114, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetalinan/copywithitems/[^/]+$', 1015,
      Access.delete),
  BackendAccessRule('erp', 'POST', r'^/senetalinan/filter$', 1015, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinan/savesingle$', 1015, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinan/savewithitems$', 1015, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinanciro/filter$', 1016, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinanciro/savesingle$', 1016, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetalinancirohareket/savesingle$',
      1016, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinanhareket$', 1015, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinanhareket/filter$', 1015, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinanhareket/savesingle$', 1015, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinanhareket/savetanzim$', 1015, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetalinaniade/copywithitems/[^/]+$',
      1019, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinaniade/filter$', 1019, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinaniade/savesingle$', 1019, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinaniade/savewithitems$', 1019, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinaniadehareket$', 1019, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetalinaniadehareket/savesingle$',
      1019, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetalinanportfoydentahsil/filter$',
      1020, Access.read),
  BackendAccessRule('erp', 'POST', r'^/senetalinanportfoydentahsil/savesingle$',
      1020, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetalinanportfoydentahsilhareket$',
      1020, Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/senetalinanportfoydentahsilhareket/savesingle$', 1020, Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/senetalinanprotesto/copywithitems/[^/]+$', 1018, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinanprotesto/filter$', 1018, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinanprotesto/savesingle$', 1018, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetalinanprotesto/savewithitems$',
      1018, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinanprotestohareket$', 1018, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetalinanprotestohareket/savesingle$',
      1018, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetalinantahsil/copywithitems/[^/]+$',
      1017, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinantahsil/filter$', 1017, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinantahsil/savesingle$', 1017, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetalinantahsil/savewithitems$', 1017,
      Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetalinantahsilhareket$', 1017, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetalinantahsilhareket/savesingle$',
      1017, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetverilen/copywithitems/[^/]+$', 1021,
      Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/senetverilen/filter$', 1021, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/senetverilen/savesingle$', 1021, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetverilen/savewithitems$', 1021, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetverilenhareket$', 1021, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetverilenhareket/filter$', 1021, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/senetverilenhareket/savesingle$', 1021, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetverilenhareketdagilim$', 1033, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetverileniade/copywithitems/[^/]+$',
      1023, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/senetverileniade/filter$', 1023, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/senetverileniade/savesingle$', 1023, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetverileniade/savewithitems$', 1023, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetverileniadehareket$', 1023, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetverileniadehareket/savesingle$',
      1023, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetverilenodeme/copywithitems/[^/]+$',
      1022, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/senetverilenodeme/filter$', 1022, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/senetverilenodeme/savesingle$', 1022, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetverilenodeme/savewithitems$', 1022,
      Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/senetverilenodemehareket$', 1022, Access.create),
  BackendAccessRule('erp', 'POST', r'^/senetverilenodemehareket/savesingle$',
      1022, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/siparis/allbyhareketidsasync$', 401, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/siparis/copywithitems/[^/]+$', 401, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/siparis/easysavewithitems$', 401, Access.create),
  BackendAccessRule('erp', 'POST', r'^/siparis/filter$', 401, Access.read),
  BackendAccessRule('erp', 'POST', r'^/siparis/query$', 401, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/siparis/savesingle$', 401, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/siparis/savetekliftensiparis$', 401, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/siparis/savewithitems$', 401, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/siparisalis/allbyhareketidsasync$', 402, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/siparisalis/copywithitems/[^/]+$', 402, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/siparisalis/easysavewithitems$', 402, Access.create),
  BackendAccessRule('erp', 'POST', r'^/siparisalis/filter$', 402, Access.read),
  BackendAccessRule('erp', 'POST', r'^/siparisalis/query$', 402, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/siparisalis/savesingle$', 402, Access.create),
  BackendAccessRule('erp', 'POST', r'^/siparisalis/savetekliftensiparis$', 402,
      Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/siparisalis/savewithitems$', 402, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/siparisalishareketonay$', 404, Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/siparishareket/savelistfromimport/[^/]+$', 401, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/siparishareket/savesingle$', 401, Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/siparishareketalis/savelistfromimport/[^/]+$', 402, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/siparishareketalis/savesingle$', 402, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/siparissatishareketonay$', 403, Access.create),
  BackendAccessRule('erp', 'POST', r'^/sirket$', 1, Access.create),
  BackendAccessRule('erp', 'POST', r'^/sirketozelrapor$', 20, Access.create),
  BackendAccessRule('erp', 'POST', r'^/stok$', 101, Access.create),
  BackendAccessRule('erp', 'POST', r'^/stok/easysave$', 101, Access.create),
  BackendAccessRule('erp', 'POST', r'^/stok/filter$', 101, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/stok/getstokbykodlist$', 101, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/stok/savefromexcel$', 101, Access.create),
  BackendAccessRule('erp', 'POST', r'^/stok/savelist$', 101, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/stok/stokalternatif$', 101, Access.update),
  BackendAccessRule('erp', 'POST', r'^/stok/stokbarkod$', 101, Access.update),
  BackendAccessRule('erp', 'POST', r'^/stok/stokfiyat$', 101, Access.update),
  BackendAccessRule('erp', 'POST', r'^/stok/stokolcubr$', 101, Access.update),
  BackendAccessRule('erp', 'POST', r'^/stok/stokozellik$', 101, Access.update),
  BackendAccessRule('erp', 'POST', r'^/stok/stoksube$', 101, Access.update),
  BackendAccessRule('erp', 'POST', r'^/stokcari$', 109, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/stokdevir/copywithitems/[^/]+$', 105, Access.delete),
  BackendAccessRule('erp', 'POST', r'^/stokdevir/filter$', 105, Access.read),
  BackendAccessRule('erp', 'POST', r'^/stokdevir/query$', 105, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/stokdevir/savesingle$', 105, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/stokdevir/savewithitems$', 105, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/stokdevirhareket/savesingle$', 105, Access.create),
  BackendAccessRule('erp', 'POST', r'^/stokfiyatlistesi/copywithitems/[^/]+$',
      113, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/stokfiyatlistesi/savesingle$', 113, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/stokfiyatlistesi/savewithitems$', 113, Access.create),
  BackendAccessRule('erp', 'POST', r'^/stokfiyatlistesihareket/savesingle$',
      113, Access.create),
  BackendAccessRule('erp', 'POST', r'^/stokkategori$', 110, Access.create),
  BackendAccessRule('erp', 'POST', r'^/stokozelliksabit$', 27, Access.create),
  BackendAccessRule('erp', 'POST', r'^/stokparti$', 116, Access.create),
  BackendAccessRule('erp', 'POST', r'^/stoksayim/filter$', 115, Access.read),
  BackendAccessRule('erp', 'POST', r'^/stoksayim/query$', 115, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/stoksayim/savesingle$', 115, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/stoksayim/savewithitems$', 115, Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/stoksayim/stokhareketlereaktar/[^/]+/[^/]+$', 115, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/stoksayim/stoksayimbirlestir$', 115, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/stoksayimhareket/savesingle$', 115, Access.create),
  BackendAccessRule('erp', 'POST', r'^/stokseri$', 117, Access.create),
  BackendAccessRule('erp', 'POST', r'^/stokseri/generate$', 117, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/stokvirman/copywithitems/[^/]+$', 112, Access.delete),
  BackendAccessRule('erp', 'POST', r'^/stokvirman/filter$', 112, Access.read),
  BackendAccessRule('erp', 'POST', r'^/stokvirman/query$', 112, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/stokvirman/savesingle$', 112, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/stokvirman/savewithitems$', 112, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/stokvirmanhareket/savesingle$', 112, Access.create),
  BackendAccessRule('erp', 'POST', r'^/sube$', 6, Access.create),
  BackendAccessRule('erp', 'POST', r'^/surucu$', 23, Access.create),
  BackendAccessRule('erp', 'POST', r'^/tahsilat$', 1025, Access.create),
  BackendAccessRule('erp', 'POST', r'^/tahsilat/query$', 1025, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/talep/allbyhareketidsasync$', 701, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/talep/copywithitems/[^/]+$', 701, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/talep/easysavewithitems$', 701, Access.create),
  BackendAccessRule('erp', 'POST', r'^/talep/filter$', 701, Access.read),
  BackendAccessRule('erp', 'POST', r'^/talep/query$', 701, Access.read),
  BackendAccessRule('erp', 'POST', r'^/talep/savesingle$', 701, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/talep/savewithitems$', 701, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/talepalis/allbyhareketidsasync$', 702, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/talepalis/copywithitems/[^/]+$', 702, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/talepalis/easysavewithitems$', 702, Access.create),
  BackendAccessRule('erp', 'POST', r'^/talepalis/filter$', 702, Access.read),
  BackendAccessRule('erp', 'POST', r'^/talepalis/query$', 702, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/talepalis/savesingle$', 702, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/talepalis/savewithitems$', 702, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/talepalishareketonay$', 704, Access.create),
  BackendAccessRule('erp', 'POST', r'^/talephareket/savelistfromimport/[^/]+$',
      701, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/talephareket/savesingle$', 701, Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/talephareketalis/savelistfromimport/[^/]+$', 702, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/talephareketalis/savesingle$', 702, Access.create),
  BackendAccessRule('erp', 'POST', r'^/talephareketatama$', 707, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/talephareketatama/removelist$', 707, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/talephareketatama/savelist$', 707, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/talepsatishareketonay$', 703, Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/tedarikciteklif/tedarikciyegonder/[^/]+$', 607, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/teklif/allbyhareketidsasync$', 601, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/teklif/copywithitems/[^/]+$', 601, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/teklif/easysavewithitems$', 601, Access.create),
  BackendAccessRule('erp', 'POST', r'^/teklif/filter$', 601, Access.read),
  BackendAccessRule('erp', 'POST', r'^/teklif/query$', 601, Access.read),
  BackendAccessRule('erp', 'POST', r'^/teklif/savesingle$', 601, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/teklif/savetaleptenteklif$', 601, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/teklif/savewithitems$', 601, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/teklifalis/allbyhareketidsasync$', 602, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/teklifalis/copywithitems/[^/]+$', 602, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/teklifalis/easysavewithitems$', 602, Access.create),
  BackendAccessRule('erp', 'POST', r'^/teklifalis/filter$', 602, Access.read),
  BackendAccessRule('erp', 'POST', r'^/teklifalis/query$', 602, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/teklifalis/savesingle$', 602, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/teklifalis/savetaleptenteklif$', 602, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/teklifalis/savewithitems$', 602, Access.create),
  BackendAccessRule('erp', 'POST', r'^/teklifalishareketonay/saveorupdate$',
      604, Access.create),
  BackendAccessRule('erp', 'POST', r'^/teklifhareket/savelistfromimport/[^/]+$',
      601, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/teklifhareket/savesingle$', 601, Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/teklifhareketalis/savelistfromimport/[^/]+$', 602, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/teklifhareketalis/savesingle$', 602, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/teklifsatishareketonay$', 603, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/uretim/copywithitems/[^/]+$', 902, Access.delete),
  BackendAccessRule(
      'erp', 'POST', r'^/uretim/getallbyidlist$', 902, Access.read),
  BackendAccessRule('erp', 'POST', r'^/uretim/query$', 902, Access.read),
  BackendAccessRule('erp', 'POST', r'^/uretim/saveitemsfromrecipe/[^/]+$', 902,
      Access.create),
  BackendAccessRule('erp', 'POST', r'^/uretim/savesingle$', 902, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/uretim/saveuretimemrindenuretim$', 902, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/uretim/savewithitems$', 902, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/uretimemri/copywithitems/[^/]+$', 903, Access.create),
  BackendAccessRule('erp', 'POST', r'^/uretimemri/filter$', 903, Access.read),
  BackendAccessRule('erp', 'POST', r'^/uretimemri/query$', 903, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/uretimemri/savesingle$', 903, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/uretimemri/savewithitems$', 903, Access.create),
  BackendAccessRule('erp', 'POST', r'^/uretimemrihareket/savelist/[^/]+$', 903,
      Access.create),
  BackendAccessRule('erp', 'POST',
      r'^/uretimemrihareket/savelistfromimport/[^/]+$', 903, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/uretimemrihareket/savesingle$', 903, Access.create),
  BackendAccessRule('erp', 'POST', r'^/uretimhareket/savelistfromimport/[^/]+$',
      902, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/uretimhareket/savesingle$', 902, Access.create),
  BackendAccessRule('erp', 'POST', r'^/yetki$', 2, Access.create),
  BackendAccessRule('erp', 'POST', r'^/yetki/kopyala$', 2, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/yevmiyefisi/allkapanisfisi$', 1509, Access.read),
  BackendAccessRule('erp', 'POST', r'^/yevmiyefisi/copywithitems/[^/]+$', 1502,
      Access.delete),
  BackendAccessRule('erp', 'POST', r'^/yevmiyefisi/filter$', 1502, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/yevmiyefisi/kapanisfisibakiye$', 1508, Access.read),
  BackendAccessRule('erp', 'POST', r'^/yevmiyefisi/query$', 1502, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/yevmiyefisi/savefromacilisfisi$', 1502, Access.create),
  BackendAccessRule('erp', 'POST', r'^/yevmiyefisi/savefromkapanisfisibakiye$',
      1508, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/yevmiyefisi/savefromtersbakiye$', 1507, Access.create),
  BackendAccessRule('erp', 'POST', r'^/yevmiyefisi/savefromyansitmabakiye$',
      1506, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/yevmiyefisi/savesingle$', 1502, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/yevmiyefisi/savewithitems$', 1502, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/yevmiyefisi/tersbakiye$', 1507, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/yevmiyefisi/yansitmabakiye$', 1506, Access.read),
  BackendAccessRule(
      'erp', 'POST', r'^/yevmiyefisihareket$', 1502, Access.create),
  BackendAccessRule(
      'erp', 'POST', r'^/yevmiyefisihareket/savesingle$', 1502, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/ambargc/backtodraft/[^/]+$', 1301, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/ambargc/complete/[^/]+$', 1301, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/ambargc/partialupdate$', 1301, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/ambargc/updatesingle$', 1301, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/ambargchareket/partialupdate$', 1301, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/ambargchareket/updatesingle$', 1301, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/arac$', 22, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/arayuzmetinsirket$', 30, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/bankahareket$', 1004, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/bankahareket/kilitackapatentegrasyon$',
      1004, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/bankahareket/updateentegrasyontrue$',
      1004, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/bankahesap$', 1002, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/belgeseri$', 5, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cari$', 201, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cari/cariadres$', 201, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cari/carisube$', 201, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cari/kilitackapatentegrasyon$', 201, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cari/updateentegrasyontrue$', 201, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/caridevir/backtodraft/[^/]+$', 206, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/caridevir/complete/[^/]+$', 206, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/caridevir/partialupdate$', 206, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/caridevir/updatesingle$', 206, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/caridevirhareket$', 206, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/caridevirhareket/partialupdate$', 206, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/caridevirhareket/updatesingle$', 206, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/carikategori$', 205, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/caririsk$', 202, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekalinan/backtodraft/[^/]+$', 1005, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekalinan/complete/[^/]+$', 1005, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/cekalinan/kilitackapatentegrasyon$', 1005,
      Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekalinan/updateentegrasyontrue$', 1005, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekalinan/updatesingle$', 1005, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekalinanciro/backtodraft/[^/]+$', 1006, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekalinanciro/complete/[^/]+$', 1006, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/cekalinanciro/kilitackapatentegrasyon$',
      1006, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cekalinanciro/updateentegrasyontrue$',
      1006, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekalinanciro/updatesingle$', 1006, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cekalinanhareket$', 1005, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekalinanhareket/updatesingle$', 1005, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekalinaniade/backtodraft/[^/]+$', 1010, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekalinaniade/complete/[^/]+$', 1010, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/cekalinaniade/kilitackapatentegrasyon$',
      1010, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cekalinaniade/updateentegrasyontrue$',
      1010, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekalinaniade/updatesingle$', 1010, Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/cekalinanportfoydentahsil/backtodraft/[^/]+$', 1011, Access.create),
  BackendAccessRule('erp', 'PUT',
      r'^/cekalinanportfoydentahsil/complete/[^/]+$', 1011, Access.create),
  BackendAccessRule(
      'erp',
      'PUT',
      r'^/cekalinanportfoydentahsil/kilitackapatentegrasyon$',
      1011,
      Access.update),
  BackendAccessRule(
      'erp',
      'PUT',
      r'^/cekalinanportfoydentahsil/updateentegrasyontrue$',
      1011,
      Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cekalinanportfoydentahsil/updatesingle$',
      1011, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cekalinanprotesto/backtodraft/[^/]+$',
      1009, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/cekalinanprotesto/complete/[^/]+$', 1009,
      Access.create),
  BackendAccessRule('erp', 'PUT',
      r'^/cekalinanprotesto/kilitackapatentegrasyon$', 1009, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cekalinanprotesto/updateentegrasyontrue$',
      1009, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekalinanprotesto/updatesingle$', 1009, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cekalinantahsil/backtodraft/[^/]+$', 1007,
      Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekalinantahsil/complete/[^/]+$', 1007, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/cekalinantahsil/kilitackapatentegrasyon$',
      1007, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cekalinantahsil/updateentegrasyontrue$',
      1007, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekalinantahsil/updatesingle$', 1007, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekverilen/backtodraft/[^/]+$', 1012, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekverilen/complete/[^/]+$', 1012, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/cekverilen/kilitackapatentegrasyon$',
      1012, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cekverilen/updateentegrasyontrue$', 1012,
      Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekverilen/updatesingle$', 1012, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cekverilenhareket$', 1012, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekverilenhareket/updatesingle$', 1012, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cekverileniade/backtodraft/[^/]+$', 1014,
      Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekverileniade/complete/[^/]+$', 1014, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/cekverileniade/kilitackapatentegrasyon$',
      1014, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cekverileniade/updateentegrasyontrue$',
      1014, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekverileniade/updatesingle$', 1014, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cekverilenodeme/backtodraft/[^/]+$', 1013,
      Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekverilenodeme/complete/[^/]+$', 1013, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/cekverilenodeme/kilitackapatentegrasyon$',
      1013, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/cekverilenodeme/updateentegrasyontrue$',
      1013, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/cekverilenodeme/updatesingle$', 1013, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/dat/backtodraft/[^/]+$', 801, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/dat/complete/[^/]+$', 801, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/dat/kilitackapatentegrasyon$', 801, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/dat/partialupdate$', 801, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/dat/updateentegrasyontrue$', 801, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/dat/updatesingle$', 801, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/dathareket/partialupdate$', 801, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/dathareket/updatesingle$', 801, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/depo$', 7, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/depoadres$', 9, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/depotanim$', 8, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/dosyabelge$', 1201, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/dysdosya$', 1102, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/dysdosyabelge$', 1102, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/dysdosyatur$', 1104, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/dysklasor$', 1101, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/dyskullanicigrup$', 1105, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/dyskullanicigrupklasoryetki$', 1103, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/fatura/backtodraft/[^/]+$', 301, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/fatura/changedoviz$', 301, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/fatura/changekdvdahil$', 301, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/fatura/complete/[^/]+$', 301, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/fatura/kilitackapatentegrasyon$', 301, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/fatura/partialupdate$', 301, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/fatura/updateentegrasyontrue$', 301, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/fatura/updatesingle$', 301, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/faturaalis/backtodraft/[^/]+$', 302, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/faturaalis/changedoviz$', 302, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/faturaalis/changekdvdahil$', 302, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/faturaalis/complete/[^/]+$', 302, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/faturaalis/kilitackapatentegrasyon$', 302,
      Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/faturaalis/partialupdate$', 302, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/faturaalis/updateentegrasyontrue$', 302, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/faturaalis/updatesingle$', 302, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/faturahareket/kalemtopluprojeupdate$',
      301, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/faturahareket/partialupdate$', 301, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/faturahareket/updatesingle$', 301, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/faturahareketalis/kalemtopluprojeupdate$',
      302, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/faturahareketalis/partialupdate$', 302, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/faturahareketalis/updatesingle$', 302, Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/finanskesinplan/settamamlandi/[^/]+/[^/]+$', 1030, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/finanskesinplan/updatelist$', 1030, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/finanskesinplan/updatesingle$', 1030, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/finansplan/backtodraft/[^/]+$', 1028, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/finansplan/complete/[^/]+$', 1028, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/finansplan/refreshplan/[^/]+$', 1028, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/finansplan/setplandurum/[^/]+/[^/]+$',
      1028, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/finansplan/updatesingle$', 1028, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/finansplankayit/setaktif/[^/]+$', 1034, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/finansplankayit/setpasif/[^/]+$', 1034, Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/finansplankayit/setplandurumtoonayda/[^/]+$', 1034, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/finansplankayit/updatesingle$', 1034, Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/finansplankayitgerceklesen/backtodraft/[^/]+$', 1036, Access.create),
  BackendAccessRule('erp', 'PUT',
      r'^/finansplankayitgerceklesen/complete/[^/]+$', 1036, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/finansplankayitgerceklesen/gerceklestir$',
      1036, Access.update),
  BackendAccessRule(
      'erp',
      'PUT',
      r'^/finansplankayitgerceklesen/setplandurumtoonayda/[^/]+$',
      1036,
      Access.update),
  BackendAccessRule('erp', 'PUT', r'^/finansplankayithareket/updatesingle$',
      1034, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/finansplankayitonay/onayla$', 1035, Access.update),
  BackendAccessRule(
      'erp',
      'PUT',
      r'^/finansplankayitonay/setplandurumtoodemede/[^/]+$',
      1035,
      Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/finansplankayitonay/setplandurumtoyeni/[^/]+$', 1035, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/finansplankayitverigiris/update$', 1037, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/finanstakibi/updatelist$', 1029, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/finanstakibi/updatesingle$', 1029, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/firmakredikarti$', 1026, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/giderfisi/backtodraft/[^/]+$', 1701, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/giderfisi/complete/[^/]+$', 1701, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/giderfisi/kilitackapatentegrasyon$', 1701,
      Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/giderfisi/partialupdate$', 1701, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/giderfisi/updateentegrasyontrue$', 1701, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/giderfisi/updatesingle$', 1701, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/giderfisihareket/partialupdate$', 1701, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/giderfisihareket/updatesingle$', 1701, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/hesapplani$', 1501, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/hesapplani/yansitmahesapplani$', 1501, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliye/backtodraft/[^/]+$', 501, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliye/changedoviz$', 501, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliye/changekdvdahil$', 501, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliye/complete/[^/]+$', 501, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliye/kilitackapatentegrasyon$', 501, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliye/partialupdate$', 501, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliye/updateentegrasyontrue$', 501, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliye/updatesingle$', 501, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliyealis/backtodraft/[^/]+$', 502, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliyealis/changedoviz$', 502, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliyealis/changekdvdahil$', 502, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliyealis/complete/[^/]+$', 502, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/irsaliyealis/kilitackapatentegrasyon$',
      502, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliyealis/partialupdate$', 502, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/irsaliyealis/updateentegrasyontrue$', 502,
      Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliyealis/updatesingle$', 502, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliyehareket/partialupdate$', 501, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliyehareket/updatesingle$', 501, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/irsaliyehareketalis/partialupdate$', 502,
      Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/irsaliyehareketalis/updatesingle$', 502, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/kasa$', 1001, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/kasahareket$', 1003, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/kasahareket/kilitackapatentegrasyon$',
      1003, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/kasahareket/updateentegrasyontrue$', 1003,
      Access.update),
  BackendAccessRule('erp', 'PUT', r'^/kredi$', 1031, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/kredi/backtodraft/[^/]+$', 1031, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/kredi/complete/[^/]+$', 1031, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/kredikartisozlesme$', 1024, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/krediodemeplani$', 1031, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/krediodemeplani/odemeiptal/[^/]+$', 1031,
      Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/krediodemeplani/odemeyap/[^/]+$', 1031, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/kullanici$', 2, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/kullanicioturum/pasifyap/[^/]+$', 28, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/localyaziciayar$', 29, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/masraf$', 26, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/muhasebeentegrasyonceksenet$', 1505, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/muhasebeentegrasyonkdv$', 1503, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/muhasebeentegrasyontevkifat$', 1504, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/odeme$', 1027, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/ozelhesapkapatma$', 208, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/parametrekullanicisirket$', 21, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/parametresirketerpview$', 31, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/plasiyer$', 3, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/proformafatura/kilitackapatentegrasyon$',
      1601, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/proformafatura/updateentegrasyontrue$',
      1601, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/proformafatura/updatesingle$', 1601, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/proformafaturahareket/updatesingle$',
      1601, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/proje$', 4, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/recete/kilitackapatentegrasyon$', 901, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/recete/updateentegrasyontrue$', 901, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/recete/updatesingle$', 901, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/recetebilesen/updatesingle$', 901, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/referans$', 24, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/sabloncari$', 207, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/sablonstok$', 114, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetalinan/backtodraft/[^/]+$', 1015, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetalinan/complete/[^/]+$', 1015, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/senetalinan/kilitackapatentegrasyon$',
      1015, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetalinan/updateentegrasyontrue$', 1015,
      Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetalinan/updatesingle$', 1015, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetalinanciro/backtodraft/[^/]+$', 1016,
      Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetalinanciro/complete/[^/]+$', 1016, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/senetalinanciro/kilitackapatentegrasyon$',
      1016, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetalinanciro/updateentegrasyontrue$',
      1016, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetalinanciro/updatesingle$', 1016, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetalinanhareket$', 1015, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetalinanhareket/updatesingle$', 1015, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetalinaniade/backtodraft/[^/]+$', 1019,
      Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetalinaniade/complete/[^/]+$', 1019, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/senetalinaniade/kilitackapatentegrasyon$',
      1019, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetalinaniade/updateentegrasyontrue$',
      1019, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetalinaniade/updatesingle$', 1019, Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/senetalinanportfoydentahsil/backtodraft/[^/]+$', 1020, Access.create),
  BackendAccessRule('erp', 'PUT',
      r'^/senetalinanportfoydentahsil/complete/[^/]+$', 1020, Access.create),
  BackendAccessRule(
      'erp',
      'PUT',
      r'^/senetalinanportfoydentahsil/kilitackapatentegrasyon$',
      1020,
      Access.update),
  BackendAccessRule(
      'erp',
      'PUT',
      r'^/senetalinanportfoydentahsil/updateentegrasyontrue$',
      1020,
      Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/senetalinanportfoydentahsil/updatesingle$', 1020, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetalinanprotesto/backtodraft/[^/]+$',
      1018, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/senetalinanprotesto/complete/[^/]+$',
      1018, Access.create),
  BackendAccessRule('erp', 'PUT',
      r'^/senetalinanprotesto/kilitackapatentegrasyon$', 1018, Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/senetalinanprotesto/updateentegrasyontrue$', 1018, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetalinanprotesto/updatesingle$', 1018,
      Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetalinantahsil/backtodraft/[^/]+$',
      1017, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/senetalinantahsil/complete/[^/]+$', 1017,
      Access.create),
  BackendAccessRule('erp', 'PUT',
      r'^/senetalinantahsil/kilitackapatentegrasyon$', 1017, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetalinantahsil/updateentegrasyontrue$',
      1017, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetalinantahsil/updatesingle$', 1017, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetverilen/backtodraft/[^/]+$', 1021, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetverilen/complete/[^/]+$', 1021, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/senetverilen/kilitackapatentegrasyon$',
      1021, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetverilen/updateentegrasyontrue$',
      1021, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetverilen/updatesingle$', 1021, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetverilenhareket$', 1021, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetverilenhareket/updatesingle$', 1021,
      Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetverileniade/backtodraft/[^/]+$',
      1023, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetverileniade/complete/[^/]+$', 1023, Access.create),
  BackendAccessRule('erp', 'PUT',
      r'^/senetverileniade/kilitackapatentegrasyon$', 1023, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetverileniade/updateentegrasyontrue$',
      1023, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetverileniade/updatesingle$', 1023, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetverilenodeme/backtodraft/[^/]+$',
      1022, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/senetverilenodeme/complete/[^/]+$', 1022,
      Access.create),
  BackendAccessRule('erp', 'PUT',
      r'^/senetverilenodeme/kilitackapatentegrasyon$', 1022, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/senetverilenodeme/updateentegrasyontrue$',
      1022, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/senetverilenodeme/updatesingle$', 1022, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparis/backtodraft/[^/]+$', 401, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparis/changedoviz$', 401, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparis/changekdvdahil$', 401, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparis/complete/[^/]+$', 401, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparis/kilitackapatentegrasyon$', 401, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparis/onayagonder/[^/]+$', 401, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparis/partialupdate$', 401, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparis/updateentegrasyontrue$', 401, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparis/updatesingle$', 401, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparisalis/backtodraft/[^/]+$', 402, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparisalis/changedoviz$', 402, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparisalis/changekdvdahil$', 402, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparisalis/complete/[^/]+$', 402, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/siparisalis/kilitackapatentegrasyon$',
      402, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparisalis/onayagonder/[^/]+$', 402, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparisalis/partialupdate$', 402, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/siparisalis/updateentegrasyontrue$', 402,
      Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparisalis/updatesingle$', 402, Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/siparisalishareketonay/oncekionayciyaaktar$', 404, Access.update),
  BackendAccessRule(
      'erp',
      'PUT',
      r'^/siparisalishareketonay/sonrakionayciyaaktar/[^/]+$',
      404,
      Access.update),
  BackendAccessRule('erp', 'PUT', r'^/siparisaliskapanis$', 406, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparishareket/updatesingle$', 401, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/siparishareketalis/updatesingle$', 402, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/sipariskapanis$', 405, Access.create),
  BackendAccessRule('erp', 'PUT',
      r'^/siparissatishareketonay/oncekionayciyaaktar$', 403, Access.update),
  BackendAccessRule(
      'erp',
      'PUT',
      r'^/siparissatishareketonay/sonrakionayciyaaktar/[^/]+$',
      403,
      Access.update),
  BackendAccessRule('erp', 'PUT', r'^/sirket$', 1, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/sirketozelrapor$', 20, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stok$', 101, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stok/kilitackapatentegrasyon$', 101, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stok/stokalternatif$', 101, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stok/stokbarkod$', 101, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stok/stokfiyat$', 101, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stok/stokolcubr$', 101, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stok/stokozellik$', 101, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stok/stokplanlama$', 111, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stok/stoksube$', 101, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stok/updateentegrasyontrue$', 101, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stokcari$', 109, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stokdevir/backtodraft/[^/]+$', 105, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/stokdevir/complete/[^/]+$', 105, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/stokdevir/partialupdate$', 105, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stokdevir/updatesingle$', 105, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stokdevirhareket/partialupdate$', 105, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stokdevirhareket/updatesingle$', 105, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stokfiyatlistesi/updatesingle$', 113, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stokfiyatlistesihareket/updatesingle$',
      113, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stokkategori$', 110, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stokozelliksabit$', 27, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stokparti$', 116, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stoksayim/backtodraft/[^/]+$', 115, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stoksayim/complete/[^/]+$', 115, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/stoksayim/partialupdate$', 115, Access.update),
  BackendAccessRule(
      'erp',
      'PUT',
      r'^/stoksayim/setsayimdurumaktiforpasif/[^/]+/[^/]+$',
      115,
      Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stoksayim/updatesingle$', 115, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stoksayimhareket/partialupdate$', 115, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stoksayimhareket/updatesingle$', 115, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stokseri$', 117, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stoktakipdetay/alisfaturasi/stoktakip$',
      302, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stoktakipdetay/alisirsaliyesi/stoktakip$',
      502, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stoktakipdetay/ambargc/stoktakip/[^/]+$',
      1301, Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/stoktakipdetay/depolararasitransfer/stoktakip$', 801, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stoktakipdetay/satisfaturasi/stoktakip$',
      301, Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/stoktakipdetay/satisirsaliyesi/stoktakip$', 501, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stoktakipdetay/stokdevir/stoktakip$', 105,
      Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/stoktakipdetay/stokvirman/cikis/stoktakip$', 112, Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/stoktakipdetay/stokvirman/giris/stoktakip$', 112, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/stoktakipdetay/uretim/kalem/stoktakip$',
      902, Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/stoktakipdetay/uretim/ustkayit/stoktakip$', 902, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stokvirman/backtodraft/[^/]+$', 112, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/stokvirman/complete/[^/]+$', 112, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/stokvirman/partialupdate$', 112, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stokvirman/updatesingle$', 112, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stokvirmanhareket/partialupdate$', 112, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/stokvirmanhareket/updatesingle$', 112, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/sube$', 6, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/surucu$', 23, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/tahsilat$', 1025, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/talep/backtodraft/[^/]+$', 701, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/talep/changekullanici$', 701, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/talep/complete/[^/]+$', 701, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/talep/onayagonder/[^/]+$', 701, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/talep/partialupdate$', 701, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/talep/updatesingle$', 701, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/talepalis/backtodraft/[^/]+$', 702, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/talepalis/changekullanici$', 702, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/talepalis/complete/[^/]+$', 702, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/talepalis/onayagonder/[^/]+$', 702, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/talepalis/partialupdate$', 702, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/talepalis/updatesingle$', 702, Access.update),
  BackendAccessRule('erp', 'PUT',
      r'^/talepalishareketonay/oncekionayciyaaktar$', 704, Access.update),
  BackendAccessRule(
      'erp',
      'PUT',
      r'^/talepalishareketonay/sonrakionayciyaaktar/[^/]+$',
      704,
      Access.update),
  BackendAccessRule('erp', 'PUT', r'^/talepaliskapanis$', 706, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/talephareket/updatesingle$', 701, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/talephareketalis/updatesingle$', 702, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/talephareketatama$', 707, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/talepkapanis$', 705, Access.create),
  BackendAccessRule('erp', 'PUT',
      r'^/talepsatishareketonay/oncekionayciyaaktar$', 703, Access.update),
  BackendAccessRule(
      'erp',
      'PUT',
      r'^/talepsatishareketonay/sonrakionayciyaaktar/[^/]+$',
      703,
      Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/tedarikciteklif/kabulet/[^/]+$', 607, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/tedarikciteklif/reddet/[^/]+$', 607, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/tedarikciteklif/revizeiste/[^/]+$', 607, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklif/backtodraft/[^/]+$', 601, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/teklif/changedoviz$', 601, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklif/changekdvdahil$', 601, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklif/complete/[^/]+$', 601, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklif/onayagonder/[^/]+$', 601, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklif/partialupdate$', 601, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklif/updatesingle$', 601, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklifalis/backtodraft/[^/]+$', 602, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklifalis/changedoviz$', 602, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklifalis/changekdvdahil$', 602, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklifalis/complete/[^/]+$', 602, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklifalis/onayagonder/[^/]+$', 602, Access.create),
  BackendAccessRule('erp', 'PUT', r'^/teklifalis/onayagonderbygrupno/[^/]+$',
      602, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklifalis/partialupdate$', 602, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklifalis/updatesingle$', 602, Access.update),
  BackendAccessRule(
      'erp',
      'PUT',
      r'^/teklifalishareketonay/sonrakionayciyaaktar/[^/]+$',
      604,
      Access.update),
  BackendAccessRule('erp', 'PUT', r'^/teklifaliskapanis$', 606, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklifhareket/updatesingle$', 601, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/teklifhareketalis/updatesingle$', 602, Access.update),
  BackendAccessRule('erp', 'PUT', r'^/teklifkapanis$', 605, Access.create),
  BackendAccessRule('erp', 'PUT',
      r'^/teklifsatishareketonay/oncekionayciyaaktar$', 603, Access.update),
  BackendAccessRule(
      'erp',
      'PUT',
      r'^/teklifsatishareketonay/sonrakionayciyaaktar/[^/]+$',
      603,
      Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/uretim/backtodraft/[^/]+$', 902, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/uretim/complete/[^/]+$', 902, Access.create),
  BackendAccessRule(
      'erp', 'PUT', r'^/uretim/kilitackapatentegrasyon$', 902, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/uretim/partialupdate$', 902, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/uretim/updateentegrasyontrue$', 902, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/uretim/updatesingle$', 902, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/uretimemri/backtodraft/[^/]+$', 903, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/uretimemri/complete/[^/]+$', 903, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/uretimemri/partialupdate$', 903, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/uretimemri/updatesingle$', 903, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/uretimemrihareket/updatesingle$', 903, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/uretimhareket/partialupdate$', 902, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/uretimhareket/updatesingle$', 902, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/yevmiyefisi/updatesingle$', 1502, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/yevmiyefisihareket$', 1502, Access.update),
  BackendAccessRule(
      'erp', 'PUT', r'^/yevmiyefisihareket/updatesingle$', 1502, Access.update),
];
const sharedModuleIds = <String, int>{
  'Yonetim.Sirket': 1,
  'Yonetim.Kullanici': 2,
  'Yonetim.Plasiyer': 3,
  'Yonetim.Proje': 4,
  'Yonetim.Belgeseri': 5,
  'Yonetim.Sube': 6,
  'Yonetim.Depo': 7,
  'Yonetim.Depotanim': 8,
  'Yonetim.Depoadres': 9,
  'Yonetim.Parametresirket': 19,
  'Yonetim.Sirketozelrapor': 20,
  'Yonetim.Parametrekullanicisirket': 21,
  'Yonetim.Arac': 22,
  'Yonetim.Surucu': 23,
  'Yonetim.Referans': 24,
  'Yonetim.Masaustu': 25,
  'Yonetim.Masraf': 26,
  'Yonetim.Stokozelliksabit': 27,
  'Yonetim.Kullanicioturum': 28,
  'Yonetim.Localyaziciayar': 29,
  'Yonetim.Arayuzmetinsirket': 30,
  'Yonetim.ParametresirketLocalerpview': 31,
  'Stok.StokKarti': 101,
  'Stok.StokExcelImport': 103,
  'Stok.StokDevir': 105,
  'Stok.StokCari': 109,
  'Stok.StokKategori': 110,
  'Stok.StokPlanlama': 111,
  'Stok.Stokvirman': 112,
  'Stok.Stokfiyatlistesi': 113,
  'Stok.Sablonstok': 114,
  'Stok.Stoksayim': 115,
  'Stok.StokParti': 116,
  'Stok.StokSeri': 117,
  'Cari.CariKarti': 201,
  'Cari.Caririsk': 202,
  'Cari.CariExcelImport': 204,
  'Cari.CariKategori': 205,
  'Cari.CariDevir': 206,
  'Cari.Sabloncari': 207,
  'Cari.Ozelhesapkapatma': 208,
  'Fatura.Fatura': 301,
  'Fatura.FaturaAlis': 302,
  'Siparis.Siparis': 401,
  'Siparis.SiparisAlis': 402,
  'Siparis.SiparisOnay': 403,
  'Siparis.SiparisAlisOnay': 404,
  'Siparis.SiparisKapanis': 405,
  'Siparis.SiparisAlisKapanis': 406,
  'Irsaliye.Irsaliye': 501,
  'Irsaliye.IrsaliyeAlis': 502,
  'Irsaliye.IrsaliyeExcelImportAlis': 503,
  'Teklif.Teklif': 601,
  'Teklif.TeklifAlis': 602,
  'Teklif.TeklifOnay': 603,
  'Teklif.TeklifAlisOnay': 604,
  'Teklif.TeklifKapanis': 605,
  'Teklif.TeklifAlisKapanis': 606,
  'Teklif.Tedarikciteklif': 607,
  'Teklif.TeklifKarsilastirma': 608,
  'Teklif.TeklifKarsilastirmaliOnay': 609,
  'Talep.Talep': 701,
  'Talep.TalepAlis': 702,
  'Talep.TalepOnay': 703,
  'Talep.TalepAlisOnay': 704,
  'Talep.TalepKapanis': 705,
  'Talep.TalepAlisKapanis': 706,
  'Talep.TalepAlisAtama': 707,
  'Talep.TalepAlisAtanmisTalepler': 708,
  'Dat.Dat': 801,
  'Uretim.Recete': 901,
  'Uretim.UretimSonuKaydi': 902,
  'Uretim.Uretimemri': 903,
  'Uretim.Birlestir': 915,
  'Finans.Kasa': 1001,
  'Finans.Bankahesap': 1002,
  'Finans.Kasahareket': 1003,
  'Finans.Bankahareket': 1004,
  'Finans.Cekalinan': 1005,
  'Finans.Cekalinanciro': 1006,
  'Finans.Cekalinantahsil': 1007,
  'Finans.Cekalinanprotesto': 1009,
  'Finans.Cekalinaniade': 1010,
  'Finans.Cekalinanportfoydentahsil': 1011,
  'Finans.Cekverilen': 1012,
  'Finans.Cekverilendagilim': 1032,
  'Finans.Cekverilenodeme': 1013,
  'Finans.Cekverileniade': 1014,
  'Finans.Senetalinan': 1015,
  'Finans.Senetalinanciro': 1016,
  'Finans.Senetalinantahsil': 1017,
  'Finans.Senetalinanprotesto': 1018,
  'Finans.Senetalinaniade': 1019,
  'Finans.Senetalinanportfoydentahsil': 1020,
  'Finans.Senetverilen': 1021,
  'Finans.Senetverilendagilim': 1033,
  'Finans.Senetverilenodeme': 1022,
  'Finans.Senetverileniade': 1023,
  'Finans.Kredikartisozlesme': 1024,
  'Finans.Tahsilat': 1025,
  'Finans.Firmakredikarti': 1026,
  'Finans.Odeme': 1027,
  'Finans.Finansplanlama': 1028,
  'Finans.Finanstakibi': 1029,
  'Finans.Finanskesinplan': 1030,
  'Finans.Kredi': 1031,
  'Finans.Finansplanlamakayit': 1034,
  'Finans.Finansplankayitonay': 1035,
  'Finans.Finansplankayitgerceklesen': 1036,
  'Finans.Finansplankayitverigiris': 1037,
  'Dys.Dysklasor': 1101,
  'Dys.Dysdosya': 1102,
  'Dys.Dyskullanicigrupklasoryetki': 1103,
  'Dys.Dysdosyatur': 1104,
  'Dys.Dyskullanicigrup': 1105,
  'Dosya.Dosyabelge': 1201,
  'Ambargc.Ambargc': 1301,
  'Muhasebe.Hesapplani': 1501,
  'Muhasebe.Yevmiyefisi': 1502,
  'Muhasebe.Muhasebeentegrasyonkdv': 1503,
  'Muhasebe.Muhasebeentegrasyontevkifat': 1504,
  'Muhasebe.Muhasebeentegrasyonceksenet': 1505,
  'Muhasebe.Yansitmafisi': 1506,
  'Muhasebe.Tersbakiyeyansitmafisi': 1507,
  'Muhasebe.Kapanisfisi': 1508,
  'Muhasebe.Acilisfisi': 1509,
  'Disticaret.Proformafatura': 1601,
  'Giderfisi.Giderfisi': 1701,
  'GenelRaporlar.StokhareketRapor': 5001,
  'GenelRaporlar.StokbakiyeRapor': 5002,
  'GenelRaporlar.StokyillikortalamamaliyetRapor': 5003,
  'GenelRaporlar.StokdegerRapor': 5004,
  'GenelRaporlar.StokozelliklibakiyeRapor': 5005,
  'GenelRaporlar.StoksubebakiyeRapor': 5006,
  'GenelRaporlar.StoksubedepobakiyeRapor': 5007,
  'GenelRaporlar.StoksubedinamikdepobakiyeRapor': 5008,
  'GenelRaporlar.TalepAlisRapor': 5010,
  'GenelRaporlar.TalepAlisMaliyetRapor': 5011,
  'GenelRaporlar.TalepAlisOnayRapor': 5012,
  'GenelRaporlar.SiparisAlisRapor': 5013,
  'GenelRaporlar.SiparisAlisIcmalRapor': 5014,
  'GenelRaporlar.SiparisAlisTeslimIcmalRapor': 5015,
  'GenelRaporlar.IrsaliyeAlisRapor': 5016,
  'GenelRaporlar.TeklifAlisRapor': 5017,
  'GenelRaporlar.TeklifAlisKarsilastirmaRapor': 5018,
  'GenelRaporlar.TeklifAlisOnayRapor': 5019,
  'GenelRaporlar.SatisEncokAyRapor': 5021,
  'GenelRaporlar.SatisEncokCariRapor': 5022,
  'GenelRaporlar.SatisEncokStokRapor': 5023,
  'GenelRaporlar.SatisZararinaRapor': 5024,
  'GenelRaporlar.SatisZararAyRapor': 5025,
  'GenelRaporlar.SatisZararCariRapor': 5026,
  'GenelRaporlar.SatisXararStokRapor': 5027,
  'GenelRaporlar.SiparisSatisIcmalRapor': 5028,
  'GenelRaporlar.SiparisSatisTeslimIcmalRapor': 5029,
  'GenelRaporlar.BankaHareketRapor': 5030,
  'GenelRaporlar.KasaHareketRapor': 5031,
  'GenelRaporlar.CekalinanGenelRapor': 5032,
  'GenelRaporlar.CekalinanportfoyRapor': 5033,
  'GenelRaporlar.CekalinanprotestoRapor': 5034,
  'GenelRaporlar.CekalinantahsilRapor': 5035,
  'GenelRaporlar.CekalinanteminatRapor': 5036,
  'GenelRaporlar.CekalinanciroRapor': 5037,
  'GenelRaporlar.CekverilenbeklemedeRapor': 5038,
  'GenelRaporlar.CekverilenGenelRapor': 5050,
  'GenelRaporlar.SenetalinanGenelRapor': 5051,
  'GenelRaporlar.SenetalinanportfoyRapor': 5052,
  'GenelRaporlar.SenetalinanprotestoRapor': 5053,
  'GenelRaporlar.SenetalinantahsilRapor': 5054,
  'GenelRaporlar.SenetalinanteminatRapor': 5055,
  'GenelRaporlar.SenetalinanciroRapor': 5056,
  'GenelRaporlar.SenetverilenbeklemedeRapor': 5057,
  'GenelRaporlar.SenetverilenGenelRapor': 5058,
  'GenelRaporlar.TalepSatisRapor': 5039,
  'GenelRaporlar.TeklifSatisRapor': 5040,
  'GenelRaporlar.TeklifSatisOnayRapor': 5041,
  'GenelRaporlar.SiparisSatisRapor': 5042,
  'GenelRaporlar.IrsaliyeSatisRapor': 5043,
  'GenelRaporlar.SatisFaturahareketRapor': 5044,
  'GenelRaporlar.SatisFaturairsaliyeicmaliRapor': 5045,
  'GenelRaporlar.SatisFaturalanmamisirsaliyeRapor': 5046,
  'GenelRaporlar.AlisFaturahareketRapor': 5047,
  'GenelRaporlar.AlisFaturairsaliyeicmaliRapor': 5048,
  'GenelRaporlar.AlisFaturalanmamisirsaliyeRapor': 5049,
  'GenelRaporlar.StokhareketicmalRapor': 5059,
  'GenelRaporlar.CarikarlilikRapor': 5060,
  'GenelRaporlar.StokkarlilikRapor': 5061,
  'GenelRaporlar.PlasiyerkarlilikRapor': 5062,
  'GenelRaporlar.GiderfisiRapor': 5063,
  'GenelRaporlar.FaturakarlilikRapor': 5064,
  'GenelRaporlar.SipariskarlilikRapor': 5065,
  'GenelRaporlar.RaporMuhasebehesapplani': 5066,
  'GenelRaporlar.MuhasebeyevmiyefisiRapor': 5067,
  'GenelRaporlar.MuhasebemizanRapor': 5068,
  'GenelRaporlar.FinansplanRapor': 5069,
  'GenelRaporlar.MuhasebemuavinRapor': 5070,
  'GenelRaporlar.MuhasebebilancoRapor': 5071,
  'GenelRaporlar.MuhasebegelirtablosuRapor': 5072,
  'GenelRaporlar.FinansplankayitRapor': 5073,
  'GenelRaporlar.FinansplankayitnakitakisRapor': 5074,
  'GenelRaporlar.ProjekarlilikRapor': 5075,
  'GenelRaporlar.VadefarkiRapor': 5076,
  'GenelRaporlar.KreditaksitRapor': 5077,
  'GenelRaporlar.GenelsatisRapor': 5078,
  'GenelRaporlar.StoksayimfarkRapor': 5079,
  'GenelRaporlar.CarihareketRapor': 6000,
  'GenelRaporlar.CariborcalacakRapor': 6001,
  'GenelRaporlar.StokdurumRapor': 6002,
  'Dashboard.Finans': 5101,
  'Dashboard.Satinalma': 5102,
  'Dashboard.Satis': 5103,
};
const controllerModuleIds = <String, int>{
  'ambargc': 1301,
  'ambargchareket': 1301,
  'arac': 22,
  'arayuzmetinsirket': 30,
  'bankahareket': 1004,
  'bankahesap': 1002,
  'belgeseri': 5,
  'cari': 201,
  'caridevir': 206,
  'caridevirhareket': 206,
  'carikategori': 205,
  'caririsk': 202,
  'cekalinan': 1005,
  'cekalinanciro': 1006,
  'cekalinancirohareket': 1006,
  'cekalinanhareket': 1005,
  'cekalinaniade': 1010,
  'cekalinaniadehareket': 1010,
  'cekalinanportfoydentahsil': 1011,
  'cekalinanportfoydentahsilhareket': 1011,
  'cekalinanprotesto': 1009,
  'cekalinanprotestohareket': 1009,
  'cekalinantahsil': 1007,
  'cekalinantahsilhareket': 1007,
  'cekverilen': 1012,
  'cekverilenhareket': 1012,
  'cekverilenhareketdagilim': 1032,
  'cekverileniade': 1014,
  'cekverileniadehareket': 1014,
  'cekverilenodeme': 1013,
  'cekverilenodemehareket': 1013,
  'dashfinans': 5101,
  'dashfinansuyari': 5101,
  'dashkdv': 5101,
  'dashsatinalma': 5102,
  'dashsatinalmagrafik': 5102,
  'dashsatis': 5103,
  'dashsatisgrafik': 5103,
  'dat': 801,
  'dathareket': 801,
  'depo': 7,
  'depoadres': 9,
  'depotanim': 8,
  'dosyabelge': 1201,
  'dysdosya': 1102,
  'dysdosyabelge': 1102,
  'dysdosyatur': 1104,
  'dysklasor': 1101,
  'dyskullanicigrup': 1105,
  'dyskullanicigrupdetay': 1105,
  'dyskullanicigrupklasoryetki': 1103,
  'efatura': 301,
  'eihracat': 1601,
  'eirsaliye': 501,
  'fatura': 301,
  'faturaalis': 302,
  'faturahareket': 301,
  'faturahareketalis': 302,
  'finanskesinplan': 1030,
  'finansplan': 1028,
  'finansplanhareket': 1028,
  'finansplankayit': 1034,
  'finansplankayitgerceklesen': 1036,
  'finansplankayithareket': 1034,
  'finansplankayitonay': 1035,
  'finansplankayitverigiris': 1037,
  'finanstakibi': 1029,
  'firmakredikarti': 1026,
  'formdat': 801,
  'giderfisi': 1701,
  'giderfisihareket': 1701,
  'hesapplani': 1501,
  'irsaliye': 501,
  'irsaliyealis': 502,
  'irsaliyehareket': 501,
  'irsaliyehareketalis': 502,
  'kasa': 1001,
  'kasahareket': 1003,
  'kredi': 1031,
  'kredikartisozlesme': 1024,
  'krediodemeplani': 1031,
  'kullanici': 2,
  'kullanicigrup': 2,
  'kullanicigrupyetkiistisna': 2,
  'kullanicioturum': 28,
  'localyaziciayar': 29,
  'masaustu': 25,
  'masraf': 26,
  'muhasebeentegrasyonceksenet': 1505,
  'muhasebeentegrasyonkdv': 1503,
  'muhasebeentegrasyontevkifat': 1504,
  'odeme': 1027,
  'ozelhesapkapatma': 208,
  'parametrekullanicisirket': 21,
  'parametresirket': 19,
  'parametresirketerpview': 31,
  'plasiyer': 3,
  'proformafatura': 1601,
  'proformafaturahareket': 1601,
  'proje': 4,
  'recete': 901,
  'recetebilesen': 901,
  'referans': 24,
  'sabloncari': 207,
  'sablonstok': 114,
  'senetalinan': 1015,
  'senetalinanciro': 1016,
  'senetalinancirohareket': 1016,
  'senetalinanhareket': 1015,
  'senetalinaniade': 1019,
  'senetalinaniadehareket': 1019,
  'senetalinanportfoydentahsil': 1020,
  'senetalinanportfoydentahsilhareket': 1020,
  'senetalinanprotesto': 1018,
  'senetalinanprotestohareket': 1018,
  'senetalinantahsil': 1017,
  'senetalinantahsilhareket': 1017,
  'senetverilen': 1021,
  'senetverilenhareket': 1021,
  'senetverilenhareketdagilim': 1033,
  'senetverileniade': 1023,
  'senetverileniadehareket': 1023,
  'senetverilenodeme': 1022,
  'senetverilenodemehareket': 1022,
  'siparis': 401,
  'siparisalis': 402,
  'siparisalishareketonay': 404,
  'siparisaliskapanis': 406,
  'siparishareket': 401,
  'siparishareketalis': 402,
  'sipariskapanis': 405,
  'siparissatishareketonay': 403,
  'sirket': 1,
  'sirketozelrapor': 20,
  'stok': 101,
  'stokcari': 109,
  'stokdevir': 105,
  'stokdevirhareket': 105,
  'stokfiyatlistesi': 113,
  'stokfiyatlistesihareket': 113,
  'stokkategori': 110,
  'stokozelliksabit': 27,
  'stokparti': 116,
  'stoksayim': 115,
  'stoksayimhareket': 115,
  'stokseri': 117,
  'stokvirman': 112,
  'stokvirmanhareket': 112,
  'sube': 6,
  'surucu': 23,
  'tahsilat': 1025,
  'talep': 701,
  'talepalis': 702,
  'talepalishareketonay': 704,
  'talepaliskapanis': 706,
  'talephareket': 701,
  'talephareketalis': 702,
  'talephareketatama': 707,
  'talepkapanis': 705,
  'talepsatishareketonay': 703,
  'tedarikciteklif': 607,
  'teklif': 601,
  'teklifalis': 602,
  'teklifalishareketonay': 604,
  'teklifaliskapanis': 606,
  'teklifhareket': 601,
  'teklifhareketalis': 602,
  'teklifkapanis': 605,
  'teklifsatishareketonay': 603,
  'uretim': 902,
  'uretimemri': 903,
  'uretimemrihareket': 903,
  'uretimhareket': 902,
  'vw_finansplankayit': 5073,
  'vw_finansplannakitakis': 5074,
  'yetki': 2,
  'yevmiyefisi': 1502,
  'yevmiyefisihareket': 1502,
};
