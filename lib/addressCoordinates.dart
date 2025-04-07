import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';

class LocationService {
  static const String _geocodingUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  final String apiKey;

  LocationService(this.apiKey);

  Future<LatLng?> getCoordinates(String address) async {
    try {
      // Validate API key
      if (apiKey.isEmpty) {
        _showToast('Google Maps API key is missing');
        return null;
      }

      // Validate address
      if (address.isEmpty) {
        _showToast('Please enter an address');
        return null;
      }

      final response = await http.get(
        Uri.parse('$_geocodingUrl?address=${Uri.encodeComponent(address)}&key=$apiKey'),
      ).timeout(const Duration(seconds: 10));

      // Check HTTP response status
      if (response.statusCode != 200) {
        _showToast('Failed to connect to Google Maps API: ${response.statusCode}');
        return null;
      }

      final decodedResponse = jsonDecode(response.body);

      // Handle API response status
      switch (decodedResponse['status']) {
        case 'OK':
          final location = decodedResponse['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        
        case 'ZERO_RESULTS':
          _showToast('No results found for "$address"');
          return null;
        
        case 'OVER_QUERY_LIMIT':
          _showToast('Query limit exceeded. Please try again later.');
          return null;
        
        case 'REQUEST_DENIED':
          _showToast('Request denied. Check your API key.');
          return null;
        
        case 'INVALID_REQUEST':
          _showToast('Invalid request. Please check the address format.');
          return null;
        
        case 'UNKNOWN_ERROR':
          _showToast('An unknown error occurred. Please try again.');
          return null;
        
        default:
          _showToast('Error: ${decodedResponse['status']}');
          return null;
      }
    } on http.ClientException catch (e) {
      _showToast('Network error: ${e.message}');
      return null;
    } on TimeoutException catch (_) {
      _showToast('Request timed out. Please check your connection.');
      return null;
    } on FormatException catch (_) {
      _showToast('Invalid response from server.');
      return null;
    } catch (e) {
      _showToast('An unexpected error occurred: $e');
      return null;
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    debugPrint(message);
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng(lat: $latitude, lng: $longitude)';
}