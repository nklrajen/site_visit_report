import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../models/site_visit_report.dart';
import '../theme/app_theme.dart';
import '../widgets/form_widgets.dart';

/// Main form screen for creating or editing a site visit report
/// Divided into collapsible sections matching the paper form
class FormScreen extends StatefulWidget {
  final SiteVisitReport? existingReport;

  const FormScreen({super.key, this.existingReport});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();
  final _picker = ImagePicker();
  late SiteVisitReport _report;
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  bool _hasChanges = false;

  // Section expansion state
  final Map<String, bool> _expanded = {
    'basic': true,
    'address': false,
    'dimensions': false,
    'boundaries': false,
    'land': false,
    'location': false,
    'amenities': false,
    'building': false,
    'photos': false,
    'signature': false,
  };

  // Form controllers – Basic Info
  final _bankNameCtrl = TextEditingController();
  final _loanNumberCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();

  // Address
  final _addrDeedCtrl = TextEditingController();
  final _addrSiteCtrl = TextEditingController();

  // Dimensions
  final _dimNDeedCtrl = TextEditingController();
  final _dimSDeedCtrl = TextEditingController();
  final _dimEDeedCtrl = TextEditingController();
  final _dimWDeedCtrl = TextEditingController();
  final _dimNSiteCtrl = TextEditingController();
  final _dimSSiteCtrl = TextEditingController();
  final _dimESiteCtrl = TextEditingController();
  final _dimWSiteCtrl = TextEditingController();

  // Boundaries
  final _bndNDeedCtrl = TextEditingController();
  final _bndSDeedCtrl = TextEditingController();
  final _bndEDeedCtrl = TextEditingController();
  final _bndWDeedCtrl = TextEditingController();
  final _bndNSiteCtrl = TextEditingController();
  final _bndSSiteCtrl = TextEditingController();
  final _bndESiteCtrl = TextEditingController();
  final _bndWSiteCtrl = TextEditingController();

  // Land
  final _landExtDeedCtrl = TextEditingController();
  final _landExtSiteCtrl = TextEditingController();

  // Location
  final _landMarkCtrl = TextEditingController();
  final _localityCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _roadWidthCtrl = TextEditingController();
  final _busStopCtrl = TextEditingController();
  final _railwayCtrl = TextEditingController();
  final _noUnitCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();

  // Building
  final _floorTypeCtrl = TextEditingController();
  final _noTenantsCtrl = TextEditingController();
  final _stageCtrl = TextEditingController();
  final _googlePointCtrl = TextEditingController();

  // Signature controller
  late SignatureController _signatureCtrl;

  // Photos list
  List<String> _photos = [];

  // Dropdown values
  String? _selectedBank;
  String? _selectedDate;
  String? _changesInBounds;
  String? _roadType;
  String? _propIdentified;
  String? _usageBuilding;
  String? _noOfFloor;
  String? _structure;
  String? _occupancy;
  String? _boreWell;
  String? _septicTank;
  String? _oht;
  String? _compoundWall;
  String? _sump;
  String? _ebServices;
  String? _demarcated;
  String? _maintenance;
  String? _roof;
  String? _typeLocality;

  // GPS
  double? _latitude;
  double? _longitude;
  bool _fetchingLocation = false;

  // Dropdown options
  static const _bankOptions = ['Ambit', 'Jothi Finance', 'Chola', 'Veritas', 'Equitas'];
  static const _yesNo = ['Yes', 'No'];
  static const _roadTypes = ['Tar', 'Mud', 'CC', 'Paver', 'Mixed'];
  static const _usageOptions = ['Residential', 'Commercial', 'Agricultural', 'Vacant', 'Industrial', 'Mixed'];
  static const _floorOptions = ['GF', 'GF+FF', 'GF+FF+SF', 'GF+FF+SF+TF', 'Other'];
  static const _structureOptions = ['RCC', 'Load Bearing'];
  static const _occupancyOptions = ['Self Occupied', 'Tenant', 'Vacant', 'Vacant Land'];
  static const _maintenanceOptions = ['Good', 'Average', 'Poor'];
  static const _roofOptions = ['RCC', 'ACC', 'M-Tiled', 'G.I Sheet', 'Tin Sheet'];
  static const _localityTypes = ['Village', 'Town Panchayat', 'Municipality', 'Corporation'];

