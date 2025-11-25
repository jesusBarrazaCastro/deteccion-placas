import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';

class DateInputController extends ChangeNotifier {
  DateTime? _selectedDate;

  DateTime? get selectedDate => _selectedDate;

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void clear() {
    _selectedDate = null;
    notifyListeners();
  }

  String getFormattedDate({Locale? locale, String? format}) {
    if (_selectedDate == null) return '';
    final DateFormat formatter = DateFormat(
      format ?? 'dd/MM/yyyy', // 📆 Formato por defecto día/mes/año
      locale?.toString(),
    );
    return formatter.format(_selectedDate!);
  }
}

class DateInput extends StatefulWidget {
  final String? labelText;
  final TextStyle? labelStyle;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final bool required;
  final bool enabled;
  final DateInputController controller;
  final void Function(DateTime?)? onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final Locale? locale;

  const DateInput({
    Key? key,
    this.labelText,
    this.labelStyle,
    this.width,
    this.height = 40,
    this.backgroundColor,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 2.0,
    this.required = false,
    this.enabled = true,
    required this.controller,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.locale,
  }) : super(key: key);

  @override
  State<DateInput> createState() => _DateInputState();
}

class _DateInputState extends State<DateInput> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.getFormattedDate(
        locale: widget.locale,
        format: 'dd/MM/yyyy',
      ),
    );

    // Update text whenever the controller changes
    widget.controller.addListener(() {
      _textController.text = widget.controller.getFormattedDate(
        locale: widget.locale,
        format: 'dd/MM/yyyy',
      );
    });
  }


  Future<void> _selectDate(BuildContext context) async {
    if (!widget.enabled) return;

    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: widget.locale,
      initialDate:
      widget.controller.selectedDate ?? widget.initialDate ?? now,
      firstDate: widget.firstDate ?? DateTime(2000),
      lastDate: widget.lastDate ?? DateTime(2100),
      builder: (context, child) {
        // 🎨 Personaliza el color del calendario (opcional)
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.light.primary, // color principal del calendario
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.light.primary, // color de los botones
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      widget.controller.setDate(picked);
      widget.onChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          Text(
            widget.labelText!,
            style: widget.labelStyle ??
                const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: TextField(
            controller: _textController,
            readOnly: true,
            enabled: widget.enabled,
            onTap: () => _selectDate(context),
            decoration: InputDecoration(
              hintText: '',
              filled: true,
              fillColor: widget.backgroundColor ?? Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_month_sharp, color: Colors.grey,),
                onPressed: () => _selectDate(context),
              ),
              border: OutlineInputBorder(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: widget.borderColor ?? Colors.grey,
                  width: widget.borderWidth,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: widget.borderColor ?? Colors.grey,
                  width: widget.borderWidth,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: AppTheme.light.primary,
                  width: widget.borderWidth,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
