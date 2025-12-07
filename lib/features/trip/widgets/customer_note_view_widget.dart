import 'package:flutter/material.dart';
import 'package:dir_delivery_driver/util/dimensions.dart';
import 'package:dir_delivery_driver/util/styles.dart';

class CustomerNoteViewWidget extends StatelessWidget {
  final String title;
  final String details;
  final EdgeInsets? edgeInsets;
  const CustomerNoteViewWidget({
    super.key,
    required this.title,
    required this.details,
    this.edgeInsets,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: edgeInsets ?? const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          title,
          style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.secondaryFixedDim),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(
          details,
          style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
        )
      ]),
    );
  }
}
