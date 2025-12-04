import 'package:flutter/material.dart';

/// Widget wrapper que maneja de forma consistente las safe areas
/// para todos los dispositivos, incluyendo Android con y sin botones de navegación,
/// notch, barra de estado, etc.
class SafeAreaWrapper extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets? additionalPadding;
  final Color? backgroundColor;

  const SafeAreaWrapper({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.additionalPadding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // Obtener los valores de padding del sistema
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final leftPadding = mediaQuery.padding.left;
    final rightPadding = mediaQuery.padding.right;

    // Calcular padding adicional si se proporciona
    final additional = additionalPadding ?? EdgeInsets.zero;

    Widget content = child;

    // Aplicar padding solo donde sea necesario
    if (top || bottom || left || right || additional != EdgeInsets.zero) {
      content = Padding(
        padding: EdgeInsets.only(
          top: (top ? topPadding : 0) + additional.top,
          bottom: (bottom ? bottomPadding : 0) + additional.bottom,
          left: (left ? leftPadding : 0) + additional.left,
          right: (right ? rightPadding : 0) + additional.right,
        ),
        child: child,
      );
    }

    // Si hay un color de fondo, envolver en un Container
    if (backgroundColor != null) {
      return Container(
        color: backgroundColor,
        child: content,
      );
    }

    return content;
  }
}

/// Widget que proporciona un scaffold con safe areas configuradas
/// Útil para pantallas completas que necesitan respetar todas las áreas seguras
class SafeScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const SafeScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      appBar: appBar,
      body: SafeAreaWrapper(
        top: !extendBodyBehindAppBar,
        bottom: false, // El bottom se maneja en el bottomNavigationBar
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar != null
          ? SafeAreaWrapper(
              top: false,
              bottom: true,
              child: bottomNavigationBar!,
            )
          : null,
      drawer: drawer,
      endDrawer: endDrawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}

/// Widget que proporciona padding responsivo basado en el tamaño de pantalla
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600 && size.width < 1200;
    final isDesktop = size.width >= 1200;

    EdgeInsets padding;
    if (isDesktop && desktop != null) {
      padding = desktop!;
    } else if (isTablet && tablet != null) {
      padding = tablet!;
    } else {
      padding = mobile ?? const EdgeInsets.all(16.0);
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Widget que proporciona constraints responsivos para el contenido
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final Alignment? alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600 && size.width < 1200;
    final isDesktop = size.width >= 1200;

    double? containerMaxWidth;
    if (maxWidth != null) {
      containerMaxWidth = maxWidth;
    } else {
      if (isDesktop) {
        containerMaxWidth = 1200;
      } else if (isTablet) {
        containerMaxWidth = 800;
      }
    }

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: child);
    }

    if (containerMaxWidth != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: containerMaxWidth),
          child: content,
        ),
      );
    }

    return alignment != null
        ? Align(alignment: alignment!, child: content)
        : content;
  }
}

