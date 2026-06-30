import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class ApibirCall {
  static Future<ApiCallResponse> call({
    int? offset = 0,
    String? categoryId = 'eq.4',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'apibir',
      apiUrl: 'https://kavafhnszdzjtgxkqpqw.supabase.co/rest/v1/listings',
      callType: ApiCallType.GET,
      headers: {
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImthdmFmaG5zemR6anRneGtxcHF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIzNjQ1MDEsImV4cCI6MjA5Nzk0MDUwMX0.GpXNDp0BpEddIokVtwSyqOBjMfpt89zKeldMP9qg73A',
        'Authorization':
            'bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImthdmFmaG5zemR6anRneGtxcHF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIzNjQ1MDEsImV4cCI6MjA5Nzk0MDUwMX0.GpXNDp0BpEddIokVtwSyqOBjMfpt89zKeldMP9qg73A',
      },
      params: {
        'limit': 10,
        'offset': offset,
        'select': "id,price,title,img,description",
        'category_id': categoryId,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GlavniapiCall {
  static Future<ApiCallResponse> call({
    int? offsetl = 0,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'glavniapi',
      apiUrl: 'https://fvgobdianshfsygssylk.supabase.co/rest/v1/listings',
      callType: ApiCallType.GET,
      headers: {
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ2Z29iZGlhbnNoZnN5Z3NzeWxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4MDU3MjYsImV4cCI6MjA4OTM4MTcyNn0.7WukyH_sySUgFZINc2Ze_LU4wGhvprZJxaOFvQjJk2Y',
        'Authorization':
            'bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ2Z29iZGlhbnNoZnN5Z3NzeWxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4MDU3MjYsImV4cCI6MjA4OTM4MTcyNn0.7WukyH_sySUgFZINc2Ze_LU4wGhvprZJxaOFvQjJk2Y',
      },
      params: {
        'limit': 5,
        'offset': offsetl,
        'select': "id,price,title,img,description,created_at",
        'order': "created_at.desc",
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}
