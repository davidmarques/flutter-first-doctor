import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class MedCalcAnswerWidget extends StatelessWidget {
  final String answer;
  final VoidCallback onRefreshCalculation;

  const MedCalcAnswerWidget({
    super.key,
    required this.answer,
    required this.onRefreshCalculation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header responsivo
          LayoutBuilder(
            builder: (context, constraints) {
              // Se a largura for muito pequena, empilhar verticalmente
              if (constraints.maxWidth < 400) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Resultado do Cálculo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                              fontSize: 16,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: onRefreshCalculation,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text(
                          'Refazer Cálculo',
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Layout horizontal para telas maiores
                return Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Resultado do Cálculo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                          fontSize: 16,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: TextButton.icon(
                        onPressed: onRefreshCalculation,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text(
                          'Refazer Cálculo',
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 12),
          // Conteúdo HTML da resposta
          Html(
            data: answer,
            style: {
              "body": Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
              "p": Style(
                margin: Margins.only(bottom: 8),
              ),
              "*": Style(
                textOverflow: TextOverflow.visible,
              ),
            },
          ),
        ],
      ),
    );
  }
}
