import 'package:flutter/material.dart';
import 'state.dart';

class Palette {
  final bool dark;
  const Palette(this.dark);
  Color get ground => Color(dark ? 0xFF020617 : 0xFFF8FAFC);
  Color get surface => Color(dark ? 0xFF0F172A : 0xFFFFFFFF);
  Color get raised => Color(dark ? 0xFF1E293B : 0xFFF1F5F9);
  Color get ink => Color(dark ? 0xFFF8FAFC : 0xFF0F172A);
  Color get muted => Color(dark ? 0xFF94A3B8 : 0xFF64748B);
  Color get border => Color(dark ? 0xFF1E293B : 0xFFE2E8F0);
  Color get primary => Color(dark ? 0xFF10B981 : 0xFF059669);
  Color get error => Color(dark ? 0xFFF43F5E : 0xFFE11D48);
  LinearGradient get background => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: dark
          ? const [Color(0xFF040812), Color(0xFF081430), Color(0xFF081C28)]
          : const [Colors.white, Color(0xFFF0F7FF), Color(0xFFE6F3F2)]);
}

TextStyle font(double size,
        {Color? color,
        FontWeight weight = FontWeight.w600,
        String family = 'Inter',
        double? spacing}) =>
    TextStyle(
        fontFamily: family,
        fontFamilyFallback: const ['HindSiliguri', 'NotoSansBengali'],
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing);
Widget text(String value,
        {double size = 14,
        Color? color,
        FontWeight weight = FontWeight.w600,
        TextAlign? align,
        int? lines,
        String family = 'Inter',
        double? spacing}) =>
    Text(value,
        style: font(size,
            color: color, weight: weight, family: family, spacing: spacing),
        textAlign: align,
        maxLines: lines,
        overflow: lines == null ? null : TextOverflow.ellipsis);
Widget gap([double height = 14]) => SizedBox(height: height);
Widget hgap([double width = 8]) => SizedBox(width: width);
Widget stack(List<Widget> children,
        {double spacing = 14,
        CrossAxisAlignment align = CrossAxisAlignment.start}) =>
    Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) gap(spacing),
            children[i]
          ]
        ]);
Widget panel(Palette p, Widget child,
        {double radius = 20,
        double padding = 16,
        Color? color,
        bool shadow = false}) =>
    Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
            color: color ?? p.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: p.border),
            boxShadow: shadow && !p.dark
                ? [
                    const BoxShadow(
                        color: Color(0x180F172A),
                        blurRadius: 16,
                        offset: Offset(0, 6))
                  ]
                : null),
        child: child);
Widget pill(String value, Color color, {Color? background, double size = 10}) =>
    Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: background ?? color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: .2))),
        child: text(value, size: size, color: color));
Widget roundIcon(IconData icon, Palette p,
        {VoidCallback? onTap,
        double size = 40,
        Color? tint,
        Color? background}) =>
    InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                color: background ?? p.surface,
                shape: BoxShape.circle,
                border: Border.all(color: p.border)),
            child: Icon(icon, color: tint ?? p.ink, size: size * .5)));
Widget primary(String label, VoidCallback? action,
        {bool gradient = false,
        bool busy = false,
        double height = 52,
        IconData? icon}) =>
    Opacity(
        opacity: action == null && !busy ? 0.5 : 1.0,
        child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: gradient
                    ? const LinearGradient(colors: [
                        Color(0xFF0F766E),
                        Color(0xFF0D9488),
                        Color(0xFF14B8A6)
                      ])
                    : null,
                color: gradient ? null : const Color(0xFF059669)),
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                    onTap: busy ? null : action,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                        child: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                                Flexible(
                                    child: text(label,
                                        size: 15,
                                        color: Colors.white,
                                        align: TextAlign.center,
                                        family: 'PlusJakartaSans')),
                                if (icon != null) ...[
                                  hgap(),
                                  Icon(icon, color: Colors.white, size: 18)
                                ]
                              ]))))));
