import 'package:flutter/material.dart';
import 'package:drivesense/ui/core/themes/colors.dart';

class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final VoidCallback? onLeadingPressed;

  const AppHeaderBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.onLeadingPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      centerTitle: centerTitle,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading:
          leading != null
              ? IconButton(icon: leading!, onPressed: onLeadingPressed)
              : null,
      actions: actions,
      iconTheme: IconThemeData(
        color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
