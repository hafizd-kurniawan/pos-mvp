import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_constants.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final Function(String) onMethodChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: AppConstants.paymentMethods.map((method) {
        final isSelected = selectedMethod == method;
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          child: InkWell(
            onTap: () => onMethodChanged(method),
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8.r),
                color: isSelected 
                    ? Theme.of(context).primaryColor.withOpacity(0.05)
                    : null,
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: method,
                    groupValue: selectedMethod,
                    onChanged: (value) => onMethodChanged(value!),
                  ),
                  SizedBox(width: 12.w),
                  Icon(
                    _getPaymentIcon(method),
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey.shade600,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPaymentDisplayName(method),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? Theme.of(context).primaryColor 
                                : null,
                          ),
                        ),
                        Text(
                          _getPaymentDescription(method),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                      size: 24.sp,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'cash':
        return Icons.payments;
      case 'transfer':
        return Icons.account_balance;
      case 'credit':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentDisplayName(String method) {
    switch (method) {
      case 'cash':
        return 'Cash Payment';
      case 'transfer':
        return 'Bank Transfer';
      case 'credit':
        return 'Credit/Installment';
      default:
        return method;
    }
  }

  String _getPaymentDescription(String method) {
    switch (method) {
      case 'cash':
        return 'Direct cash payment';
      case 'transfer':
        return 'Transfer via bank or mobile banking';
      case 'credit':
        return 'Credit payment with installment';
      default:
        return '';
    }
  }
}