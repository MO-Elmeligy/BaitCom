import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class PostingFeeNotice extends StatelessWidget {
  const PostingFeeNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EBDD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2D5B9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.payments_outlined, color: Color(0xFF76552F)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.text('رسوم النشر: ٣٠٠ جنيه لكل إعلان أو مشروع شراكة'),
                  style: const TextStyle(
                    color: Color(0xFF513B24),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.text(
                    'التحصيل غير مفعّل حالياً. لن يتم خصم أي مبلغ حتى ربط بوابة الدفع.',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF665840),
                    height: 1.45,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