  @override
  void initState() {
    super.initState();
    _signatureCtrl = SignatureController(
      penStrokeWidth: 2,
      penColor: AppColors.primary,
    );
    _initReport();
  }

  void _initReport() async {
    if (widget.existingReport != null) {
      _report = widget.existingReport!;
      _populateControllers();
    } else {
      final prefs = await SharedPreferences.getInstance();
      _report = SiteVisitReport.empty(const Uuid().v4())
        ..inspectorName = prefs.getString('inspector_name')
        ..companyName = prefs.getString('company_name');
    }
    // Start auto-save timer (every 30 seconds)
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_hasChanges) _autoSave();
    });
    // Listen to any controller for changes
    _attachChangeListeners();
  }

  void _attachChangeListeners() {
    for (final ctrl in _allControllers) {
      ctrl.addListener(() => setState(() => _hasChanges = true));
    }
  }

  List<TextEditingController> get _allControllers => [
    _bankNameCtrl, _loanNumberCtrl, _customerNameCtrl,
    _addrDeedCtrl, _addrSiteCtrl,
    _dimNDeedCtrl, _dimSDeedCtrl, _dimEDeedCtrl, _dimWDeedCtrl,
    _dimNSiteCtrl, _dimSSiteCtrl, _dimESiteCtrl, _dimWSiteCtrl,
    _bndNDeedCtrl, _bndSDeedCtrl, _bndEDeedCtrl, _bndWDeedCtrl,
    _bndNSiteCtrl, _bndSSiteCtrl, _bndESiteCtrl, _bndWSiteCtrl,
    _landExtDeedCtrl, _landExtSiteCtrl,
    _landMarkCtrl, _localityCtrl, _ageCtrl, _roadWidthCtrl,
    _busStopCtrl, _railwayCtrl, _noUnitCtrl, _hospitalCtrl,
    _floorTypeCtrl, _noTenantsCtrl, _stageCtrl, _googlePointCtrl,
  ];

  void _populateControllers() {
    final r = _report;
    _selectedBank = r.bankName;
    _loanNumberCtrl.text = r.loanNumber ?? '';
    _selectedDate = r.dateOfVisit;
    _customerNameCtrl.text = r.customerName ?? '';
    _addrDeedCtrl.text = r.propertyAddressDeed ?? '';
    _addrSiteCtrl.text = r.propertyAddressSite ?? '';
    _dimNDeedCtrl.text = r.dimNorthDeed ?? '';
    _dimSDeedCtrl.text = r.dimSouthDeed ?? '';
    _dimEDeedCtrl.text = r.dimEastDeed ?? '';
    _dimWDeedCtrl.text = r.dimWestDeed ?? '';
    _dimNSiteCtrl.text = r.dimNorthSite ?? '';
    _dimSSiteCtrl.text = r.dimSouthSite ?? '';
    _dimESiteCtrl.text = r.dimEastSite ?? '';
    _dimWSiteCtrl.text = r.dimWestSite ?? '';
    _bndNDeedCtrl.text = r.boundNorthDeed ?? '';
    _bndSDeedCtrl.text = r.boundSouthDeed ?? '';
    _bndEDeedCtrl.text = r.boundEastDeed ?? '';
    _bndWDeedCtrl.text = r.boundWestDeed ?? '';
    _bndNSiteCtrl.text = r.boundNorthSite ?? '';
    _bndSSiteCtrl.text = r.boundSouthSite ?? '';
    _bndESiteCtrl.text = r.boundEastSite ?? '';
    _bndWSiteCtrl.text = r.boundWestSite ?? '';
    _landExtDeedCtrl.text = r.landExtentDeed ?? '';
    _landExtSiteCtrl.text = r.landExtentSite ?? '';
    _changesInBounds = r.anyChangesInBoundaries;
    _landMarkCtrl.text = r.landMark ?? '';
    _localityCtrl.text = r.locality ?? '';
    _ageCtrl.text = r.ageOfProperty ?? '';
    _roadType = r.roadType;
    _propIdentified = r.propertyIdentified;
    _roadWidthCtrl.text = r.roadWidth ?? '';
    _busStopCtrl.text = r.nearestBusStop ?? '';
    _usageBuilding = r.usageOfBuilding;
    _railwayCtrl.text = r.railwayStation ?? '';
    _noUnitCtrl.text = r.noOfUnit ?? '';
    _hospitalCtrl.text = r.nearestHospital ?? '';
    _noOfFloor = r.noOfFloor;
    _structure = r.structure;
    _occupancy = r.occupancy;
    _boreWell = r.boreWell;
    _septicTank = r.septicTank;
    _oht = r.oht;
    _compoundWall = r.compoundWall;
    _sump = r.sump;
    _ebServices = r.ebServices;
    _floorTypeCtrl.text = r.floorType ?? '';
    _demarcated = r.demarcated;
    _noTenantsCtrl.text = r.noOfTenants ?? '';
    _maintenance = r.maintenanceOfBuilding;
    _roof = r.roof;
    _stageCtrl.text = r.stageConstructionPercent ?? '';
    _typeLocality = r.typeOfLocality;
    _latitude = r.latitude;
    _longitude = r.longitude;
    _googlePointCtrl.text = r.googlePoint ?? '';
    _photos = r.photosPaths != null
        ? List<String>.from(jsonDecode(r.photosPaths!))
        : [];
  }

  /// Collect all controller values into the report model
  void _collectFormData() {
    _report
      ..bankName = _selectedBank
      ..loanNumber = _loanNumberCtrl.text.trim()
      ..dateOfVisit = _selectedDate
      ..customerName = _customerNameCtrl.text.trim()
      ..propertyAddressDeed = _addrDeedCtrl.text.trim()
      ..propertyAddressSite = _addrSiteCtrl.text.trim()
      ..dimNorthDeed = _dimNDeedCtrl.text.trim()
      ..dimSouthDeed = _dimSDeedCtrl.text.trim()
      ..dimEastDeed = _dimEDeedCtrl.text.trim()
      ..dimWestDeed = _dimWDeedCtrl.text.trim()
      ..dimNorthSite = _dimNSiteCtrl.text.trim()
      ..dimSouthSite = _dimSSiteCtrl.text.trim()
      ..dimEastSite = _dimESiteCtrl.text.trim()
      ..dimWestSite = _dimWSiteCtrl.text.trim()
      ..boundNorthDeed = _bndNDeedCtrl.text.trim()
      ..boundSouthDeed = _bndSDeedCtrl.text.trim()
      ..boundEastDeed = _bndEDeedCtrl.text.trim()
      ..boundWestDeed = _bndWDeedCtrl.text.trim()
      ..boundNorthSite = _bndNSiteCtrl.text.trim()
      ..boundSouthSite = _bndSSiteCtrl.text.trim()
      ..boundEastSite = _bndESiteCtrl.text.trim()
      ..boundWestSite = _bndWSiteCtrl.text.trim()
      ..landExtentDeed = _landExtDeedCtrl.text.trim()
      ..landExtentSite = _landExtSiteCtrl.text.trim()
      ..anyChangesInBoundaries = _changesInBounds
      ..landMark = _landMarkCtrl.text.trim()
      ..locality = _localityCtrl.text.trim()
      ..ageOfProperty = _ageCtrl.text.trim()
      ..roadType = _roadType
      ..propertyIdentified = _propIdentified
      ..roadWidth = _roadWidthCtrl.text.trim()
      ..nearestBusStop = _busStopCtrl.text.trim()
      ..usageOfBuilding = _usageBuilding
      ..railwayStation = _railwayCtrl.text.trim()
      ..noOfUnit = _noUnitCtrl.text.trim()
      ..nearestHospital = _hospitalCtrl.text.trim()
      ..noOfFloor = _noOfFloor
      ..structure = _structure
      ..occupancy = _occupancy
      ..boreWell = _boreWell
      ..septicTank = _septicTank
      ..oht = _oht
      ..compoundWall = _compoundWall
      ..sump = _sump
      ..ebServices = _ebServices
      ..floorType = _floorTypeCtrl.text.trim()
      ..demarcated = _demarcated
      ..noOfTenants = _noTenantsCtrl.text.trim()
      ..maintenanceOfBuilding = _maintenance
      ..roof = _roof
      ..stageConstructionPercent = _stageCtrl.text.trim()
      ..typeOfLocality = _typeLocality
      ..latitude = _latitude
      ..longitude = _longitude
      ..googlePoint = _googlePointCtrl.text.trim()
      ..photosPaths = jsonEncode(_photos);
  }

  Future<void> _autoSave() async {
    _collectFormData();
    await _db.saveReport(_report);
    setState(() => _hasChanges = false);
  }

  Future<void> _saveAsDraft() async {
    setState(() => _isSaving = true);
    _collectFormData();
    _report.status = 'draft';
    await _db.saveReport(_report);
    setState(() {
      _isSaving = false;
      _hasChanges = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitReport() async {
    // Validate mandatory fields
    if (!_validateMandatoryFields()) return;

    // Save signature if drawn
    await _saveSignature();

    setState(() => _isSaving = true);
    _collectFormData();
    _report.status = 'submitted';
    await _db.saveReport(_report);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  bool _validateMandatoryFields() {
    final errors = <String>[];
    if (_selectedBank == null) errors.add('Bank Name');
    if (_customerNameCtrl.text.trim().isEmpty) errors.add('Customer Name');
    if (_addrDeedCtrl.text.trim().isEmpty) errors.add('Property Address (Deed)');
    if (_selectedDate == null) errors.add('Date of Visit');

    if (errors.isNotEmpty) {
      // Expand the first section with errors
      setState(() => _expanded['basic'] = true);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Required Fields Missing'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please fill in the following required fields:'),
              const SizedBox(height: 12),
              ...errors.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Text(e, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData(colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('dd/MM/yyyy').format(picked);
        _hasChanges = true;
      });
    }
  }

  Future<void> _fetchGPS() async {
    setState(() => _fetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled.', isError: true);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied.', isError: true);
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _googlePointCtrl.text = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
        _hasChanges = true;
      });
      _showSnack('Location captured: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}');
    } catch (e) {
      _showSnack('Failed to get location: $e', isError: true);
    } finally {
      setState(() => _fetchingLocation = false);
    }
  }

  void _openInMaps() async {
    if (_latitude == null || _longitude == null) {
      _showSnack('No GPS coordinates captured yet.', isError: true);
      return;
    }
    final url = Uri.parse('https://maps.google.com/?q=$_latitude,$_longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not open Google Maps.', isError: true);
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (image == null) return;

      // Copy to app documents directory for persistence
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(image.path).copy('${dir.path}/$fileName');

      setState(() {
        _photos.add(savedFile.path);
        _hasChanges = true;
      });
    } catch (e) {
      _showSnack('Could not add photo: $e', isError: true);
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<void> _saveSignature() async {
    if (_signatureCtrl.isNotEmpty) {
      final data = await _signatureCtrl.toPngBytes();
      if (data != null) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/sig_${_report.reportId}.png');
        await file.writeAsBytes(data);
        _report.signaturePath = file.path;
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    // Auto-save on leave if there are unsaved changes
    if (_hasChanges) {
      _collectFormData();
      _db.saveReport(_report);
    }
    for (final c in _allControllers) c.dispose();
    _signatureCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingReport == null ? 'New Site Visit Report' : 'Edit Report',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (_hasChanges)
              const Text(
                'Unsaved changes',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveAsDraft,
              icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ═══════════════════════════════════════════════════
            // SECTION 1: BASIC INFO
            // ═══════════════════════════════════════════════════
            _buildSectionHeader('1', 'Basic Information', Icons.info_outline, 'basic'),
            if (_expanded['basic']!) ...[
              // Bank Name - dropdown
              AppDropdown(
                label: 'Bank Name *',
                value: _selectedBank,
                items: _bankOptions,
                onChanged: (v) => setState(() { _selectedBank = v; _hasChanges = true; }),
                hint: 'Select bank',
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _loanNumberCtrl,
                label: 'Loan Number',
                hint: 'Enter loan number',
                icon: Icons.numbers,
              ),
              const SizedBox(height: 12),
              // Date of Visit
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: AppTextField(
                    controller: TextEditingController(text: _selectedDate ?? ''),
                    label: 'Date of Visit *',
                    hint: 'Select date',
                    icon: Icons.calendar_today,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _customerNameCtrl,
                label: 'Customer Name *',
                hint: 'Enter customer full name',
                icon: Icons.person_outline,
              ),
            ],

            // ═══════════════════════════════════════════════════
            // SECTION 2: PROPERTY ADDRESS
            // ═══════════════════════════════════════════════════
            _buildSectionHeader('2', 'Property Address', Icons.location_on_outlined, 'address'),
            if (_expanded['address']!) ...[
              AppTextField(
                controller: _addrDeedCtrl,
                label: 'Property Address As Per Deed *',
                hint: 'Enter address as written in deed',
                icon: Icons.home_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _addrSiteCtrl,
                label: 'Property Address As Per Site',
                hint: 'Enter address as observed on site',
                icon: Icons.place_outlined,
                maxLines: 3,
              ),
            ],

            // ═══════════════════════════════════════════════════
            // SECTION 3: DIMENSIONS
            // ═══════════════════════════════════════════════════
            _buildSectionHeader('3', 'Dimensions', Icons.straighten_outlined, 'dimensions'),
            if (_expanded['dimensions']!) ...[
              _buildDualRow('North', _dimNDeedCtrl, _dimNSiteCtrl),
              _buildDualRow('South', _dimSDeedCtrl, _dimSSiteCtrl),
              _buildDualRow('East', _dimEDeedCtrl, _dimESiteCtrl),
              _buildDualRow('West', _dimWDeedCtrl, _dimWSiteCtrl),
            ],

            // ═══════════════════════════════════════════════════
            // SECTION 4: BOUNDARIES
            // ═══════════════════════════════════════════════════
            _buildSectionHeader('4', 'Boundaries', Icons.square_foot_outlined, 'boundaries'),
            if (_expanded['boundaries']!) ...[
              _buildDualRow('North', _bndNDeedCtrl, _bndNSiteCtrl, isDeed: true),
              _buildDualRow('South', _bndSDeedCtrl, _bndSSiteCtrl, isDeed: true),
              _buildDualRow('East', _bndEDeedCtrl, _bndESiteCtrl, isDeed: true),
              _buildDualRow('West', _bndWDeedCtrl, _bndWSiteCtrl, isDeed: true),
              const SizedBox(height: 12),
              AppDropdown(
                label: 'Any Changes in Boundaries',
                value: _changesInBounds,
                items: _yesNo,
                onChanged: (v) => setState(() { _changesInBounds = v; _hasChanges = true; }),
                hint: 'Select Yes/No',
              ),
            ],

            // ═══════════════════════════════════════════════════
            // SECTION 5: LAND EXTENT
            // ═══════════════════════════════════════════════════
            _buildSectionHeader('5', 'Land Extent', Icons.landscape_outlined, 'land'),
            if (_expanded['land']!) ...[
              _buildDualRow('Land Extent', _landExtDeedCtrl, _landExtSiteCtrl),
            ],

            // ═══════════════════════════════════════════════════
            // SECTION 6: LOCATION & INFRASTRUCTURE
            // ═══════════════════════════════════════════════════
            _buildSectionHeader('6', 'Location & Infrastructure', Icons.map_outlined, 'location'),
            if (_expanded['location']!) ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _landMarkCtrl,
                      label: 'Land Mark',
                      hint: 'e.g. Near temple',
                      icon: Icons.flag_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      controller: _localityCtrl,
                      label: 'Locality',
                      hint: 'Area/locality name',
                      icon: Icons.my_location_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _ageCtrl,
                      label: 'Age of Property',
                      hint: 'e.g. 10 years',
                      icon: Icons.history_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDropdown(
                      label: 'Road Type',
                      value: _roadType,
                      items: _roadTypes,
                      onChanged: (v) => setState(() { _roadType = v; _hasChanges = true; }),
                      hint: 'Select',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppDropdown(
                      label: 'Property Identified',
                      value: _propIdentified,
                      items: _yesNo,
                      onChanged: (v) => setState(() { _propIdentified = v; _hasChanges = true; }),
                      hint: 'Yes/No',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      controller: _roadWidthCtrl,
                      label: 'Road Width',
                      hint: 'e.g. 20 ft',
                      icon: Icons.width_normal_outlined,
                      inputType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _busStopCtrl,
                      label: 'Nearest Bus Stop (KM)',
                      hint: 'Distance',
                      icon: Icons.directions_bus_outlined,
                      inputType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDropdown(
                      label: 'Usage of Building',
                      value: _usageBuilding,
                      items: _usageOptions,
                      onChanged: (v) => setState(() { _usageBuilding = v; _hasChanges = true; }),
                      hint: 'Select usage',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _railwayCtrl,
                      label: 'Railway Station (KM)',
                      hint: 'Distance',
                      icon: Icons.train_outlined,
                      inputType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      controller: _noUnitCtrl,
                      label: 'No. of Units',
                      hint: 'Count',
                      icon: Icons.apartment_outlined,
                      inputType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _hospitalCtrl,
                      label: 'Nearest Hospital (KM)',
                      hint: 'Distance',
                      icon: Icons.local_hospital_outlined,
                      inputType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDropdown(
                      label: 'No. of Floors',
                      value: _noOfFloor,
                      items: _floorOptions,
                      onChanged: (v) => setState(() { _noOfFloor = v; _hasChanges = true; }),
                      hint: 'Select',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppDropdown(
                      label: 'Structure',
                      value: _structure,
                      items: _structureOptions,
                      onChanged: (v) => setState(() { _structure = v; _hasChanges = true; }),
                      hint: 'Select',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDropdown(
                      label: 'Occupancy',
                      value: _occupancy,
                      items: _occupancyOptions,
                      onChanged: (v) => setState(() { _occupancy = v; _hasChanges = true; }),
                      hint: 'Select',
                    ),
                  ),
                ],
              ),

              // GPS Section
              const SizedBox(height: 16),
              _buildGpsCard(),
            ],

            // ═══════════════════════════════════════════════════
            // SECTION 7: AMENITIES
            // ═══════════════════════════════════════════════════
            _buildSectionHeader('7', 'Amenities', Icons.home_repair_service_outlined, 'amenities'),
            if (_expanded['amenities']!) ...[
              _buildAmenityRow('Bore Well', _boreWell, (v) => setState(() { _boreWell = v; _hasChanges = true; })),
              _buildAmenityRow('Septic Tank', _septicTank, (v) => setState(() { _septicTank = v; _hasChanges = true; })),
              _buildAmenityRow('OHT (Overhead Tank)', _oht, (v) => setState(() { _oht = v; _hasChanges = true; })),
              _buildAmenityRow('Compound Wall', _compoundWall, (v) => setState(() { _compoundWall = v; _hasChanges = true; })),
              _buildAmenityRow('Sump', _sump, (v) => setState(() { _sump = v; _hasChanges = true; })),
              _buildAmenityRow('EB Services', _ebServices, (v) => setState(() { _ebServices = v; _hasChanges = true; })),
            ],

            // ═══════════════════════════════════════════════════
            // SECTION 8: BUILDING DETAILS
            // ═══════════════════════════════════════════════════
            _buildSectionHeader('8', 'Building Details', Icons.business_outlined, 'building'),
            if (_expanded['building']!) ...[
              AppTextField(
                controller: _floorTypeCtrl,
                label: 'Floor Type',
                hint: 'e.g. Marble, Tile, Cement',
                icon: Icons.layers_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppDropdown(
                      label: 'Demarcated',
                      value: _demarcated,
                      items: _yesNo,
                      onChanged: (v) => setState(() { _demarcated = v; _hasChanges = true; }),
                      hint: 'Yes/No',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      controller: _noTenantsCtrl,
                      label: 'No. of Tenants',
                      hint: 'Count',
                      icon: Icons.people_outline,
                      inputType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppDropdown(
                      label: 'Maintenance',
                      value: _maintenance,
                      items: _maintenanceOptions,
                      onChanged: (v) => setState(() { _maintenance = v; _hasChanges = true; }),
                      hint: 'Select',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDropdown(
                      label: 'Roof Type',
                      value: _roof,
                      items: _roofOptions,
                      onChanged: (v) => setState(() { _roof = v; _hasChanges = true; }),
                      hint: 'Select',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _stageCtrl,
                      label: 'Stage of Construction %',
                      hint: 'e.g. 75',
                      icon: Icons.construction_outlined,
                      inputType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDropdown(
                      label: 'Type of Locality',
                      value: _typeLocality,
                      items: _localityTypes,
                      onChanged: (v) => setState(() { _typeLocality = v; _hasChanges = true; }),
                      hint: 'Select',
                    ),
                  ),
                ],
              ),
            ],

            // ═══════════════════════════════════════════════════
            // SECTION 9: PHOTOS
            // ═══════════════════════════════════════════════════
            _buildSectionHeader('9', 'Site Photos', Icons.photo_camera_outlined, 'photos'),
            if (_expanded['photos']!) _buildPhotosSection(),

            // ═══════════════════════════════════════════════════
            // SECTION 10: SIGNATURE
            // ═══════════════════════════════════════════════════
            _buildSectionHeader('10', 'Digital Signature', Icons.draw_outlined, 'signature'),
            if (_expanded['signature']!) _buildSignatureSection(),

            // ─── Submit Button ────────────────────────────────
            const SizedBox(height: 24),
            _buildSubmitButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String num, String title, IconData icon, String key) {
    final isOpen = _expanded[key] ?? false;
    return GestureDetector(
      onTap: () => setState(() => _expanded[key] = !isOpen),
      child: Container(
        margin: const EdgeInsets.only(top: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isOpen ? AppColors.primary : AppColors.primaryDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  num,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDualRow(String label, TextEditingController deedCtrl, TextEditingController siteCtrl, {bool isDeed = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: deedCtrl,
                  label: 'As Per Deed',
                  hint: isDeed ? 'Boundary desc.' : 'Measurement',
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField(
                  controller: siteCtrl,
                  label: 'As Per Site',
                  hint: isDeed ? 'Boundary desc.' : 'Measurement',
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityRow(String label, String? value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: AppDropdown(
              label: '',
              value: value,
              items: const ['Yes', 'No', 'N/A'],
              onChanged: onChanged,
              hint: 'Select',
              compact: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sectionBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GPS Location',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (_latitude != null && _longitude != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Lat: ${_latitude!.toStringAsFixed(5)}, Lng: ${_longitude!.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _googlePointCtrl,
            label: 'Google Point / Location Note',
            hint: 'Coordinates or descriptive location',
            icon: Icons.pin_drop_outlined,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _fetchingLocation ? null : _fetchGPS,
                  icon: _fetchingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.gps_fixed, size: 16),
                  label: Text(_fetchingLocation ? 'Fetching...' : 'Capture GPS'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _latitude != null ? _openInMaps : null,
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Open Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      children: [
        // Thumbnail grid
        if (_photos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (_, i) => _PhotoThumbnail(
              path: _photos[i],
              onDelete: () => _removePhoto(i),
            ),
          ),
        if (_photos.isNotEmpty) const SizedBox(height: 12),
        // Add photo button
        DottedAddButton(
          label: 'Add Photo',
          icon: Icons.add_a_photo_outlined,
          onTap: _showPhotoOptions,
        ),
      ],
    );
  }

  Widget _buildSignatureSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                const Text(
                  'Sign in the box below',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _signatureCtrl.clear(),
                  icon: const Icon(Icons.clear, size: 14),
                  label: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          Signature(
            controller: _signatureCtrl,
            height: 160,
            backgroundColor: Colors.white,
          ),
          if (_report.signaturePath != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'Previous signature saved',
                    style: TextStyle(
                      color: AppColors.success,
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

  Widget _buildSubmitButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _submitReport,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Submit Report'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : _saveAsDraft,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save as Draft'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final String path;
  final VoidCallback onDelete;

  const _PhotoThumbnail({required this.path, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.divider,
              child: const Icon(Icons.broken_image_outlined, color: AppColors.textHint),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
