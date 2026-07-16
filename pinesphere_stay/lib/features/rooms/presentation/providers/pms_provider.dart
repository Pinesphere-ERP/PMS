import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../main.dart';
import '../../../bookings/domain/models/booking_entity.dart';

class ResortModel {
  final String id;
  final String name;
  final String image;
  final String location;
  final String description;

  ResortModel({
    required this.id,
    required this.name,
    required this.image,
    required this.location,
    this.description = '',
  });
}

class RoomModel {
  final String id;
  final String roomNumber;
  final String type;
  final double price; // Base Price
  final double seasonPrice; // Season pricing surcharge
  final double weekendPrice; // Weekend pricing surcharge
  final double holidayPrice; // Holiday pricing surcharge
  final double extraBedPrice; // Extra bed surcharge
  final List<Map<String, dynamic>> amenities; // Custom amenities, e.g. [{'name': 'Food', 'price': 30.0}]
  final String status; // 'Vacant', 'Occupied', 'Maintenance', 'Cleaning'
  final String resortId;
  final String? currentBookingId;
  final List<String> images;
  final String description;

  RoomModel({
    required this.id,
    required this.roomNumber,
    required this.type,
    required this.price,
    required this.seasonPrice,
    required this.weekendPrice,
    required this.holidayPrice,
    required this.extraBedPrice,
    required this.amenities,
    required this.status,
    required this.resortId,
    this.currentBookingId,
    required this.images,
    this.description = '',
  });

  RoomModel copyWith({
    String? id,
    String? roomNumber,
    String? type,
    double? price,
    double? seasonPrice,
    double? weekendPrice,
    double? holidayPrice,
    double? extraBedPrice,
    List<Map<String, dynamic>>? amenities,
    String? status,
    String? resortId,
    String? currentBookingId,
    List<String>? images,
    String? description,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      type: type ?? this.type,
      price: price ?? this.price,
      seasonPrice: seasonPrice ?? this.seasonPrice,
      weekendPrice: weekendPrice ?? this.weekendPrice,
      holidayPrice: holidayPrice ?? this.holidayPrice,
      extraBedPrice: extraBedPrice ?? this.extraBedPrice,
      amenities: amenities ?? this.amenities,
      status: status ?? this.status,
      resortId: resortId ?? this.resortId,
      currentBookingId: currentBookingId ?? this.currentBookingId,
      images: images ?? this.images,
      description: description ?? this.description,
    );
  }
}

class BookingModel {
  final String id;
  final String resortId;
  final String roomId;
  final String roomNumber;
  final String guestName;
  final String guestPhone;
  final String guestIdProof;
  final String guestIdNumber;
  final String bookingSource; // 'Walk-in', 'Phone', 'WhatsApp', 'Online'
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String status; // 'Active', 'Completed', 'Upcoming'
  final double depositPaid;

  // Invoice Summary Breakdowns:
  final double basePriceSum;
  final double weekendSurcharge;
  final double seasonSurcharge;
  final double holidaySurcharge;
  final double extraBedCharge;
  final double amenitiesCharge;
  final double totalSum;

  // Checkout Incidentals:
  final double damageBill;
  final double laundryBill;
  final double miniBarBill;
  final double restaurantBill;
  final bool isPaid;

  BookingModel({
    required this.id,
    required this.resortId,
    required this.roomId,
    required this.roomNumber,
    required this.guestName,
    required this.guestPhone,
    required this.guestIdProof,
    required this.guestIdNumber,
    required this.bookingSource,
    required this.checkInDate,
    required this.checkOutDate,
    required this.status,
    required this.depositPaid,
    this.basePriceSum = 0,
    this.weekendSurcharge = 0,
    this.seasonSurcharge = 0,
    this.holidaySurcharge = 0,
    this.extraBedCharge = 0,
    this.amenitiesCharge = 0,
    this.totalSum = 0,
    this.damageBill = 0,
    this.laundryBill = 0,
    this.miniBarBill = 0,
    this.restaurantBill = 0,
    this.isPaid = false,
  });

