import 'package:flutter/material.dart';

class AddressInfo extends StatelessWidget {
  final bool isIntheDeliveryArea;

  const AddressInfo({super.key, required this.isIntheDeliveryArea});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      color: isIntheDeliveryArea ? Colors.green[100] : Colors.red[100],
      child: Text(
        isIntheDeliveryArea ? "Inside the geofence" : "Outside the geofence",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isIntheDeliveryArea ? Colors.green : Colors.red,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
