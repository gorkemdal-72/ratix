import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';

/// Gizlilik Politikası Ekranı
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik Politikası')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Gizlilik Politikası'),
              const SizedBox(height: 8),
              Text('Son güncelleme: 13 Haziran 2026', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              _buildSection(context, '1. Toplanan Veriler',
                'Ratix uygulaması, hesap oluşturma sırasında e-posta adresinizi, kullanıcı adınızı ve görünen adınızı toplar. '
                'Ayrıca uygulamayı kullanırken oluşturduğunuz listeler, puanlamalar, yorumlar ve sosyal etkileşimler (takip, beğeni) kaydedilir.'),
              _buildSection(context, '2. Verilerin Kullanımı',
                'Topladığımız verileri yalnızca aşağıdaki amaçlarla kullanırız:\n'
                '• Hesabınızı oluşturmak ve yönetmek\n'
                '• Kişiselleştirilmiş içerik listelerinizi saklamak\n'
                '• Sosyal özellikler (takip, beğeni, yorum) sağlamak\n'
                '• Uygulama performansını iyileştirmek\n'
                '• Bildirim göndermek (izin verildiyse)'),
              _buildSection(context, '3. Veri Güvenliği',
                'Verileriniz Supabase altyapısında güvenli bir şekilde saklanır. '
                'Şifreler hash\'lenerek tutulur ve hiçbir zaman düz metin olarak saklanmaz. '
                'Tüm veri transferleri SSL/TLS şifrelemesi ile korunur.'),
              _buildSection(context, '4. Üçüncü Taraf Paylaşımı',
                'Kişisel verileriniz hiçbir üçüncü tarafla satılmaz veya paylaşılmaz. '
                'Yalnızca yasal zorunluluk durumlarında yetkili makamlarla paylaşılabilir.'),
              _buildSection(context, '5. Çerezler ve Analitik',
                'Uygulama, temel işlevsellik için yerel depolama (SharedPreferences, Hive) kullanır. '
                'Firebase Analytics aracılığıyla anonim kullanım istatistikleri toplanabilir.'),
              _buildSection(context, '6. Haklarınız',
                'Dilediğiniz zaman:\n'
                '• Hesabınızı ve tüm verilerinizi silmeyi talep edebilirsiniz\n'
                '• Verilerinizin bir kopyasını isteyebilirsiniz\n'
                '• Bildirim tercihlerinizi değiştirebilirsiniz\n'
                '• Profil bilgilerinizi güncelleyebilirsiniz'),
              _buildSection(context, '7. İletişim',
                'Gizlilik politikası hakkında sorularınız için ratixdestek@gmail.com adresinden bize ulaşabilirsiniz.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

/// Kullanım Koşulları Ekranı
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanım Koşulları')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Kullanım Koşulları'),
              const SizedBox(height: 8),
              Text('Son güncelleme: 13 Haziran 2026', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              _buildSection(context, '1. Kabul',
                'Ratix uygulamasını kullanarak bu kullanım koşullarını kabul etmiş sayılırsınız. '
                'Bu koşulları kabul etmiyorsanız uygulamayı kullanmayınız.'),
              _buildSection(context, '2. Hesap Kuralları',
                '• Her kullanıcı yalnızca bir hesap oluşturabilir\n'
                '• Hesap bilgilerinizin doğru ve güncel olması sizin sorumluluğunuzdadır\n'
                '• Hesabınızın güvenliğinden siz sorumlusunuz\n'
                '• 13 yaşından küçükler hesap oluşturamazlar'),
              _buildSection(context, '3. İçerik Kuralları',
                'Aşağıdaki içerikler kesinlikle yasaktır:\n'
                '• Hakaret, nefret söylemi, ayrımcılık\n'
                '• Spam veya yanıltıcı içerik\n'
                '• Uygunsuz veya müstehcen içerik\n'
                '• Telif hakkı ihlali\n'
                '• Diğer kullanıcılara taciz veya zorbalık'),
              _buildSection(context, '4. Moderasyon',
                'Ratix ekibi, kurallara aykırı içerikleri kaldırma ve hesapları askıya alma veya '
                'kalıcı olarak kapatma hakkını saklı tutar. Uyarı sistemi:\n'
                '• İlk ihlal: Uyarı\n'
                '• İkinci ihlal: Geçici susturma\n'
                '• Üçüncü ihlal: Kalıcı ban'),
              _buildSection(context, '5. Fikri Mülkiyet',
                'Ratix uygulamasının tasarımı, logosu ve kaynak kodu Ratix ekibine aittir. '
                'Kullanıcılar tarafından oluşturulan içerikler (listeler, yorumlar) kullanıcılara aittir.'),
              _buildSection(context, '6. Sorumluluk Reddi',
                'Ratix, üçüncü taraf API\'lerinden (TMDB, RAWG, Open Library, iTunes) alınan verilerin '
                'doğruluğundan sorumlu değildir. Uygulama "olduğu gibi" sunulmaktadır.'),
              _buildSection(context, '7. Değişiklikler',
                'Bu koşullar önceden haber verilmeksizin güncellenebilir. '
                'Güncel koşullar her zaman uygulama içinden erişilebilir.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

/// Destek ve İletişim Ekranı
class SupportContactScreen extends StatelessWidget {
  const SupportContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Destek ve İletişim')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          children: [
            // Üst banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Size Nasıl Yardımcı Olabiliriz?',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sorularınız ve önerileriniz için bize ulaşın',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),

            // İletişim kartları
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.cardShadow(context),
              ),
              child: Column(
                children: [
                  _buildContactTile(
                    context,
                    icon: Icons.email_outlined,
                    title: 'E-posta',
                    subtitle: 'ratixdestek@gmail.com',
                    onTap: () => _launchUrl('mailto:ratixdestek@gmail.com'),
                  ),

                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),

            // SSS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.cardShadow(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sık Sorulan Sorular', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildFAQ(context, 'Hesabımı nasıl silerim?',
                    'Ayarlar > Destek ve İletişim bölümünden bize e-posta göndererek hesap silme talebinde bulunabilirsiniz.'),
                  _buildFAQ(context, 'Şifremi unuttum, ne yapmalıyım?',
                    'Giriş ekranında "Şifremi Unuttum" seçeneğine tıklayarak e-posta adresinize sıfırlama linki gönderebilirsiniz.'),
                  _buildFAQ(context, 'Bir kullanıcıyı nasıl şikayet ederim?',
                    'Kullanıcının profil sayfasında sağ üst köşedeki menüden "Şikayet Et" seçeneğini kullanabilirsiniz.'),
                  _buildFAQ(context, 'Verilerim güvende mi?',
                    'Evet! Tüm verileriniz SSL şifrelemesi ile korunan Supabase altyapısında güvenle saklanmaktadır.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildFAQ(BuildContext context, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('❓ $question', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text(answer, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
        ],
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