  BookingModel copyWith({
    String? status,
    double? damageBill,
    double? laundryBill,
    double? miniBarBill,
    double? restaurantBill,
    bool? isPaid,
  }) {
    return BookingModel(
      id: id,
      resortId: resortId,
      roomId: roomId,
      roomNumber: roomNumber,
      guestName: guestName,
      guestPhone: guestPhone,
      guestIdProof: guestIdProof,
      guestIdNumber: guestIdNumber,
      bookingSource: bookingSource,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      status: status ?? this.status,
      depositPaid: depositPaid,
      basePriceSum: basePriceSum,
      weekendSurcharge: weekendSurcharge,
      seasonSurcharge: seasonSurcharge,
      holidaySurcharge: holidaySurcharge,
      extraBedCharge: extraBedCharge,
      amenitiesCharge: amenitiesCharge,
      totalSum: totalSum,
      damageBill: damageBill ?? this.damageBill,
      laundryBill: laundryBill ?? this.laundryBill,
      miniBarBill: miniBarBill ?? this.miniBarBill,
      restaurantBill: restaurantBill ?? this.restaurantBill,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

class PmsState {
  final List<ResortModel> resorts;
  final List<RoomModel> rooms;
  final List<BookingModel> bookings;

  PmsState({
    required this.resorts,
    required this.rooms,
    required this.bookings,
  });

  PmsState copyWith({
    List<ResortModel>? resorts,
    List<RoomModel>? rooms,
    List<BookingModel>? bookings,
  }) {
    return PmsState(
      resorts: resorts ?? this.resorts,
      rooms: rooms ?? this.rooms,
      bookings: bookings ?? this.bookings,
    );
  }
}

class PmsNotifier extends Notifier<PmsState> {
  final List<String> _locallyDeletedResortIds = [];

  @override
  PmsState build() {
    Future.microtask(() async {
      await _loadLocallyDeletedResorts();
      await loadResorts();
      await loadRooms();
      await loadBookings();
      await autoVacateExpiredBookings();
    });
    return _initialState();
  }

  Future<void> _loadLocallyDeletedResorts() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/deleted_resorts.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> list = jsonDecode(content);
        _locallyDeletedResortIds.clear();
        _locallyDeletedResortIds.addAll(list.cast<String>());
        state = state.copyWith(
          resorts: state.resorts.where((r) => !_locallyDeletedResortIds.contains(r.id)).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error loading deleted resorts list: $e');
    }
  }

  Future<void> _saveLocallyDeletedResorts() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/deleted_resorts.json');
      await file.writeAsString(jsonEncode(_locallyDeletedResortIds));
    } catch (e) {
      debugPrint('Error saving deleted resorts list: $e');
    }
  }

