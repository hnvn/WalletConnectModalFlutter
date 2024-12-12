import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility_temp_fork/flutter_keyboard_visibility_temp_fork.dart';
import 'package:walletconnect_modal_flutter/constants/constants.dart';
import 'package:walletconnect_modal_flutter/constants/string_constants.dart';
import 'package:walletconnect_modal_flutter/models/walletconnect_modal_theme_data.dart';
import 'package:walletconnect_modal_flutter/services/utils/platform/platform_utils_singleton.dart';
import 'package:walletconnect_modal_flutter/widgets/grid_list/grid_list_item.dart';
import 'package:walletconnect_modal_flutter/widgets/grid_list/grid_list_item_model.dart';
import 'package:walletconnect_modal_flutter/widgets/grid_list/grid_list_provider.dart';
import 'package:walletconnect_modal_flutter/widgets/wallet_image.dart';
import 'package:walletconnect_modal_flutter/widgets/walletconnect_modal_theme.dart';

enum GridListState { short, long, extraShort }

class GridList<T> extends StatelessWidget {
  static const double tileSize = 60;
  static const double smallTileSize = 50;
  static double getTileBorderRadius(double tileSize) => tileSize / 4.0;

  const GridList({
    super.key,
    this.state = GridListState.short,
    required this.provider,
    this.viewLongList,
    required this.onSelect,
    required this.createListItem,
    this.heightOverride,
    this.longBottomSheetHeightOverride,
    this.longBottomSheetAspectRatio = 0.79,
    this.itemAspectRatio = 0.8,
  });

  final GridListState state;
  final GridListProvider<T> provider;
  final void Function()? viewLongList;
  final void Function(T) onSelect;
  final Widget Function(GridListItemModel<T>, double) createListItem;
  final double? heightOverride;
  final double? longBottomSheetHeightOverride;
  final double longBottomSheetAspectRatio;
  final double itemAspectRatio;

  @override
  Widget build(BuildContext context) {
    final WalletConnectModalThemeData themeData =
        WalletConnectModalTheme.getData(context);

    return ValueListenableBuilder(
      valueListenable: provider.initialized,
      builder: (context, bool value, child) {
        if (value) {
          return _buildGridList(context);
        } else {
          return Container(
            padding: const EdgeInsets.all(8.0),
            height: 240,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  color: themeData.primary100,
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildGridList(BuildContext context) {
    final themeData = WalletConnectModalTheme.getData(context);
    final size = MediaQuery.of(context).size;

    final longBottomSheet = platformUtils.instance.isLongBottomSheet(
      MediaQuery.of(context).orientation,
    );

    return ValueListenableBuilder(
      valueListenable: provider.itemList,
      builder: (context, List<GridListItemModel<T>> value, child) {
        // Get the number of items to display, and the height of the grid list
        int itemCount;
        double height;
        switch (state) {
          case GridListState.short:
            itemCount = min(8, value.length);
            height = longBottomSheet ? 140 : 230;
            break;
          case GridListState.long:
            itemCount = value.length;
            height = longBottomSheet ? 200 : 560;
            break;
          case GridListState.extraShort:
            itemCount = min(4, value.length);
            height = 140;
            break;
        }

        // Handle overrides
        if (longBottomSheet && longBottomSheetHeightOverride != null) {
          height = longBottomSheetHeightOverride!;
        } else if (!longBottomSheet && heightOverride != null) {
          height = heightOverride!;
        }

        // Handle keyboard visibility if we have an empty list
        if (value.isEmpty) {
          return KeyboardVisibilityBuilder(
              builder: (context, isKeyboardVisible) {
            final Widget t = Text(
              StringConstants.noResults,
              style: TextStyle(
                color: themeData.foreground200,
                fontFamily: themeData.fontFamily,
                fontSize: 16,
              ),
            );
            return Container(
              padding: const EdgeInsets.all(8.0),
              height: height,
              child: isKeyboardVisible
                  ? Padding(
                      padding: EdgeInsets.only(top: height / 4),
                      child: t,
                    )
                  : Center(
                      child: t,
                    ),
            );
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          height: height,
          child: GridView.builder(
            key: Key('${value.length}'),
            itemCount: itemCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: longBottomSheet ? 8 : 4,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              childAspectRatio: longBottomSheet
                  ? longBottomSheetAspectRatio
                  : itemAspectRatio,
            ),
            itemBuilder: (context, index) {
              if (index == itemCount - 1 &&
                  value.length > itemCount &&
                  state != GridListState.long) {
                return _buildViewAll(
                  context,
                  value,
                  itemCount,
                );
              } else {
                return GridListItem(
                  key: Key(value[index].title),
                  onSelect: () => onSelect(value[index].data),
                  child: createListItem(
                    value[index],
                    size.height < 700.0
                        ? GridList.smallTileSize
                        : GridList.tileSize,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildViewAll(
    BuildContext context,
    List<GridListItemModel<T>> items,
    int startIndex,
  ) {
    final themeData = WalletConnectModalTheme.getData(context);
    final Size size = MediaQuery.of(context).size;
    final tileSize =
        size.height < 700.0 ? GridList.smallTileSize : GridList.tileSize;

    List<Widget> images = [];

    for (int i = 0; i < 4; i++) {
      if (startIndex + i + 1 > items.length) {
        break;
      }

      images.add(
        WalletImage(
          imageUrl: items[startIndex + i].image,
          imageSize: tileSize / 3.0,
        ),
      );
    }

    return GridListItem(
      key: WalletConnectModalConstants.gridListViewAllButtonKey,
      onSelect: viewLongList ?? () {},
      child: Column(
        children: [
          Container(
            width: tileSize,
            height: tileSize,
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              color: themeData.background200,
              border: Border.all(
                color: themeData.overlay010,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
              borderRadius: BorderRadius.circular(
                GridList.getTileBorderRadius(GridList.tileSize),
              ),
            ),
            child: Center(
              child: Wrap(
                spacing: 4.0,
                runSpacing: 4.0,
                children: images,
              ),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'View All',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontSize: 12.0,
              color: themeData.foreground100,
            ),
          ),
        ],
      ),
    );
  }
}
