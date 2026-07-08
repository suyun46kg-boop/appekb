import '../database.dart';

class DeviceTokensTable extends SupabaseTable<DeviceTokensRow> {
  @override
  String get tableName => 'device_tokens';

  @override
  DeviceTokensRow createRow(Map<String, dynamic> data) => DeviceTokensRow(data);
}

class DeviceTokensRow extends SupabaseDataRow {
  DeviceTokensRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => DeviceTokensTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get fcmToken => getField<String>('fcm_token')!;
  set fcmToken(String value) => setField<String>('fcm_token', value);

  String get platform => getField<String>('platform')!;
  set platform(String value) => setField<String>('platform', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
