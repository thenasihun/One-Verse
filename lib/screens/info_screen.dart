import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oneverse/core/constants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart'; 
import 'package:url_launcher/url_launcher.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  // app version ko dynamically load karne ke liye
  String _appVersion = "1.0.1";     

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      // External Application mode Play Store aur WhatsApp ke liye zaroori hai
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open: $url")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardTheme.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About OneVerse'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        children: [
          const SizedBox(height: 10),
          // --- APP LOGO ---
          Center(
            child: Container(
              height: 110,
              width: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                // Logo path: assets/images/logo.png (Check if exists)
                child: Image.asset(
                  'assets/images/logo.png', 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.auto_awesome, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          _AboutCard(cardColor: cardColor, launchURL: _launchURL),
          
          const SizedBox(height: 24),
          
          // --- LINK TILES WITH FONT AWESOME ---
          _LinkTile(
            icon: Icons.language_rounded,
            label: "Visit Website",
            color: Colors.blue,
            onTap: () => _launchURL(AppConstants.nasihunWebsite),
          ),
          _LinkTile(
            icon: FontAwesomeIcons.whatsapp, // Professional Icon
            label: "Whatsapp Channel",
            color: const Color(0xFF25D366),
            onTap: () => _launchURL(AppConstants.whatsappUrl),
          ),
          _LinkTile(
            icon: Icons.grid_view_rounded,
            label: "More Islamic Apps",
            color: Theme.of(context).primaryColor,
            onTap: () => _launchURL(AppConstants.moreAppsUrl),
          ),
          _LinkTile(
            icon: Icons.alternate_email_rounded,
            label: "Contact & Feedback",
            color: Colors.orange,
            onTap: () => _launchURL(AppConstants.contactUrl),
          ),

          const SizedBox(height: 24),
          _SocialMediaCard(cardColor: cardColor, launchURL: _launchURL),
          
          const SizedBox(height: 32),
          
          // --- VERSION DISPLAY ---
          _VersionCard(version: _appVersion),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: FaIcon(icon, color: color, size: 18), // FaIcon for better scaling
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      ),
    );
  }
}

class _SocialMediaCard extends StatelessWidget {
  final Color? cardColor;
  final Future<void> Function(String url) launchURL;

  const _SocialMediaCard({required this.cardColor, required this.launchURL});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            "Follow us for updates",
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SocialButton(
                icon: FontAwesomeIcons.instagram,
                color: const Color(0xFFC13584),
                onTap: () => launchURL(AppConstants.instagramUrl),
              ),
              _SocialButton(
                icon: FontAwesomeIcons.facebook,
                color: const Color(0xFF1877F2),
                onTap: () => launchURL(AppConstants.facebookUrl),
              ),
              _SocialButton(
                icon: FontAwesomeIcons.youtube,
                color: const Color(0xFFFF0000),
                onTap: () => launchURL(AppConstants.youtubeUrl),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: FaIcon(icon, color: color, size: 28),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final Color? cardColor;
  final Future<void> Function(String url) launchURL;

  const _AboutCard({required this.cardColor, required this.launchURL});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "This app is a humble effort to make the Quran accessible, one verse at a time.",
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(fontSize: 18, height: 1.6),
            ),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.bodyMedium?.color),
                children: [
                  const TextSpan(text: "Designed & Presented by\n"),
                  TextSpan(
                    text: "Nasihun.com",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor, 
                      fontWeight: FontWeight.bold,
                      height: 2.0
                    ),
                    recognizer: TapGestureRecognizer()..onTap = () => launchURL(AppConstants.nasihunWebsite),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  final String version;

  const _VersionCard({required this.version});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "OneVerse", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)
        ),
        const SizedBox(height: 4),
        Text("Version $version", style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 12),
        const Text(
          "Built with love for the Ummah",
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ],
    );
  }
}