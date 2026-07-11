import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/dio_client.dart';

class ResortModel {
  final String id;
  final String name;
  final String image;
  final String location;

  ResortModel({
    required this.id,
    required this.name,
    required this.image,
    required this.location,
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
  });

  RoomModel copyWith({
    String? status,
    String? currentBookingId,
    List<String>? images,
    double? price,
    double? seasonPrice,
    double? weekendPrice,
    double? holidayPrice,
    double? extraBedPrice,
    List<Map<String, dynamic>>? amenities,
  }) {
    return RoomModel(
      id: id,
      roomNumber: roomNumber,
      type: type,
      price: price ?? this.price,
      seasonPrice: seasonPrice ?? this.seasonPrice,
      weekendPrice: weekendPrice ?? this.weekendPrice,
      holidayPrice: holidayPrice ?? this.holidayPrice,
      extraBedPrice: extraBedPrice ?? this.extraBedPrice,
      amenities: amenities ?? this.amenities,
      status: status ?? this.status,
      resortId: resortId,
      currentBookingId: currentBookingId ?? this.currentBookingId,
      images: images ?? this.images,
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
    required this.basePriceSum,
    required this.weekendSurcharge,
    required this.seasonSurcharge,
    required this.holidaySurcharge,
    required this.extraBedCharge,
    required this.amenitiesCharge,
    required this.totalSum,
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
    // Load data from backend
    Future.microtask(() {
      loadRooms();
      loadBookings();
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
          status: json['status'],
          resortId: json['resort_id'] == '33333333-3333-3333-3333-333333333333' ? 'resort-1' : 'resort-2',
          images: List<String>.from(json['images'] ?? []),
        )).toList();
        
        state = state.copyWith(rooms: loadedRooms);
      }
    } catch (e) {
      print('Failed to load rooms: $e');
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
            resortId: json['property_id'] == '33333333-3333-3333-3333-333333333333' ? 'resort-1' : 'resort-2',
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
      print('Failed to load bookings: $e');
    }
  }


  static PmsState _initialState() {
    final resorts = [
      ResortModel(
        id: 'resort-1',
        name: 'PineSphere Forest Resort',
        image: 'https://images.unsplash.com/photo-1546548970-71785318a17b?auto=format&fit=crop&w=800&q=80',
        location: 'Kodaikanal, Tamil Nadu',
      ),
      ResortModel(
        id: 'resort-2',
        name: 'PineSphere Beachside Sanctuary',
        image: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
        location: 'Varkala, Kerala',
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
      
      if (response.statusCode == 201) {
        // Re-check-in if needed or just reload
        final newBookingId = response.data['booking_id'];
        await dio.post('/bookings/$newBookingId/check-in');
        
        await loadRooms();
        await loadBookings();
      }
    } catch (e) {
      print('Failed to create booking: $e');
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
      print('Failed to check out: $e');
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
      print('Failed to update room status: $e');
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
      });
      if (response.statusCode == 200) {
        await loadRooms();
      }
    } catch (e) {
      print('Failed to update room details: $e');
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
      print('Failed to delete room: $e');
    }
  }

  void autoVacateExpiredBookings() {
    final now = DateTime.now();
    bool changed = false;

    final updatedRooms = state.rooms.map((room) {
      if (room.status == 'Occupied' && room.currentBookingId != null) {
        final bookingIndex = state.bookings.indexWhere((b) => b.id == room.currentBookingId && b.status == 'Active');
        if (bookingIndex != -1) {
          final booking = state.bookings[bookingIndex];
          if (booking.checkOutDate.isBefore(now)) {
            changed = true;
            return room.copyWith(
              status: 'Vacant',
              currentBookingId: null,
            );
          }
        }
      }
      return room;
    }).toList();

    if (changed) {
      state = state.copyWith(
        rooms: updatedRooms,
        bookings: state.bookings.map((b) {
          if (b.status == 'Active' && b.checkOutDate.isBefore(now)) {
            return b.copyWith(status: 'Completed');
          }
          return b;
        }).toList(),
      );
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
            : '44444444-4444-4444-4444-444444444444',
      });
      
      if (response.statusCode == 201) {
        await loadRooms();
      }
    } catch (e) {
      print('Failed to add room: $e');
    }
  }

  void addResort(ResortModel resort) {
    state = state.copyWith(
      resorts: [...state.resorts, resort],
    );
  }

  void addResortWithRooms(ResortModel resort, int numRooms) {
    final generatedRooms = List.generate(numRooms, (index) {
      final resortIndex = state.resorts.length + 1;
      final roomNumber = '${resortIndex * 100 + index + 1}';
      
      return RoomModel(
        id: 'room_${resort.id}_$index',
        roomNumber: roomNumber,
        type: index % 2 == 0 ? 'Deluxe Suite' : 'Standard Room',
        price: index % 2 == 0 ? 150.0 : 90.0,
        seasonPrice: index % 2 == 0 ? 40.0 : 25.0,
        weekendPrice: index % 2 == 0 ? 25.0 : 15.0,
        holidayPrice: index % 2 == 0 ? 60.0 : 35.0,
        extraBedPrice: index % 2 == 0 ? 20.0 : 10.0,
        amenities: [
          {'name': 'Food / Buffet Included', 'price': 30.0},
          {'name': 'Portable Bluetooth Speaker', 'price': 15.0},
          {'name': 'Smart TV Access', 'price': 10.0},
          {'name': 'Projector Setup', 'price': 25.0},
        ],
        status: 'Vacant',
        resortId: resort.id,
        images: index % 2 == 0 
            ? [
                'https://images.unsplash.com/photo-1618773928121-c32242e63f39?auto=format&fit=crop&w=500&q=80',
              ]
            : [
                'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=500&q=80',
              ],
      );
    });

    state = state.copyWith(
      resorts: [...state.resorts, resort],
      rooms: [...state.rooms, ...generatedRooms],
    );
  }
}

final pmsProvider = NotifierProvider<PmsNotifier, PmsState>(() {
  return PmsNotifier();
});
