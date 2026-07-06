/// Complete data model for the Site Visit Report
/// Mirrors all fields from the Axiom Technical Services paper form

class SiteVisitReport {
  // Primary key
  int? id;
  String reportId;       // UUID for unique identification
  String status;         // 'draft' | 'submitted'
  DateTime createdAt;
  DateTime updatedAt;

  // ─── Section 1: Basic Info ───────────────────────────────────────
  String? bankName;      // Dropdown: Ambit/Jothi Finance/Chola/Veritas/Equitas
  String? loanNumber;
  String? dateOfVisit;   // Date formatted string
  String? customerName;

  // ─── Section 2: Property Address ─────────────────────────────────
  String? propertyAddressDeed;   // As per deed (multiline)
  String? propertyAddressSite;   // As per site (multiline)

  // ─── Section 3: Dimensions ───────────────────────────────────────
  // As per Deed
  String? dimNorthDeed;
  String? dimSouthDeed;
  String? dimEastDeed;
  String? dimWestDeed;
  String? dimNorthSite;
  String? dimSouthSite;
  String? dimEastSite;
  String? dimWestSite;

  // ─── Section 4: Boundaries ───────────────────────────────────────
  String? boundNorthDeed;
  String? boundSouthDeed;
  String? boundEastDeed;
  String? boundWestDeed;
  String? boundNorthSite;
  String? boundSouthSite;
  String? boundEastSite;
  String? boundWestSite;

  // ─── Section 5: Land Details ──────────────────────────────────────
  String? landExtentDeed;
  String? landExtentSite;
  String? anyChangesInBoundaries;  // Yes/No dropdown

  // ─── Section 6: Location & Infrastructure ────────────────────────
  String? landMark;
  String? locality;
  String? ageOfProperty;
  String? roadType;        // Tar/Mud/CC/Paver/Mixed
  String? propertyIdentified;  // Yes/No
  String? roadWidth;
  String? nearestBusStop;
  String? usageOfBuilding;  // Residential/Commercial/Agri/Vacant/Industrial/Mixed
  String? railwayStation;
  String? noOfUnit;
  String? nearestHospital;
  String? noOfFloor;       // GF/FF/SF/TF
  String? structure;       // RCC/Load Bearing
  String? occupancy;       // Self Occupied/Tenant/Vacant/Vacant Land

  // ─── Section 7: Amenities ─────────────────────────────────────────
  String? boreWell;
  String? septicTank;
  String? oht;             // Overhead Tank
  String? compoundWall;
  String? sump;
  String? ebServices;

  // ─── Section 8: Building Details ──────────────────────────────────
  String? floorType;
  String? demarcated;      // Yes/No
  String? noOfTenants;
  String? maintenanceOfBuilding;  // Good/Average
  String? roof;            // RCC/ACC/M-Tiled/G.I Sheet/Tin Sheet
  String? stageConstructionPercent;
  String? typeOfLocality;  // Village/Town Panchayat/Municipality/Corporation

  // ─── Section 9: GPS & Maps ─────────────────────────────────────────
  double? latitude;
  double? longitude;
  String? googlePoint;     // Descriptive text

  // ─── Section 10: Photos & Signature ───────────────────────────────
  String? photosPaths;     // JSON-encoded list of file paths
  String? signaturePath;   // Path to signature image

  // ─── Inspector Info ─────────────────────────────────────────────
  String? inspectorName;
  String? companyName;

  SiteVisitReport({
    this.id,
    required this.reportId,
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
    this.bankName,
    this.loanNumber,
    this.dateOfVisit,
    this.customerName,
    this.propertyAddressDeed,
    this.propertyAddressSite,
    this.dimNorthDeed,
    this.dimSouthDeed,
    this.dimEastDeed,
    this.dimWestDeed,
    this.dimNorthSite,
    this.dimSouthSite,
    this.dimEastSite,
    this.dimWestSite,
    this.boundNorthDeed,
    this.boundSouthDeed,
    this.boundEastDeed,
    this.boundWestDeed,
    this.boundNorthSite,
    this.boundSouthSite,
    this.boundEastSite,
    this.boundWestSite,
    this.landExtentDeed,
    this.landExtentSite,
    this.anyChangesInBoundaries,
    this.landMark,
    this.locality,
    this.ageOfProperty,
    this.roadType,
    this.propertyIdentified,
    this.roadWidth,
    this.nearestBusStop,
    this.usageOfBuilding,
    this.railwayStation,
    this.noOfUnit,
    this.nearestHospital,
    this.noOfFloor,
    this.structure,
    this.occupancy,
    this.boreWell,
    this.septicTank,
    this.oht,
    this.compoundWall,
    this.sump,
    this.ebServices,
    this.floorType,
    this.demarcated,
    this.noOfTenants,
    this.maintenanceOfBuilding,
    this.roof,
    this.stageConstructionPercent,
    this.typeOfLocality,
    this.latitude,
    this.longitude,
    this.googlePoint,
    this.photosPaths,
    this.signaturePath,
    this.inspectorName,
    this.companyName,
  });