  Future<void> loadRooms() async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('/properties/rooms');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final loadedRooms = data.map((json) {
          final double baseRent = (json['price'] as num).toDouble();
          String descText = json['description'] ?? '';
          double season = baseRent * 0.3;
          double weekend = baseRent * 0.15;
          double holiday = baseRent * 0.4;
          double extraBed = baseRent * 0.1;
          List<Map<String, dynamic>> amenitiesList = [
            {'name': 'Food / Buffet Included', 'price': 300.0},
            {'name': 'Portable Bluetooth Speaker', 'price': 150.0},
            {'name': 'Smart TV Access', 'price': 100.0},
          ];

          List<String> imagesList = List<String>.from(json['images'] ?? []);

          try {
            if (descText.startsWith('{') && descText.endsWith('}')) {
              final Map<String, dynamic> parsed = Map<String, dynamic>.from(jsonDecode(descText));
              descText = parsed['description'] ?? '';
              season = (parsed['season_price'] as num?)?.toDouble() ?? season;
              weekend = (parsed['weekend_price'] as num?)?.toDouble() ?? weekend;
              holiday = (parsed['holiday_price'] as num?)?.toDouble() ?? holiday;
              extraBed = (parsed['extra_bed_price'] as num?)?.toDouble() ?? extraBed;
              if (parsed['amenities'] != null) {
                amenitiesList = (parsed['amenities'] as List<dynamic>)
                    .map((a) => Map<String, dynamic>.from(a as Map))
                    .toList();
              }
            }
          } catch (_) {
            // Fallback to legacy/default
          }

          if (imagesList.isEmpty) {
            imagesList = [
              'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=500&q=80'
            ];
          }

          return RoomModel(
            id: json['id'],
            roomNumber: json['room_number']?.toString() ?? '',
            type: json['type'],
            price: baseRent,
            seasonPrice: season,
            weekendPrice: weekend,
            holidayPrice: holiday,
            extraBedPrice: extraBed,
            amenities: amenitiesList,
            status: (json['status'] as String?)?.isNotEmpty == true 
                ? '${json['status'][0].toUpperCase()}${json['status'].substring(1).toLowerCase()}' 
                : 'Vacant',
            resortId: json['resort_id'] == '33333333-3333-3333-3333-333333333333' ? 'resort-1' : (json['resort_id'] == '44444444-4444-4444-4444-444444444444' ? 'resort-2' : json['resort_id']),
            images: imagesList,
            description: descText,
          );
        }).toList();
        
