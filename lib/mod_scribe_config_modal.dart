import 'package:flutter/material.dart';

class ScribeTypeModal {
  static Future<String?> show({
    required BuildContext context,
    required Map<String, dynamic> scribeTypesByCountry,
    String? currentScribeType,
    required Function(String) onScribeTypeChanged,
  }) async {
    String country = scribeTypesByCountry.keys.first;
    final countryTypes = scribeTypesByCountry[country] ?? scribeTypesByCountry['us'];
    final typeKeys = countryTypes.keys.toList();
    String? selected = currentScribeType;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.7),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Customizar modo de prontuário'),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: typeKeys.map<Widget>((typeKey) {
                            final type = countryTypes[typeKey];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/soft-gradient-diagonal.webp'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Card(
                                elevation: 0,
                                color: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: RadioListTile<String>(
                                  title: Text(
                                    type['name'] ?? typeKey,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    type['description'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  value: typeKey,
                                  groupValue: selected,
                                  activeColor: Colors.black87,
                                  onChanged: (val) {
                                    if (val != null) {
                                      onScribeTypeChanged(val);
                                      selected = val;
                                      Navigator.of(ctx).pop();
                                    }
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[400],
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    return selected;
  }
}
