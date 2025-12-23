// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResponseDto _$ResponseDtoFromJson(Map<String, dynamic> json) => ResponseDto(
  status: json['status'] as String,
  result: ResultDto.fromJson(json['result'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ResponseDtoToJson(ResponseDto instance) =>
    <String, dynamic>{'status': instance.status, 'result': instance.result};

ResultDto _$ResultDtoFromJson(Map<String, dynamic> json) => ResultDto(
  intent: json['intent'] as String,
  params: (json['params'] as List<dynamic>)
      .map((e) => EventDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ResultDtoToJson(ResultDto instance) => <String, dynamic>{
  'intent': instance.intent,
  'params': instance.params,
};

EventDto _$EventDtoFromJson(Map<String, dynamic> json) => EventDto(
  summary: json['summary'] as String,
  start: json['start'] == null ? null : DateTime.parse(json['start'] as String),
  end: json['end'] == null ? null : DateTime.parse(json['end'] as String),
  location: json['location'] as String?,
  description: json['description'] as String?,
);

Map<String, dynamic> _$EventDtoToJson(EventDto instance) => <String, dynamic>{
  'summary': instance.summary,
  'start': instance.start?.toIso8601String(),
  'end': instance.end?.toIso8601String(),
  'location': instance.location,
  'description': instance.description,
};