        state = state.copyWith(rooms: loadedRooms);
      }
    } catch (e) {
      debugPrint('Failed to load rooms: $e');
    }
  }

  Future<void> loadResorts() async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('/properties');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final loadedResorts = data.map((json) {
          final id = json['id'];
          final resortId = id == '33333333-3333-3333-3333-333333333333' ? 'resort-1' : (id == '44444444-4444-4444-4444-444444444444' ? 'resort-2' : id);
          
          String descText = json['description'] ?? '';
          String locVal = json['city'] ?? '';
          String imgVal = json['image'] ?? '';

          try {
            if (descText.startsWith('{') && descText.endsWith('}')) {
              final Map<String, dynamic> parsed = Map<String, dynamic>.from(jsonDecode(descText));
              descText = parsed['description'] ?? '';
              locVal = parsed['location'] ?? locVal;
              imgVal = parsed['image'] ?? imgVal;
            }
          } catch (_) {
            // Fallback to legacy/default
          }

          if (locVal.isEmpty || locVal == 'Unknown') {
            if (resortId == 'resort-1') {
              locVal = 'Kodaikanal, Tamil Nadu';
            } else if (resortId == 'resort-2') {
              locVal = 'Varkala, Kerala';
            } else {
              locVal = 'Unknown';
            }
          }
          if (imgVal.isEmpty) {
            if (resortId == 'resort-1') {
              imgVal = 'https://images.unsplash.com/photo-1546548970-71785318a17b?auto=format&fit=crop&w=800&q=80';
            } else {
              imgVal = 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80';
            }
          }

          return ResortModel(
            id: resortId,
            name: json['name'] ?? '',
            image: imgVal,
            location: locVal,
            description: descText,
          );
        }).where((resort) => !_locallyDeletedResortIds.contains(resort.id)).toList();

        final defaultFilteredResorts = _initialState().resorts.where((r) => !_locallyDeletedResortIds.contains(r.id)).toList();
        state = state.copyWith(resorts: loadedResorts.isEmpty ? defaultFilteredResorts : loadedResorts);
      }
    } catch (e) {
      debugPrint('Failed to load resorts: $e');
    }
  }

  Future<void> loadBookings() async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('/bookings');
      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['items'] ?? [];
        final loadedBookings = items.map((json) {
          final parsedCheckOutDate = json['check_out_date'] != null ? DateTime.tryParse(json['check_out_date'].toString()) ?? DateTime.now().add(const Duration(days: 1)) : DateTime.now().add(const Duration(days: 1));

          String statusVal = 'Upcoming';
          if (json['booking_status'] == 'checked_in') {
            statusVal = 'Active';
          } else if (json['booking_status'] == 'checked_out') {
            statusVal = 'Completed';
          } else if (json['booking_status'] == 'cancelled') {
            statusVal = 'Completed';
          }
          
          final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
          if (parsedCheckOutDate.isBefore(today) && statusVal != 'Completed') {
            statusVal = 'Completed';
          }
          
          return BookingModel(
            id: json['booking_id']?.toString() ?? 'unknown_id',
            resortId: json['property_id'] == '33333333-3333-3333-3333-333333333333' ? 'resort-1' : (json['property_id'] == '44444444-4444-4444-4444-444444444444' ? 'resort-2' : (json['property_id']?.toString() ?? 'resort-1')),
            roomId: json['room_id']?.toString() ?? '',
            roomNumber: json['room_number']?.toString() ?? '',
            guestName: json['guest_name']?.toString() ?? 'Guest',
            guestPhone: json['guest_mobile']?.toString() ?? '',
            guestIdProof: 'Aadhaar Card',
            guestIdNumber: '',
            bookingSource: json['booking_source']?.toString() ?? 'Walk-in',
            checkInDate: json['check_in_date'] != null ? DateTime.tryParse(json['check_in_date'].toString()) ?? DateTime.now() : DateTime.now(),
            checkOutDate: parsedCheckOutDate,
            status: statusVal,
            depositPaid: double.tryParse(json['deposit']?.toString() ?? '0') ?? 0.0,
            basePriceSum: double.tryParse(json['room_rent']?.toString() ?? '100.0') ?? 100.0,
            weekendSurcharge: 0.0,
            seasonSurcharge: 0.0,
            holidaySurcharge: 0.0,
            extraBedCharge: 0.0,
            amenitiesCharge: double.tryParse(json['taxes']?.toString() ?? '0') ?? 0.0,
            totalSum: double.tryParse(json['total_payable']?.toString() ?? '100.0') ?? 100.0,
          );
        }).toList();
        
        // Merge offline bookings from ObjectBox
        try {
          final offlineEntities = objectBox.store.box<BookingEntity>().getAll();
          for (final entity in offlineEntities) {
            if (!loadedBookings.any((b) => b.id == entity.uuid)) {
              loadedBookings.add(BookingModel(
                id: entity.uuid,
                resortId: entity.propertyId,
                roomId: entity.roomId,
                roomNumber: entity.roomNumber,
                guestName: entity.guestName,
                guestPhone: '',
                guestIdProof: 'Aadhaar Card',
                guestIdNumber: '',
                bookingSource: entity.bookingSource,
                checkInDate: DateTime.tryParse(entity.checkInDate) ?? DateTime.now(),
                checkOutDate: DateTime.tryParse(entity.checkOutDate) ?? DateTime.now().add(const Duration(days: 1)),
                status: entity.bookingStatus == 'checked_in' ? 'Active' : (entity.bookingStatus == 'checked_out' || entity.bookingStatus == 'cancelled' ? 'Completed' : 'Upcoming'),
                depositPaid: entity.deposit,
                basePriceSum: entity.roomRent,
                weekendSurcharge: 0.0,
                seasonSurcharge: 0.0,
                holidaySurcharge: 0.0,
                extraBedCharge: 0.0,
                amenitiesCharge: entity.taxes,
                totalSum: entity.totalPayable,
              ));
            }
          }
        } catch (dbErr) {
          debugPrint('Failed to merge offline bookings: $dbErr');
        }

        state = state.copyWith(bookings: loadedBookings);
      }
    } catch (e) {
      debugPrint('Failed to load bookings: $e');
    }
  }


  static PmsState _initialState() {
    final resorts = [
      ResortModel(
        id: 'resort-1',
        name: 'PineSphere Forest Resort',
        image: 'https://images.unsplash.com/photo-1546548970-71785318a17b?auto=format&fit=crop&w=800&q=80',
        location: 'Kodaikanal, Tamil Nadu',
        description: 'A serene getaway surrounded by towering pines and misty hills.',
      ),
      ResortModel(
        id: 'resort-2',
        name: 'PineSphere Beachside Sanctuary',
        image: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
        location: 'Varkala, Kerala',
        description: 'A beautiful seaside escape with stunning cliffside ocean views.',
      ),
    ];
    final rooms = <RoomModel>[];
    final bookings = <BookingModel>[];

    return PmsState(resorts: resorts, rooms: rooms, bookings: bookings);
  }

  Future<void> createBooking(BookingModel booking) async {
    try {
      final dio = ref.read(dioClientProvider);
      
      final String resolvedPropertyId = booking.resortId == 'resort-1' 
          ? '33333333-3333-3333-3333-333333333333' 
          : (booking.resortId == 'resort-2'
              ? '44444444-4444-4444-4444-444444444444'
              : booking.resortId);

      // Create guest first to prevent 404 Guest not found on booking creation
      final guestResponse = await dio.post('/bookings/guests', data: {
        'property_id': resolvedPropertyId,
        'full_name': booking.guestName,
        'mobile': booking.guestPhone,
        'id_type': booking.guestIdProof,
        'id_number': booking.guestIdNumber,
      });

      final String guestUuid = guestResponse.data['guest_id'];
      
      final response = await dio.post('/bookings', data: {
        'property_id': resolvedPropertyId,
        'room_id': booking.roomId,
        'guest_id': guestUuid,
        'booking_type': 'walkin',
        'booking_source': booking.bookingSource,
        'check_in_date': booking.checkInDate.toIso8601String().substring(0, 10),
        'check_out_date': booking.checkOutDate.toIso8601String().substring(0, 10),
        'adults': 1,
        'children': 0,
        'room_rent': booking.totalSum - booking.depositPaid,
        'deposit': booking.depositPaid,
        'discount': 0.0,
        'taxes': booking.amenitiesCharge,
        'advance_paid': booking.depositPaid,
        'extra_bed': false,
      });
      
      if (response.statusCode == 201) {
        // Re-check-in if needed or just reload
        final newBookingId = response.data['booking_id'];
        await dio.post('/bookings/$newBookingId/check-in');
        
        await loadRooms();
        await loadBookings();
      }
    } catch (e) {
      debugPrint('Failed to create booking: $e');
      // Offline fallback: Add to local state and mark room as Occupied so it is viewed immediately
      state = state.copyWith(
        bookings: [...state.bookings, booking],
        rooms: state.rooms.map((room) {
          if (room.id == booking.roomId) {
            return room.copyWith(
              status: 'Occupied',
              currentBookingId: booking.id,
            );
          }
          return room;
        }).toList(),
      );

      // Save to local ObjectBox DB for persistence
      try {
        final resolvedPropertyId = booking.resortId == 'resort-1' 
            ? '33333333-3333-3333-3333-333333333333' 
            : (booking.resortId == 'resort-2'
                ? '44444444-4444-4444-4444-444444444444'
                : booking.resortId);

        final entity = BookingEntity(
          uuid: booking.id,
          propertyId: resolvedPropertyId,
          roomId: booking.roomId,
          guestId: 'offline_${DateTime.now().millisecondsSinceEpoch}', 
          guestName: booking.guestName,
          roomNumber: booking.roomNumber,
          roomType: '',
          bookingType: 'walkin',
          bookingSource: booking.bookingSource,
          checkInDate: booking.checkInDate.toIso8601String().substring(0, 10),
          checkOutDate: booking.checkOutDate.toIso8601String().substring(0, 10),
          adults: 1,
          children: 0,
          infants: 0,
          roomRent: booking.totalSum - booking.depositPaid,
          deposit: booking.depositPaid,
          discount: 0.0,
          taxes: booking.amenitiesCharge,
          totalPayable: booking.totalSum,
          advancePaid: booking.depositPaid,
          pendingAmount: booking.totalSum - booking.depositPaid,
          extraBed: false,
          guestPreferences: '',
          notes: '',
          vehicleNumber: '',
          bookingStatus: 'confirmed',
          paymentStatus: 'pending',
          lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
        );
        objectBox.store.box<BookingEntity>().put(entity);
        debugPrint('Offline booking saved to local DB successfully');
      } catch (dbErr) {
        debugPrint('Failed to save offline booking to DB: $dbErr');
      }
    }
  }

  Future<void> checkOut(
    String bookingId, {
    double damage = 0,
    double laundry = 0,
    double miniBar = 0,
    double restaurant = 0,
  }) async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post('/bookings/$bookingId/check-out', data: {
        'damage_bill': damage,
        'laundry_bill': laundry,
        'minibar_bill': miniBar,
        'restaurant_bill': restaurant,
      });
      
      if (response.statusCode == 200) {
        await loadRooms();
        await loadBookings();
      }
    } catch (e) {
      debugPrint('Failed to check out: $e');
    }
  }

  Future<void> updateRoomStatus(String roomId, String status) async {
    try {
      final dio = ref.read(dioClientProvider);
      if (status == 'Vacant') {
        final response = await dio.post('/properties/rooms/$roomId/clean');
        if (response.statusCode == 200) {
          await loadRooms();
        }
      }
    } catch (e) {
      debugPrint('Failed to update room status: $e');
    }
  }

  Future<void> updateRoomDetails(String roomId, RoomModel updatedRoom) async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.put('/properties/rooms/$roomId', data: {
        'room_number': updatedRoom.roomNumber,
        'type': updatedRoom.type,
        'price': updatedRoom.price,
        'status': updatedRoom.status,
        'description': updatedRoom.description,
      });
      if (response.statusCode == 200) {
        await loadRooms();
      }
    } catch (e) {
      debugPrint('Failed to update room details: $e');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.delete('/properties/rooms/$roomId');
      if (response.statusCode == 200) {
        await loadRooms();
      }
    } catch (e) {
      debugPrint('Failed to delete room: $e');
    }
  }

  Future<void> autoVacateExpiredBookings() async {
    final now = DateTime.now();
    final dio = ref.read(dioClientProvider);
    bool changed = false;
    for (final room in state.rooms) {
      if (room.status == 'Occupied' && room.currentBookingId != null) {
        final bookingIndex = state.bookings.indexWhere((b) => b.id == room.currentBookingId && b.status == 'Active');
        if (bookingIndex != -1) {
          final booking = state.bookings[bookingIndex];
          if (booking.checkOutDate.isBefore(now)) {
            try {
              await dio.post('/bookings/${booking.id}/check-out', data: {
                'damage_bill': 0.0,
                'laundry_bill': 0.0,
                'minibar_bill': 0.0,
                'restaurant_bill': 0.0,
              });
              await dio.post('/properties/rooms/${room.id}/clean');
              changed = true;
            } catch (e) {
              debugPrint('Auto-vacate backend call failed for booking ${booking.id}: $e');
            }
          }
        }
      }
    }
    if (changed) {
      await loadRooms();
      await loadBookings();
    }
  }

  Future<void> addRoom(RoomModel room, {bool refresh = true}) async {
    try {
      final dio = ref.read(dioClientProvider);
      
      // Upload any local images to the backend first
      List<String> finalImages = [];
      for (String imagePath in room.images) {
        if (!imagePath.startsWith('http') && imagePath.isNotEmpty) {
          try {
            final formData = FormData.fromMap({
              'file': await MultipartFile.fromFile(imagePath),
            });
            final uploadResponse = await dio.post('/properties/upload', data: formData);
            if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
              finalImages.add(uploadResponse.data['url']);
            } else {
              finalImages.add(imagePath); // fallback
            }
          } catch (e) {
            debugPrint('Image upload failed: $e');
            finalImages.add(imagePath); // fallback
          }
        } else {
          finalImages.add(imagePath);
        }
      }

      final response = await dio.post('/properties/rooms', data: {
        'room_number': room.roomNumber,
        'type': room.type,
        'price': room.price,
        'resort_id': room.resortId == 'resort-1' 
            ? '33333333-3333-3333-3333-333333333333' 
            : (room.resortId == 'resort-2' ? '44444444-4444-4444-4444-444444444444' : room.resortId),
        'description': jsonEncode({
          'description': room.description,
          'season_price': room.seasonPrice,
          'weekend_price': room.weekendPrice,
          'holiday_price': room.holidayPrice,
          'extra_bed_price': room.extraBedPrice,
          'amenities': room.amenities,
          'images': finalImages,
        }),
        'image_url': finalImages.join(','),
      });
      
      if ((response.statusCode == 200 || response.statusCode == 201) && refresh) {
        await loadRooms();
      }
    } catch (e) {
      debugPrint('Failed to add room: $e');
      // Offline fallback: Add to local state
      state = state.copyWith(
        rooms: [...state.rooms, room],
      );
    }
  }

  Future<void> addResort(ResortModel resort) async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post('/properties', data: {
        'owner_name': 'Default Owner',
        'owner_mobile': '9999999999',
        'owner_email': 'owner@example.com',
        'business_name': '${resort.name} Business',
        'property_name': resort.name,
        'property_type': 'Resort',
        'star_category': 5,
        'year_established': 2024,
        'total_floors': 3,
        'total_rooms': 10,
        'description': jsonEncode({
          'description': resort.description,
          'location': resort.location,
          'image': resort.image,
        }),
        'city': resort.location,
        'cover_image': resort.image,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadResorts();
      }
    } catch (e) {
      debugPrint('Failed to create resort: $e');
      // Offline fallback: Add to local state
      state = state.copyWith(
        resorts: [...state.resorts, resort],
      );
    }
  }

  Future<void> updateResort(ResortModel resort) async {
    try {
      final dio = ref.read(dioClientProvider);
      final String resolvedId = resort.id == 'resort-1' 
          ? '33333333-3333-3333-3333-333333333333' 
          : (resort.id == 'resort-2' ? '44444444-4444-4444-4444-444444444444' : resort.id);

      final response = await dio.put('/properties/$resolvedId', data: {
        'owner_name': 'Default Owner',
        'owner_mobile': '9999999999',
        'owner_email': 'owner@example.com',
        'business_name': '${resort.name} Business',
        'property_name': resort.name,
        'property_type': 'Resort',
        'star_category': 5,
        'year_established': 2024,
        'total_floors': 3,
        'total_rooms': 10,
        'description': jsonEncode({
          'description': resort.description,
          'location': resort.location,
          'image': resort.image,
        }),
        'city': resort.location,
        'cover_image': resort.image,
      });

      if (response.statusCode == 200) {
        await loadResorts();
      }
    } catch (e) {
      debugPrint('Failed to update resort: $e');
      // Offline fallback: Update local state
      final index = state.resorts.indexWhere((r) => r.id == resort.id);
      if (index != -1) {
        final list = List<ResortModel>.from(state.resorts);
        list[index] = resort;
        state = state.copyWith(resorts: list);
      }
    }
  }

  Future<void> deleteResort(String resortId) async {
    try {
      if (!_locallyDeletedResortIds.contains(resortId)) {
        _locallyDeletedResortIds.add(resortId);
        await _saveLocallyDeletedResorts();
      }

      final dio = ref.read(dioClientProvider);
      final String resolvedId = resortId == 'resort-1' 
          ? '33333333-3333-3333-3333-333333333333' 
          : (resortId == 'resort-2' ? '44444444-4444-4444-4444-444444444444' : resortId);

      await dio.delete('/properties/$resolvedId');
      await loadResorts();
    } catch (e) {
      debugPrint('Failed to delete resort: $e');
      // Offline fallback: Delete locally
      state = state.copyWith(
        resorts: state.resorts.where((r) => r.id != resortId).toList(),
      );
    }
  }

  Future<void> addResortWithRooms(ResortModel resort, int numRooms) async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post('/properties', data: {
        'owner_name': 'Default Owner',
        'owner_mobile': '9999999999',
        'owner_email': 'owner@example.com',
        'business_name': '${resort.name} Business',
        'property_name': resort.name,
        'property_type': 'Resort',
        'star_category': 5,
        'year_established': 2024,
        'total_floors': 3,
        'total_rooms': numRooms,
        'description': resort.description,
        'city': resort.location,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final newResortId = response.data['property_id'];
        for (int i = 0; i < numRooms; i++) {
          final roomNumber = '${(state.resorts.length + 1) * 100 + i + 1}';
          final newRoom = RoomModel(
            id: '',
            roomNumber: roomNumber,
            type: i % 2 == 0 ? 'Deluxe Suite' : 'Standard Room',
            price: i % 2 == 0 ? 1500.0 : 900.0,
            seasonPrice: i % 2 == 0 ? 400.0 : 250.0,
            weekendPrice: i % 2 == 0 ? 250.0 : 150.0,
            holidayPrice: i % 2 == 0 ? 600.0 : 350.0,
            extraBedPrice: i % 2 == 0 ? 200.0 : 100.0,
            amenities: const [
              {'name': 'Food / Buffet Included', 'price': 300.0},
              {'name': 'Portable Bluetooth Speaker', 'price': 150.0},
              {'name': 'Smart TV Access', 'price': 100.0},
            ],
            status: 'Vacant',
            resortId: newResortId,
            images: i % 2 == 0 
                ? ['https://images.unsplash.com/photo-1618773928121-c32242e63f39?auto=format&fit=crop&w=500&q=80']
                : ['https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=500&q=80'],
            description: i % 2 == 0 
                ? 'Luxurious Deluxe Suite featuring premium view, elegant interiors and master bed.' 
                : 'Comfortable Standard Room with modern furniture and high-speed Wi-Fi.',
          );
          await addRoom(newRoom, refresh: false);
        }
        await loadResorts();
        await loadRooms();
      }
    } catch (e) {
      debugPrint('Failed to create resort with rooms: $e');
      // Offline fallback: Add resort and generate mock rooms locally so they are viewed instantly
      final generatedRooms = List.generate(numRooms, (index) {
        final roomNumber = '${(state.resorts.length + 1) * 100 + index + 1}';
        return RoomModel(
          id: 'room_${resort.id}_$index',
          roomNumber: roomNumber,
          type: index % 2 == 0 ? 'Deluxe Suite' : 'Standard Room',
          price: index % 2 == 0 ? 1500.0 : 900.0,
          seasonPrice: index % 2 == 0 ? 400.0 : 250.0,
          weekendPrice: index % 2 == 0 ? 250.0 : 150.0,
          holidayPrice: index % 2 == 0 ? 600.0 : 350.0,
          extraBedPrice: index % 2 == 0 ? 200.0 : 100.0,
          amenities: const [
            {'name': 'Food / Buffet Included', 'price': 300.0},
            {'name': 'Portable Bluetooth Speaker', 'price': 150.0},
            {'name': 'Smart TV Access', 'price': 100.0},
          ],
          status: 'Vacant',
          resortId: resort.id,
          images: index % 2 == 0 
              ? ['https://images.unsplash.com/photo-1618773928121-c32242e63f39?auto=format&fit=crop&w=500&q=80']
              : ['https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=500&q=80'],
          description: index % 2 == 0 
              ? 'Luxurious Deluxe Suite featuring premium view, elegant interiors and master bed.' 
              : 'Comfortable Standard Room with modern furniture and high-speed Wi-Fi.',
        );
      });

      state = state.copyWith(
        resorts: [...state.resorts, resort],
        rooms: [...state.rooms, ...generatedRooms],
      );
    }
  }
}

final pmsProvider = NotifierProvider<PmsNotifier, PmsState>(() {
  return PmsNotifier();
});
