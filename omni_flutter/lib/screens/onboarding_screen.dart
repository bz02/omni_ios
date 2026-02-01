import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  DateTime _selectedDate = DateTime.now();
  final _petNameController = TextEditingController();
  final _petTypeController = TextEditingController();

  // For enhanced calendar
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _selectedDay = DateTime.now().day;

  @override
  void dispose() {
    _petNameController.dispose();
    _petTypeController.dispose();
    super.dispose();
  }

  void _updateSelectedDate() {
    setState(() {
      _selectedDate = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    });
  }

  void _generateEnergyDNA() {
    if (_petNameController.text.isEmpty || _petTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    context.read<AppState>().completeOnboarding(
          dateOfBirth: _selectedDate,
          petName: _petNameController.text,
          petType: _petTypeController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFB6D9).withOpacity(0.2),
              const Color(0xFFA78BFA).withOpacity(0.2),
              const Color(0xFFF8F4FF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Text(
                  '✨ Welcome to Omni',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2640),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your AI-Powered Energy Guide',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Enhanced Calendar Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Birthday',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Month Dropdown
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              value: _selectedMonth,
                              decoration: InputDecoration(
                                labelText: 'Month',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: List.generate(12, (index) {
                                final month = index + 1;
                                const months = [
                                  'January', 'February', 'March', 'April',
                                  'May', 'June', 'July', 'August',
                                  'September', 'October', 'November', 'December'
                                ];
                                return DropdownMenuItem(
                                  value: month,
                                  child: Text(months[index]),
                                );
                              }),
                              onChanged: (value) {
                                setState(() {
                                  _selectedMonth = value!;
                                  _updateSelectedDate();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Day Dropdown
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedDay,
                              decoration: InputDecoration(
                                labelText: 'Day',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: List.generate(31, (index) {
                                final day = index + 1;
                                return DropdownMenuItem(
                                  value: day,
                                  child: Text('$day'),
                                );
                              }),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDay = value!;
                                  _updateSelectedDate();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Year Dropdown
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedYear,
                              decoration: InputDecoration(
                                labelText: 'Year',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: List.generate(75, (index) {
                                final year = DateTime.now().year - index;
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text('$year'),
                                );
                              }),
                              onChanged: (value) {
                                setState(() {
                                  _selectedYear = value!;
                                  _updateSelectedDate();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Pet Name
                TextField(
                  controller: _petNameController,
                  decoration: InputDecoration(
                    labelText: 'Pet\'s Name',
                    hintText: 'e.g., Luna',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.pets),
                  ),
                ),

                const SizedBox(height: 16),

                // Pet Type
                TextField(
                  controller: _petTypeController,
                  decoration: InputDecoration(
                    labelText: 'Pet Type',
                    hintText: 'e.g., Cat',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.category),
                  ),
                ),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _generateEnergyDNA,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFFF6B9D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Generate My Energy DNA ✨',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
