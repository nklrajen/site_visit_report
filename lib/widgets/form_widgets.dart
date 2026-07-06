import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable text field with consistent styling
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final int maxLines;
  final TextInputType inputType;
  final String? Function(String?)? validator;
  final bool compact;
  final bool readOnly;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.maxLines = 1,
    this.inputType = TextInputType.text,
    this.validator,
    this.compact = false,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: maxLines > 1 ? TextInputType.multiline : inputType,
      readOnly: readOnly,
      validator: validator,
      style: TextStyle(
        fontSize: compact ? 13 : 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label.isNotEmpty ? label : null,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, size: compact ? 16 : 18, color: AppColors.textSecondary)
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 8 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputFocused, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        filled: true,
        fillColor: readOnly ? AppColors.surface : Colors.white,
      ),
    );
  }
}

/// Reusable dropdown with consistent styling
class AppDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String hint;
  final bool compact;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              color: AppColors.textHint,
            ),
          ),
          style: TextStyle(
            fontSize: compact ? 12 : 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 6 : 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.inputFocused, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          dropdownColor: Colors.white,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(fontSize: compact ? 12 : 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Dotted border add button used for photos
class DottedAddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const DottedAddButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.sectionBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.4),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status badge chip
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDraft = status == 'draft';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDraft
            ? AppColors.accent.withOpacity(0.1)
            : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDraft
              ? AppColors.accent.withOpacity(0.3)
              : AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Text(
        isDraft ? 'Draft' : 'Submitted',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDraft ? AppColors.accent : AppColors.success,
        ),
      ),
    );
  }
}
