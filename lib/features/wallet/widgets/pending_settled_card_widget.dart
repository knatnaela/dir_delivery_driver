import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dir_delivery_driver/common_widgets/divider_widget.dart';
import 'package:dir_delivery_driver/features/wallet/controllers/wallet_controller.dart';
import 'package:dir_delivery_driver/features/wallet/domain/models/pending_settled_withdraw_model.dart';
import 'package:dir_delivery_driver/features/wallet/widgets/pending_withdrawn_bottomsheet_widget.dart';
import 'package:dir_delivery_driver/helper/date_converter.dart';
import 'package:dir_delivery_driver/helper/price_converter.dart';
import 'package:dir_delivery_driver/util/dimensions.dart';
import 'package:dir_delivery_driver/util/images.dart';
import 'package:dir_delivery_driver/util/styles.dart';

class PendingSettledCardWidget extends StatelessWidget {
  final PendingSettleInfo pendingSettleInfo;
  const PendingSettledCardWidget({super.key, required this.pendingSettleInfo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        0,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
      ),
      child: GetBuilder<WalletController>(builder: (walletController) {
        return InkWell(
          splashColor: walletController.selectedHistoryIndex == 1 ? null : Colors.transparent,
          onTap: () {
            if (walletController.selectedHistoryIndex == 1) {
              showModalBottomSheet(
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                context: context,
                builder: (_) => PendingWithdrawnBottomsheetWidget(pendingSettleInfo: pendingSettleInfo),
              );
            }
          },
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Row(children: [
                Expanded(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                      width: Dimensions.iconSizeLarge,
                      child: Image.asset(Images.myEarnIcon, color: Theme.of(context).primaryColor)),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(
                          walletController.selectedHistoryIndex == 1 ? 'req_created_at'.tr : 'request_settled'.tr,
                          style: textSemiBold.copyWith(color: Theme.of(context).primaryColor),
                        ),
                        if (walletController.selectedHistoryIndex == 1)
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                                color: pendingSettleInfo.status == 'pending'
                                    ? Colors.blue.withValues(alpha: 0.25)
                                    : pendingSettleInfo.status == 'denied'
                                        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.25)
                                        : Theme.of(context).primaryColor.withValues(alpha: 0.25)),
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                            margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                            child: Text('${pendingSettleInfo.status?.tr}',
                                style: textRegular.copyWith(
                                    color: pendingSettleInfo.status == 'pending'
                                        ? Colors.blue
                                        : pendingSettleInfo.status == 'denied'
                                            ? Theme.of(context).colorScheme.error
                                            : Theme.of(context).primaryColor)),
                          )
                      ]),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                        child: Text(
                          DateConverter.isoStringToDateTimeString(pendingSettleInfo.createdAt!),
                          style: textRegular.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ),
                    ]),
                  ),
                ])),
                Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall,
                      vertical: Dimensions.paddingSizeExtraSmall,
                    ),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Theme.of(context).primaryColor.withValues(alpha: .08)),
                    child: Text(PriceConverter.convertPrice(context, pendingSettleInfo.amount ?? 0),
                        style: textRobotoBold.copyWith(color: Theme.of(context).primaryColor)))
              ]),
            ),
            DividerWidget(height: .5, color: Theme.of(context).hintColor.withValues(alpha: .75))
          ]),
        );
      }),
    );
  }
}
