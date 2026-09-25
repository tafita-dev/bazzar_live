// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductImpl _$$ProductImplFromJson(Map<String, dynamic> json) =>
    _$ProductImpl(
      id: json['id'] as String,
      codeJp: json['code_jp'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      sellerId: json['seller_id'] as String,
      categoryId: json['category_id'] as String?,
      imageUrl: json['image_url'] as String?,
    );

Map<String, dynamic> _$$ProductImplToJson(_$ProductImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code_jp': instance.codeJp,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'stock': instance.stock,
      'seller_id': instance.sellerId,
      'category_id': instance.categoryId,
      'image_url': instance.imageUrl,
    };
