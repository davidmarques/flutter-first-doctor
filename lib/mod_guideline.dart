import 'package:flutter/material.dart';

// Widget externo para a caixa de texto da questão do guideline
class GuidelineQuestionBox extends StatefulWidget {
  const GuidelineQuestionBox({super.key});

  @override
  State<GuidelineQuestionBox> createState() => _GuidelineQuestionBoxState();
}

class _GuidelineQuestionBoxState extends State<GuidelineQuestionBox> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      minLines: 2,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Digite sua questão sobre guidelines',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class GuidelineHubPage extends StatefulWidget {
  const GuidelineHubPage({super.key});

  @override
  State<GuidelineHubPage> createState() => _GuidelineHubPageState();
}

class _GuidelineHubPageState extends State<GuidelineHubPage> {
  int _selectedTab = 0; // 0 = Ferramenta, 1 = Histórico

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0x550000FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFF000000),
          tooltip: 'Voltar',
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTab = 0;
                  });
                },
                child: Center(
                  child: Text(
                    'GuidelineHub',
                    style: TextStyle(
                      color: _selectedTab == 0 ? const Color(0xFF333333) : const Color(0x55333333),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedTab = 1;
                });
              },
              child: Text(
                'Histórico',
                style: TextStyle(
                  color: _selectedTab == 1 ? const Color(0xFF333333) : const Color(0x55333333),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _selectedTab == 0
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Bem-vindo ao GuidelineHub!',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aqui você poderá buscar, salvar e consultar guidelines clínicos de diversas especialidades.',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 32),
                          const Center(
                            child: Icon(Icons.menu_book, size: 80, color: Colors.orange),
                          ),
                          const SizedBox(height: 32),
                          GuidelineQuestionBox(),
                        ],
                      ),
                    )
                  : const Center(child: Text('Aqui será exibido o histórico de pesquisas.')),
            ),
          ],
        ),
      ),
    );
  }

}
