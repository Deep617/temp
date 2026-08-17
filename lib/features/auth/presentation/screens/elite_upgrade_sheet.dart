// ─────────────────────────────────────────────────────────
//  elite_upgrade_sheet.dart
//  Bottom sheet shown when non-Elite taps influencer
//  Usage:
//    showModalBottomSheet(context: context,
//      builder: (_) => EliteUpgradeSheet(influencer: inf));
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/app_router.dart';
import '../../data/response_ml/register_response.dart';

class EliteUpgradeSheet extends StatelessWidget {
  const EliteUpgradeSheet({super.key, required this.influencer});
  final InfluencerProfile influencer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:        Color(0xFF0e0f14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border:       Border(top: BorderSide(color: Color(0xFF1C2438))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          // Influencer preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFFF6B00)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      influencer.firstName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(influencer.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(width: 6),
                          const Text('⭐',
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '📸 ${influencer.followers} followers · @${influencer.instagramHandle}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      if (influencer.primaryActivity != null)
                        Text(
                          '🏋️ ${influencer.primaryActivity}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // Locked badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: Color(0xFFF59E0B), size: 11),
                      SizedBox(width: 3),
                      Text('Elite', style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Divider
          Divider(
            height: 1,
            color: Colors.white.withOpacity(0.06),
            indent: 20, endIndent: 20,
          ),
          const SizedBox(height: 20),

          // Unlock text
          const Text('🔒 Match Locked',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 8),
          Text(
            'Upgrade to Elite to connect with\ntop fitness influencers',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Elite benefits
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.06),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.15)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ...[
                    ('⭐', 'Access to all Influencer profiles'),
                    ('📅', 'Book up to 3 sessions/month per influencer'),
                    ('🔓', 'Unlimited swipes + 100km radius'),
                    ('🎟️', '200 chat tokens'),
                  ].map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(e.$1, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Text(e.$2,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            )),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // CTA buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Skip button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Next Profile →',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                // Upgrade button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.subscription);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Upgrade to Elite ₹599/mo',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
