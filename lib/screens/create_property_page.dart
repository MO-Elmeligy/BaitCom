import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/property_listing.dart';
import '../models/property_media.dart';
import '../utils/phone_number.dart';
import '../widgets/posting_fee_notice.dart';

const _formForest = Color(0xFF173B35);
const _formSand = Color(0xFFF6F4EF);

class CreatePropertyPage extends StatefulWidget {
  const CreatePropertyPage({
    required this.uploadMedia,
    super.key,
  });

  final Future<PropertyMedia> Function(XFile file) uploadMedia;

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
  final _contactPhone = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _selectedMedia = [];
  final Map<XFile, Future<Uint8List>> _mediaPreviews = {};
  final Map<XFile, PropertyMedia> _uploadedMedia = {};
  String _type = 'apartment';
  bool _isSubmitting = false;
  int _uploadedMediaCount = 0;

  static const _maxMediaCount = 10;
  static const _maxMediaBytes = 25 * 1024 * 1024;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _city.dispose();
    _district.dispose();
    _price.dispose();
    _area.dispose();
    _bedrooms.dispose();
    _contactPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: AppLocalizations.of(context).textDirection,
        child: Scaffold(
          backgroundColor: _formSand,
          appBar: AppBar(
              title: Text(AppLocalizations.of(context).text('إضافة عقار')),
              backgroundColor: _formSand),
          body: Form(
            key: _formKey,
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _intro(AppLocalizations.of(context).text(
                      'أضف تفاصيل واضحة ليسهل على المشتري العثور على عقارك.')),
                  const SizedBox(height: 18),
                  const PostingFeeNotice(),
                  const SizedBox(height: 18),
                  _section(context, 'المعلومات الأساسية'),
                  _input(context, _title, 'عنوان الإعلان',
                      icon: Icons.title, requiredField: true),
                  const SizedBox(height: 12),
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
                        'رقم التواصل يظهر للمهتمين بالإعلان ولا يتطلب إرسال رمز تحقق.',
                      ),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    minLines: 2,
                    maxLines: 4,
                    decoration: _decoration(context, 'وصف العقار', Icons.notes),
                    validator: (value) => (value?.trim().length ?? 0) < 10
                        ? AppLocalizations.of(context)
                            .text('اكتب وصفاً من ١٠ أحرف على الأقل')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: _decoration(
                        context, 'نوع العقار', Icons.home_work_outlined),
                    items: [
                      DropdownMenuItem(
                        value: 'apartment',
                        child: Text(AppLocalizations.of(context).text('شقة')),
                      ),
                      DropdownMenuItem(
                        value: 'land',
                        child: Text(AppLocalizations.of(context).text('أرض')),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _type = value ?? 'apartment'),
                  ),
                  const SizedBox(height: 18),
                  _section(context, 'صور وفيديو العقار'),
                  Text(
                    AppLocalizations.of(context).text(
                      'أضف حتى ١٠ صور أو فيديوهات، بحد أقصى ٢٥ ميجابايت للملف.',
                    ),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickImages,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          AppLocalizations.of(context).text('إضافة صور'),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickVideo,
                        icon: const Icon(Icons.video_library_outlined),
                        label: Text(
                          AppLocalizations.of(context).text('إضافة فيديو'),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedMedia.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedMedia.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) =>
                            _mediaPreview(_selectedMedia[index]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _section(context, 'الموقع والسعر'),
                  Row(children: [
                    Expanded(
                        child: _input(context, _city, 'المدينة',
                            icon: Icons.location_city, requiredField: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _input(context, _district, 'المنطقة',
                            icon: Icons.place_outlined, requiredField: true)),
                  ]),
                  const SizedBox(height: 12),
                  _input(context, _price, 'السعر بالجنيه',
                      icon: Icons.payments_outlined,
                      requiredField: true,
                      numeric: true,
                      strictlyPositive: true),
                  const SizedBox(height: 18),
                  _section(context, 'المساحة والتقسيم'),
                  Row(children: [
                    Expanded(
                        child: _input(context, _area, 'المساحة بالمتر²',
                            icon: Icons.square_foot,
                            requiredField: true,
                            numeric: true,
                            strictlyPositive: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _input(context, _bedrooms, 'عدد الغرف',
                            icon: Icons.bed_outlined,
                            numeric: true,
                            requiredField: true)),
                  ]),
                  const SizedBox(height: 14),
                  Text(AppLocalizations.of(context).text(
                      'تأكد من صحة السعر والموقع قبل الحفظ. سيرسل الإعلان إلى المراجعة إذا كان الخادم متصلاً.'),
                      style: TextStyle(
                          color: Colors.black54, fontSize: 12, height: 1.5)),
                  const SizedBox(height: 22),
                  if (_isSubmitting) ...[
                    LinearProgressIndicator(
                      value: _selectedMedia.isEmpty
                          ? null
                          : _uploadedMediaCount / _selectedMedia.length,
                      color: _formForest,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).text(
                        'جارٍ رفع الوسائط وحفظ الإعلان...',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(AppLocalizations.of(context)
                              .text('حفظ الإعلان')))),
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

  Widget _section(BuildContext context, String title) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: _formForest,
          fontSize: 16)),
    );

  Widget _input(BuildContext context, TextEditingController controller, String label,
          {required IconData icon,
          required bool requiredField,
          bool numeric = false,
          bool strictlyPositive = false}) =>
      TextFormField(
        controller: controller,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: _decoration(context, label, icon),
        validator: (value) {
          final strings = AppLocalizations.of(context);
          final text = _normalize(value ?? '').trim();
          if (requiredField && text.isEmpty) {
            return strings.text('هذا الحقل مطلوب');
          }
          if (numeric && text.isNotEmpty) {
            final number = double.tryParse(text);
            if (number == null || number < 0) {
              return strings.text('أدخل رقماً صحيحاً');
            }
            if (strictlyPositive && number == 0) {
              return strings.text('يجب أن تكون القيمة أكبر من صفر');
            }
          }
          return null;
        },
      );

  InputDecoration _decoration(
          BuildContext context, String label, IconData icon) =>
      InputDecoration(
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

  Future<void> _pickImages() async {
    final remaining = _maxMediaCount - _selectedMedia.length;
    if (remaining <= 0) {
      _showMediaLimitMessage();
      return;
    }
    try {
      final files = await _picker.pickMultiImage(
        limit: remaining,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (!mounted || files.isEmpty) return;
      for (final file in files.take(remaining)) {
        await _addSelectedMedia(file);
      }
    } catch (error) {
      _showPickerError(error);
    }
  }

  Future<void> _pickVideo() async {
    if (_selectedMedia.length >= _maxMediaCount) {
      _showMediaLimitMessage();
      return;
    }
    try {
      final file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (!mounted || file == null) return;
      await _addSelectedMedia(file);
    } catch (error) {
      _showPickerError(error);
    }
  }

  Future<void> _addSelectedMedia(XFile file) async {
    if (await file.length() > _maxMediaBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).text(
              'حجم الملف أكبر من الحد المسموح به وهو ٢٥ ميجابايت.',
            ),
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _selectedMedia.add(file);
      _mediaPreviews[file] = file.readAsBytes();
    });
  }

  Widget _mediaPreview(XFile file) {
    final isVideo = _isVideo(file);
    return SizedBox(
      width: 92,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isVideo
                ? const ColoredBox(
                    color: Color(0xFFE7EEE9),
                    child: Icon(
                      Icons.play_circle_outline_rounded,
                      color: _formForest,
                      size: 38,
                    ),
                  )
                : FutureBuilder<Uint8List>(
                    future: _mediaPreviews[file],
                    builder: (context, snapshot) => snapshot.hasData
                        ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                        : const ColoredBox(
                            color: Color(0xFFE7EEE9),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                  ),
          ),
          PositionedDirectional(
            top: 3,
            end: 3,
            child: IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() {
                        _selectedMedia.remove(file);
                        _mediaPreviews.remove(file);
                        _uploadedMedia.remove(file);
                      }),
              icon: const Icon(Icons.close, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  bool _isVideo(XFile file) =>
      file.mimeType?.startsWith('video/') ??
      const {'mp4', 'mov', 'm4v', 'webm'}
          .contains(file.name.split('.').last.toLowerCase());

  void _showMediaLimitMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).text('الحد الأقصى ١٠ ملفات للإعلان.'),
        ),
      ),
    );
  }

  void _showPickerError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${AppLocalizations.of(context).text('تعذر اختيار الملف')}: $error',
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final contactPhone = normalizeContactPhoneNumber(_contactPhone.text)!;
    final bedrooms = int.tryParse(_normalize(_bedrooms.text)) ?? 0;
    setState(() {
      _isSubmitting = true;
      _uploadedMediaCount = 0;
    });

    try {
      final uploadedMedia = <PropertyMedia>[];
      for (final file in _selectedMedia) {
        final media =
            _uploadedMedia[file] ?? await widget.uploadMedia(file);
        _uploadedMedia[file] = media;
        uploadedMedia.add(media);
        if (!mounted) return;
        setState(() => _uploadedMediaCount = uploadedMedia.length);
      }
      if (!mounted) return;
      Navigator.of(context).pop(
        PropertyListing(
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
          contactPhone: contactPhone,
          listIcon:
              _type == 'land' ? Icons.landscape_rounded : Icons.apartment_rounded,
          media: uploadedMedia,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).text('تعذر رفع الوسائط')}: $error',
          ),
        ),
      );
    }
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
