import 'package:flutter/material.dart';

import '../models/property_listing.dart';

const _formForest = Color(0xFF173B35);
const _formSand = Color(0xFFF6F4EF);

class CreatePropertyPage extends StatefulWidget {
  const CreatePropertyPage({super.key});

  @override
  State<CreatePropertyPage> createState() => _CreatePropertyPageState();
}

class _CreatePropertyPageState extends State<CreatePropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _price = TextEditingController();
  final _area = TextEditingController();
  final _bedrooms = TextEditingController(text: '2');
  String _type = 'apartment';

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _city.dispose();
    _district.dispose();
    _price.dispose();
    _area.dispose();
    _bedrooms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _formSand,
          appBar: AppBar(
              title: const Text('إضافة عقار'), backgroundColor: _formSand),
          body: Form(
            key: _formKey,
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _intro(
                      'أضف تفاصيل واضحة ليسهل على المشتري العثور على عقارك.'),
                  const SizedBox(height: 18),
                  _section('المعلومات الأساسية'),
                  _input(_title, 'عنوان الإعلان',
                      icon: Icons.title, requiredField: true),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    minLines: 2,
                    maxLines: 4,
                    decoration: _decoration('وصف العقار', Icons.notes),
                    validator: (value) => (value?.trim().length ?? 0) < 10
                        ? 'اكتب وصفاً من ١٠ أحرف على الأقل'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration:
                        _decoration('نوع العقار', Icons.home_work_outlined),
                    items: const [
                      DropdownMenuItem(value: 'apartment', child: Text('شقة')),
                      DropdownMenuItem(value: 'land', child: Text('أرض')),
                    ],
                    onChanged: (value) =>
                        setState(() => _type = value ?? 'apartment'),
                  ),
                  const SizedBox(height: 18),
                  _section('الموقع والسعر'),
                  Row(children: [
                    Expanded(
                        child: _input(_city, 'المدينة',
                            icon: Icons.location_city, requiredField: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _input(_district, 'المنطقة',
                            icon: Icons.place_outlined, requiredField: true)),
                  ]),
                  const SizedBox(height: 12),
                  _input(_price, 'السعر بالجنيه',
                      icon: Icons.payments_outlined,
                      requiredField: true,
                      numeric: true),
                  const SizedBox(height: 18),
                  _section('المساحة والتقسيم'),
                  Row(children: [
                    Expanded(
                        child: _input(_area, 'المساحة بالمتر²',
                            icon: Icons.square_foot,
                            requiredField: true,
                            numeric: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _input(_bedrooms, 'عدد الغرف',
                            icon: Icons.bed_outlined,
                            numeric: true,
                            requiredField: true)),
                  ]),
                  const SizedBox(height: 14),
                  const Text(
                      'تأكد من صحة السعر والموقع قبل الحفظ. سيرسل الإعلان إلى المراجعة إذا كان الخادم متصلاً.',
                      style: TextStyle(
                          color: Colors.black54, fontSize: 12, height: 1.5)),
                  const SizedBox(height: 22),
                  SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.check),
                          label: const Text('حفظ الإعلان'))),
                ]),
          ),
        ),
      );

  Widget _intro(String text) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFE7EEE9),
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.info_outline, color: _formForest),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: _formForest, height: 1.4)))
        ]),
      );

  Widget _section(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w800, color: _formForest, fontSize: 16)));

  Widget _input(TextEditingController controller, String label,
          {required IconData icon,
          required bool requiredField,
          bool numeric = false}) =>
      TextFormField(
        controller: controller,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: _decoration(label, icon),
        validator: (value) {
          final text = _normalize(value ?? '').trim();
          if (requiredField && text.isEmpty) return 'هذا الحقل مطلوب';
          if (numeric && text.isNotEmpty) {
            final number = double.tryParse(text);
            if (number == null || number < 0) return 'أدخل رقماً صحيحاً';
            if ((label.contains('السعر') || label.contains('المساحة')) &&
                number == 0) return 'يجب أن تكون القيمة أكبر من صفر';
          }
          return null;
        },
      );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _formForest),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E6DF))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _formForest, width: 1.4)),
      );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final bedrooms = int.tryParse(_normalize(_bedrooms.text)) ?? 0;
    Navigator.of(context).pop(PropertyListing(
      id: 'local-property-${DateTime.now().microsecondsSinceEpoch}',
      title: _title.text.trim(),
      description: _description.text.trim(),
      status: 'pending_review',
      city: _city.text.trim(),
      district: _district.text.trim(),
      priceEgp: double.parse(_normalize(_price.text)),
      areaM2: double.parse(_normalize(_area.text)),
      bedrooms: bedrooms,
      propertyType: _type,
      listIcon:
          _type == 'land' ? Icons.landscape_rounded : Icons.apartment_rounded,
    ));
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
