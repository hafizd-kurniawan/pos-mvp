// Placeholder widgets for dialogs and other components

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/car.dart';
import '../models/invoice.dart';

// Car Filter Dialog
class CarFilterDialog extends StatefulWidget {
  final List<String> brands;
  final String? selectedBrand;
  final String? selectedModel;
  final int? yearFrom;
  final int? yearTo;
  final double? priceFrom;
  final double? priceTo;
  final String? fuelType;
  final String? transmission;

  const CarFilterDialog({
    super.key,
    required this.brands,
    this.selectedBrand,
    this.selectedModel,
    this.yearFrom,
    this.yearTo,
    this.priceFrom,
    this.priceTo,
    this.fuelType,
    this.transmission,
  });

  @override
  State<CarFilterDialog> createState() => _CarFilterDialogState();
}

class _CarFilterDialogState extends State<CarFilterDialog> {
  // Implementation would go here - simplified for demo
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Cars'),
      content: const Text('Filter options would be implemented here'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, <String, dynamic>{}),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

// Car Details Dialog
class CarDetailsDialog extends StatelessWidget {
  final Car car;

  const CarDetailsDialog({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              car.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16.h),
            Text('License: ${car.licensePlate}'),
            Text('Status: ${car.statusDisplayName}'),
            if (car.sellingPrice != null)
              Text('Price: Rp ${car.sellingPrice!.toStringAsFixed(0)}'),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

// Invoice Filter Dialog
class InvoiceFilterDialog extends StatefulWidget {
  final String? selectedStatus;
  final DateTime? fromDate;
  final DateTime? toDate;

  const InvoiceFilterDialog({
    super.key,
    this.selectedStatus,
    this.fromDate,
    this.toDate,
  });

  @override
  State<InvoiceFilterDialog> createState() => _InvoiceFilterDialogState();
}

class _InvoiceFilterDialogState extends State<InvoiceFilterDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Invoices'),
      content: const Text('Invoice filter options would be implemented here'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, <String, dynamic>{}),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

// Invoice Details Dialog
class InvoiceDetailsDialog extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailsDialog({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Invoice ${invoice.invoiceNumber}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16.h),
            Text('Type: ${invoice.typeDisplayName}'),
            Text('Status: ${invoice.statusDisplayName}'),
            Text('Amount: Rp ${invoice.totalAmount.toStringAsFixed(0)}'),
            Text('Payment: ${invoice.paymentMethodDisplayName}'),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                if (!invoice.isPaid)
                  ElevatedButton(
                    onPressed: () {
                      // Mark as paid logic would go here
                      Navigator.pop(context);
                    },
                    child: const Text('Mark Paid'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Invoice Card
class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor(invoice.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      invoice.statusDisplayName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(invoice.status),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text('Amount: Rp ${invoice.totalAmount.toStringAsFixed(0)}'),
              Text('Payment: ${invoice.paymentMethodDisplayName}'),
              Text('Date: ${invoice.createdAt.toString().split(' ')[0]}'),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'draft':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}