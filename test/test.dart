import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: RadioGroup<String>(
          groupValue: 'a',
          onChanged: (String? val) {},
          child: Column(
            children: [
              RadioListTile<String>(
                value: 'a',
                title: Text('A'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
