import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/dio_client.dart';
import '../../../audit/data/audit_service.dart';

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
  @override
  PmsState build() {
    Future.microtask(() async {
      await loadResorts();
      await loadRooms();
      await loadBookings();
      await autoVacateExpiredBookings();
    });
    return _initialState();
  }

  Future<void> loadRooms() async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('/properties/rooms');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final loadedRooms = data.map((json) => RoomModel(
          id: json['id'],
          roomNumber: json['room_number'],
          type: json['type'],
          price: (json['price'] as num).toDouble(),
          seasonPrice: 40.0,
          weekendPrice: 20.0,
          holidayPrice: 60.0,
          extraBedPrice: 15.0,
          amenities: const [
            {'name': 'Food / Buffet Included', 'price': 30.0},
            {'name': 'Portable Bluetooth Speaker', 'price': 15.0},
            {'name': 'Smart TV Access', 'price': 10.0},
            {'name': 'Projector Setup', 'price': 25.0},
          ],
          status: (json['status'] as String?)?.isNotEmpty == true 
              ? '${json['status'][0].toUpperCase()}${json['status'].substring(1).toLowerCase()}' 
              : 'Vacant',
          resortId: json['resort_id'] == '33333333-3333-3333-3333-333333333333' ? 'resort-1' : (json['resort_id'] == '44444444-4444-4444-4444-444444444444' ? 'resort-2' : json['resort_id']),
          images: List<String>.from(json['images'] ?? []),
          description: json['description'] ?? '',
        )).toList();
        
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
          return ResortModel(
            id: resortId,
            name: json['name'] ?? '',
            image: resortId == 'resort-1' 
                ? 'https://images.unsplash.com/photo-1546548970-71785318a17b?auto=format&fit=crop&w=800&q=80'
                : 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
            location: json['city'] == 'Unknown' ? 'Kodaikanal, Tamil Nadu' : json['city'] ?? '',
            description: json['description'] ?? '',
          );
        }).toList();
        state = state.copyWith(resorts: loadedResorts.isEmpty ? _initialState().resorts : loadedResorts);
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
          String statusVal = 'Upcoming';
          if (json['booking_status'] == 'checked_in') {
            statusVal = 'Active';
          } else if (json['booking_status'] == 'checked_out') {
            statusVal = 'Completed';
          } else if (json['booking_status'] == 'cancelled') {
            statusVal = 'Completed';
          }
          
          return BookingModel(
            id: json['booking_id'],
            resortId: json['property_id'] == '33333333-3333-3333-3333-333333333333' ? 'resort-1' : (json['property_id'] == '44444444-4444-4444-4444-444444444444' ? 'resort-2' : json['property_id']),
            roomId: json['room_id'],
            roomNumber: json['room_number'] ?? '',
            guestName: json['guest_name'] ?? 'Guest',
            guestPhone: json['guest_mobile'] ?? '',
            guestIdProof: 'Aadhaar Card',
            guestIdNumber: '',
            bookingSource: json['booking_source'] ?? 'Walk-in',
            checkInDate: DateTime.parse(json['check_in_date']),
            checkOutDate: DateTime.parse(json['check_out_date']),
            status: statusVal,
            depositPaid: (json['deposit'] as num?)?.toDouble() ?? 0.0,
            basePriceSum: (json['room_rent'] as num?)?.toDouble() ?? 100.0,
            weekendSurcharge: 0.0,
            seasonSurcharge: 0.0,
            holidaySurcharge: 0.0,
            extraBedCharge: 0.0,
            amenitiesCharge: (json['taxes'] as num?)?.toDouble() ?? 0.0,
            totalSum: (json['total_payable'] as num?)?.toDouble() ?? 100.0,
          );
        }).toList();
        
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
      final guestUuid = const Uuid().v4();
      
      final response = await dio.post('/bookings', data: {
        'property_id': booking.resortId == 'resort-1' 
            ? '33333333-3333-3333-3333-333333333333' 
            : '44444444-4444-4444-4444-444444444444',
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
        'guest_name': booking.guestName,
        'guest_phone': booking.guestPhone,
        'guest_id_proof': booking.guestIdProof,
        'guest_id_number': booking.guestIdNumber,
      });
      
      final newBookingId = response.data['booking_id'];

      ref.read(auditServiceProvider).log(
        moduleName: 'bookings',
        actionType: 'create_booking',
        targetEntity: 'booking',
        targetRecordId: newBookingId?.toString() ?? '',
        propertyId: booking.resortId == 'resort-1'
            ? '33333333-3333-3333-3333-333333333333'
            : '44444444-4444-4444-4444-444444444444',
        newValue: {
          'guest_name': booking.guestName,
          'room_id': booking.roomId,
          'check_in_date': booking.checkInDate.toIso8601String().substring(0, 10),
          'check_out_date': booking.checkOutDate.toIso8601String().substring(0, 10),
          'total_payable': booking.totalSum,
        },
      );

      if (response.statusCode == 201) {
        await dio.post('/bookings/$newBookingId/check-in');
        await loadRooms();
        await loadBookings();
      }
    } catch (e) {
      debugPrint('Failed to create booking: $e');
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
      
      ref.read(auditServiceProvider).log(
        moduleName: 'checkout',
        actionType: 'check_out',
        targetEntity: 'booking',
        targetRecordId: bookingId,
        newValue: {
          'damage_bill': damage,
          'laundry_bill': laundry,
          'minibar_bill': miniBar,
          'restaurant_bill': restaurant,
        },
      );

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
          ref.read(auditServiceProvider).log(
            moduleName: 'rooms',
            actionType: 'update_room_status',
            targetEntity: 'room',
            targetRecordId: roomId,
            newValue: {'status': status},
          );
          await loadRooms();
        }
      }
    } catch (e) {
      debugPrint('Failed to update room status: $e');
    }
  }

  Future<void> updateRoomDetails(String roomId, RoomModel updatedRoom) async {
    try {
      ref.read(auditServiceProvider).log(
        moduleName: 'rooms',
        actionType: 'update_room_details',
        targetEntity: 'room',
        targetRecordId: roomId,
        newValue: {
          'room_number': updatedRoom.roomNumber,
          'type': updatedRoom.type,
          'price': updatedRoom.price,
          'status': updatedRoom.status,
          'description': updatedRoom.description,
        },
      );
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
        ref.read(auditServiceProvider).log(
          moduleName: 'rooms',
          actionType: 'delete_room',
          targetEntity: 'room',
          targetRecordId: roomId,
        );
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
              ref.read(auditServiceProvider).log(
                moduleName: 'checkout',
                actionType: 'auto_vacate',
                targetEntity: 'booking',
                targetRecordId: booking.id,
                newValue: {
                  'room_id': room.id,
                  'room_number': room.roomNumber,
                  'guest_name': booking.guestName,
                  'scheduled_checkout': booking.checkOutDate.toIso8601String(),
                },
              );
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

  Future<void> addRoom(RoomModel room) async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post('/properties/rooms', data: {
        'room_number': room.roomNumber,
        'type': room.type,
        'price': room.price,
        'resort_id': room.resortId == 'resort-1' 
            ? '33333333-3333-3333-3333-333333333333' 
            : (room.resortId == 'resort-2' ? '44444444-4444-4444-4444-444444444444' : room.resortId),
        'description': room.description,
      });
      
      if (response.statusCode == 201) {
        ref.read(auditServiceProvider).log(
          moduleName: 'rooms',
          actionType: 'add_room',
          targetEntity: 'room',
          targetRecordId: response.data['room_id']?.toString() ?? '',
          newValue: {
            'room_number': room.roomNumber,
            'type': room.type,
            'price': room.price,
            'resort_id': room.resortId,
          },
        );
        await loadRooms();
      }
    } catch (e) {
      debugPrint('Failed to add room: $e');
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
        'description': resort.description,
        'city': resort.location,
      });
      
      if (response.statusCode == 201) {
        ref.read(auditServiceProvider).log(
          moduleName: 'properties',
          actionType: 'add_resort',
          targetEntity: 'property',
          targetRecordId: response.data['property_id']?.toString() ?? '',
          newValue: {
            'name': resort.name,
            'location': resort.location,
          },
        );
        await loadResorts();
      }
    } catch (e) {
      debugPrint('Failed to create resort: $e');
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
      
      if (response.statusCode == 201) {
        final newResortId = response.data['property_id'];
        ref.read(auditServiceProvider).log(
          moduleName: 'properties',
          actionType: 'add_resort_with_rooms',
          targetEntity: 'property',
          targetRecordId: newResortId?.toString() ?? '',
          newValue: {
            'name': resort.name,
            'location': resort.location,
            'num_rooms': numRooms,
          },
        );
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
          await addRoom(newRoom);
        }
        await loadResorts();
        await loadRooms();
      }
    } catch (e) {
      debugPrint('Failed to create resort with rooms: $e');
    }
  }
}

final pmsProvider = NotifierProvider<PmsNotifier, PmsState>(() {
  return PmsNotifier();
});
