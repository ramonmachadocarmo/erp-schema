// To parse this JSON data, do
//
//     final address = addressFromJson(jsonString);
//     final quote = quoteFromJson(jsonString);

import 'dart:convert';

Address addressFromJson(String str) => Address.fromJson(json.decode(str));

String addressToJson(Address data) => json.encode(data.toJson());

Quote quoteFromJson(String str) => Quote.fromJson(json.decode(str));

String quoteToJson(Quote data) => json.encode(data.toJson());


///A postal address as it crosses the wire today — identical shape independently duplicated
///in sales-service's OrderAddress and config-service's Address before this schema existed.
class Address {
    String alias;
    String city;
    String complement;
    String district;
    
    ///Empty when the address is an inline snapshot (e.g. on an order) rather than a saved
    ///record.
    String? id;
    
    ///Absent (not null) when unset — Go's omitempty drops the key entirely.
    double? lat;
    
    ///Absent (not null) when unset — Go's omitempty drops the key entirely.
    double? lng;
    String number;
    String state;
    String street;
    String zip;

    Address({
        required this.alias,
        required this.city,
        required this.complement,
        required this.district,
        this.id,
        this.lat,
        this.lng,
        required this.number,
        required this.state,
        required this.street,
        required this.zip,
    });

    factory Address.fromJson(Map<String, dynamic> json) => Address(
        alias: json["alias"],
        city: json["city"],
        complement: json["complement"],
        district: json["district"],
        id: json["id"],
        lat: json["lat"]?.toDouble(),
        lng: json["lng"]?.toDouble(),
        number: json["number"],
        state: json["state"],
        street: json["street"],
        zip: json["zip"],
    );

    Map<String, dynamic> toJson() => {
        "alias": alias,
        "city": city,
        "complement": complement,
        "district": district,
        "id": id,
        "lat": lat,
        "lng": lng,
        "number": number,
        "state": state,
        "street": street,
        "zip": zip,
    };
}


///A purchasing quote (orçamento), matching purchasing-service's domain.Quote wire shape.
///QuoteLine is intentionally local to this schema — it is NOT $ref'd to sales-service's
///OrderItem, which stays a separate, independently-evolving shape per its own bounded
///context.
class Quote {
    
    ///Server-assigned; absent on a create request.
    String? createdAt;
    double? deliveryAmount;
    double? discountAmount;
    
    ///Server-assigned; absent on a create request.
    String? id;
    List<QuoteLine> items;
    String notes;
    QuoteStatus? status;
    
    ///Server-computed: sum of item totals. Absent/ignored on a create or update request.
    double? subtotalAmount;
    String supplierId;
    
    ///Server-computed: subtotal - discount + delivery. Absent/ignored on a create or update
    ///request.
    double? totalAmount;

    Quote({
        this.createdAt,
        this.deliveryAmount,
        this.discountAmount,
        this.id,
        required this.items,
        required this.notes,
        this.status,
        this.subtotalAmount,
        required this.supplierId,
        this.totalAmount,
    });

    factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        createdAt: json["created_at"],
        deliveryAmount: json["delivery_amount"]?.toDouble(),
        discountAmount: json["discount_amount"]?.toDouble(),
        id: json["id"],
        items: List<QuoteLine>.from(json["items"].map((x) => QuoteLine.fromJson(x))),
        notes: json["notes"],
        status: quoteStatusValues.map[json["status"]],
        subtotalAmount: json["subtotal_amount"]?.toDouble(),
        supplierId: json["supplier_id"],
        totalAmount: json["total_amount"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "created_at": createdAt,
        "delivery_amount": deliveryAmount,
        "discount_amount": discountAmount,
        "id": id,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
        "notes": notes,
        "status": quoteStatusValues.reverse[status],
        "subtotal_amount": subtotalAmount,
        "supplier_id": supplierId,
        "total_amount": totalAmount,
    };
}

class QuoteLine {
    
    ///Server-assigned; absent on a create/update request.
    String? id;
    String productId;
    double quantity;
    
    ///Server-computed: quantity * unit_price.
    double? totalPrice;
    double unitPrice;

    QuoteLine({
        this.id,
        required this.productId,
        required this.quantity,
        this.totalPrice,
        required this.unitPrice,
    });

    factory QuoteLine.fromJson(Map<String, dynamic> json) => QuoteLine(
        id: json["id"],
        productId: json["product_id"],
        quantity: json["quantity"]?.toDouble(),
        totalPrice: json["total_price"]?.toDouble(),
        unitPrice: json["unit_price"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "product_id": productId,
        "quantity": quantity,
        "total_price": totalPrice,
        "unit_price": unitPrice,
    };
}


///Server-assigned; absent/ignored on a create or update request.
enum QuoteStatus {
    CANCELLED,
    CONVERTED,
    OPEN
}

final quoteStatusValues = EnumValues({
    "CANCELLED": QuoteStatus.CANCELLED,
    "CONVERTED": QuoteStatus.CONVERTED,
    "OPEN": QuoteStatus.OPEN
});

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
            reverseMap = map.map((k, v) => MapEntry(v, k));
            return reverseMap;
    }
}
