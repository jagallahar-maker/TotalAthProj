import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/screens/spreadsheet_import_screen.dart';
import 'package:total_athlete/services/data_reset_service.dart';
import 'package:total_athlete/services/crashlytics_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader(context, 'Account'),
          const SizedBox(height: 12),
          _buildAccountCard(context, user),
          
          const SizedBox(height: 32),
          
          // Units Section
          _buildSectionHeader(context, 'Units'),
          const SizedBox(height: 12),
          _buildUnitPreferenceCard(context, provider, user),
          
          const SizedBox(height: 32),
          
          // Equipment Settings Section
          _buildSectionHeader(context, 'Equipment Settings'),
          const SizedBox(height: 12),
          _buildEquipmentSettingsCard(context, provider, user),
          
          const SizedBox(height: 32),
          
          // Appearance Section (Placeholder)
          _buildSectionHeader(context, 'Appearance'),
          const SizedBox(height: 12),
          _buildAppearanceCard(context),
          
          const SizedBox(height: 32),
          
          // Developer Tools Section
          _buildSectionHeader(context, 'Developer Tools'),
          const SizedBox(height: 12),
          _buildDeveloperToolsCard(context),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        children: [
          _buildProfileRow(context, Icons.person_outline_rounded, 'Name', user.name),
          const SizedBox(height: 12),
          _buildProfileRow(context, Icons.email_outlined, 'Email', user.email),
        ],
      ),
    );
  }

  Widget _buildProfileRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitPreferenceCard(BuildContext context, AppProvider provider, user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUnit = user.preferredUnit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fitness_center_rounded,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Weight Unit',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Choose how you want weights displayed throughout the app',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildUnitOption(
                  context,
                  'Kilograms',
                  'kg',
                  currentUnit == 'kg',
                  () => provider.updateUnitPreference('kg'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUnitOption(
                  context,
                  'Pounds',
                  'lb',
                  currentUnit == 'lb',
                  () => provider.updateUnitPreference('lb'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitOption(
    BuildContext context,
    String label,
    String unit,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkPrimary.withOpacity(0.15) : AppColors.lightPrimary.withOpacity(0.15))
              : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Icon(
                Icons.check_circle,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentSettingsCard(BuildContext context, AppProvider provider, user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Smith Machine Bar Weight',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Set the default bar weight for smith machine exercises. Standard barbell weight is 45 lb / 20 kg.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 20),
          
          // Kilograms input
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kilograms (kg)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: user.smithMachineBarWeightKg.toStringAsFixed(1)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                            width: 2,
                          ),
                        ),
                        suffixText: 'kg',
                      ),
                      onChanged: (value) {
                        final weight = double.tryParse(value);
                        if (weight != null && weight >= 0) {
                          provider.updateSmithMachineBarWeight(kg: weight);
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pounds (lb)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: user.smithMachineBarWeightLb.toStringAsFixed(1)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                            width: 2,
                          ),
                        ),
                        suffixText: 'lb',
                      ),
                      onChanged: (value) {
                        final weight = double.tryParse(value);
                        if (weight != null && weight >= 0) {
                          provider.updateSmithMachineBarWeight(lb: weight);
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_rounded,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Theme',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Dark mode is currently active. Theme customization coming soon.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperToolsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.code_rounded,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Developer Tools',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Import historical data or reset app data for testing',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 16),
          
          // Import from Spreadsheet Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.push('/spreadsheet-import');
              },
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Import from Spreadsheet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                side: BorderSide(
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Rebuild Personal Records Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showRebuildPRsDialog(context),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Rebuild Personal Records'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                side: BorderSide(
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Test Crash Button (for Crashlytics testing)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showTestCrashDialog(context),
              icon: const Icon(Icons.bug_report_rounded),
              label: const Text('Test Crash (Crashlytics)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.orange.shade400 : Colors.orange.shade600,
                side: BorderSide(
                  color: isDark ? Colors.orange.shade400 : Colors.orange.shade600,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Test Non-Fatal Error Button (for Crashlytics testing)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showTestNonFatalErrorDialog(context),
              icon: const Icon(Icons.error_outline_rounded),
              label: const Text('Test Non-Fatal Error'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.amber.shade400 : Colors.amber.shade600,
                side: BorderSide(
                  color: isDark ? Colors.amber.shade400 : Colors.amber.shade600,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Reset All Data Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showResetDataDialog(context),
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Reset All Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.red.shade400 : Colors.red.shade600,
                side: BorderSide(
                  color: isDark ? Colors.red.shade400 : Colors.red.shade600,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showTestCrashDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Row(
          children: [
            Icon(
              Icons.bug_report_rounded,
              color: isDark ? Colors.orange.shade400 : Colors.orange.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              'Test Crash',
              style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
            ),
          ],
        ),
        content: Text(
          'This will force a crash to test Firebase Crashlytics integration.\n\nThe crash will be reported to Firebase Console within a few minutes.\n\n⚠️ The app will close immediately.',
          style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              
              // Log context before crash
              final crashlytics = CrashlyticsService();
              crashlytics.log('User triggered test crash from Settings > Developer Tools');
              crashlytics.setCustomKey('test_crash', 'true');
              
              // Show brief message before crashing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Triggering test crash...'),
                  duration: Duration(seconds: 1),
                ),
              );
              
              // Delay crash slightly to show the snackbar
              Future.delayed(const Duration(milliseconds: 500), () {
                crashlytics.testCrash();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.orange.shade400 : Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Trigger Crash'),
          ),
        ],
      ),
    );
  }
  
  void _showTestNonFatalErrorDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: isDark ? Colors.amber.shade400 : Colors.amber.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              'Test Non-Fatal Error',
              style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
            ),
          ],
        ),
        content: Text(
          'This will log a non-fatal error to Firebase Crashlytics.\n\nThe error will appear in the Firebase Console but the app will continue running normally.\n\n✅ Safe to test - app will not crash.',
          style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              
              // Log a non-fatal error with context
              final crashlytics = CrashlyticsService();
              crashlytics.log('User triggered test non-fatal error from Settings > Developer Tools');
              crashlytics.setCustomKey('test_non_fatal_error', 'true');
              crashlytics.setCustomKey('test_timestamp', DateTime.now().toIso8601String());
              
              // Record a non-fatal error
              crashlytics.recordError(
                Exception('Test non-fatal error from Developer Tools'),
                StackTrace.current,
                reason: 'Testing Crashlytics non-fatal error reporting',
                fatal: false,
              );
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✅ Non-fatal error logged to Crashlytics'),
                  backgroundColor: isDark ? Colors.green.shade700 : Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.amber.shade400 : Colors.amber.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Error'),
          ),
        ],
      ),
    );
  }
  
  void _showRebuildPRsDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Row(
          children: [
            Icon(
              Icons.refresh_rounded,
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
            const SizedBox(width: 12),
            Text(
              'Rebuild Personal Records?',
              style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
            ),
          ],
        ),
        content: Text(
          'This will scan all your completed workouts and recalculate Personal Records using the correct ranking logic (highest weight first, then highest reps).\n\nExisting PRs will be cleared and rebuilt from workout history.',
          style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              
              final provider = Provider.of<AppProvider>(context, listen: false);
              
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => PopScope(
                  canPop: false,
                  child: AlertDialog(
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    content: Row(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(width: 16),
                        Text(
                          'Rebuilding PRs...',
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              
              // Rebuild PRs with error handling
              try {
                await provider.rebuildPersonalRecords();
                
                // Close loading dialog
                if (context.mounted) {
                  Navigator.of(context).pop();
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Personal Records rebuilt successfully! Found ${provider.personalRecords.length} PRs.'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                // Close loading dialog on error
                if (context.mounted) {
                  Navigator.of(context).pop();
                  
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error rebuilding Personal Records: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
            child: const Text('Rebuild'),
          ),
        ],
      ),
    );
  }

  void _showResetDataDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: isDark ? Colors.red.shade400 : Colors.red.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              'Reset All Data?',
              style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete all your workouts, personal records, bodyweight logs, and goals. This action cannot be undone.\n\nYour exercise database and routine templates will be preserved.',
          style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _performDataReset(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.red.shade400 : Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDataReset(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final resetService = DataResetService();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Resetting data...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    // Perform reset
    final success = await resetService.resetAllUserData();
    
    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    
    // Show result
    if (context.mounted) {
      if (success) {
        // Refresh app state
        await provider.forceReloadAllData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ All data has been reset successfully'),
            backgroundColor: isDark ? Colors.green.shade700 : Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Navigate to home
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Failed to reset data. Please try again.'),
            backgroundColor: isDark ? Colors.red.shade700 : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
