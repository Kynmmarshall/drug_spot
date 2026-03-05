import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.path,
    required this.useAsset,
    this.radius = 20,
    this.backgroundColor,
  });

  final String path;
  final bool useAsset;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
      child: ClipOval(
        child: SizedBox(width: size, height: size, child: _buildImage(context)),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (path.isEmpty) {
      return _placeholder(context);
    }

    if (useAsset) {
      if (path.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(
          path,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => _placeholder(context),
        );
      }
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }

    return Image.network(
      path,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _placeholder(context);
      },
      errorBuilder: (_, __, ___) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Icon(Icons.person, color: Theme.of(context).colorScheme.primary);
  }
}
