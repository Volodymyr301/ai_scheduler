// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

part 'server_response_dto.g.dart';


@JsonSerializable()
class ResponseDto {
  final String status;
  final ResultDto result;

  ResponseDto({required this.status, required this.result});

  factory ResponseDto.fromJson(Map<String, dynamic> json) => _$ResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ResponseDtoToJson(this);
}

@JsonSerializable()
class ResultDto {
  final String intent;
  final List<EventDto> params;

  ResultDto({required this.intent, required this.params});

  factory ResultDto.fromJson(Map<String, dynamic> json) => _$ResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ResultDtoToJson(this);
}


@JsonSerializable()
class EventDto {
  final String summary;

  final DateTime? start, end;
  final String? location, description;

  EventDto({required this.summary, required this.start, required this.end, this.location, this.description});

  factory EventDto.fromJson(Map<String, dynamic> json) => _$EventDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EventDtoToJson(this);
}