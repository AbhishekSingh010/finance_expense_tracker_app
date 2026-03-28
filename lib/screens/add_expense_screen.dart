import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../services/gemini_service.dart';
import '../data/models/expense.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;
  const AddExpenseScreen({Key? key, this.existingExpense}) : super(key: key);

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = ['Food', 'Travel', 'Bills', 'Shopping', 'Others'];
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      _amountController.text = widget.existingExpense!.amount.toString();
      _noteController.text = widget.existingExpense!.note;
      if (_categories.contains(widget.existingExpense!.category)) {
        _selectedCategory = widget.existingExpense!.category;
      }
      try {
        _selectedDate = DateTime.parse(widget.existingExpense!.date);
      } catch (e) {
        // use default
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final expense = Expense(
        id: widget.existingExpense?.id,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        note: _noteController.text,
      );

      if (widget.existingExpense != null) {
        Provider.of<ExpenseProvider>(context, listen: false).updateExpense(expense);
      } else {
        Provider.of<ExpenseProvider>(context, listen: false).addExpense(expense);
      }
      Navigator.pop(context);
    }
  }

  Future<void> _scanReceipt() async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    if (!provider.hasApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set Gemini API Key in settings first')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      setState(() {
        _isScanning = true;
      });

      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await _geminiService.scanReceipt(base64Image, 'image/jpeg', provider.apiKey!);

      if (result != null) {
        setState(() {
          if (result['amount'] != null) _amountController.text = result['amount'].toString();
          if (result['note'] != null) _noteController.text = result['note'].toString();

          final parsedCategory = result['category']?.toString() ?? '';
          final capCategory = parsedCategory.isNotEmpty ? '${parsedCategory[0].toUpperCase()}${parsedCategory.substring(1)}' : '';

          if (parsedCategory.isNotEmpty && _categories.contains(capCategory)) {
            _selectedCategory = capCategory;
          } else if (parsedCategory.isNotEmpty && _categories.contains(parsedCategory)) {
            _selectedCategory = parsedCategory;
          }

          if (result['date'] != null) {
            try {
              _selectedDate = DateTime.parse(result['date']);
            } catch (_) {}
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt scanned successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to parse receipt')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning receipt: $e')),
        );
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingExpense != null;
    final currencySymbol = Provider.of<ExpenseProvider>(context).currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.error),
                  onPressed: () {
                    if (widget.existingExpense?.id != null) {
                      Provider.of<ExpenseProvider>(context, listen: false)
                          .deleteExpense(widget.existingExpense!.id!);
                      Navigator.pop(context);
                    }
                  },
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isEditing) ...[
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : _scanReceipt,
                      icon: _isScanning
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt),
                      label: Text(_isScanning ? 'Scanning...' : 'Scan Receipt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Container(
                    decoration: AppTheme.glassDecoration(
                      opacity: 0.05,
                      color: AppTheme.surface,
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 20, right: 10),
                              child: Text(currencySymbol, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category, color: AppTheme.textSecondary),
                    ),
                    dropdownColor: AppTheme.surface,
                    items: _categories.map((String category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Picker
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today, color: AppTheme.textSecondary),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Note Field
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                      prefixIcon: Icon(Icons.notes, color: AppTheme.textSecondary),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button
                  ElevatedButton(
                    onPressed: _saveExpense,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(isEditing ? 'Update Expense' : 'Save Expense', style: const TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
