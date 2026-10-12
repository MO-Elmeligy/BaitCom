import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/partnership_project.dart';
import '../utils/phone_number.dart';
import '../widgets/posting_fee_notice.dart';

const _partnershipForest = Color(0xFF173B35);
const _partnershipSand = Color(0xFFF6F4EF);

class CreatePartnershipPage extends StatefulWidget {
  const CreatePartnershipPage({super.key});

  @override
  State<CreatePartnershipPage> createState() => _CreatePartnershipPageState();
}

class _CreatePartnershipPageState extends State<CreatePartnershipPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _landPrice = TextEditingController();
  final _buildCost = TextEditingController();
  final _minimumContribution = TextEditingController();
  final _units = TextEditingController(text: '8');
  final _members = TextEditingController(text: '8');
  final _duration = TextEditingController(text: '18');
  final _contactPhone = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _city.dispose();
    _district.dispose();
    _landPrice.dispose();
    _buildCost.dispose();
    _minimumContribution.dispose();
    _units.dispose();
    _members.dispose();
    _duration.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: AppLocalizations.of(context).textDirection,
    child: Scaffold(
      backgroundColor: _partnershipSand,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).text('إنشاء مشروع شراكة')),
        backgroundColor: _partnershipSand,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _note(
              AppLocalizations.of(context).text(
                'عرّف بالمشروع وتكاليفه المتوقعة بوضوح. لا يتم تحصيل أموال أو إنشاء التزامات قانونية من خلال هذه النسخة.',
              ),
            ),
            const SizedBox(height: 18),
            const PostingFeeNotice(),
            const SizedBox(height: 18),
            _section(context, 'بيانات المشروع'),
            _input(
              context,
              _title,
              'اسم المشروع',
              Icons.apartment_outlined,
              requiredField: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              decoration: _decoration(
                context,
                'وصف المشروع وخطته',
                Icons.notes,
              ),
              validator: (value) => (value?.trim().length ?? 0) < 20
                  ? AppLocalizations.of(
                      context,
                    ).text('اكتب وصفاً من ٢٠ حرفاً على الأقل')
                  : null,
            ),
            const SizedBox(height: 18),
            _section(context, 'الموقع'),
            Row(
              children: [
                Expanded(
                  child: _input(
                    context,
                    _city,
                    'المدينة',
                    Icons.location_city,
                    requiredField: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _input(
                    context,
                    _district,
                    'المنطقة',
                    Icons.place_outlined,
                    requiredField: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _section(context, 'بيانات التواصل'),
            TextFormField(
              controller: _contactPhone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: _decoration(
                context,
                'رقم الهاتف للتواصل',
                Icons.phone_android,
              ),
              validator: (value) =>
                  normalizeContactPhoneNumber(value ?? '') == null
                  ? AppLocalizations.of(
                      context,
                    ).text('أدخل رقم هاتف صحيح للتواصل')
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                AppLocalizations.of(context).text(
                  'رقم التواصل يظهر للمهتمين بالمشروع ولا يتطلب إرسال رمز تحقق.',
                ),
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 18),
            _section(context, 'التكلفة والمشاركون'),
            _input(
              context,
              _landPrice,
              'سعر الأرض بالجنيه',
              Icons.landscape_outlined,
              requiredField: true,
              numeric: true,
            ),
            const SizedBox(height: 12),
            _input(
              context,
              _minimumContribution,
              'الحد الأدنى للمساهمة بالجنيه',
              Icons.payments_outlined,
              requiredField: true,
              numeric: true,
            ),
            _input(
              context,
              _buildCost,
              'تقدير تكلفة البناء بالجنيه',
              Icons.construction_outlined,
              requiredField: true,
              numeric: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _input(
                    context,
                    _units,
                    'عدد الوحدات',
                    Icons.home_work_outlined,
                    requiredField: true,
                    numeric: true,
                    positiveInt: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _input(
                    context,
                    _members,
                    'عدد الشركاء',
                    Icons.groups_outlined,
                    requiredField: true,
                    numeric: true,
                    positiveInt: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _input(
              context,
              _duration,
              'المدة المتوقعة بالأشهر',
              Icons.schedule,
              requiredField: true,
              numeric: true,
              positiveInt: true,
            ),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context).text(
                'التكاليف تقديرية ويجب مراجعتها مع مختصين. أرفق المستندات والعقود بعد اعتماد آلية التحقق القانونية.',
              ),
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(AppLocalizations.of(context).text('حفظ المشروع')),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _note(String text) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFE7EEE9),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: _partnershipForest),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _partnershipForest, height: 1.5),
          ),
        ),
      ],
    ),
  );

  Widget _section(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: _partnershipForest,
        fontSize: 16,
      ),
    ),
  );

  Widget _input(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon, {
    required bool requiredField,
    bool numeric = false,
    bool positiveInt = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: numeric ? TextInputType.number : TextInputType.text,
    decoration: _decoration(context, label, icon),
    validator: (value) {
      final strings = AppLocalizations.of(context);
      final text = _normalize(value ?? '').trim();
      if (requiredField && text.isEmpty) {
        return strings.text('هذا الحقل مطلوب');
      }
      if (numeric && text.isNotEmpty) {
        final number = double.tryParse(text);
        if (number == null || number <= 0) {
          return strings.text('أدخل رقماً أكبر من صفر');
        }
        if (positiveInt && number != number.roundToDouble()) {
          return strings.text('أدخل عدداً صحيحاً');
        }
      }
      return null;
    },
  );

  InputDecoration _decoration(
    BuildContext context,
    String label,
    IconData icon,
  ) => InputDecoration(
    labelText: label,
    alignLabelWithHint: true,
    prefixIcon: Icon(icon, color: _partnershipForest),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE8E6DF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _partnershipForest, width: 1.4),
    ),
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      PartnershipProject(
        id: 'local-project-${DateTime.now().microsecondsSinceEpoch}',
        title: _title.text.trim(),
        description: _description.text.trim(),
        city: _city.text.trim(),
        district: _district.text.trim(),
        targetMembers: int.parse(_normalize(_members.text)),
        expectedDurationMonths: int.parse(_normalize(_duration.text)),
        fundingProgress: 0,
        currentMemberCount: 0,
        totalUnits: int.parse(_normalize(_units.text)),
        landPriceEgp: double.parse(_normalize(_landPrice.text)),
        estimatedBuildCostEgp: double.parse(_normalize(_buildCost.text)),
        minimumContributionEgp: double.parse(
          _normalize(_minimumContribution.text),
        ),
        status: 'pending_review',
        contactPhone:
            normalizeContactPhoneNumber(_contactPhone.text.trim())!,
      ),
    );
  }

  String _normalize(String value) => value
      .replaceAll('٬', '')
      .replaceAll(',', '')
      .replaceAll('٫', '.')
      .replaceAll('٠', '0')
      .replaceAll('١', '1')
      .replaceAll('٢', '2')
      .replaceAll('٣', '3')
      .replaceAll('٤', '4')
      .replaceAll('٥', '5')
      .replaceAll('٦', '6')
      .replaceAll('٧', '7')
      .replaceAll('٨', '8')
      .replaceAll('٩', '9');
}
