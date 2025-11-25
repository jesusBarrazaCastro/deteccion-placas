import 'package:flutter/material.dart';

class DialogUtil {
  /// Opens a dialog with a custom widget and a close button
  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    double? width,
    double? height,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    bool barrierDismissible = true,
    Color backgroundColor = Colors.white,
    BorderRadiusGeometry borderRadius = const BorderRadius.all(Radius.circular(16)),
    bool? showCloseButton = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        return Dialog(
          //backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          child: Container(
            decoration: BoxDecoration(color: backgroundColor, borderRadius: borderRadius),
            width: width ?? MediaQuery.of(context).size.width * 0.8,
            height: height ?? MediaQuery.of(context).size.height * 0.6,
            padding: padding,
            child: Column(
              children: [
                Row(
                  children: [
                    Text(title??'', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),),
                    const Spacer(),
                    if(showCloseButton??false)
                    InkWell(
                      child: const Icon(Icons.close, color: Colors.black,),
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                ),
                const Divider(),
                Flexible(child: child)
              ],
            )
          ),
        );
      },
    );
  }
}
