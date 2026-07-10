import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return _initialState();
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

    final defaultAmenities = [
      {'name': 'Food / Buffet Included', 'price': 30.0},
      {'name': 'Portable Bluetooth Speaker', 'price': 15.0},
      {'name': 'Smart TV Access', 'price': 10.0},
      {'name': 'Projector Setup', 'price': 25.0},
    ];

    final rooms = [
      // Resort 1
      RoomModel(
        id: 'room-101',
        roomNumber: '101',
        type: 'Deluxe Suite',
        price: 120.0,
        seasonPrice: 40.0,
        weekendPrice: 20.0,
        holidayPrice: 50.0,
        extraBedPrice: 15.0,
        amenities: defaultAmenities,
        status: 'Occupied',
        resortId: 'resort-1',
        currentBookingId: 'b1',
        images: [
          'https://images.unsplash.com/photo-1618773928121-c32242e63f39?auto=format&fit=crop&w=500&q=80',
          'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=500&q=80',
        ],
      ),
      RoomModel(
        id: 'room-102',
        roomNumber: '102',
        type: 'Twin Room',
        price: 85.0,
        seasonPrice: 30.0,
        weekendPrice: 15.0,
        holidayPrice: 40.0,
        extraBedPrice: 10.0,
        amenities: defaultAmenities,
        status: 'Vacant',
        resortId: 'resort-1',
        images: [
          'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=500&q=80',
        ],
      ),
      RoomModel(
        id: 'room-103',
        roomNumber: '103',
        type: 'Standard King',
        price: 95.0,
        seasonPrice: 30.0,
        weekendPrice: 15.0,
        holidayPrice: 40.0,
        extraBedPrice: 12.0,
        amenities: defaultAmenities,
        status: 'Maintenance',
        resortId: 'resort-1',
        images: [
          'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=500&q=80',
        ],
      ),
      RoomModel(
        id: 'room-104',
        roomNumber: '104',
        type: 'Executive Villa',
        price: 250.0,
        seasonPrice: 80.0,
        weekendPrice: 50.0,
        holidayPrice: 100.0,
        extraBedPrice: 30.0,
        amenities: defaultAmenities,
        status: 'Vacant',
        resortId: 'resort-1',
        images: [
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=500&q=80',
        ],
      ),
      // Resort 2
      RoomModel(
        id: 'room-201',
        roomNumber: '201',
        type: 'Ocean View Suite',
        price: 180.0,
        seasonPrice: 50.0,
        weekendPrice: 30.0,
        holidayPrice: 70.0,
        extraBedPrice: 20.0,
        amenities: defaultAmenities,
        status: 'Occupied',
        resortId: 'resort-2',
        currentBookingId: 'b2',
        images: [
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=500&q=80',
        ],
      ),
      RoomModel(
        id: 'room-202',
        roomNumber: '202',
        type: 'Deluxe Cottage',
        price: 140.0,
        seasonPrice: 40.0,
        weekendPrice: 20.0,
        holidayPrice: 60.0,
        extraBedPrice: 15.0,
        amenities: defaultAmenities,
        status: 'Vacant',
        resortId: 'resort-2',
        images: [
          'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=500&q=80',
        ],
      ),
    ];

    final bookings = [
      BookingModel(
        id: 'b1',
        resortId: 'resort-1',
        roomId: 'room-101',
        roomNumber: '101',
        guestName: 'John Doe',
        guestPhone: '+91 98765 43210',
        guestIdProof: 'Aadhaar Card',
        guestIdNumber: '1234 5678 9012',
        bookingSource: 'Walk-in',
        checkInDate: DateTime.now().subtract(const Duration(days: 2)),
        checkOutDate: DateTime.now().add(const Duration(days: 3)),
        status: 'Active',
        depositPaid: 100.0,
        basePriceSum: 240.0,
        weekendSurcharge: 40.0,
        seasonSurcharge: 0.0,
        holidaySurcharge: 0.0,
        extraBedCharge: 30.0,
        amenitiesCharge: 40.0,
        totalSum: 350.0,
      ),
      BookingModel(
        id: 'b2',
        resortId: 'resort-2',
        roomId: 'room-201',
        roomNumber: '201',
        guestName: 'Alice Smith',
        guestPhone: '+91 99999 88888',
        guestIdProof: 'Passport',
        guestIdNumber: 'L8765432',
        bookingSource: 'WhatsApp',
        checkInDate: DateTime.now().subtract(const Duration(days: 1)),
        checkOutDate: DateTime.now().add(const Duration(days: 4)),
        status: 'Active',
        depositPaid: 200.0,
        basePriceSum: 720.0,
        weekendSurcharge: 60.0,
        seasonSurcharge: 50.0,
        holidaySurcharge: 0.0,
        extraBedCharge: 0.0,
        amenitiesCharge: 30.0,
        totalSum: 860.0,
      ),
    ];

    return PmsState(resorts: resorts, rooms: rooms, bookings: bookings);
  }

  void createBooking(BookingModel booking) {
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
  }

  void checkOut(
    String bookingId, {
    double damage = 0,
    double laundry = 0,
    double miniBar = 0,
    double restaurant = 0,
  }) {
    state = state.copyWith(
      bookings: state.bookings.map((booking) {
        if (booking.id == bookingId) {
          return booking.copyWith(
            status: 'Completed',
            damageBill: damage,
            laundryBill: laundry,
            miniBarBill: miniBar,
            restaurantBill: restaurant,
            isPaid: true,
          );
        }
        return booking;
      }).toList(),
      rooms: state.rooms.map((room) {
        if (room.currentBookingId == bookingId) {
          return room.copyWith(
            status: 'Maintenance', // default to Maintenance after checkout
            currentBookingId: null,
          );
        }
        return room;
      }).toList(),
    );
  }

  void updateRoomStatus(String roomId, String status) {
    state = state.copyWith(
      rooms: state.rooms.map((room) {
        if (room.id == roomId) {
          return room.copyWith(
            status: status,
            currentBookingId: status != 'Occupied' ? null : room.currentBookingId,
          );
        }
        return room;
      }).toList(),
    );
  }

  void updateRoomDetails(String roomId, RoomModel updatedRoom) {
    state = state.copyWith(
      rooms: state.rooms.map((room) {
        return room.id == roomId ? updatedRoom : room;
      }).toList(),
    );
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

  void addRoom(RoomModel room) {
    state = state.copyWith(
      rooms: [...state.rooms, room],
    );
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
