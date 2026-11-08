import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const _navy = Color(0xFF14213D);

class ErpFormSection extends StatelessWidget {
  final List<Widget> children;
  final String? title;
  final IconData? icon;
  final Color? iconColor;
  const ErpFormSection(
      {super.key,
      required this.children,
      this.title,
      this.icon,
      this.iconColor});
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: s.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: s.outlineVariant.withValues(alpha: .7))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title?.isNotEmpty == true || icon != null) ...[
              Row(children: [
                if (icon != null) ...[
                  Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: (iconColor ?? s.primary).withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(8)),
                      child:
                          Icon(icon, size: 17, color: iconColor ?? s.primary)),
                  const SizedBox(width: 9)
                ],
                if (title?.isNotEmpty == true)
                  Expanded(
                      child: Text(title!,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: s.onSurface))),
              ]),
              const SizedBox(height: 12),
              Divider(color: s.outlineVariant),
              const SizedBox(height: 12),
            ],
            ...children,
          ]),
    );
  }
}

ErpAdaptiveTabs? _findTabs(Widget? child) {
  if (child is ErpAdaptiveTabs) return child;
  if (child is Container) return _findTabs(child.child);
  if (child is Padding) return _findTabs(child.child);
  if (child is Material) return _findTabs(child.child);
  if (child is SizedBox) return _findTabs(child.child);
  if (child is ColoredBox) return _findTabs(child.child);
  return null;
}

PreferredSizeWidget? _bottom(
    BuildContext context, PreferredSizeWidget? bottom) {
  if (!ErpDesignStyle.modern(context) || bottom == null) return bottom;
  if (bottom is PreferredSize) {
    final tabs = _findTabs(bottom.child);
    if (tabs != null) return tabs;
    return bottom;
  }
  return bottom;
}

Widget _toolbarTitle(Widget child) {
  if (child is Text) {
    final style =
        (child.style ?? const TextStyle()).copyWith(color: Colors.white);
    if (child.data == null)
      return Text.rich(child.textSpan!,
          style: style,
          maxLines: child.maxLines ?? 1,
          overflow: child.overflow ?? TextOverflow.ellipsis,
          textAlign: child.textAlign);
    return Text(child.data!,
        key: child.key,
        style: style,
        maxLines: child.maxLines ?? 1,
        overflow: child.overflow ?? TextOverflow.ellipsis,
        textAlign: child.textAlign,
        softWrap: child.softWrap,
        textScaler: child.textScaler,
        semanticsLabel: child.semanticsLabel);
  }
  if (child is Icon)
    return Icon(child.icon,
        key: child.key,
        size: child.size,
        color: Colors.white,
        semanticLabel: child.semanticLabel);
  if (child is Row)
    return Row(
        key: child.key,
        mainAxisAlignment: child.mainAxisAlignment,
        mainAxisSize: child.mainAxisSize,
        crossAxisAlignment: child.crossAxisAlignment,
        textBaseline: child.textBaseline,
        children: child.children.map(_toolbarTitle).toList());
  if (child is Column)
    return Column(
        key: child.key,
        mainAxisAlignment: child.mainAxisAlignment,
        mainAxisSize: child.mainAxisSize,
        crossAxisAlignment: child.crossAxisAlignment,
        textBaseline: child.textBaseline,
        children: child.children.map(_toolbarTitle).toList());
  if (child is Expanded)
    return Expanded(
        key: child.key, flex: child.flex, child: _toolbarTitle(child.child));
  if (child is Flexible)
    return Flexible(
        key: child.key,
        flex: child.flex,
        fit: child.fit,
        child: _toolbarTitle(child.child));
  if (child is Padding)
    return Padding(
        key: child.key,
        padding: child.padding,
        child: child.child == null ? null : _toolbarTitle(child.child!));
  if (child is Container)
    return Container(
        key: child.key,
        alignment: child.alignment,
        padding: child.padding,
        color: child.color,
        decoration: child.decoration,
        foregroundDecoration: child.foregroundDecoration,
        constraints: child.constraints,
        margin: child.margin,
        transform: child.transform,
        transformAlignment: child.transformAlignment,
        clipBehavior: child.clipBehavior,
        child: child.child == null ? null : _toolbarTitle(child.child!));
  if (child is SizedBox)
    return SizedBox(
        key: child.key,
        width: child.width,
        height: child.height,
        child: child.child == null ? null : _toolbarTitle(child.child!));
  if (child is GestureDetector && child.child != null)
    return GestureDetector(
        key: child.key,
        onTap: child.onTap,
        onTapDown: child.onTapDown,
        onTapUp: child.onTapUp,
        onTapCancel: child.onTapCancel,
        onDoubleTap: child.onDoubleTap,
        onLongPress: child.onLongPress,
        behavior: child.behavior,
        excludeFromSemantics: child.excludeFromSemantics,
        child: _toolbarTitle(child.child!));
  if (child is IconButton)
    return IconButton(
        key: child.key,
        icon: _toolbarTitle(child.icon),
        onPressed: child.onPressed,
        tooltip: child.tooltip,
        iconSize: child.iconSize,
        padding: child.padding,
        alignment: child.alignment,
        visualDensity: child.visualDensity,
        constraints: child.constraints,
        color: Colors.white,
        disabledColor: Colors.white38,
        focusNode: child.focusNode,
        autofocus: child.autofocus,
        enableFeedback: child.enableFeedback,
        isSelected: child.isSelected,
        selectedIcon: child.selectedIcon == null
            ? null
            : _toolbarTitle(child.selectedIcon!),
        style: child.style);
  return child;
}

