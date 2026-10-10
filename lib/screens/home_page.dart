import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_transitions/go_transitions.dart';

import '../auth/firebase_auth_status.dart';
import '../data/cloudinary_media_uploader.dart';
import '../data/mock_feed.dart';
import '../data/real_estate_api.dart';
import '../l10n/app_localizations.dart';
import '../models/partnership_project.dart';
import '../models/property_listing.dart';
import '../widgets/bayt_co_logo.dart';
import '../widgets/liquid_glass_bottom_nav_bar.dart';
import '../widgets/property_media_gallery.dart';
import 'create_partnership_page.dart';
import 'create_property_page.dart';
import 'phone_auth_page.dart';

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
  late final _api = RealEstateApi(idTokenProvider: currentFirebaseIdToken);
  late final _mediaUploader = CloudinaryMediaUploader(
    signatureProvider: _api.createMediaUploadSignature,
  );
  final Set<String> _favorites = <String>{};
  final List<PropertyListing> _userProperties = <PropertyListing>[];
  final List<PartnershipProject> _userProjects = <PartnershipProject>[];
  List<PropertyListing>? _apiProperties;
  List<PartnershipProject>? _apiProjects;
  String? _devUserId;
  bool _apiConnected = false;
  int _tab = 0;
  String _query = '';
  String _typeFilter = 'all';
  double _maximumPrice = double.infinity;

  bool get _isPartnerships => _tab == 1;
  bool get _hasApiReadyFirebaseUser =>
      firebaseAuthReady &&
      FirebaseAuth.instance.currentUser?.phoneNumber?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    _loadApiFeed();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _api.close();
    _mediaUploader.close();
    super.dispose();
  }

  List<PropertyListing> get _visibleProperties {
    final apiProperties = _apiProperties ?? const <PropertyListing>[];
    final published = kReleaseMode
        ? apiProperties
        : [
            ...apiProperties,
            ...MockFeed.publishedProperties.where(
              (sample) =>
                  !apiProperties.any((listing) => listing.id == sample.id),
            ),
          ];
    final source = _tab == 2
        ? [
            ...published,
            ..._userProperties,
          ].where((item) => _favorites.contains(item.id))
        : [..._userProperties, ...published];
    return source.where((item) {
      final query = _query.trim().toLowerCase();
      final matchesText =
          query.isEmpty ||
          '${item.title} ${item.city} ${item.district}'.toLowerCase().contains(
            query,
          );
      final matchesType =
          _typeFilter == 'all' ||
          (_typeFilter == 'apartment' && item.propertyType == 'apartment') ||
          (_typeFilter == 'land' && item.propertyType == 'land');
      return matchesText && matchesType && item.priceEgp <= _maximumPrice;
    }).toList();
  }

  List<PartnershipProject> get _visibleProjects {
    final query = _query.trim().toLowerCase();
    final apiProjects = _apiProjects ?? const <PartnershipProject>[];
    final projects = kReleaseMode
        ? apiProjects
        : [
            ...apiProjects,
            ...MockFeed.openProjects.where(
              (sample) =>
                  !apiProjects.any((project) => project.id == sample.id),
            ),
          ];
    return [..._userProjects, ...projects].where((project) {
      return query.isEmpty ||
          '${project.title} ${project.description} ${project.city} ${project.district}'
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: AppLocalizations.of(context).textDirection,
    child: Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: _sand,
        title: Row(
          children: [
            const BaytCoLogo(size: 42),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).text('بيت كو'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _forest,
                  ),
                ),
                Text(
                  AppLocalizations.of(context).text('بيتك يبدأ بخطوة'),
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).text('تحديث البيانات'),
            onPressed: _loadApiFeed,
            icon: const Icon(Icons.refresh, color: _forest),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).text('الإشعارات'),
            onPressed: () => _showMessage(
              AppLocalizations.of(context).text('لا توجد إشعارات جديدة حالياً'),
            ),
            icon: const Icon(Icons.notifications_none, color: _forest),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, .025),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_tab), child: _pageBody()),
        ),
      ),
      floatingActionButton: _tab == 3
          ? null
          : FloatingActionButton.extended(
              backgroundColor: _forest,
              foregroundColor: Colors.white,
              onPressed: () => _createOptions(context),
              icon: const Icon(Icons.add),
              label: Text(
                AppLocalizations.of(
                  context,
                ).text(_isPartnerships ? 'أنشئ مشروعاً' : 'أضف عقارك'),
              ),
            ),
      bottomNavigationBar: LiquidGlassBottomNavBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) {
          setState(() {
            _tab = value;
            _query = '';
            _searchController.clear();
          });
        },
        destinations: [
          GlassNavDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: AppLocalizations.of(context).text('العقارات'),
          ),
          GlassNavDestination(
            icon: Icons.groups_outlined,
            selectedIcon: Icons.groups_rounded,
            label: AppLocalizations.of(context).text('الشراكات'),
          ),
          GlassNavDestination(
            icon: Icons.favorite_border,
            selectedIcon: Icons.favorite,
            label: AppLocalizations.of(context).text('المفضلة'),
          ),
          GlassNavDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: AppLocalizations.of(context).text('حسابي'),
          ),
        ],
      ),
    ),
  );

  Widget _pageBody() {
    if (_tab == 3) return _accountPage();
    final strings = AppLocalizations.of(context);
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
              ? strings.text('عقاراتك المفضلة')
              : strings.text(_isPartnerships ? 'شراكات متاحة' : 'عقارات مميزة'),
          isFavorites
              ? strings.text('الإعلانات التي حفظتها للرجوع إليها')
              : strings.text(
                  _isPartnerships ? 'فرص البناء المشترك' : 'اختيارات مناسبة لك',
                ),
        ),
        if (isEmpty)
          _emptyState(
            strings.text(
              isFavorites ? 'لم تحفظ أي عقار بعد' : 'لا توجد نتائج مطابقة',
            ),
          ),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).text(
            _isPartnerships
                ? 'استثمروا في مستقبل مشترك'
                : 'من المالك إليك مباشرة',
          ),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Text(
          AppLocalizations.of(context).text(
            _isPartnerships
                ? 'ابنِ بيتك مع شركاء تثق بهم'
                : 'اعثر على بيتك القادم',
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context).text(
            _isPartnerships
                ? 'تابع التكلفة والمراحل والحصص بوضوح.'
                : 'تصفح إعلانات مباشرة بلا تعقيد.',
          ),
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _stat(
              AppLocalizations.of(
                context,
              ).text(_isPartnerships ? 'مشاريع نشطة' : 'عقارات متاحة'),
              _isPartnerships
                  ? AppLocalizations.of(context).digits(
                      kReleaseMode
                          ? (_apiProjects?.length ?? 0)
                          : MockFeed.activeProjectCountLabel,
                    )
                  : AppLocalizations.of(context).digits(
                      kReleaseMode
                          ? (_apiProperties?.length ?? 0)
                          : MockFeed.publishedPropertyCountLabel,
                    ),
            ),
            const SizedBox(width: 28),
            _stat(
              AppLocalizations.of(
                context,
              ).text(_isPartnerships ? 'شركاء' : 'مناطق'),
              _isPartnerships
                  ? AppLocalizations.of(context).digits(
                      kReleaseMode
                          ? (_apiProjects?.fold<int>(
                                  0,
                                  (total, project) =>
                                      total + project.currentMemberCount,
                                ) ??
                                0)
                          : MockFeed.partnerCountLabel,
                    )
                  : AppLocalizations.of(context).digits(
                      kReleaseMode
                          ? (_apiProperties
                                    ?.map((listing) => listing.city)
                                    .toSet()
                                    .length ??
                                0)
                          : MockFeed.cityCountLabel,
                    ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _connectionNotice() => Container(
    margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1D8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          color: Color(0xFF94672A),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context).text(
              kReleaseMode
                  ? 'تعذر إرسال الطلب الآن. تحقق من اتصال الخادم وحاول مجدداً.'
                  : 'وضع معاينة: الخادم غير متصل، نعرض بيانات تجريبية.',
            ),
            style: const TextStyle(fontSize: 11, color: Color(0xFF76511F)),
          ),
        ),
      ],
    ),
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
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );

  Widget _searchBox(bool propertyMode) => Container(
    margin: const EdgeInsets.fromLTRB(18, 18, 18, 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE9E6DF)),
    ),
    child: Row(
      children: [
        const Icon(Icons.search, color: _forest),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).text(
                propertyMode
                    ? 'ابحث عن عقار أو منطقة'
                    : 'ابحث عن مشروع أو منطقة',
              ),
              hintStyle: const TextStyle(color: Colors.black45, fontSize: 13),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context).text('تصفية النتائج'),
          onPressed: propertyMode ? _showFilters : null,
          icon: Icon(
            Icons.tune,
            color: propertyMode ? _copper : Colors.black26,
          ),
        ),
      ],
    ),
  );

  Widget _quickFilters() => SizedBox(
    height: 44,
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      scrollDirection: Axis.horizontal,
      children: [
        _filterChip('all', 'الكل'),
        _filterChip('apartment', 'شقق'),
        _filterChip('land', 'أراضٍ'),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 6),
          child: ActionChip(
            avatar: const Icon(Icons.tune, size: 16),
            label: Text(AppLocalizations.of(context).text('السعر')),
            onPressed: _showFilters,
          ),
        ),
      ],
    ),
  );

  Widget _filterChip(String value, String label) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 7),
    child: ChoiceChip(
      label: Text(AppLocalizations.of(context).text(label)),
      selected: _typeFilter == value,
      onSelected: (_) => setState(() => _typeFilter = value),
      selectedColor: const Color(0xFFDCE9E2),
      labelStyle: TextStyle(
        color: _typeFilter == value ? _forest : Colors.black54,
        fontSize: 12,
      ),
      side: BorderSide(
        color: _typeFilter == value
            ? const Color(0xFFDCE9E2)
            : const Color(0xFFE9E6DF),
      ),
    ),
  );

  Future<void> _showFilters() async {
    var type = _typeFilter;
    var ceiling = _maximumPrice;
    final strings = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Directionality(
          textDirection: strings.textDirection,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.text('تصفية العقارات'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _forest,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  strings.text('نوع العقار'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      const [
                            ('all', 'الكل'),
                            ('apartment', 'شقق'),
                            ('land', 'أراضٍ'),
                          ]
                          .map(
                            (item) => ChoiceChip(
                              label: Text(strings.text(item.$2)),
                              selected: type == item.$1,
                              onSelected: (_) =>
                                  setSheetState(() => type = item.$1),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.text('الحد الأقصى للسعر'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: [2000000.0, 5000000.0, double.infinity]
                      .map(
                        (price) => ChoiceChip(
                          label: Text(_priceLimitLabel(price, strings)),
                          selected: ceiling == price,
                          onSelected: (_) =>
                              setSheetState(() => ceiling = price),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          type = 'all';
                          ceiling = double.infinity;
                        });
                      },
                      child: Text(strings.text('إعادة ضبط')),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _typeFilter = type;
                          _maximumPrice = ceiling;
                        });
                        Navigator.pop(sheetContext);
                      },
                      child: Text(strings.text('عرض النتائج')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _priceLimitLabel(double price, AppLocalizations strings) =>
      strings.isArabic
      ? (price == 2000000
            ? 'حتى ٢ مليون'
            : (price == 5000000 ? 'حتى ٥ ملايين' : 'كل الأسعار'))
      : (price == 2000000
            ? 'Up to EGP 2 million'
            : (price == 5000000 ? 'Up to EGP 5 million' : 'Any price'));

  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _forest,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            AppLocalizations.of(context).text('عرض الكل'),
            style: const TextStyle(color: _copper),
          ),
        ),
      ],
    ),
  );

  Widget _propertyCard(PropertyListing listing) {
    final strings = AppLocalizations.of(context);
    final isFavorite = _favorites.contains(listing.id);
    final coverImages = listing.media.where((item) => item.type == 'image');
    final coverImage = coverImages.isEmpty ? null : coverImages.first;
    return Card(
      margin: const EdgeInsets.fromLTRB(18, 4, 18, 10),
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFECE9E2)),
      ),
      child: InkWell(
        onTap: () => _showPropertyDetails(listing),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 82,
                height: 86,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5ECE7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: coverImage == null
                    ? Icon(listing.listIcon, color: _forest, size: 34)
                    : Image.network(
                        coverImage.url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(listing.listIcon, color: _forest, size: 34),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                          strings.text(
                            listing.status == 'pending_review'
                                ? 'قيد المراجعة'
                                : 'منشور',
                          ),
                          style: TextStyle(
                            fontSize: 10,
                            color: listing.status == 'pending_review'
                                ? _copper
                                : const Color(0xFF45836D),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: strings.text(
                            isFavorite
                                ? 'إزالة من المفضلة'
                                : 'إضافة إلى المفضلة',
                          ),
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(
                            width: 34,
                            height: 34,
                          ),
                          onPressed: () => setState(
                            () => isFavorite
                                ? _favorites.remove(listing.id)
                                : _favorites.add(listing.id),
                          ),
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? Colors.redAccent
                                : Colors.black38,
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _forest,
                      ),
                    ),
                    Text(
                      listing.locationLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${listing.priceLabel(isArabic: strings.isArabic)} ${strings.text('جنيه')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _copper,
                      ),
                    ),
                    Text(
                      listing.infoLabel(isArabic: strings.isArabic),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _projectCard(PartnershipProject project) {
    final strings = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(18, 4, 18, 10),
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFECE9E2)),
      ),
      child: InkWell(
        onTap: () => _showProjectDetails(project),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE6EEE9),
                    child: Icon(Icons.apartment, color: _forest),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _forest,
                          ),
                        ),
                        Text(
                          project.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_back_ios_new,
                    size: 14,
                    color: Colors.black38,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Text(
                    strings.text('اكتمال المساهمات'),
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const Spacer(),
                  Text(
                    '${strings.digits((project.fundingProgress * 100).round())}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _forest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: project.fundingProgress,
                  minHeight: 7,
                  color: _copper,
                  backgroundColor: const Color(0xFFECE9E2),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${project.membersLabel(isArabic: strings.isArabic)}  ·  ${project.durationLabel(isArabic: strings.isArabic)}',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String message) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        const Icon(Icons.search_off_rounded, color: Colors.black26, size: 48),
        const SizedBox(height: 10),
        Text(message, style: const TextStyle(color: Colors.black54)),
        TextButton(
          onPressed: () {
            setState(() {
              _query = '';
              _searchController.clear();
              _typeFilter = 'all';
              _maximumPrice = double.infinity;
            });
          },
          child: Text(AppLocalizations.of(context).text('مسح البحث والفلاتر')),
        ),
      ],
    ),
  );

  Widget _accountPage() {
    final strings = AppLocalizations.of(context);
    final user = firebaseAuthReady ? FirebaseAuth.instance.currentUser : null;
    final hasApiReadyUser = user?.phoneNumber?.isNotEmpty == true;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        CircleAvatar(
          radius: 38,
          backgroundColor: const Color(0xFFDCE9E2),
          child: Icon(
            user == null ? Icons.person_outline : Icons.verified_user_outlined,
            color: _forest,
            size: 40,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            strings.text(
              hasApiReadyUser ? 'أهلاً بك' : 'مرحباً بك في بيت كو',
            ),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _forest,
            ),
          ),
        ),
        Center(
          child: Text(
            (hasApiReadyUser ? user?.phoneNumber : user?.email) ??
                strings.text('سجّل الدخول لإدارة إعلاناتك وطلباتك'),
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () {
            appLocale.value = Locale(strings.isArabic ? 'en' : 'ar');
          },
          icon: const Icon(Icons.language),
          label: Text(strings.text('تغيير اللغة')),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: hasApiReadyUser ? _signOut : _openPhoneSignIn,
          icon: Icon(
            hasApiReadyUser ? Icons.logout : Icons.phone_android,
          ),
          label: Text(
            strings.text(
              hasApiReadyUser
                  ? 'تسجيل الخروج'
                  : (user == null
                        ? 'تسجيل الدخول برقم الهاتف'
                        : 'اربط رقم هاتفك لمتابعة استخدام التطبيق'),
            ),
          ),
        ),
        if (!firebaseAuthReady)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              strings.text(
                'تسجيل الدخول يحتاج إلى إعداد Firebase قبل استخدامه.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
        _accountTile(
          Icons.home_work_outlined,
          'إعلاناتي',
          'إدارة العقارات التي أضفتها',
        ),
        _accountTile(
          Icons.groups_outlined,
          'مشاريعي وطلباتي',
          'متابعة الشراكات وطلبات الانضمام',
        ),
        _accountTile(
          Icons.support_agent_outlined,
          'المساعدة والدعم',
          'تواصل مع فريق بيت كو',
        ),
      ],
    );
  }

  Future<T?> _pushWithTransition<T extends Object>(Widget page) async {
    final result = await Navigator.of(context).push<dynamic>(
      GoTransitionRoute(
        transition: GoTransitions.fadeUpwards,
        builder: (_) => page,
      ),
    );
    return result is T ? result : null;
  }

  Future<void> _openPhoneSignIn() async {
    final strings = AppLocalizations.of(context);
    if (!firebaseAuthReady) {
      _showMessage(strings.text('إعداد Firebase مطلوب'));
      return;
    }
    final signedIn = await _pushWithTransition<bool>(const PhoneAuthPage());
    if (!mounted || signedIn != true) return;
    setState(() {});
    try {
      await _api.getCurrentUser();
      if (!mounted) return;
      _showMessage(strings.text('تم تسجيل الدخول بنجاح'));
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        strings.text('تم تسجيل الدخول، لكن تعذر الاتصال بالخادم حالياً'),
      );
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) setState(() {});
  }

  Widget _accountTile(IconData icon, String title, String subtitle) => Card(
    color: Colors.white,
    elevation: 0,
    child: ListTile(
      leading: Icon(icon, color: _forest),
      title: Text(AppLocalizations.of(context).text(title)),
      subtitle: Text(AppLocalizations.of(context).text(subtitle)),
      trailing: const Icon(Icons.chevron_left),
      onTap: () => _showMessage(
        AppLocalizations.of(context).text('سجّل الدخول للوصول إلى هذه الصفحة'),
      ),
    ),
  );

  Future<void> _showPropertyDetails(
    PropertyListing listing,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Directionality(
      textDirection: AppLocalizations.of(context).textDirection,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (listing.media.isEmpty)
                Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5ECE7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(listing.listIcon, color: _forest, size: 64),
                )
              else
                PropertyMediaGallery(media: listing.media, height: 210),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      listing.title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: _forest,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _favorites.add(listing.id));
                      Navigator.pop(sheetContext);
                      _showMessage(
                        AppLocalizations.of(
                          context,
                        ).text('أُضيف العقار إلى المفضلة'),
                      );
                    },
                    icon: const Icon(
                      Icons.favorite_border,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              Text(
                listing.locationLabel,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                '${listing.priceLabel(isArabic: AppLocalizations.of(context).isArabic)} ${AppLocalizations.of(context).text('جنيه')}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _copper,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoPill(
                    Icons.square_foot,
                    listing.infoLabel(
                      isArabic: AppLocalizations.of(context).isArabic,
                    ),
                  ),
                  _infoPill(
                    listing.status == 'pending_review'
                        ? Icons.hourglass_top_rounded
                        : Icons.verified_outlined,
                    AppLocalizations.of(context).text(
                      listing.status == 'pending_review'
                          ? 'قيد المراجعة'
                          : 'منشور',
                    ),
                  ),
                  _infoPill(
                    Icons.handshake_outlined,
                    AppLocalizations.of(context).text('تواصل مباشر مع المالك'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(context).text('تفاصيل العقار'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _forest,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                listing.description.isEmpty
                    ? AppLocalizations.of(context).text(
                        'تفاصيل ومعلومات العقار مقدمة من المالك. ننصح بمعاينة الوحدة والتحقق من المستندات قبل إتمام أي اتفاق.',
                      )
                    : listing.description,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: listing.status == 'pending_review'
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.hourglass_top_rounded),
                        label: Text(
                          AppLocalizations.of(
                            context,
                          ).text('الإعلان قيد المراجعة'),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showMessage(
                            AppLocalizations.of(
                              context,
                            ).text('تم تسجيل طلب المعاينة تجريبياً'),
                          );
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          AppLocalizations.of(context).text('طلب معاينة'),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _showProjectDetails(
    PartnershipProject project,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Directionality(
      textDirection: AppLocalizations.of(context).textDirection,
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
                    colors: [_forest, Color(0xFF2D6256)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: Colors.white,
                  size: 58,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                project.title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: _forest,
                ),
              ),
              Text(
                '${project.city} · ${project.district}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Text(project.description, style: const TextStyle(fontSize: 15)),
              if (project.totalUnits != null ||
                  project.landPriceEgp != null ||
                  project.estimatedBuildCostEgp != null ||
                  project.minimumContributionEgp != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (project.totalUnits != null)
                      _infoPill(
                        Icons.apartment,
                        '${AppLocalizations.of(context).digits(project.totalUnits!)} ${AppLocalizations.of(context).text('وحدة')}',
                      ),
                    if (project.landPriceEgp != null)
                      _infoPill(
                        Icons.landscape_outlined,
                        '${AppLocalizations.of(context).text('الأرض')} ${_formatEgp(project.landPriceEgp!, AppLocalizations.of(context))}',
                      ),
                    if (project.estimatedBuildCostEgp != null)
                      _infoPill(
                        Icons.construction_outlined,
                        '${AppLocalizations.of(context).text('البناء')} ${_formatEgp(project.estimatedBuildCostEgp!, AppLocalizations.of(context))}',
                      ),
                    if (project.minimumContributionEgp != null)
                      _infoPill(
                        Icons.payments_outlined,
                        '${AppLocalizations.of(context).text('الحد الأدنى للمساهمة')} ${_formatEgp(project.minimumContributionEgp!, AppLocalizations.of(context))}',
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              Text(
                '${AppLocalizations.of(context).text('اكتمال المساهمات:')} ${AppLocalizations.of(context).digits((project.fundingProgress * 100).round())}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _forest,
                ),
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: project.fundingProgress,
                  minHeight: 9,
                  color: _copper,
                  backgroundColor: const Color(0xFFECE9E2),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoPill(
                    Icons.groups_outlined,
                    '${project.membersLabel(isArabic: AppLocalizations.of(context).isArabic)} ${AppLocalizations.of(context).isArabic ? 'من' : 'of'} ${AppLocalizations.of(context).digits(project.targetMembers)}',
                  ),
                  _infoPill(
                    Icons.schedule,
                    project.durationLabel(
                      isArabic: AppLocalizations.of(context).isArabic,
                    ),
                  ),
                  _infoPill(Icons.location_on_outlined, project.city),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(context).text('قبل الانضمام'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _forest,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).text(
                  'راجع مستندات الأرض وخطة التكلفة وآلية توزيع الوحدات. هذه الصفحة للتعريف بالمشروع فقط، ولا تستقبل أموالاً أو تنشئ التزاماً قانونياً.',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: project.status == 'pending_review'
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.hourglass_top_rounded),
                        label: Text(
                          AppLocalizations.of(
                            context,
                          ).text('المشروع قيد المراجعة'),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: () => _requestProjectJoin(project),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: Text(
                          AppLocalizations.of(context).text('طلب الانضمام'),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _requestProjectJoin(PartnershipProject project) async {
    final strings = AppLocalizations.of(context);
    if (!firebaseAuthReady) {
      _showMessage(strings.text('تحتاج إلى تسجيل الدخول لإرسال طلب الانضمام.'));
      return;
    }
    final signedIn = await _ensureSignedIn();
    if (!mounted || !signedIn) return;

    final minimum = project.minimumContributionEgp ?? 1;
    final contributionController = TextEditingController(
      text: minimum.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    final requestedContribution = await showDialog<double>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: strings.textDirection,
        child: AlertDialog(
          title: Text(strings.text('طلب الانضمام')),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.text(
                    'أدخل قيمة المساهمة التي تتوقعها. إرسال الطلب لا يستقبل أموالاً ولا ينشئ التزاماً مالياً.',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${strings.text('الحد الأدنى للمساهمة')}: ${_formatEgp(minimum, strings)}',
                  style: const TextStyle(
                    color: _forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: contributionController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: strings.text('مبلغ مساهمتك المتوقعة'),
                    suffixText: strings.text('جنيه'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final amount = double.tryParse(
                      (value ?? '').trim().replaceAll(',', ''),
                    );
                    if (amount == null || amount < minimum || amount <= 0) {
                      return strings.text(
                        'أدخل مبلغاً يساوي الحد الأدنى أو يزيد عليه.',
                      );
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.text('إلغاء')),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  dialogContext,
                  double.parse(
                    contributionController.text.trim().replaceAll(',', ''),
                  ),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: _forest),
              child: Text(strings.text('إرسال الطلب')),
            ),
          ],
        ),
      ),
    );
    contributionController.dispose();
    if (!mounted || requestedContribution == null) return;

    try {
      await _api.requestToJoinProject(
        projectId: project.id,
        requestedContributionEgp: requestedContribution,
      );
      if (!mounted) return;
      _showMessage(
        strings.text('تم إرسال طلب الانضمام للمراجعة. لا يتم تحصيل أي أموال.'),
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        strings.text(
          'تعذر إرسال الطلب الآن. تحقق من اتصال الخادم وحاول مجدداً.',
        ),
      );
    }
  }

  Widget _infoPill(IconData icon, String text) => Chip(
    avatar: Icon(icon, size: 16, color: _forest),
    label: Text(text, style: const TextStyle(fontSize: 11)),
    backgroundColor: const Color(0xFFF1F4F0),
    side: BorderSide.none,
  );

  String _formatEgp(double amount, AppLocalizations strings) {
    final digits = amount.round().toString();
    final grouped = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        grouped.write(strings.isArabic ? '٬' : ',');
      }
      grouped.write(digits[index]);
    }
    return '${strings.digits(grouped)} ${strings.isArabic ? 'ج.م' : 'EGP'}';
  }

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );

  Future<void> _createOptions(BuildContext context) async {
    final canCreate = await _ensureSignedIn();
    if (!context.mounted || !canCreate) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Directionality(
        textDirection: AppLocalizations.of(context).textDirection,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).text('ابدأ خطوتك التالية'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _forest,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_work_outlined, color: _forest),
                title: Text(
                  AppLocalizations.of(context).text('أضف إعلان عقار'),
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  ).text('اعرض عقارك للمشترين مباشرة'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openPropertyForm();
                },
              ),
              ListTile(
                leading: const Icon(Icons.groups_outlined, color: _forest),
                title: Text(
                  AppLocalizations.of(context).text('أنشئ مشروع شراكة'),
                ),
                subtitle: Text(
                  AppLocalizations.of(
                    context,
                  ).text('شارك تفاصيل الأرض وخطة المشروع'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openPartnershipForm();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _ensureSignedIn() async {
    if (!firebaseAuthReady) return !kReleaseMode;
    if (_hasApiReadyFirebaseUser) return true;
    final signedIn = await _pushWithTransition<bool>(const PhoneAuthPage());
    return signedIn ?? false;
  }

  Future<void> _openPropertyForm() async {
    final strings = AppLocalizations.of(context);
    final listing = await _pushWithTransition<PropertyListing>(
      CreatePropertyPage(
        uploadMedia: (file) {
          if (!_hasApiReadyFirebaseUser) {
            throw StateError(
              strings.text('سجّل الدخول قبل رفع صور أو فيديو للعقار.'),
            );
          }
          return _mediaUploader.upload(file);
        },
      ),
    );
    if (!mounted || listing == null) return;
    var savedListing = listing;
    var savedRemotely = false;
    var message = strings.text(
      'تعذر الاتصال بالخادم؛ أُضيف العقار مؤقتاً على هذا الجهاز.',
    );
    if (_devUserId != null || _hasApiReadyFirebaseUser) {
      try {
        savedListing = await _api.createProperty(
          ownerId: _devUserId,
          listing: listing,
        );
        savedRemotely = true;
        message = strings.text('تم إرسال الإعلان إلى الخادم وهو قيد المراجعة.');
      } catch (_) {
        if (listing.media.isNotEmpty) {
          _showMessage(
            strings.text(
              'تم رفع الوسائط لكن تعذر حفظ الإعلان. تحقق من اتصال الخادم وحاول مجدداً.',
            ),
          );
          return;
        }
        if (kReleaseMode) {
          _showMessage(
            strings.text(
              'تعذر إرسال الطلب الآن. تحقق من اتصال الخادم وحاول مجدداً.',
            ),
          );
          return;
        }
      }
    }
    if (kReleaseMode && !savedRemotely) {
      _showMessage(
        strings.text(
          'تعذر إرسال الطلب الآن. تحقق من اتصال الخادم وحاول مجدداً.',
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _userProperties.insert(0, savedListing));
    _showMessage(message);
  }

  Future<void> _openPartnershipForm() async {
    final strings = AppLocalizations.of(context);
    final project = await _pushWithTransition<PartnershipProject>(
      const CreatePartnershipPage(),
    );
    if (!mounted || project == null) return;
    var savedProject = project;
    var savedRemotely = false;
    var message = strings.text(
      'تعذر الاتصال بالخادم؛ أُضيف المشروع مؤقتاً على هذا الجهاز.',
    );
    if (_devUserId != null || _hasApiReadyFirebaseUser) {
      try {
        savedProject = await _api.createProject(
          managerId: _devUserId,
          project: project,
        );
        savedRemotely = true;
        message = strings.text('تم إرسال المشروع إلى الخادم وهو قيد المراجعة.');
      } catch (_) {
        if (kReleaseMode) {
          _showMessage(
            strings.text(
              'تعذر إرسال الطلب الآن. تحقق من اتصال الخادم وحاول مجدداً.',
            ),
          );
          return;
        }
      }
    }
    if (kReleaseMode && !savedRemotely) {
      _showMessage(
        strings.text(
          'تعذر إرسال الطلب الآن. تحقق من اتصال الخادم وحاول مجدداً.',
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _userProjects.insert(0, savedProject));
    _showMessage(message);
  }
}
