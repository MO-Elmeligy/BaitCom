import 'package:flutter/material.dart';

import '../data/mock_feed.dart';
import '../data/real_estate_api.dart';
import '../models/partnership_project.dart';
import '../models/property_listing.dart';
import 'create_partnership_page.dart';
import 'create_property_page.dart';

const _forest = Color(0xFF173B35);
const _sand = Color(0xFFF6F4EF);
const _copper = Color(0xFFB87945);

class InteractiveHomePage extends StatefulWidget {
  const InteractiveHomePage({super.key});

  @override
  State<InteractiveHomePage> createState() => _InteractiveHomePageState();
}

class _InteractiveHomePageState extends State<InteractiveHomePage> {
  final _searchController = TextEditingController();
  final _api = RealEstateApi();
  final Set<String> _favorites = <String>{};
  final List<PropertyListing> _userProperties = <PropertyListing>[];
  final List<PartnershipProject> _userProjects = <PartnershipProject>[];
  List<PropertyListing>? _apiProperties;
  List<PartnershipProject>? _apiProjects;
  String? _devUserId;
  bool _apiConnected = false;
  int _tab = 0;
  String _query = '';
  String _typeFilter = 'الكل';
  double _maximumPrice = 10000000;

  bool get _isPartnerships => _tab == 1;

  @override
  void initState() {
    super.initState();
    _loadApiFeed();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _api.close();
    super.dispose();
  }

  List<PropertyListing> get _visibleProperties {
    final published = _apiProperties ?? MockFeed.publishedProperties;
    final source = _tab == 2
        ? [...published, ..._userProperties]
            .where((item) => _favorites.contains(item.id))
        : [..._userProperties, ...published];
    return source.where((item) {
      final query = _query.trim().toLowerCase();
      final matchesText = query.isEmpty ||
          '${item.title} ${item.city} ${item.district}'
              .toLowerCase()
              .contains(query);
      final matchesType = _typeFilter == 'الكل' ||
          (_typeFilter == 'شقق' && item.propertyType == 'apartment') ||
          (_typeFilter == 'أراضٍ' && item.propertyType == 'land');
      return matchesText && matchesType && item.priceEgp <= _maximumPrice;
    }).toList();
  }