/// Keeps the existing Classic toolbar; Modern uses the shared navy toolbar.
class ErpPageAppBar extends AppBar {
  ErpPageAppBar({
    super.key,
    required BuildContext context,
    Widget? title,
    Widget? leading,
    List<Widget>? actions,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    PreferredSizeWidget? bottom,
    double? toolbarHeight,
    bool? centerTitle,
    double? titleSpacing,
  }) : super(
          title: ErpDesignStyle.modern(context) && title != null
              ? _toolbarTitle(title)
              : title,
          leading: ErpDesignStyle.modern(context) && leading != null
              ? _toolbarTitle(leading)
              : leading,
          actions: ErpDesignStyle.modern(context)
              ? actions?.map(_toolbarTitle).toList()
              : actions,
          backgroundColor:
              ErpDesignStyle.modern(context) ? _navy : backgroundColor,
          foregroundColor:
              ErpDesignStyle.modern(context) ? Colors.white : foregroundColor,
          elevation: ErpDesignStyle.modern(context) ? 0 : elevation,
          bottom: _bottom(context, bottom),
          toolbarHeight: toolbarHeight,
          centerTitle: ErpDesignStyle.modern(context) ? false : centerTitle,
          titleSpacing: titleSpacing,
        );
}

class ErpPageSliverAppBar extends SliverAppBar {
  ErpPageSliverAppBar({
    super.key,
    required BuildContext context,
    Widget? title,
    List<Widget>? actions,
    Widget? leading,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? surfaceTintColor,
    double? elevation,
    double? expandedHeight,
    double toolbarHeight = kToolbarHeight,
    bool pinned = false,
    Widget? flexibleSpace,
    PreferredSizeWidget? bottom,
  }) : super(
          title: ErpDesignStyle.modern(context) && title != null
              ? _toolbarTitle(title)
              : title,
          actions: ErpDesignStyle.modern(context)
              ? actions?.map(_toolbarTitle).toList()
              : actions,
          leading: ErpDesignStyle.modern(context) && leading != null
              ? _toolbarTitle(leading)
              : leading,
          backgroundColor:
              ErpDesignStyle.modern(context) ? _navy : backgroundColor,
          foregroundColor:
              ErpDesignStyle.modern(context) ? Colors.white : foregroundColor,
          surfaceTintColor: surfaceTintColor,
          elevation: elevation,
          expandedHeight: expandedHeight,
          toolbarHeight: toolbarHeight,
          pinned: pinned,
          flexibleSpace: flexibleSpace,
          bottom: _bottom(context, bottom),
        );
}

/// Uses the same controller and callbacks, so swiping and validation stay intact.
class ErpAdaptiveTabs extends StatefulWidget implements PreferredSizeWidget {
  final TabBar tabBar;
  final bool modern;
  ErpAdaptiveTabs(
      {super.key, required BuildContext context, required this.tabBar})
      : modern = ErpDesignStyle.modern(context);
  @override
  Size get preferredSize =>
      modern ? const Size.fromHeight(64) : tabBar.preferredSize;
  @override
  State<ErpAdaptiveTabs> createState() => _ErpAdaptiveTabsState();
}

class _ErpAdaptiveTabsState extends State<ErpAdaptiveTabs> {
  final _scroll = ScrollController();
  int _shownIndex = -1;
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _reveal(int index) {
    if (_shownIndex == index) return;
    _shownIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target =
          (index * 114.0 - _scroll.position.viewportDimension / 2 + 57)
              .clamp(0.0, _scroll.position.maxScrollExtent);
      if ((_scroll.offset - target).abs() > .5)
        _scroll.animateTo(target,
            duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bar = widget.tabBar;
    if (!widget.modern) return bar;
    final controller = bar.controller ?? DefaultTabController.of(context);
    final scheme = Theme.of(context).colorScheme;
    final scrollable = bar.isScrollable || bar.tabs.length > 4;
    return AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (scrollable) _reveal(controller.index);
          Widget tile(int index) => Padding(
                padding: EdgeInsets.only(
                    right: index == bar.tabs.length - 1 ? 0 : 6),
                child: Material(
                  color: controller.index == index
                      ? scheme.primary
                      : const Color(0xFF24334F),
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                      onTap: () {
                        controller.animateTo(index);
                        bar.onTap?.call(index);
                      },
                      child: SizedBox(
                          height: 44,
                          child: Center(
                              child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: DefaultTextStyle(
                                    style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: controller.index == index
                                            ? scheme.onPrimary
                                            : Colors.white70),
                                    child: _label(
                                        bar.tabs[index],
                                        controller.index == index
                                            ? scheme.onPrimary
                                            : Colors.white70))),
                          )))),
                ),
              );
          final row = Row(children: [
            for (var i = 0; i < bar.tabs.length; i++)
              if (scrollable)
                SizedBox(width: 114, child: tile(i))
              else
                Expanded(child: tile(i)),
          ]);
          return Material(
              color: _navy,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  child: scrollable
                      ? SingleChildScrollView(
                          controller: _scroll,
                          scrollDirection: Axis.horizontal,
                          child: row)
                      : row));
        });
  }

  Widget _label(Widget child, Color color) {
    if (child is Tab) {
      if (child.text != null) return Text(child.text!);
      if (child.child != null) return _label(child.child!, color);
      if (child.icon != null) return _label(child.icon!, color);
    }
    if (child is Text && child.data != null)
      return Text(child.data!, style: child.style?.copyWith(color: color));
    if (child is Icon)
      return Icon(child.icon, size: child.size ?? 16, color: color);
    if (child is Row)
      return Row(
          mainAxisSize: MainAxisSize.min,
          children: child.children.map((c) => _label(c, color)).toList());
    if (child is Column)
      return Column(
          mainAxisSize: MainAxisSize.min,
          children: child.children.map((c) => _label(c, color)).toList());
    return child;
  }
}
