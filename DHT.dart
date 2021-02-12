import 'package:flutter/services.dart';

class DHT {
  final double temp;
  final double humidity;

  DHT({this.temp, this.humidity});

  factory DHT.fromJson(Map<dynamic, dynamic> json) {
    double parser(dynamic source) {
      try {
        return double.parse(source.toString());
      } on FormatException {
        return -1;
      }
    }

    return DHT(
        temp: parser(json['quantidade_gas']), humidity: parser(json['fuga_gas']));
  }
}