  /// Convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'report_id': reportId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'bank_name': bankName,
      'loan_number': loanNumber,
      'date_of_visit': dateOfVisit,
      'customer_name': customerName,
      'property_address_deed': propertyAddressDeed,
      'property_address_site': propertyAddressSite,
      'dim_north_deed': dimNorthDeed,
      'dim_south_deed': dimSouthDeed,
      'dim_east_deed': dimEastDeed,
      'dim_west_deed': dimWestDeed,
      'dim_north_site': dimNorthSite,
      'dim_south_site': dimSouthSite,
      'dim_east_site': dimEastSite,
      'dim_west_site': dimWestSite,
      'bound_north_deed': boundNorthDeed,
      'bound_south_deed': boundSouthDeed,
      'bound_east_deed': boundEastDeed,
      'bound_west_deed': boundWestDeed,
      'bound_north_site': boundNorthSite,
      'bound_south_site': boundSouthSite,
      'bound_east_site': boundEastSite,
      'bound_west_site': boundWestSite,
      'land_extent_deed': landExtentDeed,
      'land_extent_site': landExtentSite,
      'any_changes_in_boundaries': anyChangesInBoundaries,
      'land_mark': landMark,
      'locality': locality,
      'age_of_property': ageOfProperty,
      'road_type': roadType,
      'property_identified': propertyIdentified,
      'road_width': roadWidth,
      'nearest_bus_stop': nearestBusStop,
      'usage_of_building': usageOfBuilding,
      'railway_station': railwayStation,
      'no_of_unit': noOfUnit,
      'nearest_hospital': nearestHospital,
      'no_of_floor': noOfFloor,
      'structure': structure,
      'occupancy': occupancy,
      'bore_well': boreWell,
      'septic_tank': septicTank,
      'oht': oht,
      'compound_wall': compoundWall,
      'sump': sump,
      'eb_services': ebServices,
      'floor_type': floorType,
      'demarcated': demarcated,
      'no_of_tenants': noOfTenants,
      'maintenance_of_building': maintenanceOfBuilding,
      'roof': roof,
      'stage_construction_percent': stageConstructionPercent,
      'type_of_locality': typeOfLocality,
      'latitude': latitude,
      'longitude': longitude,
      'google_point': googlePoint,
      'photos_paths': photosPaths,
      'signature_path': signaturePath,
      'inspector_name': inspectorName,
      'company_name': companyName,
    };
  }

  /// Create from SQLite Map
  factory SiteVisitReport.fromMap(Map<String, dynamic> map) {
    return SiteVisitReport(
      id: map['id'],
      reportId: map['report_id'] ?? '',
      status: map['status'] ?? 'draft',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      bankName: map['bank_name'],
      loanNumber: map['loan_number'],
      dateOfVisit: map['date_of_visit'],
      customerName: map['customer_name'],
      propertyAddressDeed: map['property_address_deed'],
      propertyAddressSite: map['property_address_site'],
      dimNorthDeed: map['dim_north_deed'],
      dimSouthDeed: map['dim_south_deed'],
      dimEastDeed: map['dim_east_deed'],
      dimWestDeed: map['dim_west_deed'],
      dimNorthSite: map['dim_north_site'],
      dimSouthSite: map['dim_south_site'],
      dimEastSite: map['dim_east_site'],
      dimWestSite: map['dim_west_site'],
      boundNorthDeed: map['bound_north_deed'],
      boundSouthDeed: map['bound_south_deed'],
      boundEastDeed: map['bound_east_deed'],
      boundWestDeed: map['bound_west_deed'],
      boundNorthSite: map['bound_north_site'],
      boundSouthSite: map['bound_south_site'],
      boundEastSite: map['bound_east_site'],
      boundWestSite: map['bound_west_site'],
      landExtentDeed: map['land_extent_deed'],
      landExtentSite: map['land_extent_site'],
      anyChangesInBoundaries: map['any_changes_in_boundaries'],
      landMark: map['land_mark'],
      locality: map['locality'],
      ageOfProperty: map['age_of_property'],
      roadType: map['road_type'],
      propertyIdentified: map['property_identified'],
      roadWidth: map['road_width'],
      nearestBusStop: map['nearest_bus_stop'],
      usageOfBuilding: map['usage_of_building'],
      railwayStation: map['railway_station'],
      noOfUnit: map['no_of_unit'],
      nearestHospital: map['nearest_hospital'],
      noOfFloor: map['no_of_floor'],
      structure: map['structure'],
      occupancy: map['occupancy'],
      boreWell: map['bore_well'],
      septicTank: map['septic_tank'],
      oht: map['oht'],
      compoundWall: map['compound_wall'],
      sump: map['sump'],
      ebServices: map['eb_services'],
      floorType: map['floor_type'],
      demarcated: map['demarcated'],
      noOfTenants: map['no_of_tenants'],
      maintenanceOfBuilding: map['maintenance_of_building'],
      roof: map['roof'],
      stageConstructionPercent: map['stage_construction_percent'],
      typeOfLocality: map['type_of_locality'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      googlePoint: map['google_point'],
      photosPaths: map['photos_paths'],
      signaturePath: map['signature_path'],
      inspectorName: map['inspector_name'],
      companyName: map['company_name'],
    );
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() => toMap();

  /// Create an empty new report
  factory SiteVisitReport.empty(String uuid) {
    final now = DateTime.now();
    return SiteVisitReport(
      reportId: uuid,
      status: 'draft',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Display title for list view
  String get displayTitle {
    if (customerName != null && customerName!.isNotEmpty) return customerName!;
    if (loanNumber != null && loanNumber!.isNotEmpty) return 'Loan: $loanNumber';
    return 'Report #${reportId.substring(0, 8).toUpperCase()}';
  }

  String get displaySubtitle {
    final parts = <String>[];
    if (bankName != null && bankName!.isNotEmpty) parts.add(bankName!);
    if (locality != null && locality!.isNotEmpty) parts.add(locality!);
    return parts.isNotEmpty ? parts.join(' • ') : 'Draft';
  }
}