Widget secondary(String label, VoidCallback? action, Palette p,
        {IconData? icon}) =>
    SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
            onPressed: action,
            style: OutlinedButton.styleFrom(
                foregroundColor: p.primary,
                side: BorderSide(color: p.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 18), hgap()],
              Flexible(
                  child: text(label,
                      size: 13, color: p.primary, align: TextAlign.center))
            ])));
Widget link(String value, VoidCallback action,
        {Color color = const Color(0xFF0D9488), double size = 12}) =>
    InkWell(
        onTap: action,
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: text(value, size: size, color: color)));
void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)));
Widget field(String label, TextEditingController controller, Palette p,
        {String? hint,
        TextInputType keyboard = TextInputType.text,
        bool obscure = false,
        int? maxLength,
        int lines = 1,
        ValueChanged<String>? onChanged,
        Widget? suffix}) =>
    stack([
      if (label.isNotEmpty) text(label, size: 12, color: p.muted),
      TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboard,
          obscureText: obscure,
          maxLength: maxLength,
          maxLines: lines,
          style: font(14, color: p.ink),
          decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: font(13, color: p.muted),
              filled: true,
              fillColor: p.ground,
              suffixIcon: suffix,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.primary, width: 1.5))))
    ], spacing: 8);
Widget sectionTitle(String title, Palette p,
        {String? action, VoidCallback? onAction}) =>
    Row(children: [
      Expanded(
          child:
              text(title, size: 16, color: p.ink, family: 'PlusJakartaSans')),
      if (action != null) link(action, onAction ?? () {}, color: p.primary)
    ]);
Widget infoRow(String title, String value, Palette p, {Color? valueColor}) =>
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: text(title, size: 12, color: p.muted)),
      hgap(),
      Flexible(
          child: text(value,
              size: 13, color: valueColor ?? p.ink, align: TextAlign.right))
    ]);
Widget tabs(List<String> options, int selected, ValueChanged<int> onTap,
        Palette p) =>
    Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: p.raised, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          for (int i = 0; i < options.length; i++)
            Expanded(
                child: InkWell(
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 3),
                        decoration: BoxDecoration(
                            color:
                                i == selected ? p.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: i == selected
                                ? [
                                    const BoxShadow(
                                        color: Color(0x10000000), blurRadius: 4)
                                  ]
                                : null),
                        child: text(options[i],
                            size: 11,
                            color: i == selected ? p.primary : p.muted,
                            align: TextAlign.center))))
        ]));
ThemeData buildTheme(bool dark) {
  final p = Palette(dark);
  return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: p.ground,
      colorScheme: ColorScheme.fromSeed(
          seedColor: p.primary,
          brightness: dark ? Brightness.dark : Brightness.light,
          surface: p.surface),
      textTheme: TextTheme(
          bodyMedium: font(14, color: p.ink),
          bodySmall: font(12, color: p.muted)),
      dividerColor: p.border);
}

class Emblem extends StatelessWidget {
  final double size;
  const Emblem({super.key, this.size = 68});
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 18 / 68),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF020617)]),
          border: Border.all(color: const Color(0x33FFFFFF), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x330D9488), blurRadius: 16)
          ]),
      child: Center(
          child: CustomPaint(
              size: Size(size / 2, size / 2), painter: EmblemPainter())));
}

class EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(w * .12, h * .18, w * .88, h * .28),
            const Radius.circular(2)),
        Paint()..color = const Color(0xFF38BDF8));
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(w * .22, h * .36, w * .78, h * .46),
            const Radius.circular(2)),
        Paint()..color = const Color(0xFF2DD4BF));
    final path = Path()
      ..moveTo(w * .5, h * .88)
      ..lineTo(w * .26, h * .54)
      ..lineTo(w * .74, h * .54)
      ..close();
    c.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)])
              .createShader(Rect.fromLTRB(0, h * .54, w, h * .88)));
    c.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF5EEAD4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class Ground extends StatelessWidget {
  final ToriState state;
  final Widget child;
  const Ground({super.key, required this.state, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(gradient: Palette(state.dark).background),
      child: child);
}