  List<PartnershipProject> get _visibleProjects {
    final query = _query.trim().toLowerCase();
    final projects = _apiProjects ?? MockFeed.openProjects;
    return [..._userProjects, ...projects].where((project) {
      return query.isEmpty ||
          '${project.title} ${project.description} ${project.city} ${project.district}'
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: _sand,
            title: const Row(children: [
              CircleAvatar(
                backgroundColor: _forest,
                child: Icon(Icons.domain_rounded, color: Colors.white),
              ),
              SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('بيت كو',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _forest)),
                Text('بيتك يبدأ بخطوة',
                    style: TextStyle(fontSize: 11, color: Colors.black54)),
              ]),
            ]),
            actions: [
              IconButton(
                tooltip: 'تحديث البيانات',
                onPressed: _loadApiFeed,
                icon: const Icon(Icons.refresh, color: _forest),
              ),
              IconButton(
                tooltip: 'الإشعارات',
                onPressed: () => _showMessage('لا توجد إشعارات جديدة حالياً'),
                icon: const Icon(Icons.notifications_none, color: _forest),
              ),
            ],
          ),
          body: SafeArea(child: _pageBody()),
          floatingActionButton: _tab == 3
              ? null
              : FloatingActionButton.extended(
                  backgroundColor: _forest,
                  foregroundColor: Colors.white,
                  onPressed: () => _createOptions(context),
                  icon: const Icon(Icons.add),
                  label: Text(_isPartnerships ? 'أنشئ مشروعاً' : 'أضف عقارك'),
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (value) {
              setState(() {
                _tab = value;
                _query = '';
                _searchController.clear();
              });
            },
            backgroundColor: Colors.white,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'العقارات'),
              NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups_rounded),
                  label: 'الشراكات'),
              NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'المفضلة'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'حسابي'),
            ],
          ),
        ),
      );

  Widget _pageBody() {
    if (_tab == 3) return _accountPage();
    final isFavorites = _tab == 2;
    final propertyMode = !_isPartnerships;
    final properties = _visibleProperties;
    final projects = _visibleProjects;
    final isEmpty = propertyMode ? properties.isEmpty : projects.isEmpty;

    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        if (!isFavorites) _hero(),
        if (!_apiConnected) _connectionNotice(),
        _searchBox(propertyMode),
        if (propertyMode && !isFavorites) _quickFilters(),
        _heading(
          isFavorites
              ? 'عقاراتك المفضلة'
              : (_isPartnerships ? 'شراكات متاحة' : 'عقارات مميزة'),
          isFavorites
              ? 'الإعلانات التي حفظتها للرجوع إليها'
              : (_isPartnerships ? 'فرص البناء المشترك' : 'اختيارات مناسبة لك'),
        ),
        if (isEmpty)
          _emptyState(
              isFavorites ? 'لم تحفظ أي عقار بعد' : 'لا توجد نتائج مطابقة'),
        if (propertyMode)
          ...properties.map(_propertyCard)
        else
          ...projects.map(_projectCard),
      ],
    );
  }

  Widget _hero() => Container(
        margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_forest, Color(0xFF2D6256)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              _isPartnerships
                  ? 'استثمروا في مستقبل مشترك'
                  : 'من المالك إليك مباشرة',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          Text(
              _isPartnerships
                  ? 'ابنِ بيتك مع شركاء تثق بهم'
                  : 'اعثر على بيتك القادم',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
              _isPartnerships
                  ? 'تابع التكلفة والمراحل والحصص بوضوح.'
                  : 'تصفح إعلانات مباشرة بلا تعقيد.',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          Row(children: [
            _stat(
                _isPartnerships ? 'مشاريع نشطة' : 'عقارات متاحة',
                _isPartnerships
                    ? MockFeed.activeProjectCountLabel
                    : MockFeed.publishedPropertyCountLabel),
            const SizedBox(width: 28),
            _stat(
                _isPartnerships ? 'شركاء' : 'مناطق',
                _isPartnerships
                    ? MockFeed.partnerCountLabel
                    : MockFeed.cityCountLabel),
          ]),
        ]),
      );

  Widget _connectionNotice() => Container(
        margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1D8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(children: [
          Icon(Icons.cloud_off_outlined, color: Color(0xFF94672A), size: 18),
          SizedBox(width: 8),
          Expanded(
              child: Text('وضع معاينة: الخادم غير متصل، نعرض بيانات تجريبية.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF76511F)))),
        ]),
      );

  Future<void> _loadApiFeed() async {
    try {
      final properties = await _api.getProperties();
      final projects = await _api.getProjects();
      String? userId;
      var myProperties = <PropertyListing>[];
      var myProjects = <PartnershipProject>[];
      try {
        userId = await _api.createDevelopmentSession();
        myProperties = await _api.getMyProperties(userId);
        myProjects = await _api.getMyProjects(userId);
      } catch (_) {
        // Public browsing still works when the development session is disabled.
      }
      if (!mounted) return;
      setState(() {
        _apiProperties = properties;
        _apiProjects = projects;
        _devUserId = userId;
        _apiConnected = true;
        _userProperties
          ..clear()
          ..addAll(myProperties);
        _userProjects
          ..clear()
          ..addAll(myProjects);
      });
    } catch (_) {
      if (mounted) setState(() => _apiConnected = false);
    }
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      );

  Widget _searchBox(bool propertyMode) => Container(
        margin: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE9E6DF))),
        child: Row(children: [
          const Icon(Icons.search, color: _forest),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: propertyMode
                    ? 'ابحث عن عقار أو منطقة'
                    : 'ابحث عن مشروع أو منطقة',
                hintStyle: const TextStyle(color: Colors.black45, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            tooltip: 'تصفية النتائج',
            onPressed: propertyMode ? _showFilters : null,
            icon: Icon(Icons.tune,
                color: propertyMode ? _copper : Colors.black26),
          ),
        ]),
      );

  Widget _quickFilters() => SizedBox(
        height: 44,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          scrollDirection: Axis.horizontal,
          children: [
            _filterChip('الكل'),
            _filterChip('شقق'),
            _filterChip('أراضٍ'),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 6),
              child: ActionChip(
                avatar: const Icon(Icons.tune, size: 16),
                label: const Text('السعر'),
                onPressed: _showFilters,
              ),
            ),
          ],
        ),
      );

  Widget _filterChip(String value) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 7),
        child: ChoiceChip(
          label: Text(value),
          selected: _typeFilter == value,
          onSelected: (_) => setState(() => _typeFilter = value),
          selectedColor: const Color(0xFFDCE9E2),
          labelStyle: TextStyle(
              color: _typeFilter == value ? _forest : Colors.black54,
              fontSize: 12),
          side: BorderSide(
              color: _typeFilter == value
                  ? const Color(0xFFDCE9E2)
                  : const Color(0xFFE9E6DF)),
        ),
      );

  Future<void> _showFilters() async {
    var type = _typeFilter;
    var ceiling = _maximumPrice;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تصفية العقارات',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _forest)),
                  const SizedBox(height: 18),
                  const Text('نوع العقار',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 8,
                      children: ['الكل', 'شقق', 'أراضٍ']
                          .map((item) => ChoiceChip(
                              label: Text(item),
                              selected: type == item,
                              onSelected: (_) =>
                                  setSheetState(() => type = item)))
                          .toList()),
                  const SizedBox(height: 16),
                  const Text('الحد الأقصى للسعر',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                      spacing: 8,
                      children: [2000000.0, 5000000.0, 10000000.0]
                          .map((price) => ChoiceChip(
                              label: Text(_priceLimitLabel(price)),
                              selected: ceiling == price,
                              onSelected: (_) =>
                                  setSheetState(() => ceiling = price)))
                          .toList()),
                  const SizedBox(height: 20),
                  Row(children: [
                    TextButton(
                        onPressed: () {
                          setSheetState(() {
                            type = 'الكل';
                            ceiling = 10000000;
                          });
                        },
                        child: const Text('إعادة ضبط')),
                    const Spacer(),
                    FilledButton(
                        onPressed: () {
                          setState(() {
                            _typeFilter = type;
                            _maximumPrice = ceiling;
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('عرض النتائج')),
                  ]),
                ]),
          ),
        ),
      ),
    );
  }

  String _priceLimitLabel(double price) => price == 2000000
      ? 'حتى ٢ مليون'
      : (price == 5000000 ? 'حتى ٥ ملايين' : 'كل الأسعار');

  Widget _heading(String title, String subtitle) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _forest)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
              ])),
          TextButton(
              onPressed: () {},
              child: const Text('عرض الكل', style: TextStyle(color: _copper))),
        ]),
      );

  Widget _propertyCard(PropertyListing listing) {
    final isFavorite = _favorites.contains(listing.id);
    return Card(
      margin: const EdgeInsets.fromLTRB(18, 4, 18, 10),
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFECE9E2))),
      child: InkWell(
        onTap: () => _showPropertyDetails(listing),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
                width: 82,
                height: 86,
                decoration: BoxDecoration(
                    color: const Color(0xFFE5ECE7),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(listing.listIcon, color: _forest, size: 34)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Icon(
                      listing.status == 'pending_review'
                          ? Icons.hourglass_top_rounded
                          : Icons.verified,
                      color: listing.status == 'pending_review'
                          ? _copper
                          : const Color(0xFF45836D),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      listing.status == 'pending_review'
                          ? 'قيد المراجعة'
                          : 'إعلان موثق',
                      style: TextStyle(
                        fontSize: 10,
                        color: listing.status == 'pending_review'
                            ? _copper
                            : const Color(0xFF45836D),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints:
                          const BoxConstraints.tightFor(width: 34, height: 34),
                      onPressed: () => setState(() => isFavorite
                          ? _favorites.remove(listing.id)
                          : _favorites.add(listing.id)),
                      icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.redAccent : Colors.black38,
                          size: 19),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: _forest)),
                  Text(listing.locationLabel,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54)),
                  const SizedBox(height: 5),
                  Text('${listing.priceLabel} جنيه',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: _copper)),
                  Text(listing.infoLabel,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black54)),
                ])),
          ]),
        ),
      ),
    );
  }

  Widget _projectCard(PartnershipProject project) => Card(
        margin: const EdgeInsets.fromLTRB(18, 4, 18, 10),
        color: Colors.white,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFECE9E2))),
        child: InkWell(
          onTap: () => _showProjectDetails(project),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const CircleAvatar(
                    backgroundColor: Color(0xFFE6EEE9),
                    child: Icon(Icons.apartment, color: _forest)),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(project.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: _forest)),
                      Text(project.description,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black54)),
                    ])),
                const Icon(Icons.arrow_back_ios_new,
                    size: 14, color: Colors.black38),
              ]),
              const SizedBox(height: 15),
              Row(children: [
                const Text('اكتمال المساهمات',
                    style: TextStyle(fontSize: 11, color: Colors.black54)),
                const Spacer(),
                Text('${(project.fundingProgress * 100).round()}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: _forest))
              ]),
              const SizedBox(height: 7),
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                      value: project.fundingProgress,
                      minHeight: 7,
                      color: _copper,
                      backgroundColor: const Color(0xFFECE9E2))),
              const SizedBox(height: 10),
              Text('${project.membersLabel}  ·  ${project.durationLabel}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ]),
          ),
        ),
      );

  Widget _emptyState(String message) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          const Icon(Icons.search_off_rounded, color: Colors.black26, size: 48),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Colors.black54)),
          TextButton(
              onPressed: () {
                setState(() {
                  _query = '';
                  _searchController.clear();
                  _typeFilter = 'الكل';
                  _maximumPrice = 10000000;
                });
              },
              child: const Text('مسح البحث والفلاتر')),
        ]),
      );

  Widget _accountPage() =>
      ListView(padding: const EdgeInsets.all(20), children: [
        const SizedBox(height: 12),
        const CircleAvatar(
            radius: 38,
            backgroundColor: Color(0xFFDCE9E2),
            child: Icon(Icons.person_outline, color: _forest, size: 40)),
        const SizedBox(height: 12),
        const Center(
            child: Text('مرحباً بك في بيت كو',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _forest))),
        const Center(
            child: Text('سجّل الدخول لإدارة إعلاناتك وطلباتك',
                style: TextStyle(color: Colors.black54))),
        const SizedBox(height: 20),
        FilledButton.icon(
            onPressed: () =>
                _showMessage('سيتم تفعيل تسجيل الدخول في المرحلة التالية'),
            icon: const Icon(Icons.phone_android),
            label: const Text('تسجيل الدخول برقم الهاتف')),
        const SizedBox(height: 12),
        _accountTile(
            Icons.home_work_outlined, 'إعلاناتي', 'إدارة العقارات التي أضفتها'),
        _accountTile(Icons.groups_outlined, 'مشاريعي وطلباتي',
            'متابعة الشراكات وطلبات الانضمام'),
        _accountTile(Icons.support_agent_outlined, 'المساعدة والدعم',
            'تواصل مع فريق بيت كو'),
      ]);

  Widget _accountTile(IconData icon, String title, String subtitle) => Card(
      color: Colors.white,
      elevation: 0,
      child: ListTile(
          leading: Icon(icon, color: _forest),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => _showMessage('سجّل الدخول للوصول إلى هذه الصفحة')));

  Future<void> _showPropertyDetails(PropertyListing listing) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            height: 170,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: const Color(0xFFE5ECE7),
                                borderRadius: BorderRadius.circular(18)),
                            child: Icon(listing.listIcon,
                                color: _forest, size: 64)),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: Text(listing.title,
                                  style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: _forest))),
                          IconButton(
                              onPressed: () {
                                setState(() => _favorites.add(listing.id));
                                Navigator.pop(sheetContext);
                                _showMessage('أُضيف العقار إلى المفضلة');
                              },
                              icon: const Icon(Icons.favorite_border,
                                  color: Colors.redAccent))
                        ]),
                        Text(listing.locationLabel,
                            style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text('${listing.priceLabel} جنيه',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _copper)),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          _infoPill(Icons.square_foot, listing.infoLabel),
                          _infoPill(
                              listing.status == 'pending_review'
                                  ? Icons.hourglass_top_rounded
                                  : Icons.verified_outlined,
                              listing.status == 'pending_review'
                                  ? 'قيد المراجعة'
                                  : 'إعلان موثق'),
                          _infoPill(
                              Icons.handshake_outlined, 'تواصل مباشر مع المالك')
                        ]),
                        const SizedBox(height: 14),
                        const Text('تفاصيل العقار',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _forest)),
                        const SizedBox(height: 6),
                        Text(listing.description.isEmpty
                            ? 'تفاصيل ومعلومات العقار مقدمة من المالك. ننصح بمعاينة الوحدة والتحقق من المستندات قبل إتمام أي اتفاق.'
                            : listing.description),
                        const SizedBox(height: 16),
                        SizedBox(
                            width: double.infinity,
                            child: listing.status == 'pending_review'
                                ? OutlinedButton.icon(
                                    onPressed: null,
                                    icon:
                                        const Icon(Icons.hourglass_top_rounded),
                                    label: const Text('الإعلان قيد المراجعة'),
                                  )
                                : FilledButton.icon(
                                    onPressed: () {
                                      Navigator.pop(sheetContext);
                                      _showMessage(
                                          'تم تسجيل طلب المعاينة تجريبياً');
                                    },
                                    icon: const Icon(Icons.calendar_month),
                                    label: const Text('طلب معاينة'))),
                      ]))),
        ),
      );

  Future<void> _showProjectDetails(PartnershipProject project) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [_forest, Color(0xFF2D6256)]),
                                borderRadius: BorderRadius.circular(18)),
                            child: const Icon(Icons.apartment_rounded,
                                color: Colors.white, size: 58)),
                        const SizedBox(height: 16),
                        Text(project.title,
                            style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: _forest)),
                        Text('${project.city} · ${project.district}',
                            style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 12),
                        Text(project.description,
                            style: const TextStyle(fontSize: 15)),
                        if (project.totalUnits != null ||
                            project.landPriceEgp != null ||
                            project.estimatedBuildCostEgp != null) ...[
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            if (project.totalUnits != null)
                              _infoPill(Icons.apartment,
                                  '${_eastern(project.totalUnits!)} وحدة'),
                            if (project.landPriceEgp != null)
                              _infoPill(Icons.landscape_outlined,
                                  'الأرض ${_formatEgp(project.landPriceEgp!)} ج.م'),
                            if (project.estimatedBuildCostEgp != null)
                              _infoPill(Icons.construction_outlined,
                                  'البناء ${_formatEgp(project.estimatedBuildCostEgp!)} ج.م'),
                          ]),
                        ],
                        const SizedBox(height: 18),
                        Text(
                            'اكتمال المساهمات: ${(project.fundingProgress * 100).round()}%',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: _forest)),
                        const SizedBox(height: 7),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                                value: project.fundingProgress,
                                minHeight: 9,
                                color: _copper,
                                backgroundColor: const Color(0xFFECE9E2))),
                        const SizedBox(height: 14),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          _infoPill(Icons.groups_outlined,
                              '${project.membersLabel} من ${_eastern(project.targetMembers)}'),
                          _infoPill(Icons.schedule, project.durationLabel),
                          _infoPill(Icons.location_on_outlined, project.city)
                        ]),
                        const SizedBox(height: 14),
                        const Text('قبل الانضمام',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _forest)),
                        const SizedBox(height: 6),
                        const Text(
                            'راجع مستندات الأرض وخطة التكلفة وآلية توزيع الوحدات. هذه الصفحة للتعريف بالمشروع فقط، ولا تستقبل أموالاً أو تنشئ التزاماً قانونياً.'),
                        const SizedBox(height: 16),
                        SizedBox(
                            width: double.infinity,
                            child: project.status == 'pending_review'
                                ? OutlinedButton.icon(
                                    onPressed: null,
                                    icon:
                                        const Icon(Icons.hourglass_top_rounded),
                                    label: const Text('المشروع قيد المراجعة'),
                                  )
                                : FilledButton.icon(
                                    onPressed: () {
                                      Navigator.pop(sheetContext);
                                      _showMessage(
                                          'تم تسجيل اهتمامك تجريبياً — لا توجد مدفوعات داخل التطبيق');
                                    },
                                    icon: const Icon(Icons.person_add_alt_1),
                                    label: const Text('طلب الانضمام'))),
                      ]))),
        ),
      );

  Widget _infoPill(IconData icon, String text) => Chip(
      avatar: Icon(icon, size: 16, color: _forest),
      label: Text(text, style: const TextStyle(fontSize: 11)),
      backgroundColor: const Color(0xFFF1F4F0),
      side: BorderSide.none);

  String _eastern(int number) => number
      .toString()
      .split('')
      .map((digit) => const {
            '0': '٠',
            '1': '١',
            '2': '٢',
            '3': '٣',
            '4': '٤',
            '5': '٥',
            '6': '٦',
            '7': '٧',
            '8': '٨',
            '9': '٩'
          }[digit]!)
      .join();

  String _formatEgp(double amount) {
    final digits = amount.round().toString();
    final grouped = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) grouped.write('٬');
      grouped.write(digits[index]);
    }
    return grouped
        .toString()
        .split('')
        .map((digit) =>
            const {
              '0': '٠',
              '1': '١',
              '2': '٢',
              '3': '٣',
              '4': '٤',
              '5': '٥',
              '6': '٦',
              '7': '٧',
              '8': '٨',
              '9': '٩',
            }[digit] ??
            digit)
        .join();
  }

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message), behavior: SnackBarBehavior.floating));

  void _createOptions(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ابدأ خطوتك التالية',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _forest)),
                  ListTile(
                      leading:
                          const Icon(Icons.home_work_outlined, color: _forest),
                      title: const Text('أضف إعلان عقار'),
                      subtitle: const Text('اعرض عقارك للمشترين مباشرة'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openPropertyForm();
                      }),
                  ListTile(
                      leading:
                          const Icon(Icons.groups_outlined, color: _forest),
                      title: const Text('أنشئ مشروع شراكة'),
                      subtitle: const Text('شارك تفاصيل الأرض وخطة المشروع'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openPartnershipForm();
                      }),
                ]),
          ),
        ),
      );

  Future<void> _openPropertyForm() async {
    final listing = await Navigator.of(context).push<PropertyListing>(
      MaterialPageRoute(builder: (_) => const CreatePropertyPage()),
    );
    if (!mounted || listing == null) return;
    var savedListing = listing;
    var message = 'تعذر الاتصال بالخادم؛ أُضيف العقار مؤقتاً على هذا الجهاز.';
    if (_devUserId != null) {
      try {
        savedListing = await _api.createProperty(
          ownerId: _devUserId!,
          listing: listing,
        );
        message = 'تم إرسال الإعلان إلى الخادم وهو قيد المراجعة.';
      } catch (_) {
        // Keep the in-memory draft available if the API cannot save it.
      }
    }
    if (!mounted) return;
    setState(() => _userProperties.insert(0, savedListing));
    _showMessage(message);
  }

  Future<void> _openPartnershipForm() async {
    final project = await Navigator.of(context).push<PartnershipProject>(
      MaterialPageRoute(builder: (_) => const CreatePartnershipPage()),
    );
    if (!mounted || project == null) return;
    var savedProject = project;
    var message = 'تعذر الاتصال بالخادم؛ أُضيف المشروع مؤقتاً على هذا الجهاز.';
    if (_devUserId != null) {
      try {
        savedProject = await _api.createProject(
          managerId: _devUserId!,
          project: project,
        );
        message = 'تم إرسال المشروع إلى الخادم وهو قيد المراجعة.';
      } catch (_) {
        // Keep the in-memory draft available if the API cannot save it.
      }
    }
    if (!mounted) return;
    setState(() => _userProjects.insert(0, savedProject));
    _showMessage(message);
  }
}
