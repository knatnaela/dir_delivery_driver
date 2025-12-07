import 'package:flutter/material.dart';
import 'package:dir_delivery_driver/util/dimensions.dart';
import 'package:dir_delivery_driver/util/styles.dart';

class FareWidget extends StatelessWidget {
  final String title;
  final String value;
  const FareWidget({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(value,
          style: textRegular.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: Dimensions.fontSizeSmall)),
      const SizedBox(height: 3),
      Text(title,
          style: textRobotoRegular.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              fontSize: Dimensions.fontSizeSmall)),
    ]);
  }
}
