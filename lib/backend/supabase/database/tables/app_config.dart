import '../database.dart';

class AppConfigTable extends SupabaseTable<AppConfigRow> {
  @override
  String get tableName => 'app_config';

  @override
  AppConfigRow createRow(Map<String, dynamic> data) => AppConfigRow(data);
}

class AppConfigRow extends SupabaseDataRow {
  AppConfigRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AppConfigTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get minVersion => getField<String>('min_version')!;
  set minVersion(String value) => setField<String>('min_version', value);

  String get latestVersion => getField<String>('latest_version')!;
  set latestVersion(String value) => setField<String>('latest_version', value);

  String get messageRu => getField<String>('message_ru')!;
  set messageRu(String value) => setField<String>('message_ru', value);

  String get messageKy => getField<String>('message_ky')!;
  set messageKy(String value) => setField<String>('message_ky', value);

  String get androidUrl => getField<String>('android_url')!;
  set androidUrl(String value) => setField<String>('android_url', value);

  String get iosUrl => getField<String>('ios_url') ?? '';
  set iosUrl(String value) => setField<String>('ios_url', value);
}
